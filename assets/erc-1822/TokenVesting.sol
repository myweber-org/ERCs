
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVesting {
    address public immutable beneficiary;
    uint256 public immutable cliff;
    uint256 public immutable start;
    uint256 public immutable duration;
    uint256 public immutable slicePeriodSeconds;
    uint256 public released;
    mapping(address => uint256) public tokenBalances;

    event TokensReleased(address indexed token, uint256 amount);
    event TokensVested(address indexed token, uint256 amount);

    constructor(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _slicePeriodSeconds
    ) {
        require(_beneficiary != address(0), "Beneficiary zero address");
        require(_cliff <= _duration, "Cliff exceeds duration");
        require(_slicePeriodSeconds > 0, "Slice period zero");

        beneficiary = _beneficiary;
        start = _start;
        cliff = _start + _cliff;
        duration = _duration;
        slicePeriodSeconds = _slicePeriodSeconds;
    }

    function vestTokens(address token, uint256 amount) external {
        require(amount > 0, "Amount zero");
        tokenBalances[token] += amount;
        emit TokensVested(token, amount);
    }

    function releasableAmount(address token) public view returns (uint256) {
        if (block.timestamp < cliff) {
            return 0;
        } else if (block.timestamp >= start + duration) {
            return tokenBalances[token];
        } else {
            uint256 timeFromStart = block.timestamp - start;
            uint256 vestedSlicePeriods = timeFromStart / slicePeriodSeconds;
            uint256 totalSlicePeriods = duration / slicePeriodSeconds;
            uint256 vestedAmount = (tokenBalances[token] * vestedSlicePeriods) / totalSlicePeriods;
            return vestedAmount - released;
        }
    }

    function release(address token) external {
        uint256 amount = releasableAmount(token);
        require(amount > 0, "No tokens releasable");
        
        released += amount;
        tokenBalances[token] -= amount;
        
        (bool success, ) = token.call(
            abi.encodeWithSignature("transfer(address,uint256)", beneficiary, amount)
        );
        require(success, "Token transfer failed");
        
        emit TokensReleased(token, amount);
    }

    function vestedAmount(address token) external view returns (uint256) {
        return tokenBalances[token];
    }
}