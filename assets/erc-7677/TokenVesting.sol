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
    
    event VestingCreated(address indexed beneficiary, uint256 amount, uint256 startTime, uint256 duration);
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
        require(beneficiary != address(0), "Zero address beneficiary");
        require(amount > 0, "Zero vesting amount");
        require(startTime >= block.timestamp, "Start time in past");
        require(duration > 0, "Zero duration");
        require(vestingSchedules[beneficiary].totalAmount == 0, "Schedule exists");
        
        vestingSchedules[beneficiary] = VestingSchedule({
            totalAmount: amount,
            releasedAmount: 0,
            startTime: startTime,
            duration: duration,
            revoked: false
        });
        
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        emit VestingCreated(beneficiary, amount, startTime, duration);
    }
    
    function release(address beneficiary) external {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        require(schedule.totalAmount > 0, "No vesting schedule");
        require(!schedule.revoked, "Vesting revoked");
        
        uint256 releasable = _releasableAmount(schedule);
        require(releasable > 0, "No tokens releasable");
        
        schedule.releasedAmount += releasable;
        require(token.transfer(beneficiary, releasable), "Transfer failed");
        
        emit TokensReleased(beneficiary, releasable);
    }
    
    function revoke(address beneficiary) external onlyOwner {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        require(schedule.totalAmount > 0, "No vesting schedule");
        require(!schedule.revoked, "Already revoked");
        
        uint256 unreleased = _releasableAmount(schedule);
        uint256 refund = schedule.totalAmount - schedule.releasedAmount - unreleased;
        
        schedule.revoked = true;
        
        if (refund > 0) {
            require(token.transfer(owner(), refund), "Refund transfer failed");
        }
        
        emit VestingRevoked(beneficiary, refund);
    }
    
    function releasableAmount(address beneficiary) external view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        return _releasableAmount(schedule);
    }
    
    function _releasableAmount(VestingSchedule storage schedule) internal view returns (uint256) {
        if (schedule.totalAmount == 0 || schedule.revoked) {
            return 0;
        }
        
        if (block.timestamp < schedule.startTime) {
            return 0;
        }
        
        if (block.timestamp >= schedule.startTime + schedule.duration) {
            return schedule.totalAmount - schedule.releasedAmount;
        }
        
        uint256 timeElapsed = block.timestamp - schedule.startTime;
        uint256 totalVested = (schedule.totalAmount * timeElapsed) / schedule.duration;
        
        if (totalVested > schedule.releasedAmount) {
            return totalVested - schedule.releasedAmount;
        }
        
        return 0;
    }
}