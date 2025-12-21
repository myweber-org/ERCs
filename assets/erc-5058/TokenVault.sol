// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenVault {
    address public owner;
    IERC20 public immutable token;
    bool public paused;
    mapping(address => uint256) public balances;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyPaused(address indexed admin);
    event EmergencyUnpaused(address indexed admin);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "TokenVault: caller is not the owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "TokenVault: vault is paused");
        _;
    }

    constructor(address _tokenAddress) {
        require(_tokenAddress != address(0), "TokenVault: token address cannot be zero");
        owner = msg.sender;
        token = IERC20(_tokenAddress);
        paused = false;
    }

    function deposit(uint256 amount) external whenNotPaused {
        require(amount > 0, "TokenVault: amount must be greater than zero");
        
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "TokenVault: token transfer failed");
        
        balances[msg.sender] += amount;
        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) external whenNotPaused {
        require(amount > 0, "TokenVault: amount must be greater than zero");
        require(balances[msg.sender] >= amount, "TokenVault: insufficient balance");
        
        balances[msg.sender] -= amount;
        
        bool success = token.transfer(msg.sender, amount);
        require(success, "TokenVault: token transfer failed");
        
        emit Withdrawn(msg.sender, amount);
    }

    function emergencyPause() external onlyOwner {
        require(!paused, "TokenVault: already paused");
        paused = true;
        emit EmergencyPaused(msg.sender);
    }

    function emergencyUnpause() external onlyOwner {
        require(paused, "TokenVault: not paused");
        paused = false;
        emit EmergencyUnpaused(msg.sender);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "TokenVault: new owner is the zero address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function getVaultBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getUserBalance(address user) external view returns (uint256) {
        return balances[user];
    }
}