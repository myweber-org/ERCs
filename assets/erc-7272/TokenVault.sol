// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVault {
    address public owner;
    IERC20 public token;
    
    uint256 public dailyWithdrawalLimit;
    uint256 public withdrawalCooldown;
    bool public emergencyPaused;
    
    mapping(address => uint256) public lastWithdrawalTime;
    mapping(address => uint256) public withdrawnToday;
    
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyPaused(address indexed by);
    event EmergencyResumed(address indexed by);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier notPaused() {
        require(!emergencyPaused, "Vault paused");
        _;
    }
    
    constructor(address _token, uint256 _dailyLimit, uint256 _cooldown) {
        owner = msg.sender;
        token = IERC20(_token);
        dailyWithdrawalLimit = _dailyLimit;
        withdrawalCooldown = _cooldown;
        emergencyPaused = false;
    }
    
    function deposit(uint256 amount) external notPaused {
        require(amount > 0, "Amount must be positive");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        emit Deposited(msg.sender, amount);
    }
    
    function withdraw(uint256 amount) external notPaused {
        require(amount > 0, "Amount must be positive");
        require(amount <= dailyWithdrawalLimit, "Exceeds daily limit");
        
        uint256 currentTime = block.timestamp;
        uint256 lastWithdrawal = lastWithdrawalTime[msg.sender];
        
        if (currentTime - lastWithdrawal >= 1 days) {
            withdrawnToday[msg.sender] = 0;
        }
        
        require(withdrawnToday[msg.sender] + amount <= dailyWithdrawalLimit, "Daily limit exceeded");
        require(currentTime - lastWithdrawal >= withdrawalCooldown, "Cooldown active");
        
        withdrawnToday[msg.sender] += amount;
        lastWithdrawalTime[msg.sender] = currentTime;
        
        require(token.transfer(msg.sender, amount), "Transfer failed");
        emit Withdrawn(msg.sender, amount);
    }
    
    function emergencyPause() external onlyOwner {
        require(!emergencyPaused, "Already paused");
        emergencyPaused = true;
        emit EmergencyPaused(msg.sender);
    }
    
    function emergencyResume() external onlyOwner {
        require(emergencyPaused, "Not paused");
        emergencyPaused = false;
        emit EmergencyResumed(msg.sender);
    }
    
    function updateDailyLimit(uint256 newLimit) external onlyOwner {
        dailyWithdrawalLimit = newLimit;
    }
    
    function updateCooldown(uint256 newCooldown) external onlyOwner {
        withdrawalCooldown = newCooldown;
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    function getVaultBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
    
    function getUserWithdrawable(address user) external view returns (uint256) {
        uint256 currentTime = block.timestamp;
        uint256 lastWithdrawal = lastWithdrawalTime[user];
        
        if (currentTime - lastWithdrawal >= 1 days) {
            return dailyWithdrawalLimit;
        }
        
        return dailyWithdrawalLimit - withdrawnToday[user];
    }
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}