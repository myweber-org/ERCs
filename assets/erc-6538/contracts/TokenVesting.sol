// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVesting {
    address public immutable beneficiary;
    address public immutable token;
    uint256 public immutable startTime;
    uint256 public immutable cliffDuration;
    uint256 public immutable vestingDuration;
    uint256 public immutable totalAmount;
    uint256 public released;

    event TokensReleased(uint256 amount, uint256 timestamp);

    constructor(
        address _beneficiary,
        address _token,
        uint256 _startTime,
        uint256 _cliffDuration,
        uint256 _vestingDuration,
        uint256 _totalAmount
    ) {
        require(_beneficiary != address(0), "Invalid beneficiary");
        require(_token != address(0), "Invalid token");
        require(_vestingDuration > 0, "Vesting duration must be positive");
        require(_totalAmount > 0, "Total amount must be positive");

        beneficiary = _beneficiary;
        token = _token;
        startTime = _startTime;
        cliffDuration = _cliffDuration;
        vestingDuration = _vestingDuration;
        totalAmount = _totalAmount;
        released = 0;
    }

    function releasableAmount() public view returns (uint256) {
        if (block.timestamp < startTime + cliffDuration) {
            return 0;
        }

        uint256 elapsedTime = block.timestamp - startTime;
        if (elapsedTime > vestingDuration) {
            elapsedTime = vestingDuration;
        }

        uint256 vestedAmount = (totalAmount * elapsedTime) / vestingDuration;
        if (vestedAmount < released) {
            return 0;
        }
        return vestedAmount - released;
    }

    function release() external {
        uint256 amount = releasableAmount();
        require(amount > 0, "No tokens available for release");

        released += amount;
        
        (bool success, ) = token.call(
            abi.encodeWithSignature("transfer(address,uint256)", beneficiary, amount)
        );
        require(success, "Token transfer failed");

        emit TokensReleased(amount, block.timestamp);
    }

    function vestedAmount() public view returns (uint256) {
        if (block.timestamp < startTime + cliffDuration) {
            return 0;
        }

        uint256 elapsedTime = block.timestamp - startTime;
        if (elapsedTime > vestingDuration) {
            elapsedTime = vestingDuration;
        }

        return (totalAmount * elapsedTime) / vestingDuration;
    }
}