pragma solidity ^0.8.19;

contract Escrow {
    address public depositor;
    address public beneficiary;
    address public arbiter;

    bool public isApproved;

    event Deposited(address indexed depositor, uint256 amount);
    event Approved(uint256 amount);
    event Refunded(uint256 amount);

    constructor(address _beneficiary, address _arbiter) {
        depositor = msg.sender;
        beneficiary = _beneficiary;
        arbiter = _arbiter;
    }

    function deposit() external payable {
        require(msg.sender == depositor, "Only depositor can deposit");
        require(address(this).balance == 0, "Funds already deposited");
        emit Deposited(msg.sender, msg.value);
    }

    function approve() external {
        require(msg.sender == arbiter, "Only arbiter can approve");
        require(!isApproved, "Already approved");
        require(address(this).balance > 0, "No funds to release");

        isApproved = true;
        uint256 balance = address(this).balance;
        (bool success, ) = beneficiary.call{value: balance}("");
        require(success, "Transfer failed");
        emit Approved(balance);
    }

    function refund() external {
        require(msg.sender == arbiter, "Only arbiter can refund");
        require(!isApproved, "Cannot refund after approval");
        require(address(this).balance > 0, "No funds to refund");

        uint256 balance = address(this).balance;
        (bool success, ) = depositor.call{value: balance}("");
        require(success, "Transfer failed");
        emit Refunded(balance);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}