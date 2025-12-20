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
    address public tokenAddress;
    uint256 public withdrawalLimit;
    uint256 public dailyWithdrawalLimit;
    bool public paused;
    
    mapping(address => uint256) public lastWithdrawalTime;
    mapping(address => uint256) public dailyWithdrawalAmount;
    
    event Withdrawal(address indexed user, uint256 amount, uint256 timestamp);
    event EmergencyPause(bool paused);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier notPaused() {
        require(!paused, "Contract is paused");
        _;
    }
    
    constructor(address _tokenAddress, uint256 _withdrawalLimit, uint256 _dailyWithdrawalLimit) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        withdrawalLimit = _withdrawalLimit;
        dailyWithdrawalLimit = _dailyWithdrawalLimit;
        paused = false;
    }
    
    function withdraw(uint256 amount) external notPaused {
        require(amount <= withdrawalLimit, "Exceeds single withdrawal limit");
        
        uint256 currentDay = block.timestamp / 1 days;
        uint256 userLastDay = lastWithdrawalTime[msg.sender] / 1 days;
        
        if (currentDay > userLastDay) {
            dailyWithdrawalAmount[msg.sender] = 0;
        }
        
        require(
            dailyWithdrawalAmount[msg.sender] + amount <= dailyWithdrawalLimit,
            "Exceeds daily withdrawal limit"
        );
        
        lastWithdrawalTime[msg.sender] = block.timestamp;
        dailyWithdrawalAmount[msg.sender] += amount;
        
        (bool success, ) = tokenAddress.call(
            abi.encodeWithSignature("transfer(address,uint256)", msg.sender, amount)
        );
        require(success, "Token transfer failed");
        
        emit Withdrawal(msg.sender, amount, block.timestamp);
    }
    
    function setWithdrawalLimit(uint256 newLimit) external onlyOwner {
        withdrawalLimit = newLimit;
    }
    
    function setDailyWithdrawalLimit(uint256 newLimit) external onlyOwner {
        dailyWithdrawalLimit = newLimit;
    }
    
    function togglePause() external onlyOwner {
        paused = !paused;
        emit EmergencyPause(paused);
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    function getDailyRemaining(address user) external view returns (uint256) {
        uint256 currentDay = block.timestamp / 1 days;
        uint256 userLastDay = lastWithdrawalTime[user] / 1 days;
        
        if (currentDay > userLastDay) {
            return dailyWithdrawalLimit;
        }
        
        return dailyWithdrawalLimit - dailyWithdrawalAmount[user];
    }
}