
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
    event VestingRevoked(address indexed beneficiary, uint256 unreleasedAmount);
    
    constructor(IERC20 _token) {
        require(address(_token) != address(0), "Token address cannot be zero");
        token = _token;
    }
    
    function createVestingSchedule(
        address beneficiary,
        uint256 amount,
        uint256 startTime,
        uint256 cliffDuration,
        uint256 vestingDuration
    ) external onlyOwner {
        require(beneficiary != address(0), "Beneficiary cannot be zero address");
        require(amount > 0, "Amount must be greater than 0");
        require(cliffDuration <= vestingDuration, "Cliff must be shorter than vesting duration");
        require(vestingSchedules[beneficiary].totalAmount == 0, "Schedule already exists");
        
        vestingSchedules[beneficiary] = VestingSchedule({
            totalAmount: amount,
            releasedAmount: 0,
            startTime: startTime,
            cliffDuration: cliffDuration,
            vestingDuration: vestingDuration,
            revoked: false
        });
        
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        
        emit VestingScheduleCreated(beneficiary, amount);
    }
    
    function release(address beneficiary) external {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        require(schedule.totalAmount > 0, "No vesting schedule found");
        require(!schedule.revoked, "Vesting schedule revoked");
        require(block.timestamp >= schedule.startTime + schedule.cliffDuration, "Cliff period not ended");
        
        uint256 unreleased = releasableAmount(beneficiary);
        require(unreleased > 0, "No tokens to release");
        
        schedule.releasedAmount += unreleased;
        require(token.transfer(beneficiary, unreleased), "Token transfer failed");
        
        emit TokensReleased(beneficiary, unreleased);
    }
    
    function releasableAmount(address beneficiary) public view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        if (schedule.totalAmount == 0 || schedule.revoked) {
            return 0;
        }
        
        if (block.timestamp < schedule.startTime + schedule.cliffDuration) {
            return 0;
        }
        
        if (block.timestamp >= schedule.startTime + schedule.vestingDuration) {
            return schedule.totalAmount - schedule.releasedAmount;
        }
        
        uint256 timeElapsed = block.timestamp - schedule.startTime;
        uint256 vestedAmount = (schedule.totalAmount * timeElapsed) / schedule.vestingDuration;
        
        if (vestedAmount < schedule.releasedAmount) {
            return 0;
        }
        
        return vestedAmount - schedule.releasedAmount;
    }
    
    function revoke(address beneficiary) external onlyOwner {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        require(schedule.totalAmount > 0, "No vesting schedule found");
        require(!schedule.revoked, "Already revoked");
        
        uint256 unreleased = releasableAmount(beneficiary);
        uint256 refund = schedule.totalAmount - schedule.releasedAmount - unreleased;
        
        schedule.revoked = true;
        
        if (unreleased > 0) {
            require(token.transfer(beneficiary, unreleased), "Token transfer failed");
        }
        
        if (refund > 0) {
            require(token.transfer(owner(), refund), "Token transfer failed");
        }
        
        emit VestingRevoked(beneficiary, refund);
    }
    
    function getVestingInfo(address beneficiary) external view returns (
        uint256 totalAmount,
        uint256 releasedAmount,
        uint256 startTime,
        uint256 cliffDuration,
        uint256 vestingDuration,
        bool revoked,
        uint256 releasable
    ) {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        return (
            schedule.totalAmount,
            schedule.releasedAmount,
            schedule.startTime,
            schedule.cliffDuration,
            schedule.vestingDuration,
            schedule.revoked,
            releasableAmount(beneficiary)
        );
    }
}