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
        uint256 releaseInterval;
    }
    
    mapping(address => VestingSchedule) public vestingSchedules;
    mapping(address => bool) public hasVestingSchedule;
    
    event VestingScheduleCreated(address indexed beneficiary, uint256 amount);
    event TokensReleased(address indexed beneficiary, uint256 amount);
    
    constructor(address _tokenAddress) {
        require(_tokenAddress != address(0), "Token address cannot be zero");
        token = IERC20(_tokenAddress);
    }
    
    function createVestingSchedule(
        address _beneficiary,
        uint256 _amount,
        uint256 _cliffDuration,
        uint256 _vestingDuration,
        uint256 _releaseInterval
    ) external onlyOwner {
        require(_beneficiary != address(0), "Beneficiary cannot be zero address");
        require(_amount > 0, "Amount must be greater than zero");
        require(!hasVestingSchedule[_beneficiary], "Beneficiary already has vesting schedule");
        require(_releaseInterval > 0, "Release interval must be greater than zero");
        require(_vestingDuration >= _cliffDuration, "Vesting duration must be greater than or equal to cliff");
        
        vestingSchedules[_beneficiary] = VestingSchedule({
            totalAmount: _amount,
            releasedAmount: 0,
            startTime: block.timestamp,
            cliffDuration: _cliffDuration,
            vestingDuration: _vestingDuration,
            releaseInterval: _releaseInterval
        });
        
        hasVestingSchedule[_beneficiary] = true;
        
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
        
        emit VestingScheduleCreated(_beneficiary, _amount);
    }
    
    function releaseTokens() external {
        require(hasVestingSchedule[msg.sender], "No vesting schedule found");
        
        VestingSchedule storage schedule = vestingSchedules[msg.sender];
        uint256 unreleasedAmount = releasableAmount(msg.sender);
        
        require(unreleasedAmount > 0, "No tokens available for release");
        
        schedule.releasedAmount += unreleasedAmount;
        
        require(token.transfer(msg.sender, unreleasedAmount), "Token transfer failed");
        
        emit TokensReleased(msg.sender, unreleasedAmount);
    }
    
    function releasableAmount(address _beneficiary) public view returns (uint256) {
        if (!hasVestingSchedule[_beneficiary]) {
            return 0;
        }
        
        VestingSchedule storage schedule = vestingSchedules[_beneficiary];
        
        if (block.timestamp < schedule.startTime + schedule.cliffDuration) {
            return 0;
        }
        
        if (block.timestamp >= schedule.startTime + schedule.vestingDuration) {
            return schedule.totalAmount - schedule.releasedAmount;
        }
        
        uint256 elapsedTime = block.timestamp - schedule.startTime - schedule.cliffDuration;
        uint256 totalIntervals = schedule.vestingDuration / schedule.releaseInterval;
        uint256 elapsedIntervals = elapsedTime / schedule.releaseInterval;
        
        uint256 vestedAmount = (schedule.totalAmount * elapsedIntervals) / totalIntervals;
        
        if (vestedAmount > schedule.totalAmount) {
            vestedAmount = schedule.totalAmount;
        }
        
        return vestedAmount - schedule.releasedAmount;
    }
    
    function vestedAmount(address _beneficiary) public view returns (uint256) {
        if (!hasVestingSchedule[_beneficiary]) {
            return 0;
        }
        
        VestingSchedule storage schedule = vestingSchedules[_beneficiary];
        
        if (block.timestamp < schedule.startTime + schedule.cliffDuration) {
            return 0;
        }
        
        if (block.timestamp >= schedule.startTime + schedule.vestingDuration) {
            return schedule.totalAmount;
        }
        
        uint256 elapsedTime = block.timestamp - schedule.startTime - schedule.cliffDuration;
        uint256 totalIntervals = schedule.vestingDuration / schedule.releaseInterval;
        uint256 elapsedIntervals = elapsedTime / schedule.releaseInterval;
        
        uint256 vestedAmount = (schedule.totalAmount * elapsedIntervals) / totalIntervals;
        
        if (vestedAmount > schedule.totalAmount) {
            vestedAmount = schedule.totalAmount;
        }
        
        return vestedAmount;
    }
    
    function getVestingSchedule(address _beneficiary) external view returns (
        uint256 totalAmount,
        uint256 releasedAmount,
        uint256 startTime,
        uint256 cliffDuration,
        uint256 vestingDuration,
        uint256 releaseInterval
    ) {
        require(hasVestingSchedule[_beneficiary], "No vesting schedule found");
        
        VestingSchedule storage schedule = vestingSchedules[_beneficiary];
        
        return (
            schedule.totalAmount,
            schedule.releasedAmount,
            schedule.startTime,
            schedule.cliffDuration,
            schedule.vestingDuration,
            schedule.releaseInterval
        );
    }
}