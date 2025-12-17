// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenVesting {
    address public immutable beneficiary;
    uint256 public immutable cliff;
    uint256 public immutable start;
    uint256 public immutable duration;
    uint256 public immutable totalAmount;
    uint256 public released;

    event TokensReleased(uint256 amount);

    constructor(
        address beneficiary_,
        uint256 start_,
        uint256 cliff_,
        uint256 duration_,
        uint256 totalAmount_
    ) {
        require(beneficiary_ != address(0), "Beneficiary cannot be zero address");
        require(cliff_ <= duration_, "Cliff must be less than or equal to duration");
        require(totalAmount_ > 0, "Total amount must be greater than zero");

        beneficiary = beneficiary_;
        start = start_;
        cliff = cliff_;
        duration = duration_;
        totalAmount = totalAmount_;
    }

    function releasableAmount() public view returns (uint256) {
        if (block.timestamp < start + cliff) {
            return 0;
        } else if (block.timestamp >= start + duration) {
            return totalAmount - released;
        } else {
            uint256 elapsedTime = block.timestamp - start;
            uint256 vestedAmount = (totalAmount * elapsedTime) / duration;
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
        emit TokensReleased(amount);

        (bool success, ) = beneficiary.call{value: amount}("");
        require(success, "Token release failed");
    }

    function vestedAmount() public view returns (uint256) {
        if (block.timestamp < start + cliff) {
            return 0;
        } else if (block.timestamp >= start + duration) {
            return totalAmount;
        } else {
            uint256 elapsedTime = block.timestamp - start;
            uint256 vested = (totalAmount * elapsedTime) / duration;
            return vested > totalAmount ? totalAmount : vested;
        }
    }
}