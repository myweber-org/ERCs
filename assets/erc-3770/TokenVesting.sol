// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenVesting {
    address public immutable beneficiary;
    address public immutable token;
    uint256 public immutable start;
    uint256 public immutable cliff;
    uint256 public immutable duration;
    uint256 public immutable totalAmount;
    uint256 public released;

    event TokensReleased(uint256 amount);

    constructor(
        address beneficiary_,
        address token_,
        uint256 start_,
        uint256 cliff_,
        uint256 duration_,
        uint256 totalAmount_
    ) {
        require(beneficiary_ != address(0), "beneficiary zero address");
        require(token_ != address(0), "token zero address");
        require(cliff_ <= duration_, "cliff > duration");
        require(totalAmount_ > 0, "totalAmount zero");

        beneficiary = beneficiary_;
        token = token_;
        start = start_;
        cliff = cliff_;
        duration = duration_;
        totalAmount = totalAmount_;
    }

    function releasableAmount() public view returns (uint256) {
        if (block.timestamp < start + cliff) {
            return 0;
        }
        if (block.timestamp >= start + duration) {
            return totalAmount - released;
        }
        uint256 elapsedTime = block.timestamp - start;
        uint256 vestedAmount = (totalAmount * elapsedTime) / duration;
        if (vestedAmount > totalAmount) {
            vestedAmount = totalAmount;
        }
        return vestedAmount - released;
    }

    function release() external {
        uint256 amount = releasableAmount();
        require(amount > 0, "no tokens to release");
        released += amount;
        require(IERC20(token).transfer(beneficiary, amount), "transfer failed");
        emit TokensReleased(amount);
    }

    function vestedAmount() external view returns (uint256) {
        if (block.timestamp < start + cliff) {
            return 0;
        }
        if (block.timestamp >= start + duration) {
            return totalAmount;
        }
        uint256 elapsedTime = block.timestamp - start;
        uint256 vested = (totalAmount * elapsedTime) / duration;
        return vested > totalAmount ? totalAmount : vested;
    }
}