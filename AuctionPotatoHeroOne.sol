// based on Bryn Bellomy code
// https://medium.com/@bryn.bellomy/solidity-tutorial-building-a-simple-auction-contract-fcc918b0878a
// Some modifications :
// - Added Partners
// - Custom start
// - Potato Style 
// - Redeem to Automate the hero transfer

// based on Bryn Bellomy code
// https://medium.com/@bryn.bellomy/solidity-tutorial-building-a-simple-auction-contract-fcc918b0878a
// Some modifications :
// - Added Partners
// - Custom start
// - Potato Style 
// - Redeem to Automate the hero transfer

pragma solidity ^0.4.21;

/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, returns 0 if it would go into minus range.
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b >= a) {
            return 0;
        }
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract AuctionPotatoHeroOne {
    
    using SafeMath for uint256;
    AbstractHeroSale m_HeroSale;
    address public owner;
    
    // state
    bool public canceled;
    bool public started;
    
    address public partner1 = 0x9b974CadC31dBFec68B82bFB2127519AaC3257D3;
    address public partner2 = 0xacce111753FcF50D77D2057A8527baBdD102F24E;
    address public highestBidder;
    
    string public infoUrl;
    string name;
    uint public heroID = 0;
    uint public price = 1 finney;
    uint public timeToAdd = 1 hours;
    uint public timeLimit;
    mapping (address => uint) public balances;
    bool gameActive = false;
    
    event LogBid(address bidder, uint bid, uint newTime);
    event LogWithdrawal(address withdrawer, address withdrawalAccount, uint amount);
    event LogCanceled();
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    modifier isWinner(){
        require(msg.sender == highestBidder && now > timeLimit);
        _;
    }
    
    modifier isActive(){
        require(gameActive);
        _;
    }

    function AuctionPotatoHeroOne() public {
        owner = msg.sender;
        highestBidder = msg.sender;
        timeLimit = now.add(timeToAdd);
        infoUrl = "https://cryptodungeons.io";
    }
 
    function withdraw() public returns (bool success)
    {
        address withdrawalAccount;
        uint withdrawalAmount;

        if (canceled) {
            // if the auction was canceled, everyone should simply be allowed to withdraw their funds
            withdrawalAccount = msg.sender;
            withdrawalAmount = balances[withdrawalAccount];
            // set funds to 0
            balances[withdrawalAccount] = 0;
        }
        
        // owner can withdraw 
        if (msg.sender == owner || msg.sender == partner1 || msg.sender == partner2) {
            withdrawalAccount = msg.sender;
            withdrawalAmount = balances[withdrawalAccount];
            // set funds to 0
            balances[withdrawalAccount] = 0;
        }
        
        // overbid people can withdraw their bid + profit
        // exclude owner because he is set above
        if (!canceled && (msg.sender != highestBidder && msg.sender != owner)) {
            withdrawalAccount = msg.sender;
            withdrawalAmount = balances[withdrawalAccount];
            balances[withdrawalAccount] = 0;
        }

        // highest bidder can withdraw leftovers if he didn't before
        if (msg.sender == highestBidder && msg.sender != owner) {
            withdrawalAccount = msg.sender;
            withdrawalAmount = balances[withdrawalAccount].sub(price);
            balances[withdrawalAccount] = balances[withdrawalAccount].sub(withdrawalAmount);
        }

        if (withdrawalAmount == 0) revert();
    
        // send the funds
        if (!msg.sender.send(withdrawalAmount)) revert();

        emit LogWithdrawal(msg.sender, withdrawalAccount, withdrawalAmount);

        return true;
    }
    
    
    function bid() public isActive payable{
        require(msg.value >= price && now < timeLimit);
        
            uint toAdd = msg.value.div(5); //20%
            balances[highestBidder] = msg.value.sub(toAdd.div(2));// "send" to previous bidder 10% of highestBidd
            
            highestBidder = msg.sender; // set high bidder
            price = price.add(toAdd); // increase price
            
            uint pt1share = toAdd.div(2).div(5); // add to partner1 20% of the bid increase
            balances[partner1] = pt1share;
            uint pt2share = toAdd.div(2).div(10); // add to partner1 10% of the bid profit (10%)
            balances[partner1] = pt2share;
            
            balances[owner] = toAdd.div(2).sub(pt1share).sub(pt2share);
            timeLimit = now.add(timeToAdd);
            
            emit LogBid(msg.sender, price, timeLimit);
            
    }
    
    function getMinutesLeft() public view returns(uint minutesLeft){
        if(timeLimit > now){
             return (timeLimit - now).div(60 seconds);
        }else{
            return 0;
        }
    }
    
    function redeem() public isWinner isActive{
        
        m_HeroSale.forceTransfer(owner, highestBidder, heroID);
        gameActive = false;
            
    }
    function cancelAuction() public
        onlyOwner
        returns (bool success)
    {
        canceled = true;
        emit LogCanceled();
        return true;
    }
    
    function startAuction(uint _heroID,string _name, uint _duration_secs,address heroHelper) public onlyOwner returns (bool success){
        require(started == false);
        
        
        started = true;
        gameActive = true;
        timeLimit = now + _duration_secs;
        name = _name;
        heroID = _heroID;
        AbstractHeroSale(heroHelper);
        
        return true;
        
    }

}

contract AbstractHeroSale
{                                   
    function forceTransfer(address _from, address _to, uint256 _tokenId);
}
