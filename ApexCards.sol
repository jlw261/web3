// SPDX-License-Identifier: MIT

pragma solidity  ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ApexToken is ERC721, Ownable {
    using Strings for uint256;

    constructor(string memory _name, string memory _symbol)
    ERC721(_name, _symbol){

    //Base colorways that the collection starts with

    //Types of projects that can be purchased using the 
    whitelisted[msg.sender] = true;
    }	
// ENTER  BASE URI IN THIS FORMAT "ipfs://<CID>/" 
// Vars
    uint256 public mintCost = 0;
    uint256 maxHour = 25;
    uint256 minHour = 0;
    uint256 maxSupply = 1000;
    uint256 CardCounter = 0;
    uint256 ProjectCounter = 0;
    uint256  mintHours = 1;
    string[] public colorways = ["ipfs://QmaLEXAEStXuX3eChBjpVXaBVBWcK3D4Wzn1MGqw4tGVcp/",
                                 "ipfs://QmcUWuJGMz78FU7PrvjzhvwiMtUVUKpWJsxzQyUrxwvAw3/"];

    string baseExtension = ".json";

    bool public paused = true;

    mapping(address => bool) public whitelisted;
    ApexCard[] public cards;
    Project[] public projects;

//modifiers
    modifier isCardOwner(uint256 _id){
        
        _;
    }

    modifier isWhitelisted(){
       require(whitelisted[msg.sender], "User not Whitelisted");
       _;
    }

    modifier isInBounds(string memory _operator, uint256 _hours, uint256 _id){
       if(compareStrings(_operator, "ADD")){
           require((cards[_id].hour += _hours) <= maxHour);
           _;
       }else if(compareStrings(_operator, "SUB")){
          require((cards[_id].hour -= _hours) >= minHour);
          _;
      }else{
          require(false, "Wrong Operator");
          _;
       }
    }


 // Project Structure

    struct Project{
        uint256 id;
        uint256 hour;
        address owner;
        string projectType;
    }   
 

// Card NFT structure

    struct ApexCard{
        uint256 id;
        uint256 hour;
        uint8 cw;
    }
 
//Arrays


//MINT EVENT

    event NewCard(address indexed owner, uint256 hour, uint256 lastTransfer);

//PROJECT EVENT
    event NewProject(uint256 id, string projectType);



//Maker Functions
    function _createCard(uint8 _cw) internal{
        ApexCard memory newCard = ApexCard(CardCounter, mintHours, _cw);
        cards.push(newCard);
        _safeMint(msg.sender, CardCounter);
        emit NewCard(msg.sender, CardCounter, block.timestamp);
        CardCounter++;
    }

    function mintCard(uint8 _cw)public payable{
        require(msg.value >= mintCost, "The fee is not correct");
        whitelisted[msg.sender] = false;
        _createCard(_cw);
    }

    function _createProject(string memory _projectType, uint256 _hour)internal{
        Project memory newProject = Project(ProjectCounter, _hour, msg.sender, _projectType);
        emit NewProject(ProjectCounter, _projectType);
        projects.push(newProject);

    }    

    function startProject(uint256 _hour, uint256 _id, string memory _projectType) public{
        cards[_id].hour -= _hour;
        _createProject(_projectType, _hour);
        ProjectCounter++;
    }




//Get Functions
    function getColorway(uint256 _id) public view returns(string memory){
        return colorways[cards[_id].cw];
    }

    function tokenURI(uint256 _id) public view virtual override returns(string memory URI) {
        string memory uri = string(abi.encodePacked(colorways[cards[_id].cw], cards[_id].hour.toString(), baseExtension));
        return uri;
  }
    

    function GetCards() public view returns(ApexCard[] memory){
    return cards;
}




// External Utility Functions

    function getHours(uint256 _id) public view returns(uint256){
        return cards[_id].hour;
    }

    function AddHour(uint256 _id, uint8 _hour) public {
        cards[_id].hour+=_hour;
    }
    function MinusHour(uint256 _id, uint8 _hour) public {
        cards[_id].hour-=_hour;
    }


      //Gives an address whitelist permissions
  function whitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = true;
  }

    function withdraw() external payable onlyOwner() {
        address payable _owner = payable(owner());
        _owner.transfer(address(this).balance);

    }


    function pause(bool _state) public onlyOwner {
      paused = _state;
    }


    function compareStrings(string memory a, string memory b) public pure returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));}

}

