// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVault {
    address public owner;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public dailyWithdrawals;
    uint256 public dailyLimit;
    bool public paused;
    uint256 public lastResetTime;

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

    constructor(uint256 _dailyLimit) {
        owner = msg.sender;
        dailyLimit = _dailyLimit;
        lastResetTime = block.timestamp;
    }

    function deposit() external payable notPaused {
        require(msg.value > 0, "Zero deposit");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external notPaused {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(amount > 0, "Zero withdrawal");

        _resetDailyCounter();
        require(dailyWithdrawals[msg.sender] + amount <= dailyLimit, "Daily limit exceeded");

        balances[msg.sender] -= amount;
        dailyWithdrawals[msg.sender] += amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    function _resetDailyCounter() internal {
        if (block.timestamp >= lastResetTime + 1 days) {
            lastResetTime = block.timestamp;
            dailyWithdrawals[msg.sender] = 0;
        }
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

    function updateDailyLimit(uint256 newLimit) external onlyOwner {
        require(newLimit > 0, "Invalid limit");
        dailyLimit = newLimit;
    }

    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    function getRemainingDailyWithdrawal(address user) external view returns (uint256) {
        if (block.timestamp >= lastResetTime + 1 days) {
            return dailyLimit;
        }
        return dailyLimit - dailyWithdrawals[user];
    }
}// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVault {
    mapping(address => uint256) private balances;
    address public owner;
    
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    
    constructor() {
        owner = msg.sender;
    }
    
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
    
    function withdraw(uint256 amount) external {
        require(amount > 0, "Withdrawal amount must be greater than zero");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, amount);
    }
    
    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    function emergencyWithdraw() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        (bool success, ) = owner.call{value: contractBalance}("");
        require(success, "Transfer failed");
    }
}// SPDX-License-Identifier: MIT
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
}