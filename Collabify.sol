// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

/**
[
"0xdD870fA1b7C4700F2BD7f44238821C26f7392148",
"0x583031D1113aD414F02576BD6afaBfb302140225",
"0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB"
]
**/
/**
[
1,
19,
80
]
**/



contract CollabifyPass is ERC1155, Ownable, ERC1155Supply, ReentrancyGuard, PaymentSplitter {
    string public name = "Collabify Alpha Pass";
    string public symbol = "CLBFY";
    uint256 public salePrice = 0.1 ether;
    uint256 public presalePrice = 0.08 ether;
    uint16 public maxSupply = 10000;
    uint16 index = 0;
    
    mapping(address => bool) public _publicMinted;
    mapping(address => bool) public _presaleMinted;

    bool public pause = false;
    bool public whitelist = false;
    bool public withdrawable;

   // bytes32 public whitelistMerkle = ;




    
    constructor(address[] memory _payees, uint256[] memory _shares)
    ERC1155("ipfs://QmTeT6w96z477M1ej6xqzFFweSjdcmcY2YHmsPiKLwC5ci") 
    PaymentSplitter(_payees, _shares) payable{}



    function mint(
        //bytes32[] calldata _merkleProof
        ) public payable {
        require(!pause, "Sale is not live");
        if (!whitelist){
            require(msg.value >= salePrice, "Insufficient ether value");
            require(!_publicMinted[msg.sender], "You can only mint 1");
            require(maxSupply > index, "Exceeds available supply");
            _publicMinted[msg.sender] = true;
            _mint(msg.sender, index, 1, "");
            index++;
        } else if (whitelist){
//            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        //    require(MerkleProof.verify(_merkleProof, whitelistMerkle, leaf), "Not whitelisted");
            require(msg.value >= presalePrice, "Insufficient ether value");
            require(!_presaleMinted[msg.sender], "You can only mint 1");
            require(maxSupply > index, "Exceeds available supply");
            _presaleMinted[msg.sender] = true;
            _mint(msg.sender, index, 1, "");
            index++;
        }
    }

    //Write Functions

    function setSalePrice(uint256 _price) public onlyOwner {
        salePrice = _price;
    }

    function setPresalePrice(uint256 _price) public onlyOwner {
        presalePrice = _price;
    }

    function toggleWhitelist() public returns(bool){
        whitelist = !whitelist;
        return(whitelist);
    }

    function togglePause() public returns(bool){
        pause = !pause;
        return(pause);
    }

        

//    function setWhitelistMerkle(bytes32 _merkleRoot) public onlyOwner {
//        whitelistMerkle = _merkleRoot;
//    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
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
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }


}
