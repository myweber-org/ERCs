// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVesting {
    address public immutable beneficiary;
    address public immutable token;
    uint256 public immutable startTime;
    uint256 public immutable duration;
    uint256 public immutable totalAmount;
    uint256 public released;

    event TokensReleased(uint256 amount);

    constructor(
        address beneficiary_,
        address token_,
        uint256 startTime_,
        uint256 duration_,
        uint256 totalAmount_
    ) {
        require(beneficiary_ != address(0), "Beneficiary zero address");
        require(token_ != address(0), "Token zero address");
        require(duration_ > 0, "Duration must be positive");
        require(totalAmount_ > 0, "Total amount must be positive");

        beneficiary = beneficiary_;
        token = token_;
        startTime = startTime_;
        duration = duration_;
        totalAmount = totalAmount_;
    }

    function releasableAmount() public view returns (uint256) {
        if (block.timestamp < startTime) {
            return 0;
        } else if (block.timestamp >= startTime + duration) {
            return totalAmount - released;
        } else {
            uint256 timeElapsed = block.timestamp - startTime;
            uint256 vestedAmount = (totalAmount * timeElapsed) / duration;
            return vestedAmount - released;
        }
    }

    function release() external {
        uint256 amount = releasableAmount();
        require(amount > 0, "No tokens to release");

        released += amount;
        
        (bool success, ) = token.call(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                beneficiary,
                amount
            )
        );
        require(success, "Token transfer failed");

        emit TokensReleased(amount);
    }

    function vestedAmount() public view returns (uint256) {
        if (block.timestamp < startTime) {
            return 0;
        } else if (block.timestamp >= startTime + duration) {
            return totalAmount;
        } else {
            uint256 timeElapsed = block.timestamp - startTime;
            return (totalAmount * timeElapsed) / duration;
        }
    }
}