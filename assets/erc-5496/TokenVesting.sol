
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
        bool revoked;
    }
    
    mapping(address => VestingSchedule) public vestingSchedules;
    mapping(address => bool) public hasVestingSchedule;
    
    event VestingScheduleCreated(address indexed beneficiary, uint256 totalAmount, uint256 startTime);
    event TokensReleased(address indexed beneficiary, uint256 amount);
    event VestingScheduleRevoked(address indexed beneficiary, uint256 unreleasedAmount);
    
    constructor(IERC20 _token) {
        token = _token;
    }
    
    function createVestingSchedule(
        address beneficiary,
        uint256 totalAmount,
        uint256 startTime,
        uint256 cliffDuration,
        uint256 releasePeriod,
        uint256 releaseAmountPerPeriod
    ) external onlyOwner {
        require(beneficiary != address(0), "TokenVesting: beneficiary is zero address");
        require(totalAmount > 0, "TokenVesting: totalAmount must be greater than 0");
        require(!hasVestingSchedule[beneficiary], "TokenVesting: beneficiary already has vesting schedule");
        require(releaseAmountPerPeriod > 0, "TokenVesting: releaseAmountPerPeriod must be greater than 0");
        require(releasePeriod > 0, "TokenVesting: releasePeriod must be greater than 0");
        
        vestingSchedules[beneficiary] = VestingSchedule({
            totalAmount: totalAmount,
            releasedAmount: 0,
            startTime: startTime,
            cliffDuration: cliffDuration,
            releasePeriod: releasePeriod,
            releaseAmountPerPeriod: releaseAmountPerPeriod,
            revoked: false
        });
        
        hasVestingSchedule[beneficiary] = true;
        
        require(token.transferFrom(msg.sender, address(this), totalAmount), "TokenVesting: token transfer failed");
        
        emit VestingScheduleCreated(beneficiary, totalAmount, startTime);
    }
    
    function release(address beneficiary) external {
        require(hasVestingSchedule[beneficiary], "TokenVesting: no vesting schedule for beneficiary");
        
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        require(!schedule.revoked, "TokenVesting: vesting schedule is revoked");
        require(block.timestamp >= schedule.startTime + schedule.cliffDuration, "TokenVesting: cliff period not ended");
        
        uint256 unreleasedAmount = releasableAmount(beneficiary);
        require(unreleasedAmount > 0, "TokenVesting: no tokens to release");
        
        schedule.releasedAmount += unreleasedAmount;
        
        require(token.transfer(beneficiary, unreleasedAmount), "TokenVesting: token transfer failed");
        
        emit TokensReleased(beneficiary, unreleasedAmount);
    }
    
    function releasableAmount(address beneficiary) public view returns (uint256) {
        if (!hasVestingSchedule[beneficiary]) {
            return 0;
        }
        
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        
        if (schedule.revoked) {
            return 0;
        }
        
        if (block.timestamp < schedule.startTime + schedule.cliffDuration) {
            return 0;
        }
        
        uint256 elapsedPeriods = (block.timestamp - schedule.startTime - schedule.cliffDuration) / schedule.releasePeriod;
        uint256 totalReleasable = elapsedPeriods * schedule.releaseAmountPerPeriod;
        
        if (totalReleasable > schedule.totalAmount) {
            totalReleasable = schedule.totalAmount;
        }
        
        return totalReleasable - schedule.releasedAmount;
    }
    
    function revoke(address beneficiary) external onlyOwner {
        require(hasVestingSchedule[beneficiary], "TokenVesting: no vesting schedule for beneficiary");
        
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        require(!schedule.revoked, "TokenVesting: vesting schedule already revoked");
        
        uint256 unreleasedAmount = schedule.totalAmount - schedule.releasedAmount;
        schedule.revoked = true;
        
        if (unreleasedAmount > 0) {
            require(token.transfer(owner(), unreleasedAmount), "TokenVesting: token transfer failed");
        }
        
        emit VestingScheduleRevoked(beneficiary, unreleasedAmount);
    }
    
    function getVestingInfo(address beneficiary) external view returns (
        uint256 totalAmount,
        uint256 releasedAmount,
        uint256 startTime,
        uint256 cliffDuration,
        uint256 releasePeriod,
        uint256 releaseAmountPerPeriod,
        bool revoked,
        uint256 releasable
    ) {
        require(hasVestingSchedule[beneficiary], "TokenVesting: no vesting schedule for beneficiary");
        
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        
        return (
            schedule.totalAmount,
            schedule.releasedAmount,
            schedule.startTime,
            schedule.cliffDuration,
            schedule.releasePeriod,
            schedule.releaseAmountPerPeriod,
            schedule.revoked,
            releasableAmount(beneficiary)
        );
    }
}