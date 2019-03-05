# SATT
Atayen Platform and ERC20 Token Solidity smart contract

## Campaign.sol

### Contract methods
 
`createCampaign(string memory dataUrl,	uint64 startDate,uint64 endDate)`

Creates a new campaign for an advertiser
- dataUrl : off blockchain campaign description url
- startDate : campaign start date 
- endDate : campaign end date 
returns campaign identifier (keccak256 hash)


`modCampaign(bytes32 idCampaign,string memory dataUrl,	uint64 startDate,uint64 endDate)`

modifies an existing campaign only if not started
- idCampaign : campaign identifier
- dataUrl : off blockchain campaign description url
- startDate : campaign start date 
- endDate : campaign end date 


`fundCampaign (bytes32 idCampaign,address token,uint256 amount)`

funds campaign with ERC20 token
- idCampaign : campaign identifier
- ERC20token : ERC20 token address
- amount : token amount in base units


`priceRatioCampaign(bytes32 idCampaign,uint8 typeSN,uint256 likeRatio,uint256 shareRatio,uint256 viewRatio)`

set ratios according to a social network
- idCampaign : campaign identifier
- typeSN : social network identifier (1:facebook,2:youtube,3:instagram,4:twitter)
- likeRatio : base unit amount of a like in ERC20 token
- shareRatio : base unit amount of a share in ERC20 token (facebook,Twitter only)
- viewRatio : base unit amount of a view in ERC20 token  (youtube only)



`createPriceFundYt(string memory dataUrl,uint64 startDate,uint64 endDate,uint256 likeRatio,uint256 viewRatio,address token,uint256 amount)`

youtube one-time helper to create campaign, fund it ans set its ratios
- dataUrl : off blockchain campaign description url
- startDate : campaign start date 
- endDate : campaign end date 
- likeRatio : base unit amount of a like in ERC20 token
- viewRatio : base unit amount of a view in ERC20 token


`applyCampaign(bytes32 idCampaign,uint8 typeSN, string memory idPost, string memory idUser)`

applies to a campaign for an editor
- idCampaign : campaign identifier
- typeSN : social network identifier (1:facebook,2:youtube,3:instagram,4:twitter)
- idPost : post identifier
- idUser : social network user identifier (empty for youtube)
return an editor identifier (idProm)


`startCampaign(bytes32 idCampaign)`

starts camapign before start date
- idCampaign : campaign identifier


`validateProm(bytes32 idProm)`

validates editor application for an advertiser
- idProm : editor identifier


`endCampaign(bytes32 idCampaign)`

ends camapign before end date
- idCampaign : campaign identifier


`getGains(bytes32 idProm)`

withdraw editor earnings to his wallet
- idProm : editor identifier


`getRemainingFunds(bytes32 idCampaign)`

withdraw advertiser remaining funds to his wallet
- idCampaign : campaign identifier


`updateCampaignStats(idCampaign)`

call oracle for validated campaign editors
- idCampaign : campaign identifier


### Contract calls (read only methods)
 
`campaigns(bytes32 idCampaign)`

- idCampaign : campaign identifier


`proms(bytes32 idProm)`

- idProm : editor identifier


`results(bytes32 idResult)`

- idResult : result identifier


`getProms(bytes32 idCampaign)`

- idCampaign : campaign identifier


`getRatios(bytes32 idCampaign)`

- idCampaign : campaign identifier


`getReachs(bytes32 idCampaign)`

- idCampaign : campaign identifier


`getResults(bytes32 idProm)`

- idProm : editor identifier



### Admin methods (only owner)

`addOracle(oracle)`

set oracle contract address


`modToken(token,accepted)`

allow or disallow ERC20 token to fund campaign
- token : ERC20 token address
- accepted : accepted or not (boolean)



### Objects (struct)

Campaign
- *address* advertiser : campaign creator address (advertiser)
- *string* dataUrl : off blockchain campaign description url
- *uint64* startDate : campaign start date (unix timestamp in seconds)
- *uint64* endDate : campaign end date (unix timestamp in seconds)
- *uint64* nbProms : editor counter
- *uint64* nbValidProms : validated editor counter
- *mapping* (uint64 => bytes32) proms : campain associated editors
- *Fund* funds : funds available to pay editors
- *mapping(uint8 => cpRatio)* ratios : payment ratios by social network


promElement
- *address* influencer : editor address
- *bytes32* idCampaign : camapign identifier
- *bool* isAccepted : is editor accepted by advertiser
- *Fund* funds : tokens earnings available to withdraw
- *uint8* typeSN: social network identifier (1:facebook,2:youtube,3:instagram,4:twitter)
- *string* idPost : post identifier
- *string* idUser : social network user identifier (empty for youtube)
- *uint64* nbResults : results counter
- *mapping (uint64 => bytes32)* results : stats array 
- *bytes32* prevResult : last oracle stat result

Result
- *bytes32* idProm : editor identifier
- *uint64* likes : like counts
- *uint64* shares : share counts
- *uint64* views : view counts
		
Fund
- *address* token : token contract address
- *uint256* amount : token amount in base units

cpRatio
- *uint256* likeRatio : token amount earned for one like
- *uint256* shareRatio : token amount earned for one share
- *uint256* viewRatio : token amount earned for one view

### enums


typeSN
- Facebook
- Youtube
- Instagram
- Twitter

### log events

`CampaignCreated(bytes32 indexed id,uint64 startDate,uint64 endDate,string dataUrl,uint8 rewardType)`
event raised when a campaign is created

`CampaignFundsSpent(bytes32 indexed id )`
event raised when a campaign ends due to lack of funds

`CampaignApplied(bytes32 indexed id ,bytes32 indexed prom )`
event raised when an editor applies to a campaign
