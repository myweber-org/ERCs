
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
        uint256 releasePeriod;
        uint256 releaseAmountPerPeriod;
    }
    
    mapping(address => VestingSchedule) public vestingSchedules;
    
    event VestingScheduleCreated(address indexed beneficiary, uint256 totalAmount, uint256 startTime);
    event TokensReleased(address indexed beneficiary, uint256 amount);
    
    constructor(address _tokenAddress) {
        require(_tokenAddress != address(0), "Token address cannot be zero");
        token = IERC20(_tokenAddress);
    }
    
    function createVestingSchedule(
        address _beneficiary,
        uint256 _totalAmount,
        uint256 _startTime,
        uint256 _cliffDuration,
        uint256 _releasePeriod,
        uint256 _releaseAmountPerPeriod
    ) external onlyOwner {
        require(_beneficiary != address(0), "Beneficiary cannot be zero address");
        require(_totalAmount > 0, "Total amount must be greater than zero");
        require(vestingSchedules[_beneficiary].totalAmount == 0, "Vesting schedule already exists");
        require(_releaseAmountPerPeriod > 0, "Release amount per period must be greater than zero");
        
        vestingSchedules[_beneficiary] = VestingSchedule({
            totalAmount: _totalAmount,
            releasedAmount: 0,
            startTime: _startTime,
            cliffDuration: _cliffDuration,
            releasePeriod: _releasePeriod,
            releaseAmountPerPeriod: _releaseAmountPerPeriod
        });
        
        require(token.transferFrom(msg.sender, address(this), _totalAmount), "Token transfer failed");
        
        emit VestingScheduleCreated(_beneficiary, _totalAmount, _startTime);
    }
    
    function releasableAmount(address _beneficiary) public view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[_beneficiary];
        
        if (schedule.totalAmount == 0) {
            return 0;
        }
        
        if (block.timestamp < schedule.startTime + schedule.cliffDuration) {
            return 0;
        }
        
        uint256 elapsedTime = block.timestamp - (schedule.startTime + schedule.cliffDuration);
        uint256 completedPeriods = elapsedTime / schedule.releasePeriod;
        uint256 totalReleasable = completedPeriods * schedule.releaseAmountPerPeriod;
        
        if (totalReleasable > schedule.totalAmount) {
            totalReleasable = schedule.totalAmount;
        }
        
        return totalReleasable - schedule.releasedAmount;
    }
    
    function release(address _beneficiary) external {
        uint256 amount = releasableAmount(_beneficiary);
        require(amount > 0, "No tokens available for release");
        
        VestingSchedule storage schedule = vestingSchedules[_beneficiary];
        schedule.releasedAmount += amount;
        
        require(token.transfer(_beneficiary, amount), "Token transfer failed");
        
        emit TokensReleased(_beneficiary, amount);
    }
    
    function getVestingInfo(address _beneficiary) external view returns (
        uint256 totalAmount,
        uint256 releasedAmount,
        uint256 startTime,
        uint256 cliffEndTime,
        uint256 nextReleaseTime,
        uint256 releasable
    ) {
        VestingSchedule storage schedule = vestingSchedules[_beneficiary];
        totalAmount = schedule.totalAmount;
        releasedAmount = schedule.releasedAmount;
        startTime = schedule.startTime;
        cliffEndTime = schedule.startTime + schedule.cliffDuration;
        
        if (block.timestamp >= cliffEndTime && schedule.releasedAmount < schedule.totalAmount) {
            uint256 elapsedTime = block.timestamp - cliffEndTime;
            uint256 completedPeriods = elapsedTime / schedule.releasePeriod;
            nextReleaseTime = cliffEndTime + ((completedPeriods + 1) * schedule.releasePeriod);
        } else {
            nextReleaseTime = cliffEndTime;
        }
        
        releasable = releasableAmount(_beneficiary);
    }
}