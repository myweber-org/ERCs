// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVault {
    address public owner;
    mapping(address => uint256) public balances;
    bool public emergencyLock;
    
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyLocked(bool status);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier notLocked() {
        require(!emergencyLock, "Vault is locked due to emergency");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        emergencyLock = false;
    }
    
    function deposit() external payable notLocked {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
    
    function withdraw(uint256 amount) external notLocked {
        require(amount > 0, "Withdrawal amount must be greater than zero");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, amount);
    }
    
    function toggleEmergencyLock() external onlyOwner {
        emergencyLock = !emergencyLock;
        emit EmergencyLocked(emergencyLock);
    }
    
    function emergencyWithdraw() external {
        require(emergencyLock, "Emergency withdrawal only available when locked");
        uint256 userBalance = balances[msg.sender];
        require(userBalance > 0, "No balance to withdraw");
        
        balances[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: userBalance}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, userBalance);
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    function getUserBalance(address user) external view returns (uint256) {
        return balances[user];
    }
}