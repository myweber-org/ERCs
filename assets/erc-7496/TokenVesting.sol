// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVesting {
    address public immutable beneficiary;
    uint256 public immutable cliff;
    uint256 public immutable start;
    uint256 public immutable duration;
    uint256 public immutable slicePeriodSeconds;
    uint256 public immutable totalAmount;
    uint256 public released;

    event TokensReleased(uint256 amount, uint256 timestamp);

    constructor(
        address beneficiaryAddress,
        uint256 cliffDuration,
        uint256 vestingDuration,
        uint256 slicePeriod,
        uint256 amount
    ) {
        require(beneficiaryAddress != address(0), "Beneficiary is zero address");
        require(vestingDuration > 0, "Duration must be > 0");
        require(amount > 0, "Amount must be > 0");
        require(cliffDuration <= vestingDuration, "Cliff exceeds duration");

        beneficiary = beneficiaryAddress;
        cliff = cliffDuration;
        duration = vestingDuration;
        slicePeriodSeconds = slicePeriod;
        totalAmount = amount;
        start = block.timestamp;
    }

    function releasableAmount() public view returns (uint256) {
        if (block.timestamp < start + cliff) {
            return 0;
        } else if (block.timestamp >= start + duration) {
            return totalAmount - released;
        } else {
            uint256 timeFromStart = block.timestamp - start;
            uint256 vestedSlicePeriods = timeFromStart / slicePeriodSeconds;
            uint256 vestedSeconds = vestedSlicePeriods * slicePeriodSeconds;
            uint256 vestedAmount = (totalAmount * vestedSeconds) / duration;
            if (vestedAmount > totalAmount) {
                vestedAmount = totalAmount;
            }
            return vestedAmount - released;
        }
    }

    function release() external {
        uint256 amount = releasableAmount();
        require(amount > 0, "No tokens to release");

        released += amount;
        emit TokensReleased(amount, block.timestamp);

        (bool success, ) = beneficiary.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function vestedAmount() public view returns (uint256) {
        if (block.timestamp < start + cliff) {
            return 0;
        } else if (block.timestamp >= start + duration) {
            return totalAmount;
        } else {
            uint256 timeFromStart = block.timestamp - start;
            uint256 vestedSlicePeriods = timeFromStart / slicePeriodSeconds;
            uint256 vestedSeconds = vestedSlicePeriods * slicePeriodSeconds;
            uint256 vestedAmount = (totalAmount * vestedSeconds) / duration;
            if (vestedAmount > totalAmount) {
                vestedAmount = totalAmount;
            }
            return vestedAmount;
        }
    }
}