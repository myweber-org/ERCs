// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract TokenVesting {
    address public immutable beneficiary;
    address public immutable token;
    uint256 public immutable start;
    uint256 public immutable duration;
    uint256 public immutable totalAmount;
    uint256 public released;

    event TokensReleased(uint256 amount);

    constructor(
        address beneficiary_,
        address token_,
        uint256 start_,
        uint256 duration_,
        uint256 totalAmount_
    ) {
        require(beneficiary_ != address(0), "TokenVesting: beneficiary is zero address");
        require(token_ != address(0), "TokenVesting: token is zero address");
        require(duration_ > 0, "TokenVesting: duration is 0");
        require(totalAmount_ > 0, "TokenVesting: totalAmount is 0");

        beneficiary = beneficiary_;
        token = token_;
        start = start_;
        duration = duration_;
        totalAmount = totalAmount_;
    }

    function releasable() public view returns (uint256) {
        if (block.timestamp < start) {
            return 0;
        } else if (block.timestamp >= start + duration) {
            return totalAmount - released;
        } else {
            uint256 timeElapsed = block.timestamp - start;
            uint256 vestedAmount = (totalAmount * timeElapsed) / duration;
            if (vestedAmount > released) {
                return vestedAmount - released;
            }
            return 0;
        }
    }

    function release() external {
        uint256 amount = releasable();
        require(amount > 0, "TokenVesting: no tokens to release");
        
        released += amount;
        require(IERC20(token).transfer(beneficiary, amount), "TokenVesting: transfer failed");
        
        emit TokensReleased(amount);
    }

    function vestedAmount() external view returns (uint256) {
        if (block.timestamp < start) {
            return 0;
        } else if (block.timestamp >= start + duration) {
            return totalAmount;
        } else {
            uint256 timeElapsed = block.timestamp - start;
            return (totalAmount * timeElapsed) / duration;
        }
    }
}