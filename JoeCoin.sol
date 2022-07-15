// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract Ownable {

    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }
    function transferOwnership(address _to) public onlyOwner{
        newOwner = _to;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}




contract JoeCoin is ERC20, Ownable{

    address public treasuryAddress; // treasury contract address, used for adaptive transfer tax 
    uint8 _decimals; //Decimals used, for display purposes only
    uint public _totalSupply; // Total circulating supply of Token scaled to decimal points
    uint256 public transfers; // Count of transfers since last basis point update
    uint256 public bp = 900; // 90% in basis points

    mapping(address => uint) public balances; // Balances of holders
    mapping(address => mapping (address => uint256)) allowed; // Amount approved for transfer in the format allowed[from][to]


    constructor() ERC20("JoeCoin", "JC"){
        _decimals = 1;
        _totalSupply = 1000 * 10 ** _decimals;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    // The owner can set a new treasury address in the case of expansion of the update price functionality
    function setTreasuryAddress(address _address) public onlyOwner{
        treasuryAddress = _address;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }  


    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public override view returns (uint256) {
        return balances[_owner];
    }

    //  A holder can approve another wallet to pull tokens from their balance up to alloted "allowance"
    // This function sets a value of allowance
    function approve(address _to, uint256 _value) public override returns (bool) {
        allowed[msg.sender][_to] = _value;
        emit Approval(msg.sender, _to, _value);
        return true;
    }

    // View quantity that can be transfered by _to from _from

    function allowance(address _from, address _to) public override view returns (uint256) {
        return allowed[_from][_to];
    }

    // Allows the payer to increase the allowance to the payee

    function increaseAllowance(address _to, uint256 _addedValue) public override returns (bool) {
        approve(_to, allowed[msg.sender][_to] + _addedValue);
        return true;
    }

    // allows the payer to decrease the allowance to the payee, but not below 0;
    function decreaseAllowance(address _to, uint256 _subtractedValue) public override returns (bool) {
        uint256 currentAllowance = allowed[msg.sender][_to];
        require(currentAllowance >= _subtractedValue, "ERC20: decreased allowance below zero");
        approve(_to, currentAllowance - _subtractedValue);
        return true;
    }

    // This calculates the allotment of transfer tax between, what is received, burned, and stored in treasury

    function _calculateValue(uint256 _value) internal view returns (uint256 sent, uint256 received, uint256 burned, uint256 treasury) {
        sent = _value;
        received =  uint256(_value * bp / 1000);
        treasury = (_value - received) / 2;
        burned = treasury;
        return(sent, received, burned, treasury);
    }
    
    // Balances accounts by distributing transfer tax between accounts
    function _splitTokens(address _from, address _to, uint256 sent, uint256 received, uint256 burned, uint256 treasury) internal {
        balances[_from] -= sent;
        _totalSupply -= burned;
        balances[_to] += received;
        balances[treasuryAddress] += treasury;
    }

    // Transfers tokens from sender's wallet to a recipient's wallet and increments transfers by 1
    function transfer(address _to, uint256 _value) public override returns (bool) {
        require(_value <= balances[msg.sender]);    
        (uint256 sent, uint256 received, uint256 burned, uint256 treasury) = _calculateValue(_value);
        _splitTokens(msg.sender, _to, sent, received, burned, treasury);
        transfers+=1;
        emit Transfer(msg.sender, _to, sent);
        return true;
    }

    // A Payee can pull tokens from Payer's wallet up to the allowance that the payer has allocated
    // allowance balance is decreased by the transfer and transfers is incremented by 1
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] -= _value;
        (uint256 sent, uint256 received, uint256 burned, uint256 treasury) = _calculateValue(_value);
        _splitTokens(_from, _to, sent, received, burned, treasury);
        transfers+=1;
        emit Transfer(_from, _to, sent);
        return true;
    }


    // For testing purposes, owner can create tokens and increase total supply
    function mint(uint amount) public onlyOwner returns (bool) {
        balances[owner] += amount;
        _totalSupply += amount;
        return true;

    }

    function getBasisPoints() public view returns(uint256){
        return bp;
    }


    // Allows treasury contract to update Basis Points
    function setBasisPoints(uint _bp) external {
        require(msg.sender == treasuryAddress);
        bp = _bp;
    }

    function getTransfers() public view returns(uint256){
        return transfers;
    }

    // Allows treasury contract to reset transfers to 0
    function resetTransfers() external {
        require(msg.sender == treasuryAddress);
        transfers = 0;
    }

    // For testing purposes, owner can manipulate transfers 
    function setTransfers(uint _transfers) public onlyOwner{
        transfers = _transfers;
    }

}


//Treasury contract used to update transfer tax of linked token
contract Treasury is Ownable{

    address _coinAddress; // Contract address of the token
    uint public lastUpdate; // Unix timestamp of the last transfer tax update

    constructor(){
        lastUpdate = block.timestamp;
    }

    //Set the address of the token
    function setAddress(address _address) public onlyOwner {
         _coinAddress = _address;
    }
    
    /*
    Called by users no more than once every 24 hours, this updates the transfer tax based on the amount of
    transfers in the period since last update, resets transfers, and pays the function caller the treasury
    balance
    */
    function updateBasisPoints() public{
        //require((block.timestamp - lastUpdate) > 86400, "To Soon To Update");
        lastUpdate = block.timestamp;
        JoeCoin c = JoeCoin(_coinAddress);
        c.setBasisPoints(_calculateBasisPoints(c.getTransfers()));
        c.resetTransfers();
        c.transfer(msg.sender, c.balanceOf(address(this)));
    }

    //calculates basis points using an exponential growth function to scale basis points 
    function _calculateBasisPoints(uint256 _halflife) internal pure returns(uint256) {
        _halflife += 5;
        uint factor = 50;
        if(_halflife < 18){
            uint deltaRate = 2 ** (104*10**10 / (_halflife*10**10));
            factor += 9500 / deltaRate;
        }else{
            factor += 225;
        }
        return(1000-factor);
    }
}


