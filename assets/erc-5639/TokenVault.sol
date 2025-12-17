// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenVault {
    mapping(address => mapping(address => uint256)) private _balances;
    mapping(address => bool) private _authorizedTokens;

    event Deposited(address indexed user, address indexed token, uint256 amount);
    event Withdrawn(address indexed user, address indexed token, uint256 amount);
    event TokenAuthorized(address indexed token);
    event TokenRevoked(address indexed token);

    modifier onlyAuthorizedToken(address token) {
        require(_authorizedTokens[token], "TokenVault: token not authorized");
        _;
    }

    function deposit(address token, uint256 amount) external onlyAuthorizedToken(token) {
        require(amount > 0, "TokenVault: amount must be greater than zero");
        
        bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
        require(success, "TokenVault: transfer failed");
        
        _balances[msg.sender][token] += amount;
        emit Deposited(msg.sender, token, amount);
    }

    function withdraw(address token, uint256 amount) external onlyAuthorizedToken(token) {
        require(amount > 0, "TokenVault: amount must be greater than zero");
        require(_balances[msg.sender][token] >= amount, "TokenVault: insufficient balance");
        
        _balances[msg.sender][token] -= amount;
        
        bool success = IERC20(token).transfer(msg.sender, amount);
        require(success, "TokenVault: transfer failed");
        
        emit Withdrawn(msg.sender, token, amount);
    }

    function balanceOf(address user, address token) external view returns (uint256) {
        return _balances[user][token];
    }

    function authorizeToken(address token) external {
        require(!_authorizedTokens[token], "TokenVault: token already authorized");
        _authorizedTokens[token] = true;
        emit TokenAuthorized(token);
    }

    function revokeToken(address token) external {
        require(_authorizedTokens[token], "TokenVault: token not authorized");
        _authorizedTokens[token] = false;
        emit TokenRevoked(token);
    }

    function isTokenAuthorized(address token) external view returns (bool) {
        return _authorizedTokens[token];
    }
}