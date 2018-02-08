pragma solidity ^0.4.16;

contract TokenInterface {
    function transfer(address to, uint256 value) public returns (bool success);
}


contract owned {
    address public owner;

    function owned() public {
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


contract AtayenPlatform is owned {
		enum typeOffer {CPL,CPC,CPM}
		enum status {NotExists,Added,Validated,Ended}
		
		address tokenContract;

		struct Offer {
			address editor;
			address publisher;
			string dataUrl;
			typeOffer offerType;
			uint32 startDate;
			uint32 endDate;
			status offerState;
			uint256[] stats;
			
			
		}
		
		struct Tracker {
			address id;
			string dataUrl;
			status trackerState;
			}
			
		struct Lead {
		    uint256 id;
			address offer;
			address tracker;
		}
		
		struct Click {
		    uint256 id;
			address offer;
			address tracker;
		}
		struct Hit {
		    uint256 id;
			address offer;
			address tracker;
		}
		
		mapping(address => Offer) offers;
		mapping(address => Tracker) trackers;
		
		Lead[] leads;
		Click[] clicks;
		Hit[] hits;
		
		 event Buy(address a,uint256 v,bytes d);
		
		function AtayenPlatform (address token_ctr) public {
		    tokenContract = token_ctr;
		}
		
		
		modifier onlyTracker {
            require(trackers[msg.sender].id != 0x0 );
            _;
        }
        
         function tokenFallback(address _from, uint _value, bytes _data) public {
           require(msg.sender == tokenContract);
            Buy(_from,_value,_data);
        }
        
        function transfer(uint256 value)   onlyOwner public{
              TokenInterface(tokenContract).transfer(owner,value);
        }
		
		
		function addOffer(address addr,string url,typeOffer otype) public {
		    require( offers[msg.sender].offerState == status.NotExists);
		    offers[msg.sender] = Offer(addr,0x0,url,otype,0,0,status.Added,new uint256[](100));
		}
		
		function startOffer() public onlyTracker {
		    require( offers[msg.sender].offerState != status.NotExists);
		    offers[msg.sender].offerState = status.Validated;
		}
		
		function applyOffer(address addr) public {
		    require( offers[msg.sender].offerState != status.NotExists);
		    offers[msg.sender].publisher = addr;
		}
		
		function endOffer() public onlyOwner {
		    require( offers[msg.sender].offerState != status.NotExists);
		    offers[msg.sender].offerState = status.Ended;
		}
		
		function addTracker (address trackerAddr,string dataUrl) onlyOwner public {
		     require( trackers[msg.sender].trackerState == status.NotExists);
		    trackers[msg.sender] = Tracker(trackerAddr,dataUrl,status.Added);
		}
		
		function delTracker (address trackerAddr) onlyOwner public {
		     require( trackers[trackerAddr].trackerState != status.NotExists);
		    trackers[trackerAddr].trackerState = status.NotExists;
		}
		
		function lead(address offerAddr,uint256 id) onlyTracker public {
		    require(offers[offerAddr].offerState != status.NotExists);
		    leads.push(Lead(id,offerAddr,msg.sender));
		    offers[offerAddr].stats.push(id);
		    
		}
		function click(address offerAddr,uint256 id) onlyTracker public {
		    require(offers[offerAddr].offerState != status.NotExists);
		    clicks.push(Click(id,offerAddr,msg.sender));
		    offers[offerAddr].stats.push(id);
		    
		}
	function hit(address offerAddr,uint256 id) onlyTracker public {
		    require(offers[offerAddr].offerState != status.NotExists);
		    hits.push(Hit(id,offerAddr,msg.sender));
		    offers[offerAddr].stats.push(id);
		}
}