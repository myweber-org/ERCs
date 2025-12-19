// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenVesting {
    address public immutable beneficiary;
    uint256 public immutable cliff;
    uint256 public immutable start;
    uint256 public immutable duration;
    uint256 public immutable slicePeriodSeconds;
    uint256 public released;

    event TokensReleased(uint256 amount);

    constructor(
        address beneficiaryAddress,
        uint256 cliffDuration,
        uint256 durationSeconds,
        uint256 slicePeriod
    ) {
        require(beneficiaryAddress != address(0), "Beneficiary cannot be zero address");
        require(cliffDuration <= durationSeconds, "Cliff exceeds duration");
        require(durationSeconds > 0, "Duration must be > 0");
        require(slicePeriod > 0, "Slice period must be > 0");

        beneficiary = beneficiaryAddress;
        cliff = block.timestamp + cliffDuration;
        start = block.timestamp;
        duration = durationSeconds;
        slicePeriodSeconds = slicePeriod;
        released = 0;
    }

    function vestedAmount(uint256 totalAllocation) public view returns (uint256) {
        if (block.timestamp < cliff) {
            return 0;
        } else if (block.timestamp >= start + duration) {
            return totalAllocation;
        } else {
            uint256 timeFromStart = block.timestamp - start;
            uint256 vestedSlicePeriods = timeFromStart / slicePeriodSeconds;
            uint256 totalSlices = duration / slicePeriodSeconds;
            return (totalAllocation * vestedSlicePeriods) / totalSlices;
        }
    }

    function releasableAmount(uint256 totalAllocation) public view returns (uint256) {
        return vestedAmount(totalAllocation) - released;
    }

    function release(uint256 totalAllocation) external {
        uint256 amount = releasableAmount(totalAllocation);
        require(amount > 0, "No tokens to release");

        released += amount;
        emit TokensReleased(amount);
        
        // In production, add token transfer logic here
        // IERC20(tokenAddress).transfer(beneficiary, amount);
    }
}