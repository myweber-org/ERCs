// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVesting is Ownable {
    IERC20 public immutable token;
    
    struct VestingSchedule {
        uint256 totalAmount;
        uint256 releasedAmount;
        uint256 startTimestamp;
        uint256 cliffDuration;
        uint256 vestingDuration;
        bool revoked;
    }
    
    mapping(address => VestingSchedule) public vestingSchedules;
    
    event VestingScheduleCreated(address indexed beneficiary, uint256 amount, uint256 startTimestamp, uint256 cliffDuration, uint256 vestingDuration);
    event TokensReleased(address indexed beneficiary, uint256 amount);
    event VestingScheduleRevoked(address indexed beneficiary, uint256 unreleasedAmount);
    
    constructor(address tokenAddress) {
        require(tokenAddress != address(0), "Token address cannot be zero");
        token = IERC20(tokenAddress);
    }
    
    function createVestingSchedule(
        address beneficiary,
        uint256 amount,
        uint256 startTimestamp,
        uint256 cliffDuration,
        uint256 vestingDuration
    ) external onlyOwner {
        require(beneficiary != address(0), "Beneficiary cannot be zero address");
        require(amount > 0, "Amount must be greater than zero");
        require(startTimestamp >= block.timestamp, "Start timestamp must be in the future");
        require(vestingDuration > 0, "Vesting duration must be greater than zero");
        require(vestingSchedules[beneficiary].totalAmount == 0, "Vesting schedule already exists");
        
        vestingSchedules[beneficiary] = VestingSchedule({
            totalAmount: amount,
            releasedAmount: 0,
            startTimestamp: startTimestamp,
            cliffDuration: cliffDuration,
            vestingDuration: vestingDuration,
            revoked: false
        });
        
        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        
        emit VestingScheduleCreated(beneficiary, amount, startTimestamp, cliffDuration, vestingDuration);
    }
    
    function release(address beneficiary) external {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        require(schedule.totalAmount > 0, "No vesting schedule found");
        require(!schedule.revoked, "Vesting schedule has been revoked");
        
        uint256 releasableAmount = _releasableAmount(schedule);
        require(releasableAmount > 0, "No tokens available for release");
        
        schedule.releasedAmount += releasableAmount;
        
        require(token.transfer(beneficiary, releasableAmount), "Token transfer failed");
        
        emit TokensReleased(beneficiary, releasableAmount);
    }
    
    function revoke(address beneficiary) external onlyOwner {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        require(schedule.totalAmount > 0, "No vesting schedule found");
        require(!schedule.revoked, "Vesting schedule already revoked");
        
        uint256 unreleasedAmount = schedule.totalAmount - schedule.releasedAmount;
        uint256 refundAmount = unreleasedAmount - _releasableAmount(schedule);
        
        schedule.revoked = true;
        
        if (refundAmount > 0) {
            require(token.transfer(owner(), refundAmount), "Token transfer failed");
        }
        
        emit VestingScheduleRevoked(beneficiary, refundAmount);
    }
    
    function releasableAmount(address beneficiary) external view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        if (schedule.totalAmount == 0 || schedule.revoked) {
            return 0;
        }
        return _releasableAmount(schedule);
    }
    
    function vestedAmount(address beneficiary) external view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[beneficiary];
        if (schedule.totalAmount == 0) {
            return 0;
        }
        return _vestedAmount(schedule);
    }
    
    function _releasableAmount(VestingSchedule storage schedule) private view returns (uint256) {
        uint256 vested = _vestedAmount(schedule);
        if (vested > schedule.releasedAmount) {
            return vested - schedule.releasedAmount;
        }
        return 0;
    }
    
    function _vestedAmount(VestingSchedule storage schedule) private view returns (uint256) {
        if (block.timestamp < schedule.startTimestamp + schedule.cliffDuration) {
            return 0;
        }
        
        if (block.timestamp >= schedule.startTimestamp + schedule.vestingDuration) {
            return schedule.totalAmount;
        }
        
        uint256 timeElapsed = block.timestamp - schedule.startTimestamp;
        return (schedule.totalAmount * timeElapsed) / schedule.vestingDuration;
    }
}// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVesting {
    address public immutable beneficiary;
    uint256 public immutable startTime;
    uint256 public immutable duration;
    uint256 public immutable totalAmount;
    uint256 public released;

    event TokensReleased(uint256 amount, uint256 timestamp);

    constructor(address _beneficiary, uint256 _duration, uint256 _totalAmount) {
        require(_beneficiary != address(0), "Beneficiary cannot be zero address");
        require(_duration > 0, "Duration must be positive");
        require(_totalAmount > 0, "Total amount must be positive");

        beneficiary = _beneficiary;
        startTime = block.timestamp;
        duration = _duration;
        totalAmount = _totalAmount;
        released = 0;
    }

    function releasableAmount() public view returns (uint256) {
        if (block.timestamp < startTime) {
            return 0;
        }
        
        uint256 elapsedTime = block.timestamp - startTime;
        if (elapsedTime > duration) {
            elapsedTime = duration;
        }
        
        uint256 vestedAmount = (totalAmount * elapsedTime) / duration;
        return vestedAmount - released;
    }

    function release() external {
        uint256 amount = releasableAmount();
        require(amount > 0, "No tokens available for release");
        
        released += amount;
        
        // In production, this would transfer actual tokens
        // For this example, we just emit an event
        emit TokensReleased(amount, block.timestamp);
    }

    function vestedAmount() public view returns (uint256) {
        if (block.timestamp < startTime) {
            return 0;
        }
        
        uint256 elapsedTime = block.timestamp - startTime;
        if (elapsedTime > duration) {
            return totalAmount;
        }
        
        return (totalAmount * elapsedTime) / duration;
    }
}