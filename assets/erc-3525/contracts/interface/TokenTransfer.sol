// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenTransfer {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event InsufficientBalance(address account, uint256 required, uint256 available);
    
    mapping(address => uint256) private balances;
    
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        balances[msg.sender] += msg.value;
    }
    
    function transfer(address recipient, uint256 amount) external {
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        uint256 senderBalance = balances[msg.sender];
        if (senderBalance < amount) {
            emit InsufficientBalance(msg.sender, amount, senderBalance);
            revert("Insufficient balance for transfer");
        }
        
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        
        emit Transfer(msg.sender, recipient, amount);
    }
    
    function getBalance(address account) external view returns (uint256) {
        return balances[account];
    }
}