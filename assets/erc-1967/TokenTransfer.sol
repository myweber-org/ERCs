// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenTransfer {
    mapping(address => uint256) private balances;
    
    event Transfer(address indexed from, address indexed to, uint256 amount);
    
    constructor() {
        balances[msg.sender] = 1000000 * 10**18;
    }
    
    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(recipient != address(0), "TokenTransfer: transfer to zero address");
        require(amount > 0, "TokenTransfer: amount must be positive");
        require(balances[msg.sender] >= amount, "TokenTransfer: insufficient balance");
        
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}