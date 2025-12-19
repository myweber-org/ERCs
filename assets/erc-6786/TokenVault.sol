// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenVault is Ownable {
    mapping(address => uint256) private balances;
    mapping(address => bool) private authorizedWithdrawers;
    
    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdrawal(address indexed user, address indexed token, uint256 amount);
    event WithdrawerAuthorized(address indexed withdrawer);
    event WithdrawerRevoked(address indexed withdrawer);
    
    constructor() Ownable(msg.sender) {}
    
    function deposit(address tokenAddress, uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(tokenAddress != address(0), "Invalid token address");
        
        IERC20 token = IERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        balances[msg.sender] += amount;
        emit Deposit(msg.sender, tokenAddress, amount);
    }
    
    function withdraw(address tokenAddress, uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(authorizedWithdrawers[msg.sender] || msg.sender == owner(), "Not authorized to withdraw");
        
        balances[msg.sender] -= amount;
        
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(msg.sender, amount), "Transfer failed");
        
        emit Withdrawal(msg.sender, tokenAddress, amount);
    }
    
    function authorizeWithdrawer(address withdrawer) external onlyOwner {
        require(withdrawer != address(0), "Invalid address");
        authorizedWithdrawers[withdrawer] = true;
        emit WithdrawerAuthorized(withdrawer);
    }
    
    function revokeWithdrawer(address withdrawer) external onlyOwner {
        authorizedWithdrawers[withdrawer] = false;
        emit WithdrawerRevoked(withdrawer);
    }
    
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
    
    function isAuthorizedWithdrawer(address user) external view returns (bool) {
        return authorizedWithdrawers[user];
    }
}