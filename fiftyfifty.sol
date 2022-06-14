// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract RaffleEntry {

    bool benefactorwithdrawable;
    bool winnerwithdrawable;
    bool liveraffle = false;

    uint256 rafflecounter = 0;

    address private owner;
    
    mapping(address => bool) public controllers;
    mapping(address => uint256) tickets;

    Raffle[] public raffles;
    address[] public deposits;


    struct Raffle{
        uint256 ID;
        uint256 rafflebalance;
        uint256 rafflereward;
        uint256 start;
        uint256 end;
        address winner;
        address benefactor;
        address[] entries;
        bool benefactorWithdrawn;
        bool winnerWithdrawn;
    }

    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event ControllerSet(address indexed oldController, address indexed newController);

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    modifier isController() {
        require(controllers[msg.sender] == true);
        _;
    }



    constructor() {
        owner = msg.sender;
        controllers[msg.sender] = true;
    }


    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }
    function changeController(address _controller, bool _status) public isOwner {
        controllers[_controller] = _status;
    }

    function getOwner() external view returns (address) {
        return owner;
    }


    function startRaffle(uint256 _hours, address _benefactor) public isController{
        require(!liveraffle, "There Is An ongoing Raffle");
        require(_hours > 0);
        require(_hours < 7);
        uint duration = _hours * 60 * 60;
        Raffle memory newRaffle = Raffle({
            ID: rafflecounter,
            rafflebalance: 0,
            rafflereward: 0,
            start: block.timestamp,
            end: (block.timestamp+duration),
            winner: 0x000000000000000000000000000000000000dEaD,
            benefactor: _benefactor,
            entries: deposits,
            benefactorWithdrawn: true,
            winnerWithdrawn: true
        });
        liveraffle = true;
        raffles.push(newRaffle);
    }

    
    function enterRaffle()public payable{
        require(msg.value > 0, "Entry Requires A Value");
        require(raffles[rafflecounter].ID >= 0, "Raffle Does Not Exist");
        require(raffles[rafflecounter].end > block.timestamp);
        raffles[rafflecounter].rafflebalance += msg.value;
        raffles[rafflecounter].entries.push(msg.sender);
        tickets[msg.sender]+= msg.value;
    }

    function getEntries() public view returns(address[] memory){
        return raffles[rafflecounter].entries;
    }

    function getTickets(address _address) public view returns(uint256){
        return tickets[_address];
    }

        function finalizeRaffle() public isController {
        require(liveraffle);
        require(raffles[rafflecounter].end <= block.timestamp);
        raffles[rafflecounter].benefactorWithdrawn = false;
        raffles[rafflecounter].winnerWithdrawn = false;
        liveraffle = false;
        raffles[rafflecounter].rafflereward = (raffles[rafflecounter].rafflebalance/2);
        for(uint i=0; i < raffles[rafflecounter].entries.length; i++){
            tickets[raffles[rafflecounter].entries[i]] = 0;
        }
        rafflecounter++;
    }

    function withdrawRaffle() public payable{
        require(!liveraffle);
        Raffle memory thisraffle=raffles[rafflecounter-1];
        require((msg.sender == thisraffle.benefactor) ||
                (msg.sender == thisraffle.winner),
                 "Must Be Benefactor Or Winner");        
        require((!thisraffle.benefactorWithdrawn) ||
                (!thisraffle.winnerWithdrawn)
        );
        if(msg.sender == thisraffle.winner){
            thisraffle.winnerWithdrawn = true;
        }else if(msg.sender == thisraffle.benefactor){
            thisraffle.benefactorWithdrawn = true;
        }
        (bool os, ) = payable(msg.sender).call{value:thisraffle.rafflereward}("");
        require(os);
    }


        
 }
