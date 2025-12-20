// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVault {
    mapping(address => uint256) private balances;
    address public immutable token;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor(address _token) {
        require(_token != address(0), "Invalid token address");
        token = _token;
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        balances[msg.sender] += amount;
        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        emit Withdrawn(msg.sender, amount);
    }

    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
}// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVault {
    address public owner;
    IERC20 public token;
    
    uint256 public dailyWithdrawalLimit;
    uint256 public withdrawalCooldown;
    bool public paused;
    
    mapping(address => uint256) public lastWithdrawalTime;
    mapping(address => uint256) public withdrawnToday;
    
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
    
    constructor(address _token, uint256 _dailyLimit, uint256 _cooldown) {
        owner = msg.sender;
        token = IERC20(_token);
        dailyWithdrawalLimit = _dailyLimit;
        withdrawalCooldown = _cooldown;
        paused = false;
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
        paused = true;
        emit EmergencyPaused(msg.sender);
    }
    
    function emergencyUnpause() external onlyOwner {
        paused = false;
        emit EmergencyUnpaused(msg.sender);
    }
    
    function updateDailyLimit(uint256 newLimit) external onlyOwner {
        dailyWithdrawalLimit = newLimit;
    }
    
    function updateCooldown(uint256 newCooldown) external onlyOwner {
        withdrawalCooldown = newCooldown;
    }
    
    function recoverTokens(address tokenAddress, uint256 amount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner, amount);
    }
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}