
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVault {
    address public owner;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public dailyWithdrawals;
    mapping(address => uint256) public lastWithdrawalDay;
    
    uint256 public constant DAILY_WITHDRAWAL_LIMIT = 1000 ether;
    bool public emergencyPaused;
    
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyPaused(bool paused);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier notPaused() {
        require(!emergencyPaused, "Vault paused");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function deposit() external payable notPaused {
        require(msg.value > 0, "Zero deposit");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
    
    function withdraw(uint256 amount) external notPaused {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(amount > 0, "Zero withdrawal");
        
        uint256 currentDay = block.timestamp / 1 days;
        
        if (lastWithdrawalDay[msg.sender] != currentDay) {
            dailyWithdrawals[msg.sender] = 0;
            lastWithdrawalDay[msg.sender] = currentDay;
        }
        
        require(
            dailyWithdrawals[msg.sender] + amount <= DAILY_WITHDRAWAL_LIMIT,
            "Daily limit exceeded"
        );
        
        balances[msg.sender] -= amount;
        dailyWithdrawals[msg.sender] += amount;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, amount);
    }
    
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
    
    function getRemainingDailyWithdrawal(address user) external view returns (uint256) {
        uint256 currentDay = block.timestamp / 1 days;
        
        if (lastWithdrawalDay[user] != currentDay) {
            return DAILY_WITHDRAWAL_LIMIT;
        }
        
        return DAILY_WITHDRAWAL_LIMIT - dailyWithdrawals[user];
    }
    
    function toggleEmergencyPause() external onlyOwner {
        emergencyPaused = !emergencyPaused;
        emit EmergencyPaused(emergencyPaused);
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}