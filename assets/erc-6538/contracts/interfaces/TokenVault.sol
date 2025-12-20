// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVault is Ownable {
    IERC20 public immutable token;
    uint256 public totalDeposits;
    bool public paused;

    mapping(address => uint256) public userDeposits;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event EmergencyPaused(address indexed admin);
    event EmergencyResumed(address indexed admin);

    constructor(address _token) {
        require(_token != address(0), "Invalid token address");
        token = IERC20(_token);
    }

    modifier whenNotPaused() {
        require(!paused, "Vault is paused");
        _;
    }

    function deposit(uint256 amount) external whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");
        
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");

        userDeposits[msg.sender] += amount;
        totalDeposits += amount;

        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) external whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");
        require(userDeposits[msg.sender] >= amount, "Insufficient balance");

        userDeposits[msg.sender] -= amount;
        totalDeposits -= amount;

        bool success = token.transfer(msg.sender, amount);
        require(success, "Token transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    function getUserBalance(address user) external view returns (uint256) {
        return userDeposits[user];
    }

    function emergencyPause() external onlyOwner {
        require(!paused, "Already paused");
        paused = true;
        emit EmergencyPaused(msg.sender);
    }

    function emergencyResume() external onlyOwner {
        require(paused, "Not paused");
        paused = false;
        emit EmergencyResumed(msg.sender);
    }

    function recoverTokens(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != address(token), "Cannot recover vault token");
        IERC20(tokenAddress).transfer(msg.sender, amount);
    }
}