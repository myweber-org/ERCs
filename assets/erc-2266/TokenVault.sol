// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVault {
    address public owner;
    address public tokenAddress;
    uint256 public dailyWithdrawalLimit;
    uint256 public withdrawalCooldown;
    
    mapping(address => uint256) public lastWithdrawalTime;
    mapping(address => uint256) public withdrawnToday;
    uint256 public lastResetTime;
    
    bool public emergencyPaused;
    
    event Withdrawal(address indexed user, uint256 amount, uint256 timestamp);
    event EmergencyPaused(address indexed by, uint256 timestamp);
    event EmergencyUnpaused(address indexed by, uint256 timestamp);
    event LimitsUpdated(uint256 newDailyLimit, uint256 newCooldown);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier notPaused() {
        require(!emergencyPaused, "Vault paused");
        _;
    }
    
    constructor(address _tokenAddress, uint256 _dailyLimit, uint256 _cooldown) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        dailyWithdrawalLimit = _dailyLimit;
        withdrawalCooldown = _cooldown;
        lastResetTime = block.timestamp;
    }
    
    function resetDailyCounters() internal {
        if (block.timestamp >= lastResetTime + 1 days) {
            lastResetTime = block.timestamp;
        }
    }
    
    function withdraw(uint256 amount) external notPaused {
        require(amount > 0, "Amount must be positive");
        require(block.timestamp >= lastWithdrawalTime[msg.sender] + withdrawalCooldown, "Cooldown active");
        
        resetDailyCounters();
        require(withdrawnToday[msg.sender] + amount <= dailyWithdrawalLimit, "Daily limit exceeded");
        
        lastWithdrawalTime[msg.sender] = block.timestamp;
        withdrawnToday[msg.sender] += amount;
        
        (bool success, ) = tokenAddress.call(
            abi.encodeWithSignature("transfer(address,uint256)", msg.sender, amount)
        );
        require(success, "Token transfer failed");
        
        emit Withdrawal(msg.sender, amount, block.timestamp);
    }
    
    function setWithdrawalLimits(uint256 newDailyLimit, uint256 newCooldown) external onlyOwner {
        dailyWithdrawalLimit = newDailyLimit;
        withdrawalCooldown = newCooldown;
        emit LimitsUpdated(newDailyLimit, newCooldown);
    }
    
    function emergencyPause() external onlyOwner {
        emergencyPaused = true;
        emit EmergencyPaused(msg.sender, block.timestamp);
    }
    
    function emergencyUnpause() external onlyOwner {
        emergencyPaused = false;
        emit EmergencyUnpaused(msg.sender, block.timestamp);
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
    
    function getRemainingDailyAllowance(address user) external view returns (uint256) {
        if (block.timestamp >= lastResetTime + 1 days) {
            return dailyWithdrawalLimit;
        }
        return dailyWithdrawalLimit - withdrawnToday[user];
    }
}