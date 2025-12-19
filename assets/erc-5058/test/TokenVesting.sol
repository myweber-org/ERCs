
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVesting {
    address public immutable beneficiary;
    uint256 public immutable cliff;
    uint256 public immutable start;
    uint256 public immutable duration;
    uint256 public immutable slicePeriodSeconds;
    uint256 public released;
    mapping(address => uint256) public vestedAmount;

    event TokensReleased(address indexed token, uint256 amount);
    event TokensVested(address indexed token, address indexed beneficiary, uint256 amount);

    constructor(
        address beneficiary_,
        uint256 start_,
        uint256 cliff_,
        uint256 duration_,
        uint256 slicePeriodSeconds_
    ) {
        require(beneficiary_ != address(0), "TokenVesting: beneficiary is zero address");
        require(cliff_ <= duration_, "TokenVesting: cliff > duration");
        require(duration_ > 0, "TokenVesting: duration is 0");
        require(slicePeriodSeconds_ > 0, "TokenVesting: slicePeriodSeconds is 0");

        beneficiary = beneficiary_;
        start = start_;
        cliff = start_ + cliff_;
        duration = duration_;
        slicePeriodSeconds = slicePeriodSeconds_;
    }

    function vestTokens(address token, uint256 amount) external {
        require(amount > 0, "TokenVesting: amount is 0");
        vestedAmount[token] += amount;
        emit TokensVested(token, beneficiary, amount);
    }

    function release(address token) external {
        uint256 unreleased = releasableAmount(token);
        require(unreleased > 0, "TokenVesting: no tokens to release");

        released += unreleased;
        vestedAmount[token] -= unreleased;

        require(IERC20(token).transfer(beneficiary, unreleased), "TokenVesting: transfer failed");
        emit TokensReleased(token, unreleased);
    }

    function releasableAmount(address token) public view returns (uint256) {
        return vestedAmount(token) - released;
    }

    function vestedAmount(address token) public view returns (uint256) {
        if (block.timestamp < cliff) {
            return 0;
        } else if (block.timestamp >= start + duration) {
            return vestedAmount[token];
        } else {
            uint256 timeFromStart = block.timestamp - start;
            uint256 vestedSlicePeriods = timeFromStart / slicePeriodSeconds;
            uint256 vestedSeconds = vestedSlicePeriods * slicePeriodSeconds;
            return (vestedAmount[token] * vestedSeconds) / duration;
        }
    }
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}