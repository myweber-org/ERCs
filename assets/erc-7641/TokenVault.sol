// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVault {
    address public owner;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public dailyWithdrawals;
    mapping(address => uint256) public lastWithdrawalTime;
    uint256 public dailyLimit;
    bool public paused;
    
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
    
    constructor(uint256 _dailyLimit) {
        owner = msg.sender;
        dailyLimit = _dailyLimit;
        paused = false;
    }
    
    function deposit() external payable notPaused {
        require(msg.value > 0, "Zero deposit");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
    
    function withdraw(uint256 amount) external notPaused {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(amount > 0, "Zero withdrawal");
        
        if (block.timestamp - lastWithdrawalTime[msg.sender] >= 1 days) {
            dailyWithdrawals[msg.sender] = 0;
        }
        
        require(dailyWithdrawals[msg.sender] + amount <= dailyLimit, "Daily limit exceeded");
        
        balances[msg.sender] -= amount;
        dailyWithdrawals[msg.sender] += amount;
        lastWithdrawalTime[msg.sender] = block.timestamp;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, amount);
    }
    
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
    
    function getDailyWithdrawalRemaining(address user) external view returns (uint256) {
        if (block.timestamp - lastWithdrawalTime[user] >= 1 days) {
            return dailyLimit;
        }
        return dailyLimit - dailyWithdrawals[user];
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
    
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
}