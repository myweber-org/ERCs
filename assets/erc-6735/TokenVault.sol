
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

    function emergencyPause() external onlyOwner {
        paused = true;
        emit EmergencyPaused(msg.sender);
    }

    function emergencyUnpause() external onlyOwner {
        paused = false;
        emit EmergencyUnpaused(msg.sender);
    }

    function updateDailyLimit(uint256 newLimit) external onlyOwner {
        dailyLimit = newLimit;
    }

    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    function getDailyWithdrawal(address user) external view returns (uint256) {
        if (block.timestamp - lastResetTime >= 1 days) {
            return 0;
        }
        return dailyWithdrawals[user];
    }

    function _resetDailyCounter() internal {
        if (block.timestamp - lastResetTime >= 1 days) {
            lastResetTime = block.timestamp;
            dailyWithdrawals[msg.sender] = 0;
        }
    }

    receive() external payable {
        deposit();
    }
}