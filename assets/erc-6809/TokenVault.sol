// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVault {
    address public owner;
    mapping(address => uint256) public balances;
    bool public emergencyStop;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyWithdrawn(address indexed user, uint256 amount);
    event EmergencyStopActivated();
    event EmergencyStopDeactivated();

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier notEmergency() {
        require(!emergencyStop, "Emergency stop active");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable notEmergency {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external notEmergency {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(address(this).balance >= amount, "Insufficient contract balance");

        balances[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        emit Withdrawn(msg.sender, amount);
    }

    function emergencyWithdraw() external {
        require(emergencyStop, "Emergency stop not active");
        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance to withdraw");

        balances[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        emit EmergencyWithdrawn(msg.sender, amount);
    }

    function activateEmergencyStop() external onlyOwner {
        require(!emergencyStop, "Already active");
        emergencyStop = true;
        emit EmergencyStopActivated();
    }

    function deactivateEmergencyStop() external onlyOwner {
        require(emergencyStop, "Not active");
        emergencyStop = false;
        emit EmergencyStopDeactivated();
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}