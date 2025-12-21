// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVault {
    address public owner;
    mapping(address => uint256) public balances;
    bool public emergencyLock;
    
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyActivated();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier notLocked() {
        require(!emergencyLock, "Vault locked");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function deposit() external payable notLocked {
        require(msg.value > 0, "Zero deposit");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
    
    function withdraw(uint256 amount) external notLocked {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(address(this).balance >= amount, "Insufficient vault funds");
        
        balances[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, amount);
    }
    
    function activateEmergency() external onlyOwner {
        emergencyLock = true;
        emit EmergencyActivated();
    }
    
    function emergencyWithdraw() external onlyOwner {
        require(emergencyLock, "Emergency not active");
        uint256 vaultBalance = address(this).balance;
        (bool success, ) = owner.call{value: vaultBalance}("");
        require(success, "Emergency transfer failed");
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    function getVaultBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    receive() external payable {
        deposit();
    }
}