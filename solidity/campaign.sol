pragma solidity ^0.4.25;

contract owned {
    address public owner;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
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
    
    function() public payable {}
    
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
    function  ask (uint8 typeSN,string idPost,string idUser, bytes32 idRequest) external;
}


contract campaign is oracleClient {
    
    enum status {NotExists,Prepared,Validated,Running,Ended}
    
    struct Campaign {
		address advertiser;
		string dataUrl; // IPFS link hosted by us
		uint32 startDate;
		uint32 endDate;
		status campaignState;
		uint64 nbProms;
		mapping (uint64 => bytes32) proms;
		Fund funds;
		uint256 cpc; 	//CPC ratio
	}
	
	
	struct Fund {
	    address token;
	    uint256 amount;
	}
	
	struct Result  {
	    uint64 likes;
	    uint64 shares;
	    uint64 views;
	}
	
	struct promElement {
	    address influencer;
	    uint8 typeSN;
	    string idPost;
	    string idUser;
	    uint64 nbResults;
	    mapping (uint64 => bytes32) results;
	}

	
	mapping (bytes32  => Campaign) campaigns;
	mapping (bytes32  => promElement) proms;
	mapping (bytes32  => Result) results;
	
	
	event CampaignCreated(bytes32 indexed id );
	event CampaignStarted(bytes32 indexed id );
	event CampaignEnded(bytes32 indexed id );
	event CampaignApplied(bytes32 indexed id ,bytes32 indexed prom );
	
	event oracleResult( bytes32 idRequest,uint64 likes,uint64 shares,uint64 views);
	
    
    function createCampaign(string dataUrl,	uint32 startDate,uint32 endDate) public returns (bytes32 idCampaign) {
        require(startDate > now);
        require(endDate > now);
        require(endDate < startDate);
        bytes32 campaignId = keccak256(abi.encodePacked(msg.sender,dataUrl,startDate,endDate,now));
        campaigns[campaignId] = Campaign(msg.sender,dataUrl,startDate,endDate,status.Prepared,0,Fund(0,0),0);
        emit CampaignCreated(campaignId);
        return campaignId;
    }
    
    function modCampaign(bytes32 idCampaign,string dataUrl,	uint32 startDate,uint32 endDate) public {
        require(startDate > now);
        require(endDate > now);
        require(endDate < startDate);
        require(campaigns[idCampaign].campaignState == status.Prepared);
        campaigns[idCampaign].dataUrl = dataUrl;
        campaigns[idCampaign].startDate = startDate;
        campaigns[idCampaign].endDate = endDate;
        
    }
    
    function fundCampaign (bytes32 idCampaign,address token,uint256 amount) public {
        require(campaigns[idCampaign].campaignState == status.Prepared);
        require(acceptedTokens[token]);
        require(campaigns[idCampaign].funds.token == address(0) || campaigns[idCampaign].funds.token == token);
       
        IERC20 erc20 = IERC20(token);
        erc20.transferFrom(msg.sender,address(this),amount);
        uint256 prev_amount = campaigns[idCampaign].funds.amount;
        
        campaigns[idCampaign].funds = Fund(token,amount+prev_amount);
    }
    
    function applyCampaign(bytes32 idCampaign,uint8 typeSN, string idPost, string idUser) public returns (bytes32 idProm) {
        // only Campaign owner ? param 
        require(campaigns[idCampaign].campaignState == status.Prepared);
        idProm = keccak256(abi.encodePacked( msg.sender,typeSN,idPost,idUser,now));
        proms[idProm] = promElement(msg.sender,typeSN,idPost,idUser,0);
        campaigns[idCampaign].proms[campaigns[idCampaign].nbProms++] = idProm;
        emit CampaignApplied(idCampaign,idProm);
        return idProm;
    }
    
    
    function startCampaign(bytes32 idCampaign) public onlyOwner {
         require(campaigns[idCampaign].campaignState == status.Validated);
         campaigns[idCampaign].campaignState == status.Running;
         emit CampaignStarted(idCampaign);
    }
    
    function updateCampaignStats(bytes32 idCampaign) public onlyOwner {
        require(campaigns[idCampaign].campaignState == status.Running);
        for(uint64 i = 0;i < campaigns[idCampaign].nbProms ;i++)
        {
            bytes32 idProm = campaigns[idCampaign].proms[i];
            bytes32 idRequest = keccak256(abi.encodePacked(proms[idProm].typeSN,proms[idProm].idPost,proms[idProm].idUser,now));
            results[idRequest] = Result(0,0,0);
            proms[idProm].results[proms[idProm].nbResults++] = idRequest;
            ask(proms[idProm].typeSN,proms[idProm].idPost,proms[idProm].idUser,idRequest);
        }
    }
    
    function endCampaign(bytes32 idCampaign) public onlyOwner {
        require(campaigns[idCampaign].campaignState == status.Running);
        campaigns[idCampaign].campaignState == status.Ended;
        emit CampaignEnded(idCampaign);
    }
    
    
    function ask(uint8 typeSN, string idPost,string idUser,bytes32 idRequest) public {
        IOracle o = IOracle(oracle);
        o.ask(typeSN,idPost,idUser,idRequest);
    }
    
    
    function update(bytes32 idRequest,uint64 likes,uint64 shares,uint64 views) external  returns (bool ok) {
        emit oracleResult(idRequest,likes,shares,views);
        results[idRequest].likes = likes;
        results[idRequest].shares = shares;
        results[idRequest].views = views;
        return true;
    }
    
}