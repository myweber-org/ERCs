// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenVault is Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => bool) private _allowedTokens;
    mapping(address => mapping(address => uint256)) private _tokenBalances;

    event Deposited(address indexed user, address indexed token, uint256 amount);
    event Withdrawn(address indexed user, address indexed token, uint256 amount);
    event TokenAllowed(address indexed token);
    event TokenDisallowed(address indexed token);

    constructor() Ownable(msg.sender) {}

    function allowToken(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "TokenVault: zero address");
        _allowedTokens[tokenAddress] = true;
        emit TokenAllowed(tokenAddress);
    }

    function disallowToken(address tokenAddress) external onlyOwner {
        _allowedTokens[tokenAddress] = false;
        emit TokenDisallowed(tokenAddress);
    }

    function isTokenAllowed(address tokenAddress) public view returns (bool) {
        return _allowedTokens[tokenAddress];
    }

    function deposit(address tokenAddress, uint256 amount) external {
        require(isTokenAllowed(tokenAddress), "TokenVault: token not allowed");
        require(amount > 0, "TokenVault: amount must be positive");

        IERC20 token = IERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), amount), "TokenVault: transfer failed");

        _balances[msg.sender] = _balances[msg.sender].add(amount);
        _tokenBalances[msg.sender][tokenAddress] = _tokenBalances[msg.sender][tokenAddress].add(amount);

        emit Deposited(msg.sender, tokenAddress, amount);
    }

    function withdraw(address tokenAddress, uint256 amount) external {
        require(amount > 0, "TokenVault: amount must be positive");
        require(_tokenBalances[msg.sender][tokenAddress] >= amount, "TokenVault: insufficient balance");

        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(msg.sender, amount), "TokenVault: transfer failed");

        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _tokenBalances[msg.sender][tokenAddress] = _tokenBalances[msg.sender][tokenAddress].sub(amount);

        emit Withdrawn(msg.sender, tokenAddress, amount);
    }

    function getBalance(address tokenAddress) external view returns (uint256) {
        return _tokenBalances[msg.sender][tokenAddress];
    }

    function getTotalBalance() external view returns (uint256) {
        return _balances[msg.sender];
    }

    function getTokenBalance(address user, address tokenAddress) external view returns (uint256) {
        return _tokenBalances[user][tokenAddress];
    }
}