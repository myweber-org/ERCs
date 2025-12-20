// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVault {
    mapping(address => uint256) private balances;
    address public owner;
    uint256 public totalDeposits;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(address(this).balance >= amount, "Contract has insufficient funds");

        balances[msg.sender] -= amount;
        totalDeposits -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function emergencyWithdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
        totalDeposits = 0;
    }
}