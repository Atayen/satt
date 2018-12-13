pragma solidity ^0.5;

contract owned {
    address payable public owner;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface IERC20 {
   function transfer(address _to, uint256 _value) external;
   
   function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) ;
}

contract ERC20Holder is owned {
    mapping (address => bool) acceptedTokens;
    function modToken(address token,bool accepted) public onlyOwner {
        acceptedTokens[token] = accepted;
    }
    
    function tokenFallback(/*address _from, uint _value, bytes _data*/) view public {
       require(acceptedTokens[msg.sender]);
    }
    
    function() external  payable {}
    
    function withdraw() onlyOwner public {
        owner.transfer(address(this).balance);
    }
    
    function transferToken (address token,address to,uint256 val) public onlyOwner {
        IERC20 erc20 = IERC20(token);
        erc20.transfer(to,val);
    }
    
}

contract oracleClient is ERC20Holder {
    address oracle;
    
    function setOracle(address a) public  onlyOwner {
        
        oracle = a;
    }
}

interface IOracle {
    function  ask (uint8 typeSN, string calldata idPost,string calldata idUser, bytes32 idRequest) external;
}


contract campaign is oracleClient {
    
    enum status {NotExists,Prepared,Validated,Running,Ended}
    enum promStatus {NotExists,Inited,Validated,Rejected}
    
    struct cpRatio {
        uint256 likeRatio;
        uint256 shareRatio;
        uint256 viewRatio;
    }
    
    struct Campaign {
		address advertiser;
		string dataUrl; // IPFS link hosted by us
		uint32 startDate;
		uint32 endDate;
		status campaignState;
		uint64 nbProms;
		mapping (uint64 => bytes32) proms;
		Fund funds;
		mapping(uint8 => cpRatio) ratios;
	}
	
	
	struct Fund {
	    address token;
	    uint256 amount;
	}
	
	struct Result  {
	    bytes32 idProm;
	    uint64 likes;
	    uint64 shares;
	    uint64 views;
	}
	
	struct promElement {
	    address influencer;
	    bytes32 idCampaign;
	    Fund funds;
	    promStatus status;
	    uint8 typeSN;
	    string idPost;
	    string idUser;
	    uint64 nbResults;
	    mapping (uint64 => bytes32) results;
	    bytes32 prevResult;
	}

	
	mapping (bytes32  => Campaign) campaigns;
	mapping (bytes32  => promElement) proms;
	mapping (bytes32  => Result) results;
	
	
	event CampaignCreated(bytes32 indexed id,uint32 startDate,uint32 endDate,string dataUrl);
	event CampaignStarted(bytes32 indexed id );
	event CampaignEnded(bytes32 indexed id );
	event CampaignFundsSpent(bytes32 indexed id );
	event CampaignApplied(bytes32 indexed id ,bytes32 indexed prom );
	
	event oracleResult( bytes32 idRequest,uint64 likes,uint64 shares,uint64 views);
	
    
    function createCampaign(string memory dataUrl,	uint32 startDate,uint32 endDate) public returns (bytes32 idCampaign) {
        require(startDate > now);
        require(endDate > now);
        require(endDate < startDate);
        bytes32 campaignId = keccak256(abi.encodePacked(msg.sender,dataUrl,startDate,endDate,now));
        campaigns[campaignId] = Campaign(msg.sender,dataUrl,startDate,endDate,status.Prepared,0,Fund(address(0),0));
        emit CampaignCreated(campaignId,startDate,endDate,dataUrl);
        return campaignId;
    }
    
    
    
    function modCampaign(bytes32 idCampaign,string memory dataUrl,	uint32 startDate,uint32 endDate) public {
        require(campaigns[idCampaign].advertiser == msg.sender);
        require(startDate > now);
        require(endDate > now);
        require(endDate < startDate);
        require(campaigns[idCampaign].campaignState == status.Prepared);
        campaigns[idCampaign].dataUrl = dataUrl;
        campaigns[idCampaign].startDate = startDate;
        campaigns[idCampaign].endDate = endDate;
        emit CampaignCreated(idCampaign,startDate,endDate,dataUrl);
    }
    
     function priceCampaign(bytes32 idCampaign,uint8 typeSN,uint256 likeRatio,uint256 shareRatio,uint256 viewRatio) public {
        require(campaigns[idCampaign].advertiser == msg.sender);
        require(campaigns[idCampaign].campaignState == status.Prepared);
        campaigns[idCampaign].ratios[typeSN] = cpRatio(likeRatio,shareRatio,viewRatio);
    }
    
    function fundCampaign (bytes32 idCampaign,address token,uint256 amount) public {
        require(campaigns[idCampaign].campaignState == status.Prepared || campaigns[idCampaign].campaignState == status.Running);
        require(acceptedTokens[token]);
        require(campaigns[idCampaign].funds.token == address(0) || campaigns[idCampaign].funds.token == token);
       
        IERC20 erc20 = IERC20(token);
        erc20.transferFrom(msg.sender,address(this),amount);
        uint256 prev_amount = campaigns[idCampaign].funds.amount;
        
        campaigns[idCampaign].funds = Fund(token,amount+prev_amount);
    }
    
    function applyCampaign(bytes32 idCampaign,uint8 typeSN, string memory idPost, string memory idUser) public returns (bytes32 idProm) {
        // only Campaign owner ? param 
       require(campaigns[idCampaign].campaignState == status.Prepared || campaigns[idCampaign].campaignState == status.Running);
        idProm = keccak256(abi.encodePacked( msg.sender,typeSN,idPost,idUser,now));
        proms[idProm] = promElement(msg.sender,idCampaign,Fund(address(0),0),promStatus.NotExists,typeSN,idPost,idUser,0,0);
        campaigns[idCampaign].proms[campaigns[idCampaign].nbProms++] = idProm;
        
        bytes32 idRequest = keccak256(abi.encodePacked(typeSN,idPost,idUser,now));
        results[idRequest] = Result(idProm,0,0,0);
        proms[idProm].results[0] = proms[idProm].prevResult = idRequest;
        proms[idProm].nbResults = 1;
        
        ask(typeSN,idPost,idUser,idRequest);
        
        emit CampaignApplied(idCampaign,idProm);
        return idProm;
    }
    
    function validateProm(bytes32 idCampaign,bytes32 idProm,bool accepted) public {
        require(campaigns[idCampaign].campaignState == status.Prepared || campaigns[idCampaign].campaignState == status.Running);
        require(campaigns[idCampaign].advertiser == msg.sender);
        require(proms[idProm].idCampaign == idCampaign);
        if(accepted)
            proms[idProm].status = promStatus.Validated;
        else
            proms[idProm].status = promStatus.Rejected;
    }
    
    
    function startCampaign(bytes32 idCampaign) public onlyOwner {
         require(campaigns[idCampaign].campaignState == status.Prepared);
         campaigns[idCampaign].campaignState == status.Running;
         campaigns[idCampaign].startDate = uint32(now);
         emit CampaignStarted(idCampaign);
    }
    
    function updateCampaignStats(bytes32 idCampaign) public onlyOwner {
        require(campaigns[idCampaign].campaignState == status.Running);
        for(uint64 i = 0;i < campaigns[idCampaign].nbProms ;i++)
        {
            bytes32 idProm = campaigns[idCampaign].proms[i];
            if(proms[idProm].status != promStatus.Validated ) {
                revert();
            }
            bytes32 idRequest = keccak256(abi.encodePacked(proms[idProm].typeSN,proms[idProm].idPost,proms[idProm].idUser,now));
            results[idRequest] = Result(idProm,0,0,0);
            proms[idProm].results[proms[idProm].nbResults++] = idRequest;
            ask(proms[idProm].typeSN,proms[idProm].idPost,proms[idProm].idUser,idRequest);
        }
    }
    
    function endCampaign(bytes32 idCampaign) public onlyOwner {
        require(campaigns[idCampaign].campaignState == status.Running);
        campaigns[idCampaign].campaignState == status.Ended;
        campaigns[idCampaign].endDate = uint32(now);
        emit CampaignEnded(idCampaign);
    }
    
    
    function ask(uint8 typeSN, string memory idPost,string memory idUser,bytes32 idRequest) public {
        IOracle o = IOracle(oracle);
        o.ask(typeSN,idPost,idUser,idRequest);
    }
    
    
    function update(bytes32 idRequest,uint64 likes,uint64 shares,uint64 views) external  returns (bool ok) {
        emit oracleResult(idRequest,likes,shares,views);
        results[idRequest].likes = likes;
        results[idRequest].shares = shares;
        results[idRequest].views = views;
        promElement storage prom = proms[results[idRequest].idProm];
      
        uint256 gain = (likes - results[prom.prevResult].likes)* campaigns[prom.idCampaign].ratios[prom.typeSN].likeRatio;
        gain += (shares - results[prom.prevResult].shares)* campaigns[prom.idCampaign].ratios[prom.typeSN].shareRatio;
        gain += (views - results[prom.prevResult].views)* campaigns[prom.idCampaign].ratios[prom.typeSN].viewRatio;
        prom.prevResult = idRequest;
        //
        // warn campaign low credits
        //
        if(campaigns[prom.idCampaign].funds.amount < gain )
        {
            campaigns[prom.idCampaign].campaignState == status.Ended;
            emit CampaignEnded(prom.idCampaign);
            emit CampaignFundsSpent(prom.idCampaign);
            return true;
        }
        campaigns[prom.idCampaign].funds.amount -= gain;
        prom.funds.amount += gain;
        return true;
    }
    
    function getGains(bytes32 idProm) public {
        require(proms[idProm].influencer == msg.sender);
        IERC20 erc20 = IERC20(proms[idProm].funds.token);
        erc20.transferFrom(address(this),proms[idProm].influencer,proms[idProm].funds.amount);
        proms[idProm].funds.amount = 0;
    }
    
    function getRemainingFunds(bytes32 idCampaign) public {
        require(campaigns[idCampaign].advertiser == msg.sender);
        IERC20 erc20 = IERC20(campaigns[idCampaign].funds.token);
        erc20.transferFrom(address(this),campaigns[idCampaign].advertiser,campaigns[idCampaign].funds.amount);
        campaigns[idCampaign].funds.amount = 0;
    }
    
}