// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVault is Ownable {
    IERC20 public immutable token;
    bool public paused;
    mapping(address => uint256) public deposits;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Paused(address indexed admin);
    event Unpaused(address indexed admin);

    constructor(address _token) {
        require(_token != address(0), "Token address cannot be zero");
        token = IERC20(_token);
        paused = false;
    }

    modifier whenNotPaused() {
        require(!paused, "Vault operations are paused");
        _;
    }

    function deposit(uint256 amount) external whenNotPaused {
        require(amount > 0, "Deposit amount must be greater than zero");
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        deposits[msg.sender] += amount;
        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) external whenNotPaused {
        require(amount > 0, "Withdrawal amount must be greater than zero");
        require(deposits[msg.sender] >= amount, "Insufficient balance");

        deposits[msg.sender] -= amount;
        require(token.transfer(msg.sender, amount), "Token transfer failed");
        emit Withdrawn(msg.sender, amount);
    }

    function emergencyPause() external onlyOwner {
        require(!paused, "Vault is already paused");
        paused = true;
        emit Paused(msg.sender);
    }

    function emergencyUnpause() external onlyOwner {
        require(paused, "Vault is not paused");
        paused = false;
        emit Unpaused(msg.sender);
    }

    function getBalance(address user) external view returns (uint256) {
        return deposits[user];
    }

    function getVaultBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
}