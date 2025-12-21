// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVault {
    address public owner;
    mapping(address => uint256) public balances;
    bool public paused;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyPauseToggled(bool paused);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier notPaused() {
        require(!paused, "Vault operations are currently paused");
        _;
    }

    constructor() {
        owner = msg.sender;
        paused = false;
    }

    function deposit() external payable notPaused {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external notPaused {
        require(amount > 0, "Withdrawal amount must be greater than zero");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal transfer failed");
        
        emit Withdrawn(msg.sender, amount);
    }

    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    function toggleEmergencyPause() external onlyOwner {
        paused = !paused;
        emit EmergencyPauseToggled(paused);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        owner = newOwner;
    }
}// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVault {
    mapping(address => uint256) private balances;
    address public owner;
    bool public paused;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Paused(address indexed caller);
    event Unpaused(address indexed caller);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
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
        require(msg.value > 0, "Deposit amount must be greater than 0");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external whenNotPaused {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(amount > 0, "Withdrawal amount must be greater than 0");
        
        balances[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, amount);
    }

    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    function pause() external onlyOwner {
        require(!paused, "Already paused");
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner {
        require(paused, "Not paused");
        paused = false;
        emit Unpaused(msg.sender);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        owner = newOwner;
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
        require(address(this).balance >= amount, "Insufficient vault funds");

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

    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    function getVaultBalance() external view returns (uint256) {
        return address(this).balance;
    }
}