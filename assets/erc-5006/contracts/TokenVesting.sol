// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVesting is Ownable {
    IERC20 public immutable token;
    
    struct VestingSchedule {
        uint256 totalAmount;
        uint256 releasedAmount;
        uint256 cliffDuration;
        uint256 vestingDuration;
        uint256 startTime;
        bool revoked;
    }
    
    mapping(address => VestingSchedule) public vestingSchedules;
    
    event VestingScheduleCreated(address indexed beneficiary, uint256 amount);
    event TokensReleased(address indexed beneficiary, uint256 amount);
    event VestingScheduleRevoked(address indexed beneficiary);
    
    constructor(IERC20 _token) {
        token = _token;
    }
    
    function createVestingSchedule(
        address beneficiary,
        uint256 amount,
        uint256 cliffDuration,
        uint256 vestingDuration
    ) external onlyOwner {
        require(beneficiary != address(0), "Zero address beneficiary");
        require(amount > 0, "Zero vesting amount");
        require(vestingSchedules[beneficiary].totalAmount == 0, "Schedule already exists");
        
        vestingSchedules[beneficiary] = VestingSchedule({
            totalAmount: amount,
            releasedAmount: 0,
            cliffDuration: cliffDuration,
            vestingDuration: vestingDuration,
            startTime: block.timestamp,
            revoked: false
        });
        
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        
        emit VestingScheduleCreated(beneficiary, amount);
    }
    
    function release(address beneficiary) external {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        require(schedule.totalAmount > 0, "No vesting schedule");
        require(!schedule.revoked, "Schedule revoked");
        
        uint256 releasable = _releasableAmount(schedule);
        require(releasable > 0, "No tokens to release");
        
        schedule.releasedAmount += releasable;
        require(token.transfer(beneficiary, releasable), "Token transfer failed");
        
        emit TokensReleased(beneficiary, releasable);
    }
    
    function revoke(address beneficiary) external onlyOwner {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        require(schedule.totalAmount > 0, "No vesting schedule");
        require(!schedule.revoked, "Already revoked");
        
        uint256 releasable = _releasableAmount(schedule);
        uint256 refund = schedule.totalAmount - schedule.releasedAmount - releasable;
        
        schedule.revoked = true;
        
        if (releasable > 0) {
            schedule.releasedAmount += releasable;
            require(token.transfer(beneficiary, releasable), "Token transfer failed");
        }
        
        if (refund > 0) {
            require(token.transfer(owner(), refund), "Token transfer failed");
        }
        
        emit VestingScheduleRevoked(beneficiary);
    }
    
    function releasableAmount(address beneficiary) external view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        return _releasableAmount(schedule);
    }
    
    function _releasableAmount(VestingSchedule storage schedule) internal view returns (uint256) {
        if (schedule.totalAmount == 0 || schedule.revoked) {
            return 0;
        }
        
        uint256 currentTime = block.timestamp;
        if (currentTime < schedule.startTime + schedule.cliffDuration) {
            return 0;
        }
        
        if (currentTime >= schedule.startTime + schedule.vestingDuration) {
            return schedule.totalAmount - schedule.releasedAmount;
        }
        
        uint256 timeElapsed = currentTime - schedule.startTime - schedule.cliffDuration;
        uint256 vestingPeriod = schedule.vestingDuration - schedule.cliffDuration;
        uint256 vestedAmount = (schedule.totalAmount * timeElapsed) / vestingPeriod;
        
        if (vestedAmount > schedule.totalAmount) {
            vestedAmount = schedule.totalAmount;
        }
        
        return vestedAmount - schedule.releasedAmount;
    }
}