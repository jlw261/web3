// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;


import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";


contract RaffleEntry is VRFConsumerBaseV2{

    bool benefactorwithdrawable;
    bool winnerwithdrawable;


    enum RAFFLE_STATE {
        STANDBY,
        LIVE,
        FINALIZING
    }
    
    RAFFLE_STATE public raffle_state;

    uint256 public rafflecounter = 0;
    uint256 public ticketcost = .1 ether;
    uint256 private randomwinner;
    uint256 private lastfinalization;

    // Duration in HRS
    uint duration = 24 * 60 * 60;

    address private owner;
    
    Raffle[] public raffles;
    address[] public entries;


    struct Raffle{
        uint256 ID;
        uint256 rafflebalance;
        uint256 start;
        uint256 end;
        uint256 entries;
        address winner;
        address benefactor;
    }

    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event ControllerSet(address indexed oldController, address indexed newController);


    constructor() VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    owner = msg.sender;
  }

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }


    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }


    function getOwner() external view returns (address) {
        return owner;
    }


    function startRaffle(address _benefactor) public isOwner{
        require(raffle_state == RAFFLE_STATE.STANDBY, "There Is An ongoing Raffle");
        Raffle memory newRaffle = Raffle({
            ID: rafflecounter,
            rafflebalance: 0,
            start: block.timestamp,
            end: (block.timestamp+duration),
            winner: 0x000000000000000000000000000000000000dEaD,
            benefactor: _benefactor,
            entries: 0
        });
        raffle_state = RAFFLE_STATE.LIVE;
        raffles.push(newRaffle);
    }

    
    function enterRaffle(uint256 _tickets)public payable{
        require(raffle_state == RAFFLE_STATE.LIVE, "Raffle Is Not Live");
        require(_tickets > 0, "Entry Requires A Ticket");
        require(msg.value >= (_tickets*ticketcost), "Not Enough Eth");
        raffles[rafflecounter].rafflebalance += msg.value;
        for(uint i = 0; i < _tickets; i++)
            entries.push(msg.sender);
        
    }

    function getEntries() public view returns(address[] memory){
        return entries;
    }


    function endRaffle() public isOwner {
        require(raffle_state == RAFFLE_STATE.LIVE, "No Live Raffle");
        require(raffles[rafflecounter].end <= block.timestamp, "Raffle is Ongoing");
        //Stop Entries
        lastfinalization = block.timestamp;
        raffle_state = RAFFLE_STATE.FINALIZING;
        // 5% Goes To Contract Owner
        raffles[rafflecounter].rafflebalance *= 95;
        raffles[rafflecounter].rafflebalance /= 100;
        //Call Chainlink For Random Number
        randomwinner = random(entries.length);
    }

    function finalizeRaffle() public isOwner payable{
        require(raffle_state == RAFFLE_STATE.FINALIZING, "Raffle Is Not Being Finalized");
        require((block.timestamp-lastfinalization) > 300, "Not Done Finalizing");
        raffle_state = RAFFLE_STATE.STANDBY;
        // Set Winner From Array of Entry Tickets By random index 
        raffles[rafflecounter].winner = entries[randomwinner];
        //Split Reward Pool in two
        uint256 payout = (raffles[rafflecounter].rafflebalance / 2);
        //Payouts
        (bool os, ) = payable(raffles[rafflecounter].winner)
        .call{value:payout}("");
        require(os);
        (bool hs, ) = payable(raffles[rafflecounter].benefactor)
        .call{value:payout}("");
        require(hs);
        // Increment Counter & Clear Entries
        rafflecounter++;
        delete entries;
    }


    function withdraw() public payable isOwner(){
        require(raffle_state == RAFFLE_STATE.STANDBY, "Cannot Withdraw During Live Raffle");
        (bool os, ) = payable(msg.sender).call{value:address(this).balance}("");
        require(os);        
    }


// ADD CHAINLINK RANDOMNESS FUNCTION


    function random(uint256 _mod) internal view returns (uint) {
           return uint(s_randomWords[0] % _mod);
        }
    

    // Chainlink VRF Random Number

    VRFCoordinatorV2Interface COORDINATOR;
// Subscription Address: 0xd9a52cd98a15943b76904733e9aa978ba7237d70

// Your subscription ID.
    uint64 s_subscriptionId = 6528;

// Rinkeby coordinator. For other networks,
    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;

// The gas lane to uses
    bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;


  uint32 callbackGasLimit = 50000;

  // The default is 3, but you can set this higher.
  uint16 requestConfirmations = 3;

  // For this example, retrieve 2 random values in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 numWords =  1;

  uint256[] public s_randomWords;
  uint256 public s_requestId;



  // Assumes the subscription is funded sufficiently.
  function requestRandomWords() external isOwner {
    // Will revert if subscription is not set and funded.
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }
  
  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    s_randomWords = randomWords;
  }




    }
