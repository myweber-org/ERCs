// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract EscrowContract {
    address public depositor;
    address public beneficiary;
    address public arbiter;
    uint256 public amount;
    bool public isReleased;
    bool public isRefunded;

    event Deposited(address indexed from, uint256 value);
    event Released(uint256 amount);
    event Refunded(uint256 amount);

    constructor(address _beneficiary, address _arbiter) payable {
        require(_beneficiary != address(0), "Beneficiary cannot be zero address");
        require(_arbiter != address(0), "Arbiter cannot be zero address");
        require(msg.value > 0, "Deposit amount must be greater than zero");

        depositor = msg.sender;
        beneficiary = _beneficiary;
        arbiter = _arbiter;
        amount = msg.value;
        isReleased = false;
        isRefunded = false;

        emit Deposited(msg.sender, msg.value);
    }

    function release() external {
        require(msg.sender == arbiter, "Only arbiter can release funds");
        require(!isReleased, "Funds already released");
        require(!isRefunded, "Funds already refunded");

        isReleased = true;
        (bool success, ) = beneficiary.call{value: amount}("");
        require(success, "Transfer to beneficiary failed");

        emit Released(amount);
    }

    function refund() external {
        require(msg.sender == arbiter, "Only arbiter can refund funds");
        require(!isReleased, "Funds already released");
        require(!isRefunded, "Funds already refunded");

        isRefunded = true;
        (bool success, ) = depositor.call{value: amount}("");
        require(success, "Transfer to depositor failed");

        emit Refunded(amount);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}