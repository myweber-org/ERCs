
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVesting is Ownable {
    IERC20 public immutable token;
    
    struct VestingSchedule {
        uint256 totalAmount;
        uint256 releasedAmount;
        uint256 startTime;
        uint256 cliffDuration;
        uint256 vestingDuration;
        bool revoked;
    }
    
    mapping(address => VestingSchedule) public vestingSchedules;
    
    event VestingScheduleCreated(address indexed beneficiary, uint256 amount);
    event TokensReleased(address indexed beneficiary, uint256 amount);
    event VestingScheduleRevoked(address indexed beneficiary);
    
    constructor(address tokenAddress) {
        require(tokenAddress != address(0), "Token address cannot be zero");
        token = IERC20(tokenAddress);
    }
    
    function createVestingSchedule(
        address beneficiary,
        uint256 amount,
        uint256 cliffDuration,
        uint256 vestingDuration
    ) external onlyOwner {
        require(beneficiary != address(0), "Beneficiary cannot be zero address");
        require(amount > 0, "Amount must be greater than zero");
        require(vestingSchedules[beneficiary].totalAmount == 0, "Schedule already exists");
        
        vestingSchedules[beneficiary] = VestingSchedule({
            totalAmount: amount,
            releasedAmount: 0,
            startTime: block.timestamp,
            cliffDuration: cliffDuration,
            vestingDuration: vestingDuration,
            revoked: false
        });
        
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        
        emit VestingScheduleCreated(beneficiary, amount);
    }
    
    function releaseTokens(address beneficiary) external {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        require(schedule.totalAmount > 0, "No vesting schedule found");
        require(!schedule.revoked, "Vesting schedule revoked");
        
        uint256 releasableAmount = _calculateReleasableAmount(schedule);
        require(releasableAmount > 0, "No tokens available for release");
        
        schedule.releasedAmount += releasableAmount;
        
        require(token.transfer(beneficiary, releasableAmount), "Token transfer failed");
        
        emit TokensReleased(beneficiary, releasableAmount);
    }
    
    function revokeVestingSchedule(address beneficiary) external onlyOwner {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        require(schedule.totalAmount > 0, "No vesting schedule found");
        require(!schedule.revoked, "Already revoked");
        
        uint256 vestedAmount = _calculateVestedAmount(schedule);
        uint256 unvestedAmount = schedule.totalAmount - vestedAmount;
        
        schedule.revoked = true;
        
        if (unvestedAmount > 0) {
            require(token.transfer(owner(), unvestedAmount), "Token transfer failed");
        }
        
        emit VestingScheduleRevoked(beneficiary);
    }
    
    function getReleasableAmount(address beneficiary) external view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        if (schedule.totalAmount == 0 || schedule.revoked) {
            return 0;
        }
        return _calculateReleasableAmount(schedule);
    }
    
    function _calculateReleasableAmount(VestingSchedule storage schedule) private view returns (uint256) {
        uint256 vestedAmount = _calculateVestedAmount(schedule);
        return vestedAmount - schedule.releasedAmount;
    }
    
    function _calculateVestedAmount(VestingSchedule storage schedule) private view returns (uint256) {
        if (block.timestamp < schedule.startTime + schedule.cliffDuration) {
            return 0;
        }
        
        if (block.timestamp >= schedule.startTime + schedule.vestingDuration) {
            return schedule.totalAmount;
        }
        
        uint256 timeElapsed = block.timestamp - (schedule.startTime + schedule.cliffDuration);
        uint256 vestingPeriod = schedule.vestingDuration - schedule.cliffDuration;
        
        return (schedule.totalAmount * timeElapsed) / vestingPeriod;
    }
}