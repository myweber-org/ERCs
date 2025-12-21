
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVesting {
    address public immutable beneficiary;
    uint256 public immutable startTimestamp;
    uint256 public immutable duration;
    uint256 public immutable totalAmount;
    uint256 public released;

    event TokensReleased(uint256 amount, uint256 timestamp);

    constructor(
        address _beneficiary,
        uint256 _startTimestamp,
        uint256 _duration,
        uint256 _totalAmount
    ) {
        require(_beneficiary != address(0), "Zero address");
        require(_duration > 0, "Duration must be positive");
        require(_totalAmount > 0, "Amount must be positive");

        beneficiary = _beneficiary;
        startTimestamp = _startTimestamp;
        duration = _duration;
        totalAmount = _totalAmount;
        released = 0;
    }

    function releasableAmount() public view returns (uint256) {
        if (block.timestamp < startTimestamp) {
            return 0;
        } else if (block.timestamp >= startTimestamp + duration) {
            return totalAmount - released;
        } else {
            uint256 timeElapsed = block.timestamp - startTimestamp;
            uint256 vestedAmount = (totalAmount * timeElapsed) / duration;
            return vestedAmount - released;
        }
    }

    function release() external {
        uint256 amount = releasableAmount();
        require(amount > 0, "No tokens to release");

        released += amount;
        emit TokensReleased(amount, block.timestamp);
        
        // In production, this would transfer actual tokens
        // For demonstration, we just update the state
    }

    function vestedAmount() external view returns (uint256) {
        if (block.timestamp < startTimestamp) {
            return 0;
        } else if (block.timestamp >= startTimestamp + duration) {
            return totalAmount;
        } else {
            uint256 timeElapsed = block.timestamp - startTimestamp;
            return (totalAmount * timeElapsed) / duration;
        }
    }
}