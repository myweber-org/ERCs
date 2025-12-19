// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVault {
    address public owner;
    mapping(address => uint256) public balances;
    bool public emergencyLock;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyWithdrawn(address indexed user, uint256 amount);
    event EmergencyLockActivated();
    event EmergencyLockDeactivated();

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
        require(address(this).balance >= amount, "Insufficient vault balance");

        balances[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        emit Withdrawn(msg.sender, amount);
    }

    function emergencyWithdraw() external {
        require(emergencyLock, "Not in emergency");
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance");

        balances[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        emit EmergencyWithdrawn(msg.sender, amount);
    }

    function activateEmergencyLock() external onlyOwner {
        require(!emergencyLock, "Already locked");
        emergencyLock = true;
        emit EmergencyLockActivated();
    }

    function deactivateEmergencyLock() external onlyOwner {
        require(emergencyLock, "Not locked");
        emergencyLock = false;
        emit EmergencyLockDeactivated();
    }

    function vaultBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function userBalance(address user) external view returns (uint256) {
        return balances[user];
    }
}