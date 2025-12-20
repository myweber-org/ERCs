// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVault {
    address public owner;
    address public tokenAddress;
    uint256 public dailyWithdrawalLimit;
    uint256 public withdrawalCooldown;
    
    mapping(address => uint256) public lastWithdrawalTime;
    mapping(address => uint256) public withdrawnToday;
    uint256 public lastResetDay;
    
    bool public paused;
    
    event Withdrawal(address indexed user, uint256 amount, uint256 timestamp);
    event EmergencyPause(bool paused);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier whenNotPaused() {
        require(!paused, "Vault paused");
        _;
    }
    
    constructor(address _tokenAddress, uint256 _dailyLimit, uint256 _cooldown) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        dailyWithdrawalLimit = _dailyLimit;
        withdrawalCooldown = _cooldown;
        lastResetDay = block.timestamp / 1 days;
    }
    
    function withdraw(uint256 amount) external whenNotPaused {
        _resetDailyCounter();
        
        require(
            block.timestamp >= lastWithdrawalTime[msg.sender] + withdrawalCooldown,
            "Withdrawal cooldown active"
        );
        
        require(
            withdrawnToday[msg.sender] + amount <= dailyWithdrawalLimit,
            "Daily limit exceeded"
        );
        
        lastWithdrawalTime[msg.sender] = block.timestamp;
        withdrawnToday[msg.sender] += amount;
        
        require(
            IERC20(tokenAddress).transfer(msg.sender, amount),
            "Token transfer failed"
        );
        
        emit Withdrawal(msg.sender, amount, block.timestamp);
    }
    
    function setDailyLimit(uint256 newLimit) external onlyOwner {
        dailyWithdrawalLimit = newLimit;
    }
    
    function setCooldown(uint256 newCooldown) external onlyOwner {
        withdrawalCooldown = newCooldown;
    }
    
    function togglePause() external onlyOwner {
        paused = !paused;
        emit EmergencyPause(paused);
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    function _resetDailyCounter() internal {
        uint256 currentDay = block.timestamp / 1 days;
        if (currentDay > lastResetDay) {
            lastResetDay = currentDay;
            // In production, consider gas optimization for this operation
        }
    }
    
    function getUserWithdrawalInfo(address user) external view returns (
        uint256 lastWithdrawal,
        uint256 withdrawnTodayAmount,
        uint256 remainingDailyLimit,
        bool canWithdrawNow
    ) {
        _resetDailyCounter();
        
        lastWithdrawal = lastWithdrawalTime[user];
        withdrawnTodayAmount = withdrawnToday[user];
        remainingDailyLimit = dailyWithdrawalLimit - withdrawnTodayAmount;
        
        canWithdrawNow = !paused && 
                        (block.timestamp >= lastWithdrawal + withdrawalCooldown) &&
                        (remainingDailyLimit > 0);
    }
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}