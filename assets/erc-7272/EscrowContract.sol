// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract EscrowContract {
    address public arbiter;
    address public depositor;
    address public beneficiary;
    uint256 public amount;
    bool public isReleased;
    bool public isRefunded;

    event Deposited(address indexed depositor, address indexed beneficiary, uint256 amount);
    event Released(uint256 amount);
    event Refunded(uint256 amount);

    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Only arbiter can call this function");
        _;
    }

    modifier onlyDepositor() {
        require(msg.sender == depositor, "Only depositor can call this function");
        _;
    }

    modifier notSettled() {
        require(!isReleased && !isRefunded, "Escrow already settled");
        _;
    }

    constructor(address _arbiter, address _beneficiary) payable {
        require(_arbiter != address(0), "Invalid arbiter address");
        require(_beneficiary != address(0), "Invalid beneficiary address");
        require(msg.value > 0, "Deposit amount must be greater than zero");

        arbiter = _arbiter;
        depositor = msg.sender;
        beneficiary = _beneficiary;
        amount = msg.value;

        emit Deposited(depositor, beneficiary, amount);
    }

    function release() external onlyArbiter notSettled {
        isReleased = true;
        payable(beneficiary).transfer(amount);
        emit Released(amount);
    }

    function refund() external onlyArbiter notSettled {
        isRefunded = true;
        payable(depositor).transfer(amount);
        emit Refunded(amount);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getStatus() external view returns (string memory) {
        if (isReleased) {
            return "Released";
        } else if (isRefunded) {
            return "Refunded";
        } else {
            return "Pending";
        }
    }
}