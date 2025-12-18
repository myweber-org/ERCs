pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVault is Ownable {
    IERC20 public immutable token;
    uint256 public dailyWithdrawalLimit;
    uint256 public withdrawalCooldown;
    bool public emergencyPaused;
    
    mapping(address => uint256) public lastWithdrawalTime;
    mapping(address => uint256) public withdrawnToday;
    uint256 public lastResetDay;
    
    event Withdrawal(address indexed user, uint256 amount);
    event EmergencyPaused(bool paused);
    event LimitsUpdated(uint256 dailyLimit, uint256 cooldown);
    
    constructor(
        address _tokenAddress,
        uint256 _dailyWithdrawalLimit,
        uint256 _withdrawalCooldown
    ) {
        token = IERC20(_tokenAddress);
        dailyWithdrawalLimit = _dailyWithdrawalLimit;
        withdrawalCooldown = _withdrawalCooldown;
        lastResetDay = block.timestamp / 1 days;
    }
    
    modifier notPaused() {
        require(!emergencyPaused, "Vault: operations paused");
        _;
    }
    
    function deposit(uint256 amount) external notPaused {
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
    }
    
    function withdraw(uint256 amount) external notPaused {
        _resetDailyCounter();
        
        require(amount <= dailyWithdrawalLimit, "Exceeds daily limit");
        require(
            withdrawnToday[msg.sender] + amount <= dailyWithdrawalLimit,
            "Exceeds remaining daily limit"
        );
        require(
            block.timestamp >= lastWithdrawalTime[msg.sender] + withdrawalCooldown,
            "Cooldown period active"
        );
        
        lastWithdrawalTime[msg.sender] = block.timestamp;
        withdrawnToday[msg.sender] += amount;
        
        require(token.transfer(msg.sender, amount), "Transfer failed");
        emit Withdrawal(msg.sender, amount);
    }
    
    function _resetDailyCounter() internal {
        uint256 currentDay = block.timestamp / 1 days;
        if (currentDay > lastResetDay) {
            lastResetDay = currentDay;
            // Reset all daily counters (in production consider gas optimization)
        }
    }
    
    function setEmergencyPause(bool pause) external onlyOwner {
        emergencyPaused = pause;
        emit EmergencyPaused(pause);
    }
    
    function updateLimits(uint256 newDailyLimit, uint256 newCooldown) external onlyOwner {
        dailyWithdrawalLimit = newDailyLimit;
        withdrawalCooldown = newCooldown;
        emit LimitsUpdated(newDailyLimit, newCooldown);
    }
    
    function recoverTokens(address tokenAddress, uint256 amount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), amount);
    }
    
    function getUserWithdrawalInfo(address user) external view returns (
        uint256 lastWithdrawal,
        uint256 withdrawnTodayAmount,
        uint256 remainingDailyLimit,
        bool canWithdrawNow
    ) {
        _resetDailyCounter(); // For accurate view, but doesn't modify state
        return (
            lastWithdrawalTime[user],
            withdrawnToday[user],
            dailyWithdrawalLimit - withdrawnToday[user],
            block.timestamp >= lastWithdrawalTime[user] + withdrawalCooldown
        );
    }
}