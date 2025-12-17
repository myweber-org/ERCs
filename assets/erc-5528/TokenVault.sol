// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVault {
    address public owner;
    mapping(address => uint256) public balances;
    uint256 public dailyWithdrawalLimit;
    mapping(address => uint256) public lastWithdrawalTime;
    mapping(address => uint256) public withdrawnToday;
    bool public emergencyPaused;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyPaused(address indexed by);
    event EmergencyResumed(address indexed by);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier notPaused() {
        require(!emergencyPaused, "Vault paused");
        _;
    }

    constructor(uint256 _dailyLimit) {
        owner = msg.sender;
        dailyWithdrawalLimit = _dailyLimit;
        emergencyPaused = false;
    }

    function deposit() external payable notPaused {
        require(msg.value > 0, "Zero deposit");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external notPaused {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(amount <= dailyWithdrawalLimit, "Exceeds daily limit");

        if (block.timestamp - lastWithdrawalTime[msg.sender] >= 1 days) {
            withdrawnToday[msg.sender] = 0;
        }

        require(
            withdrawnToday[msg.sender] + amount <= dailyWithdrawalLimit,
            "Daily limit exceeded"
        );

        balances[msg.sender] -= amount;
        withdrawnToday[msg.sender] += amount;
        lastWithdrawalTime[msg.sender] = block.timestamp;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    function setDailyLimit(uint256 newLimit) external onlyOwner {
        dailyWithdrawalLimit = newLimit;
    }

    function emergencyPause() external onlyOwner {
        emergencyPaused = true;
        emit EmergencyPaused(msg.sender);
    }

    function emergencyResume() external onlyOwner {
        emergencyPaused = false;
        emit EmergencyResumed(msg.sender);
    }

    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    function getAvailableToday(address user) external view returns (uint256) {
        if (block.timestamp - lastWithdrawalTime[user] >= 1 days) {
            return dailyWithdrawalLimit;
        }
        return dailyWithdrawalLimit - withdrawnToday[user];
    }
}