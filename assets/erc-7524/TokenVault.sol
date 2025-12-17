// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVault {
    address public owner;
    IERC20 public token;
    
    uint256 public dailyWithdrawalLimit;
    uint256 public emergencyWithdrawalLimit;
    bool public paused;
    
    mapping(address => uint256) public lastWithdrawalTime;
    mapping(address => uint256) public withdrawnToday;
    
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyWithdrawn(address indexed user, uint256 amount);
    event Paused(address indexed by);
    event Unpaused(address indexed by);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier whenNotPaused() {
        require(!paused, "Vault is paused");
        _;
    }
    
    constructor(address _token, uint256 _dailyLimit, uint256 _emergencyLimit) {
        require(_token != address(0), "Invalid token address");
        require(_dailyLimit > 0, "Daily limit must be positive");
        require(_emergencyLimit > 0, "Emergency limit must be positive");
        
        owner = msg.sender;
        token = IERC20(_token);
        dailyWithdrawalLimit = _dailyLimit;
        emergencyWithdrawalLimit = _emergencyLimit;
        paused = false;
    }
    
    function deposit(uint256 amount) external whenNotPaused {
        require(amount > 0, "Amount must be positive");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        emit Deposited(msg.sender, amount);
    }
    
    function withdraw(uint256 amount) external whenNotPaused {
        require(amount > 0, "Amount must be positive");
        require(amount <= dailyWithdrawalLimit, "Exceeds daily limit");
        
        _resetDailyCounterIfNeeded(msg.sender);
        require(withdrawnToday[msg.sender] + amount <= dailyWithdrawalLimit, "Exceeds remaining daily limit");
        
        require(token.transfer(msg.sender, amount), "Transfer failed");
        
        withdrawnToday[msg.sender] += amount;
        lastWithdrawalTime[msg.sender] = block.timestamp;
        
        emit Withdrawn(msg.sender, amount);
    }
    
    function emergencyWithdraw(uint256 amount) external whenNotPaused {
        require(amount > 0, "Amount must be positive");
        require(amount <= emergencyWithdrawalLimit, "Exceeds emergency limit");
        
        require(token.transfer(msg.sender, amount), "Transfer failed");
        
        emit EmergencyWithdrawn(msg.sender, amount);
    }
    
    function setDailyWithdrawalLimit(uint256 newLimit) external onlyOwner {
        require(newLimit > 0, "Limit must be positive");
        dailyWithdrawalLimit = newLimit;
    }
    
    function setEmergencyWithdrawalLimit(uint256 newLimit) external onlyOwner {
        require(newLimit > 0, "Limit must be positive");
        emergencyWithdrawalLimit = newLimit;
    }
    
    function pause() external onlyOwner {
        require(!paused, "Already paused");
        paused = true;
        emit Paused(msg.sender);
    }
    
    function unpause() external onlyOwner {
        require(paused, "Not paused");
        paused = false;
        emit Unpaused(msg.sender);
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    function recoverTokens(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != address(token), "Cannot recover vault token");
        IERC20(tokenAddress).transfer(owner, amount);
    }
    
    function getAvailableDailyWithdrawal(address user) external view returns (uint256) {
        _resetDailyCounterIfNeeded(user);
        return dailyWithdrawalLimit - withdrawnToday[user];
    }
    
    function _resetDailyCounterIfNeeded(address user) internal {
        if (block.timestamp - lastWithdrawalTime[user] >= 1 days) {
            withdrawnToday[user] = 0;
        }
    }
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}