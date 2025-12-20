// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVault {
    address public owner;
    mapping(address => uint256) public balances;
    bool public emergencyLock;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyLocked(bool status);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier notLocked() {
        require(!emergencyLock, "Vault locked");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable notLocked {
        require(msg.value > 0, "Zero deposit");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external notLocked {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(address(this).balance >= amount, "Insufficient vault funds");

        balances[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        emit Withdrawn(msg.sender, amount);
    }

    function toggleEmergencyLock() external onlyOwner {
        emergencyLock = !emergencyLock;
        emit EmergencyLocked(emergencyLock);
    }

    function recoverFunds(address recipient) external onlyOwner {
        require(emergencyLock, "Not in emergency");
        uint256 vaultBalance = address(this).balance;
        (bool success, ) = recipient.call{value: vaultBalance}("");
        require(success, "Recovery failed");
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function getVaultBalance() external view returns (uint256) {
        return address(this).balance;
    }
}// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVault {
    address public owner;
    mapping(address => uint256) public balances;
    bool public paused;

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

    constructor() {
        owner = msg.sender;
        paused = false;
    }

    function deposit() external payable notPaused {
        require(msg.value > 0, "Zero deposit");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external notPaused {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(address(this).balance >= amount, "Insufficient vault balance");

        balances[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        emit Withdrawn(msg.sender, amount);
    }

    function emergencyPause() external onlyOwner {
        require(!paused, "Already paused");
        paused = true;
        emit EmergencyPaused(msg.sender);
    }

    function emergencyUnpause() external onlyOwner {
        require(paused, "Not paused");
        paused = false;
        emit EmergencyUnpaused(msg.sender);
    }

    function getVaultBalance() external view returns (uint256) {
        return address(this).balance;
    }
}// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVault {
    address public owner;
    address public token;
    uint256 public withdrawalLimit;
    uint256 public withdrawalPeriod;
    bool public paused;
    
    mapping(address => uint256) public lastWithdrawalTime;
    mapping(address => uint256) public withdrawnThisPeriod;
    
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyPaused(address indexed by);
    event EmergencyUnpaused(address indexed by);
    event WithdrawalLimitUpdated(uint256 newLimit, uint256 newPeriod);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier notPaused() {
        require(!paused, "Vault paused");
        _;
    }
    
    constructor(address _token, uint256 _withdrawalLimit, uint256 _withdrawalPeriod) {
        owner = msg.sender;
        token = _token;
        withdrawalLimit = _withdrawalLimit;
        withdrawalPeriod = _withdrawalPeriod;
    }
    
    function deposit(uint256 amount) external notPaused {
        require(amount > 0, "Amount must be positive");
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Transfer failed");
        emit Deposited(msg.sender, amount);
    }
    
    function withdraw(uint256 amount) external notPaused {
        require(amount > 0, "Amount must be positive");
        require(checkWithdrawalLimit(msg.sender, amount), "Withdrawal limit exceeded");
        
        updateWithdrawalState(msg.sender, amount);
        
        require(IERC20(token).transfer(msg.sender, amount), "Transfer failed");
        emit Withdrawn(msg.sender, amount);
    }
    
    function checkWithdrawalLimit(address user, uint256 amount) internal view returns (bool) {
        if (block.timestamp >= lastWithdrawalTime[user] + withdrawalPeriod) {
            return amount <= withdrawalLimit;
        }
        return withdrawnThisPeriod[user] + amount <= withdrawalLimit;
    }
    
    function updateWithdrawalState(address user, uint256 amount) internal {
        if (block.timestamp >= lastWithdrawalTime[user] + withdrawalPeriod) {
            lastWithdrawalTime[user] = block.timestamp;
            withdrawnThisPeriod[user] = amount;
        } else {
            withdrawnThisPeriod[user] += amount;
        }
    }
    
    function emergencyPause() external onlyOwner {
        paused = true;
        emit EmergencyPaused(msg.sender);
    }
    
    function emergencyUnpause() external onlyOwner {
        paused = false;
        emit EmergencyUnpaused(msg.sender);
    }
    
    function updateWithdrawalLimit(uint256 newLimit, uint256 newPeriod) external onlyOwner {
        withdrawalLimit = newLimit;
        withdrawalPeriod = newPeriod;
        emit WithdrawalLimitUpdated(newLimit, newPeriod);
    }
    
    function recoverTokens(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != token || paused, "Cannot recover main token while active");
        require(IERC20(tokenAddress).transfer(owner, amount), "Transfer failed");
    }
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}