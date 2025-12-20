// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVault {
    address public owner;
    IERC20 public token;
    uint256 public withdrawalLimit;
    bool public paused;
    
    mapping(address => uint256) public lastWithdrawalTime;
    mapping(address => uint256) public withdrawnThisPeriod;
    
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyPaused(address indexed by);
    event EmergencyUnpaused(address indexed by);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier whenNotPaused() {
        require(!paused, "Vault paused");
        _;
    }
    
    constructor(address _token, uint256 _withdrawalLimit) {
        owner = msg.sender;
        token = IERC20(_token);
        withdrawalLimit = _withdrawalLimit;
    }
    
    function deposit(uint256 amount) external whenNotPaused {
        require(amount > 0, "Amount must be positive");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        emit Deposited(msg.sender, amount);
    }
    
    function withdraw(uint256 amount) external whenNotPaused {
        require(amount > 0, "Amount must be positive");
        require(amount <= withdrawalLimit, "Exceeds withdrawal limit");
        
        uint256 currentPeriod = block.timestamp / 1 days;
        uint256 userPeriod = lastWithdrawalTime[msg.sender] / 1 days;
        
        if (currentPeriod > userPeriod) {
            withdrawnThisPeriod[msg.sender] = 0;
        }
        
        require(withdrawnThisPeriod[msg.sender] + amount <= withdrawalLimit, "Period limit exceeded");
        
        withdrawnThisPeriod[msg.sender] += amount;
        lastWithdrawalTime[msg.sender] = block.timestamp;
        
        require(token.transfer(msg.sender, amount), "Transfer failed");
        emit Withdrawn(msg.sender, amount);
    }
    
    function emergencyPause() external onlyOwner {
        paused = true;
        emit EmergencyPaused(msg.sender);
    }
    
    function emergencyUnpause() external onlyOwner {
        paused = false;
        emit EmergencyUnpaused(msg.sender);
    }
    
    function updateWithdrawalLimit(uint256 newLimit) external onlyOwner {
        withdrawalLimit = newLimit;
    }
    
    function recoverTokens(address tokenAddress, uint256 amount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner, amount);
    }
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}