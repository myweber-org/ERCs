// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVault {
    address public owner;
    address public tokenAddress;
    bool public paused;
    uint256 public dailyWithdrawalLimit;
    uint256 public withdrawalCooldown;
    
    mapping(address => uint256) public lastWithdrawalTime;
    mapping(address => uint256) public withdrawnToday;
    
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
    
    constructor(address _tokenAddress) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        dailyWithdrawalLimit = 1000 * 10**18;
        withdrawalCooldown = 1 hours;
    }
    
    function deposit(uint256 amount) external notPaused {
        require(amount > 0, "Amount must be positive");
        
        bool success = IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");
        
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
        
        bool success = IERC20(tokenAddress).transfer(msg.sender, amount);
        require(success, "Transfer failed");
        
        lastWithdrawalTime[msg.sender] = currentTime;
        withdrawnToday[msg.sender] += amount;
        
        emit Withdrawn(msg.sender, amount);
    }
    
    function setDailyLimit(uint256 newLimit) external onlyOwner {
        dailyWithdrawalLimit = newLimit;
    }
    
    function setWithdrawalCooldown(uint256 newCooldown) external onlyOwner {
        withdrawalCooldown = newCooldown;
    }
    
    function emergencyPause() external onlyOwner {
        paused = true;
        emit EmergencyPaused(msg.sender);
    }
    
    function emergencyUnpause() external onlyOwner {
        paused = false;
        emit EmergencyUnpaused(msg.sender);
    }
    
    function recoverTokens(address token, uint256 amount) external onlyOwner {
        require(token != tokenAddress, "Cannot recover vault token");
        bool success = IERC20(token).transfer(owner, amount);
        require(success, "Transfer failed");
    }
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}