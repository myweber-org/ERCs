pragma solidity ^0.8.0;

contract TokenTransfer {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event TransferFailed(address indexed from, address indexed to, uint256 amount, string reason);
    
    mapping(address => uint256) private balances;
    
    function transfer(address to, uint256 amount) external returns (bool) {
        require(to != address(0), "TokenTransfer: transfer to zero address");
        require(amount > 0, "TokenTransfer: amount must be positive");
        require(balances[msg.sender] >= amount, "TokenTransfer: insufficient balance");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function safeTransfer(address to, uint256 amount) external {
        try this.transfer(to, amount) {
            // Transfer succeeded, event already emitted
        } catch Error(string memory reason) {
            emit TransferFailed(msg.sender, to, amount, reason);
        } catch {
            emit TransferFailed(msg.sender, to, amount, "Unknown error");
        }
    }
    
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
    
    function mint(address account, uint256 amount) external {
        balances[account] += amount;
    }
}