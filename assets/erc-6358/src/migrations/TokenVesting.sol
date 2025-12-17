
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVesting is Ownable {
    IERC20 public immutable token;
    
    struct VestingSchedule {
        uint256 totalAmount;
        uint256 releasedAmount;
        uint256 cliff;
        uint256 start;
        uint256 duration;
        uint256 slicePeriod;
    }
    
    mapping(address => VestingSchedule) public vestingSchedules;
    
    event VestingScheduleCreated(address indexed beneficiary, uint256 amount);
    event TokensReleased(address indexed beneficiary, uint256 amount);
    
    constructor(address tokenAddress) {
        token = IERC20(tokenAddress);
    }
    
    function createVestingSchedule(
        address beneficiary,
        uint256 amount,
        uint256 cliffDuration,
        uint256 vestingDuration,
        uint256 slicePeriod
    ) external onlyOwner {
        require(beneficiary != address(0), "Zero address");
        require(amount > 0, "Zero amount");
        require(cliffDuration <= vestingDuration, "Cliff > duration");
        require(slicePeriod > 0, "Zero slice period");
        
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        require(schedule.totalAmount == 0, "Schedule exists");
        
        schedule.totalAmount = amount;
        schedule.releasedAmount = 0;
        schedule.cliff = block.timestamp + cliffDuration;
        schedule.start = block.timestamp;
        schedule.duration = vestingDuration;
        schedule.slicePeriod = slicePeriod;
        
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        emit VestingScheduleCreated(beneficiary, amount);
    }
    
    function releasableAmount(address beneficiary) public view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        
        if (block.timestamp < schedule.cliff) {
            return 0;
        }
        
        if (block.timestamp >= schedule.start + schedule.duration) {
            return schedule.totalAmount - schedule.releasedAmount;
        }
        
        uint256 timeFromStart = block.timestamp - schedule.start;
        uint256 vestedSlicePeriods = timeFromStart / schedule.slicePeriod;
        uint256 vestedSeconds = vestedSlicePeriods * schedule.slicePeriod;
        uint256 vestedAmount = (schedule.totalAmount * vestedSeconds) / schedule.duration;
        
        if (vestedAmount < schedule.releasedAmount) {
            return 0;
        }
        
        return vestedAmount - schedule.releasedAmount;
    }
    
    function release(address beneficiary) external {
        uint256 amount = releasableAmount(beneficiary);
        require(amount > 0, "No releasable tokens");
        
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        schedule.releasedAmount += amount;
        
        require(token.transfer(beneficiary, amount), "Transfer failed");
        
        emit TokensReleased(beneficiary, amount);
    }
    
    function getVestingInfo(address beneficiary) external view returns (
        uint256 totalAmount,
        uint256 releasedAmount,
        uint256 cliff,
        uint256 start,
        uint256 duration,
        uint256 slicePeriod,
        uint256 releasable
    ) {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        return (
            schedule.totalAmount,
            schedule.releasedAmount,
            schedule.cliff,
            schedule.start,
            schedule.duration,
            schedule.slicePeriod,
            releasableAmount(beneficiary)
        );
    }
}