// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVault {
    address public owner;
    address public tokenAddress;
    uint256 public dailyWithdrawalLimit;
    uint256 public withdrawalCooldown;
    bool public emergencyPaused;
    
    mapping(address => uint256) public lastWithdrawalTime;
    mapping(address => uint256) public withdrawnToday;
    
    event Withdrawal(address indexed user, uint256 amount, uint256 timestamp);
    event EmergencyPaused(address indexed admin, bool status);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier notPaused() {
        require(!emergencyPaused, "Vault operations are paused");
        _;
    }
    
    constructor(address _tokenAddress, uint256 _dailyLimit, uint256 _cooldown) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        dailyWithdrawalLimit = _dailyLimit;
        withdrawalCooldown = _cooldown;
        emergencyPaused = false;
    }
    
    function withdrawTokens(uint256 amount) external notPaused {
        require(amount > 0, "Amount must be greater than zero");
        require(amount <= dailyWithdrawalLimit, "Exceeds daily withdrawal limit");
        
        address user = msg.sender;
        uint256 currentTime = block.timestamp;
        
        if (currentTime - lastWithdrawalTime[user] >= 1 days) {
            withdrawnToday[user] = 0;
        }
        
        require(
            withdrawnToday[user] + amount <= dailyWithdrawalLimit,
            "Daily limit exceeded"
        );
        
        require(
            currentTime - lastWithdrawalTime[user] >= withdrawalCooldown,
            "Withdrawal cooldown active"
        );
        
        IERC20 token = IERC20(tokenAddress);
        require(
            token.balanceOf(address(this)) >= amount,
            "Insufficient vault balance"
        );
        
        withdrawnToday[user] += amount;
        lastWithdrawalTime[user] = currentTime;
        
        require(
            token.transfer(user, amount),
            "Token transfer failed"
        );
        
        emit Withdrawal(user, amount, currentTime);
    }
    
    function setDailyLimit(uint256 newLimit) external onlyOwner {
        require(newLimit > 0, "Limit must be greater than zero");
        dailyWithdrawalLimit = newLimit;
    }
    
    function setWithdrawalCooldown(uint256 newCooldown) external onlyOwner {
        withdrawalCooldown = newCooldown;
    }
    
    function toggleEmergencyPause() external onlyOwner {
        emergencyPaused = !emergencyPaused;
        emit EmergencyPaused(msg.sender, emergencyPaused);
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    function recoverTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner, amount);
    }
    
    function getVaultBalance() external view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }
    
    function getUserWithdrawalStatus(address user) external view returns (
        uint256 lastWithdrawal,
        uint256 withdrawnTodayAmount,
        uint256 remainingDailyLimit,
        bool canWithdrawNow
    ) {
        lastWithdrawal = lastWithdrawalTime[user];
        withdrawnTodayAmount = withdrawnToday[user];
        remainingDailyLimit = dailyWithdrawalLimit - withdrawnTodayAmount;
        
        canWithdrawNow = !emergencyPaused &&
            (block.timestamp - lastWithdrawalTime[user] >= withdrawalCooldown) &&
            (withdrawnToday[user] < dailyWithdrawalLimit);
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}