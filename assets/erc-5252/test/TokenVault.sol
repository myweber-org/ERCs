pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract TokenVault {
    struct Lock {
        uint256 amount;
        uint256 unlockTime;
        bool claimed;
    }
    
    mapping(address => Lock[]) private userLocks;
    IERC20 public immutable token;
    
    event TokensLocked(address indexed user, uint256 amount, uint256 unlockTime);
    event TokensClaimed(address indexed user, uint256 amount);
    
    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }
    
    function lockTokens(uint256 amount, uint256 duration) external {
        require(amount > 0, "Amount must be positive");
        require(duration > 0, "Duration must be positive");
        
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");
        
        uint256 unlockTime = block.timestamp + duration;
        userLocks[msg.sender].push(Lock({
            amount: amount,
            unlockTime: unlockTime,
            claimed: false
        }));
        
        emit TokensLocked(msg.sender, amount, unlockTime);
    }
    
    function claimTokens(uint256 lockIndex) external {
        require(lockIndex < userLocks[msg.sender].length, "Invalid lock index");
        
        Lock storage userLock = userLocks[msg.sender][lockIndex];
        require(!userLock.claimed, "Tokens already claimed");
        require(block.timestamp >= userLock.unlockTime, "Tokens still locked");
        
        userLock.claimed = true;
        bool success = token.transfer(msg.sender, userLock.amount);
        require(success, "Token transfer failed");
        
        emit TokensClaimed(msg.sender, userLock.amount);
    }
    
    function getLockCount(address user) external view returns (uint256) {
        return userLocks[user].length;
    }
    
    function getLockDetails(address user, uint256 index) external view returns (
        uint256 amount,
        uint256 unlockTime,
        bool claimed
    ) {
        require(index < userLocks[user].length, "Invalid index");
        Lock memory lock = userLocks[user][index];
        return (lock.amount, lock.unlockTime, lock.claimed);
    }
    
    function getClaimableAmount(address user) external view returns (uint256) {
        uint256 totalClaimable = 0;
        Lock[] memory locks = userLocks[user];
        
        for (uint256 i = 0; i < locks.length; i++) {
            if (!locks[i].claimed && block.timestamp >= locks[i].unlockTime) {
                totalClaimable += locks[i].amount;
            }
        }
        
        return totalClaimable;
    }
}// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVault {
    mapping(address => uint256) private balances;
    address public owner;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

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

    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}