
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
        require(beneficiary_ != address(0), "Beneficiary cannot be zero address");
        require(cliff_ <= duration_, "Cliff must be less than or equal to duration");
        require(slicePeriodSeconds_ > 0, "Slice period must be greater than 0");

        beneficiary = beneficiary_;
        start = start_;
        cliff = start_ + cliff_;
        duration = duration_;
        slicePeriodSeconds = slicePeriodSeconds_;
    }

    function vestTokens(address token, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        vestedAmount[token] += amount;
        emit TokensVested(token, beneficiary, amount);
    }

    function releasableAmount(address token) public view returns (uint256) {
        if (block.timestamp < cliff) {
            return 0;
        } else if (block.timestamp >= start + duration) {
            return vestedAmount[token] - released;
        } else {
            uint256 timeFromStart = block.timestamp - start;
            uint256 vestedSlicePeriods = timeFromStart / slicePeriodSeconds;
            uint256 totalSlicePeriods = duration / slicePeriodSeconds;
            uint256 totalVested = (vestedAmount[token] * vestedSlicePeriods) / totalSlicePeriods;
            return totalVested - released;
        }
    }

    function release(address token) external {
        uint256 amount = releasableAmount(token);
        require(amount > 0, "No tokens to release");
        
        released += amount;
        require(IERC20(token).transfer(beneficiary, amount), "Token transfer failed");
        emit TokensReleased(token, amount);
    }
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}