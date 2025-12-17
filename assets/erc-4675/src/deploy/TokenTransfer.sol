// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenTransfer {
    address public owner;
    uint256 public constant FEE_PERCENTAGE = 1; // 1% fee
    uint256 public totalFeesCollected;

    mapping(address => uint256) public balances;

    event Transfer(address indexed from, address indexed to, uint256 value, uint256 fee);
    event FeeCollected(uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function transferWithFee(address _to, uint256 _amount) external {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        require(_to != address(0), "Invalid recipient address");

        uint256 fee = (_amount * FEE_PERCENTAGE) / 100;
        uint256 transferAmount = _amount - fee;

        balances[msg.sender] -= _amount;
        balances[_to] += transferAmount;
        totalFeesCollected += fee;

        emit Transfer(msg.sender, _to, transferAmount, fee);
        emit FeeCollected(fee);
    }

    function withdrawFees() external onlyOwner {
        uint256 fees = totalFeesCollected;
        require(fees > 0, "No fees to withdraw");

        totalFeesCollected = 0;
        payable(owner).transfer(fees);
    }

    function getBalance(address _account) external view returns (uint256) {
        return balances[_account];
    }
}