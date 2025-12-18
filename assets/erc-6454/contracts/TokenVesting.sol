pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenVesting {
    address public immutable beneficiary;
    address public immutable token;
    uint256 public immutable startTimestamp;
    uint256 public immutable cliffDuration;
    uint256 public immutable vestingDuration;
    uint256 public immutable totalAmount;
    uint256 public released;

    event TokensReleased(uint256 amount);

    constructor(
        address beneficiary_,
        address token_,
        uint256 startTimestamp_,
        uint256 cliffDuration_,
        uint256 vestingDuration_,
        uint256 totalAmount_
    ) {
        require(beneficiary_ != address(0), "Beneficiary is zero address");
        require(token_ != address(0), "Token is zero address");
        require(cliffDuration_ <= vestingDuration_, "Cliff longer than vesting");
        require(totalAmount_ > 0, "Total amount is zero");

        beneficiary = beneficiary_;
        token = token_;
        startTimestamp = startTimestamp_;
        cliffDuration = cliffDuration_;
        vestingDuration = vestingDuration_;
        totalAmount = totalAmount_;
    }

    function releasableAmount() public view returns (uint256) {
        if (block.timestamp < startTimestamp + cliffDuration) {
            return 0;
        }
        
        uint256 elapsedTime = block.timestamp - startTimestamp;
        if (elapsedTime > vestingDuration) {
            elapsedTime = vestingDuration;
        }
        
        uint256 vestedAmount = (totalAmount * elapsedTime) / vestingDuration;
        if (vestedAmount > totalAmount) {
            vestedAmount = totalAmount;
        }
        
        return vestedAmount - released;
    }

    function release() external {
        uint256 amount = releasableAmount();
        require(amount > 0, "No tokens to release");
        
        released += amount;
        require(IERC20(token).transfer(beneficiary, amount), "Token transfer failed");
        
        emit TokensReleased(amount);
    }

    function vestedAmount() external view returns (uint256) {
        if (block.timestamp < startTimestamp + cliffDuration) {
            return 0;
        }
        
        uint256 elapsedTime = block.timestamp - startTimestamp;
        if (elapsedTime > vestingDuration) {
            elapsedTime = vestingDuration;
        }
        
        uint256 vested = (totalAmount * elapsedTime) / vestingDuration;
        return vested > totalAmount ? totalAmount : vested;
    }
}