// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    
    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
    
    function mint(address _to, uint256 _amount) public {
        require(_to != address(0), "Invalid address");
        totalSupply += _amount;
        balanceOf[_to] += _amount;
        emit Transfer(address(0), _to, _amount);
        emit Mint(_to, _amount);
    }
    
    function burn(uint256 _amount) public {
        require(balanceOf[msg.sender] >= _amount, "Insufficient balance");
        totalSupply -= _amount;
        balanceOf[msg.sender] -= _amount;
        emit Transfer(msg.sender, address(0), _amount);
        emit Burn(msg.sender, _amount);
    }
    
    function transfer(address _to, uint256 _amount) public returns (bool) {
        require(_to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= _amount, "Insufficient balance");
        
        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;
        
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
}