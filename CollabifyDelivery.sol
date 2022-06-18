// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";



contract CollabifyPass is ERC1155, Ownable, ReentrancyGuard, PaymentSplitter {
    string public name = "Collabify Alpha Pass";
    string public symbol = "CLBFY";
    uint256 public salePrice = 0 ether;
    uint16 public supplyRemaining = 10000;
    uint16  index = 2;
    
    mapping(address => bool) public _publicMinted;
    mapping(address => uint256) public _fanPoints;
    mapping(address => bool) private _approvedAddresses;

    bool public pause = false;

    constructor(address[] memory _payees, uint256[] memory _shares)
    ERC1155("ipfs://QmTycz95ud6xMKGkuhmhURKuauhH1PNFxKkEpyh2XCFMEX/{id}.json") 
    PaymentSplitter(_payees, _shares) payable{}

    modifier isApproved{
        require(_approvedAddresses[msg.sender], "Not Approved");
        _;
    }


    function mint() public payable nonReentrant {
        require(!pause, "Sale is not live");
        require(msg.value >= salePrice, "Insufficient ether value");
        require(!_publicMinted[msg.sender], "You can only mint 1");
        require(supplyRemaining > 0, "Exceeds available supply");
        _publicMinted[msg.sender] = true;
        _mint(msg.sender, index, 1, "");
        supplyRemaining--;
        _fanPoints[msg.sender] = 0;
    }


    function addFanPoint(address _fanaddress, uint256 _points) public isApproved{
        _fanPoints[_fanaddress] += _points;
    }
    


    //Write Functions

    function setSalePrice(uint256 _price) public onlyOwner {
        salePrice = _price;
    }

    function togglePause() public returns(bool){
        pause = !pause;
        return(pause);
    }

    function setSupply(uint16 _supply)public onlyOwner{
        supplyRemaining = _supply;
    }

    function changeApproval(address _address, bool _status) public onlyOwner{
        _approvedAddresses[_address] = _status;
    }


    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }
    
    function uri(uint256 _tokenId) public pure override returns (string memory){
            return string(abi.encodePacked("ipfs://QmTycz95ud6xMKGkuhmhURKuauhH1PNFxKkEpyh2XCFMEX/",
        Strings.toString(_tokenId), ".json"));
    }

    function hasToken(address _account) public view returns (bool) {
        return balanceOf(_account, index) > 0;
    }

        function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

}
