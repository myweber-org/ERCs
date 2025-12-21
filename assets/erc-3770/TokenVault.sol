// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVault {
    address public owner;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public dailyWithdrawals;
    mapping(address => uint256) public lastWithdrawalTime;
    
    uint256 public constant DAILY_LIMIT = 1000 ether;
    uint256 public constant WITHDRAWAL_COOLDOWN = 1 days;
    bool public emergencyPaused;
    
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyPaused(bool paused);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier notPaused() {
        require(!emergencyPaused, "Vault paused");
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
        require(amount > 0, "Zero withdrawal");
        
        if (block.timestamp - lastWithdrawalTime[msg.sender] >= WITHDRAWAL_COOLDOWN) {
            dailyWithdrawals[msg.sender] = 0;
        }
        
        require(dailyWithdrawals[msg.sender] + amount <= DAILY_LIMIT, "Daily limit exceeded");
        
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
    
    function getRemainingDailyLimit(address user) external view returns (uint256) {
        if (block.timestamp - lastWithdrawalTime[user] >= WITHDRAWAL_COOLDOWN) {
            return DAILY_LIMIT;
        }
        return DAILY_LIMIT - dailyWithdrawals[user];
    }
    
    function setEmergencyPause(bool paused) external onlyOwner {
        emergencyPaused = paused;
        emit EmergencyPaused(paused);
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    function recoverTokens(address tokenAddress, uint256 amount) external onlyOwner {
        // Emergency token recovery function
        // Implementation depends on token standard
    }
}