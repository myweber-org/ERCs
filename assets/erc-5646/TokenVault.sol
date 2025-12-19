// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVault {
    address public owner;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public dailyWithdrawals;
    mapping(address => uint256) public lastWithdrawalDay;
    
    uint256 public dailyLimit = 1 ether;
    bool public paused = false;
    
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyPaused(address indexed by);
    event EmergencyUnpaused(address indexed by);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier notPaused() {
        require(!paused, "Vault paused");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function deposit() external payable notPaused {
        require(msg.value > 0, "Zero deposit");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
    
    function withdraw(uint256 amount) external notPaused {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(amount <= dailyLimit, "Exceeds daily limit");
        
        uint256 currentDay = block.timestamp / 1 days;
        
        if (lastWithdrawalDay[msg.sender] != currentDay) {
            dailyWithdrawals[msg.sender] = 0;
            lastWithdrawalDay[msg.sender] = currentDay;
        }
        
        require(dailyWithdrawals[msg.sender] + amount <= dailyLimit, "Daily limit exceeded");
        
        balances[msg.sender] -= amount;
        dailyWithdrawals[msg.sender] += amount;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, amount);
    }
    
    function setDailyLimit(uint256 newLimit) external onlyOwner {
        dailyLimit = newLimit;
    }
    
    function emergencyPause() external onlyOwner {
        paused = true;
        emit EmergencyPaused(msg.sender);
    }
    
    function emergencyUnpause() external onlyOwner {
        paused = false;
        emit EmergencyUnpaused(msg.sender);
    }
    
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
    
    function getRemainingDailyWithdrawal(address user) external view returns (uint256) {
        uint256 currentDay = block.timestamp / 1 days;
        
        if (lastWithdrawalDay[user] != currentDay) {
            return dailyLimit;
        }
        
        return dailyLimit - dailyWithdrawals[user];
    }
}