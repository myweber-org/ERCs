// SPDX-License-Identifier: MIT
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
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    constructor() {
        owner = msg.sender;
        paused = false;
    }

    function deposit() external payable whenNotPaused {
        require(msg.value > 0, "Deposit amount must be positive");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external whenNotPaused {
        require(amount > 0, "Withdrawal amount must be positive");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, amount);
    }

    function getBalance(address user) external view returns (uint256) {
        return balances[user];
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

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }

    receive() external payable {
        deposit();
    }
}