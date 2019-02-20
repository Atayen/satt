# satt
Atayen Platform and ERC20 Token Solidity smart contract

## Camapign.sol

### Contract methods
 
`createCampaign(string memory dataUrl,	uint64 startDate,uint64 endDate,uint8 reward)`

Creates a new campaign for an advertiser
- dataUrl : off blockchain campaign description url
- startDate : campaign start date 
- endDate : campaign end date 
- rewardType : incentive type (1 : ratio , 2 : ratio with minimum pay limit)
returns campaign identifier (keccak256 hash)



`modCampaign(bytes32 idCampaign,string memory dataUrl,	uint64 startDate,uint64 endDate,uint8 reward)`

modifies an existing campaign only if not started
- idCampaign : campaign identifier
- dataUrl : off blockchain campaign description url
- startDate : campaign start date 
- endDate : campaign end date 
- rewardType : incentive type (1 : ratio , 2 : ratio with minimum pay limit)


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


`priceReachCampaign(bytes32 idCampaign,uint8 typeSN,uint256 likeReach,uint256 shareReach,uint256 viewReach)`

set payment limits  according to a social network
- idCampaign : campaign identifier
- typeSN : social network identifier (1:facebook,2:youtube,3:instagram,4:twitter)
- likeReach : like amount to reach to enable payments 
- shareReach :share amount to reach to enable payments 
- viewReach : view amount to reach to enable payments   (youtube seulement)


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


`validateProm(bytes32 idCampaign,bytes32 idProm,bool accepted)`

validates editor application for an advertiser
- idCampaign : campaign identifier
- idProm : editor identifier
- accepted : accepted or not (boolean)


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



### structs

campaign
prom
result
fund
reach
ratio

### enums

campaign state
rewardType
prom state
typeSN

### events

CampaignCreated(bytes32 indexed id,uint64 startDate,uint64 endDate,string dataUrl,uint8 reward)
CampaignStarted(bytes32 indexed id )
CampaignEnded(bytes32 indexed id )
CampaignFundsSpent(bytes32 indexed id )
CampaignApplied(bytes32 indexed id ,bytes32 indexed prom )
oracleResult( bytes32 idRequest,uint64 likes,uint64 shares,uint64 views)