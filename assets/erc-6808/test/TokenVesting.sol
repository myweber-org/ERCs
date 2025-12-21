// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TokenVesting is Ownable, ReentrancyGuard {
    IERC20 public immutable token;
    
    struct VestingSchedule {
        uint256 totalAmount;
        uint256 releasedAmount;
        uint256 startTime;
        uint256 cliffDuration;
        uint256 releaseDuration;
        uint256 releaseInterval;
        bool revoked;
    }
    
    mapping(address => VestingSchedule[]) public vestingSchedules;
    mapping(address => uint256) public totalVestedAmount;
    mapping(address => uint256) public totalReleasedAmount;
    
    event VestingScheduleCreated(
        address indexed beneficiary,
        uint256 amount,
        uint256 startTime,
        uint256 cliffDuration,
        uint256 releaseDuration,
        uint256 releaseInterval
    );
    
    event TokensReleased(address indexed beneficiary, uint256 amount);
    event VestingRevoked(address indexed beneficiary, uint256 unreleasedAmount);
    
    constructor(IERC20 _token) {
        require(address(_token) != address(0), "Token address cannot be zero");
        token = _token;
    }
    
    function createVestingSchedule(
        address _beneficiary,
        uint256 _amount,
        uint256 _startTime,
        uint256 _cliffDuration,
        uint256 _releaseDuration,
        uint256 _releaseInterval
    ) external onlyOwner {
        require(_beneficiary != address(0), "Beneficiary cannot be zero address");
        require(_amount > 0, "Amount must be greater than zero");
        require(_releaseInterval > 0, "Release interval must be greater than zero");
        require(_releaseDuration >= _cliffDuration, "Release duration must be >= cliff duration");
        
        uint256 balance = token.balanceOf(address(this));
        require(balance >= _amount, "Insufficient token balance in contract");
        
        VestingSchedule memory schedule = VestingSchedule({
            totalAmount: _amount,
            releasedAmount: 0,
            startTime: _startTime,
            cliffDuration: _cliffDuration,
            releaseDuration: _releaseDuration,
            releaseInterval: _releaseInterval,
            revoked: false
        });
        
        vestingSchedules[_beneficiary].push(schedule);
        totalVestedAmount[_beneficiary] += _amount;
        
        emit VestingScheduleCreated(
            _beneficiary,
            _amount,
            _startTime,
            _cliffDuration,
            _releaseDuration,
            _releaseInterval
        );
    }
    
    function release(address _beneficiary, uint256 _scheduleIndex) external nonReentrant {
        require(_scheduleIndex < vestingSchedules[_beneficiary].length, "Invalid schedule index");
        
        VestingSchedule storage schedule = vestingSchedules[_beneficiary][_scheduleIndex];
        require(!schedule.revoked, "Vesting schedule has been revoked");
        
        uint256 releasableAmount = _calculateReleasableAmount(schedule);
        require(releasableAmount > 0, "No tokens available for release");
        
        schedule.releasedAmount += releasableAmount;
        totalReleasedAmount[_beneficiary] += releasableAmount;
        
        require(token.transfer(_beneficiary, releasableAmount), "Token transfer failed");
        
        emit TokensReleased(_beneficiary, releasableAmount);
    }
    
    function revokeVestingSchedule(address _beneficiary, uint256 _scheduleIndex) external onlyOwner {
        require(_scheduleIndex < vestingSchedules[_beneficiary].length, "Invalid schedule index");
        
        VestingSchedule storage schedule = vestingSchedules[_beneficiary][_scheduleIndex];
        require(!schedule.revoked, "Vesting already revoked");
        
        uint256 releasableAmount = _calculateReleasableAmount(schedule);
        uint256 unreleasedAmount = schedule.totalAmount - schedule.releasedAmount - releasableAmount;
        
        schedule.revoked = true;
        
        if (releasableAmount > 0) {
            schedule.releasedAmount += releasableAmount;
            totalReleasedAmount[_beneficiary] += releasableAmount;
            require(token.transfer(_beneficiary, releasableAmount), "Token transfer failed");
        }
        
        if (unreleasedAmount > 0) {
            require(token.transfer(owner(), unreleasedAmount), "Token transfer failed");
        }
        
        emit VestingRevoked(_beneficiary, unreleasedAmount);
    }
    
    function getReleasableAmount(address _beneficiary) external view returns (uint256) {
        uint256 totalReleasable = 0;
        for (uint256 i = 0; i < vestingSchedules[_beneficiary].length; i++) {
            if (!vestingSchedules[_beneficiary][i].revoked) {
                totalReleasable += _calculateReleasableAmount(vestingSchedules[_beneficiary][i]);
            }
        }
        return totalReleasable;
    }
    
    function getVestingScheduleCount(address _beneficiary) external view returns (uint256) {
        return vestingSchedules[_beneficiary].length;
    }
    
    function _calculateReleasableAmount(VestingSchedule memory _schedule) private view returns (uint256) {
        if (block.timestamp < _schedule.startTime + _schedule.cliffDuration) {
            return 0;
        }
        
        if (block.timestamp >= _schedule.startTime + _schedule.releaseDuration) {
            return _schedule.totalAmount - _schedule.releasedAmount;
        }
        
        uint256 elapsedTime = block.timestamp - _schedule.startTime - _schedule.cliffDuration;
        uint256 totalIntervals = _schedule.releaseDuration / _schedule.releaseInterval;
        uint256 elapsedIntervals = elapsedTime / _schedule.releaseInterval;
        
        uint256 totalReleasable = (_schedule.totalAmount * elapsedIntervals) / totalIntervals;
        
        if (totalReleasable > _schedule.releasedAmount) {
            return totalReleasable - _schedule.releasedAmount;
        }
        
        return 0;
    }
    
    function recoverExcessTokens(uint256 _amount) external onlyOwner {
        uint256 contractBalance = token.balanceOf(address(this));
        uint256 totalLocked = 0;
        
        address[] memory beneficiaries = _getAllBeneficiaries();
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            totalLocked += totalVestedAmount[beneficiaries[i]] - totalReleasedAmount[beneficiaries[i]];
        }
        
        uint256 excessAmount = contractBalance - totalLocked;
        require(_amount <= excessAmount, "Amount exceeds recoverable balance");
        
        require(token.transfer(owner(), _amount), "Token transfer failed");
    }
    
    function _getAllBeneficiaries() private view returns (address[] memory) {
        // This is a simplified implementation
        // In production, you would need to maintain a separate array of beneficiaries
        revert("Not implemented in this version");
    }
}