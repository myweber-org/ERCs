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
    event EmergencyPauseToggled(bool paused);

    error VaultPaused();
    error InsufficientBalance();
    error ZeroAmount();
    error TransferFailed();

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
        paused = false;
    }

    modifier whenNotPaused() {
        if (paused) revert VaultPaused();
        _;
    }

    function deposit(uint256 amount) external whenNotPaused {
        if (amount == 0) revert ZeroAmount();
        
        deposits[msg.sender] += amount;
        
        bool success = token.transferFrom(msg.sender, address(this), amount);
        if (!success) revert TransferFailed();
        
        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) external whenNotPaused {
        if (amount == 0) revert ZeroAmount();
        if (deposits[msg.sender] < amount) revert InsufficientBalance();
        
        deposits[msg.sender] -= amount;
        
        bool success = token.transfer(msg.sender, amount);
        if (!success) revert TransferFailed();
        
        emit Withdrawn(msg.sender, amount);
    }

    function toggleEmergencyPause() external onlyOwner {
        paused = !paused;
        emit EmergencyPauseToggled(paused);
    }

    function getUserBalance(address user) external view returns (uint256) {
        return deposits[user];
    }

    function getVaultBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
}