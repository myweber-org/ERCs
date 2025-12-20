// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping(address => uint256) private _balances;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    
    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = 0;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    function mint(address to, uint256 amount) public {
        require(to != address(0), "Mint to zero address");
        require(amount > 0, "Mint amount must be positive");
        
        _balances[to] += amount;
        totalSupply += amount;
        
        emit Transfer(address(0), to, amount);
        emit Mint(to, amount);
    }
    
    function burn(address from, uint256 amount) public {
        require(from != address(0), "Burn from zero address");
        require(amount > 0, "Burn amount must be positive");
        require(_balances[from] >= amount, "Insufficient balance");
        
        _balances[from] -= amount;
        totalSupply -= amount;
        
        emit Transfer(from, address(0), amount);
        emit Burn(from, amount);
    }
    
    function transfer(address to, uint256 amount) public returns (bool) {
        require(to != address(0), "Transfer to zero address");
        require(amount > 0, "Transfer amount must be positive");
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        return true;
    }
}