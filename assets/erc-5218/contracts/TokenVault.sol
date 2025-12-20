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
    uint256 public withdrawalPeriod;
    bool public emergencyPaused;
    
    mapping(address => uint256) public lastWithdrawalTime;
    mapping(address => uint256) public withdrawnThisPeriod;
    
    event Withdrawal(address indexed user, uint256 amount);
    event EmergencyPaused(bool status);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier notPaused() {
        require(!emergencyPaused, "Vault operations are paused");
        _;
    }
    
    constructor(address _tokenAddress, uint256 _withdrawalLimit, uint256 _withdrawalPeriod) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        withdrawalLimit = _withdrawalLimit;
        withdrawalPeriod = _withdrawalPeriod;
        emergencyPaused = false;
    }
    
    function withdraw(uint256 amount) external notPaused {
        require(amount > 0, "Amount must be greater than zero");
        
        uint256 currentTime = block.timestamp;
        uint256 periodStart = lastWithdrawalTime[msg.sender];
        
        if (currentTime - periodStart >= withdrawalPeriod) {
            withdrawnThisPeriod[msg.sender] = 0;
            lastWithdrawalTime[msg.sender] = currentTime;
        }
        
        require(
            withdrawnThisPeriod[msg.sender] + amount <= withdrawalLimit,
            "Exceeds withdrawal limit for current period"
        );
        
        withdrawnThisPeriod[msg.sender] += amount;
        
        (bool success, ) = tokenAddress.call(
            abi.encodeWithSignature("transfer(address,uint256)", msg.sender, amount)
        );
        require(success, "Token transfer failed");
        
        emit Withdrawal(msg.sender, amount);
    }
    
    function setWithdrawalLimit(uint256 newLimit) external onlyOwner {
        withdrawalLimit = newLimit;
    }
    
    function setWithdrawalPeriod(uint256 newPeriod) external onlyOwner {
        withdrawalPeriod = newPeriod;
    }
    
    function toggleEmergencyPause() external onlyOwner {
        emergencyPaused = !emergencyPaused;
        emit EmergencyPaused(emergencyPaused);
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    function getRemainingWithdrawalLimit(address user) external view returns (uint256) {
        if (block.timestamp - lastWithdrawalTime[user] >= withdrawalPeriod) {
            return withdrawalLimit;
        }
        return withdrawalLimit - withdrawnThisPeriod[user];
    }
}