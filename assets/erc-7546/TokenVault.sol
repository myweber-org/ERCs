// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVault {
    address public owner;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public dailyWithdrawals;
    uint256 public dailyLimit = 1 ether;
    bool public paused = false;
    uint256 public lastResetTime;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyPaused(address indexed admin);
    event EmergencyUnpaused(address indexed admin);

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
        lastResetTime = block.timestamp;
    }

    function deposit() external payable notPaused {
        require(msg.value > 0, "Zero deposit");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external notPaused {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(amount <= dailyLimit, "Exceeds daily limit");
        
        _resetDailyCounter();
        require(dailyWithdrawals[msg.sender] + amount <= dailyLimit, "Daily limit exceeded");
        
        balances[msg.sender] -= amount;
        dailyWithdrawals[msg.sender] += amount;
        
        payable(msg.sender).transfer(amount);
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
        _resetDailyCounter();
        uint256 used = dailyWithdrawals[user];
        return dailyLimit > used ? dailyLimit - used : 0;
    }

    function _resetDailyCounter() internal {
        if (block.timestamp >= lastResetTime + 1 days) {
            lastResetTime = block.timestamp;
            dailyWithdrawals[msg.sender] = 0;
        }
    }
}