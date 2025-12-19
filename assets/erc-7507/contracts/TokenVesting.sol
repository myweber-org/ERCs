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
        uint256 duration;
        bool revoked;
    }
    
    mapping(address => VestingSchedule) public vestingSchedules;
    
    event VestingScheduleCreated(address indexed beneficiary, uint256 amount, uint256 startTime, uint256 duration);
    event TokensReleased(address indexed beneficiary, uint256 amount);
    event VestingRevoked(address indexed beneficiary, uint256 unreleasedAmount);
    
    constructor(IERC20 _token) {
        token = _token;
    }
    
    function createVestingSchedule(
        address beneficiary,
        uint256 amount,
        uint256 startTime,
        uint256 duration
    ) external onlyOwner {
        require(beneficiary != address(0), "TokenVesting: beneficiary is zero address");
        require(amount > 0, "TokenVesting: amount must be greater than 0");
        require(startTime >= block.timestamp, "TokenVesting: start time must be in future");
        require(duration > 0, "TokenVesting: duration must be greater than 0");
        require(vestingSchedules[beneficiary].totalAmount == 0, "TokenVesting: schedule already exists");
        
        vestingSchedules[beneficiary] = VestingSchedule({
            totalAmount: amount,
            releasedAmount: 0,
            startTime: startTime,
            duration: duration,
            revoked: false
        });
        
        emit VestingScheduleCreated(beneficiary, amount, startTime, duration);
    }
    
    function release(address beneficiary) external {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        require(schedule.totalAmount > 0, "TokenVesting: no vesting schedule");
        require(!schedule.revoked, "TokenVesting: schedule revoked");
        
        uint256 releasable = _releasableAmount(schedule);
        require(releasable > 0, "TokenVesting: no tokens to release");
        
        schedule.releasedAmount += releasable;
        require(token.transfer(beneficiary, releasable), "TokenVesting: transfer failed");
        
        emit TokensReleased(beneficiary, releasable);
    }
    
    function revoke(address beneficiary) external onlyOwner {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        require(schedule.totalAmount > 0, "TokenVesting: no vesting schedule");
        require(!schedule.revoked, "TokenVesting: already revoked");
        
        uint256 unreleased = _releasableAmount(schedule);
        schedule.revoked = true;
        
        if (unreleased > 0) {
            require(token.transfer(owner(), unreleased), "TokenVesting: transfer failed");
        }
        
        emit VestingRevoked(beneficiary, unreleased);
    }
    
    function releasableAmount(address beneficiary) external view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        return _releasableAmount(schedule);
    }
    
    function vestedAmount(address beneficiary) external view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        return _vestedAmount(schedule);
    }
    
    function _releasableAmount(VestingSchedule storage schedule) private view returns (uint256) {
        return _vestedAmount(schedule) - schedule.releasedAmount;
    }
    
    function _vestedAmount(VestingSchedule storage schedule) private view returns (uint256) {
        if (block.timestamp < schedule.startTime) {
            return 0;
        } else if (block.timestamp >= schedule.startTime + schedule.duration || schedule.revoked) {
            return schedule.totalAmount;
        } else {
            return (schedule.totalAmount * (block.timestamp - schedule.startTime)) / schedule.duration;
        }
    }
}