pragma solidity ^0.8.19;

contract Escrow {
    address public depositor;
    address public beneficiary;
    address public arbiter;

    bool public isApproved;

    event Deposited(address indexed depositor, uint256 amount);
    event Approved(address indexed arbiter);
    event Released(address indexed beneficiary, uint256 amount);
    event Refunded(address indexed depositor, uint256 amount);

    constructor(address _beneficiary, address _arbiter) payable {
        require(_beneficiary != address(0), "Beneficiary cannot be zero address");
        require(_arbiter != address(0), "Arbiter cannot be zero address");
        require(msg.value > 0, "Deposit must be greater than zero");

        depositor = msg.sender;
        beneficiary = _beneficiary;
        arbiter = _arbiter;

        emit Deposited(msg.sender, msg.value);
    }

    function approve() external {
        require(msg.sender == arbiter, "Only arbiter can approve");
        require(!isApproved, "Already approved");
        isApproved = true;
        emit Approved(msg.sender);
    }

    function release() external {
        require(msg.sender == arbiter, "Only arbiter can release");
        require(isApproved, "Not approved yet");
        require(address(this).balance > 0, "No funds to release");

        uint256 balance = address(this).balance;
        (bool success, ) = beneficiary.call{value: balance}("");
        require(success, "Transfer failed");

        emit Released(beneficiary, balance);
    }

    function refund() external {
        require(msg.sender == arbiter, "Only arbiter can refund");
        require(!isApproved, "Cannot refund after approval");
        require(address(this).balance > 0, "No funds to refund");

        uint256 balance = address(this).balance;
        (bool success, ) = depositor.call{value: balance}("");
        require(success, "Transfer failed");

        emit Refunded(depositor, balance);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}