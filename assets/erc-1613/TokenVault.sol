
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenVault {
    mapping(address => uint256) private balances;
    address public immutable token;
    
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    
    constructor(address _token) {
        token = _token;
    }
    
    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        
        balances[msg.sender] += amount;
        
        (bool success, ) = token.call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", 
            msg.sender, address(this), amount)
        );
        require(success, "Token transfer failed");
        
        emit Deposited(msg.sender, amount);
    }
    
    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        
        (bool success, ) = token.call(
            abi.encodeWithSignature("transfer(address,uint256)", 
            msg.sender, amount)
        );
        require(success, "Token transfer failed");
        
        emit Withdrawn(msg.sender, amount);
    }
    
    function balanceOf(address user) external view returns (uint256) {
        return balances[user];
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVault {
    mapping(address => uint256) private balances;
    
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
    
    function withdraw(uint256 amount) external {
        require(amount > 0, "Withdrawal amount must be greater than zero");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawn(msg.sender, amount);
    }
    
    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }
    
    function getTotalVaultBalance() external view returns (uint256) {
        return address(this).balance;
    }
}