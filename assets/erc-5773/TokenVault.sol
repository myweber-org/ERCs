// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVault {
    address public owner;
    mapping(address => uint256) public balances;
    bool public isActive = true;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyShutdown(address indexed caller);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier vaultActive() {
        require(isActive, "Vault inactive");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function deposit() external payable vaultActive {
        require(msg.value > 0, "Zero deposit");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external vaultActive {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(address(this).balance >= amount, "Insufficient vault funds");

        balances[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        emit Withdrawn(msg.sender, amount);
    }

    function emergencyShutdown() external onlyOwner {
        isActive = false;
        emit EmergencyShutdown(msg.sender);
    }

    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    function vaultBalance() external view returns (uint256) {
        return address(this).balance;
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
        require(success, "Emergency withdrawal failed");
    }
}