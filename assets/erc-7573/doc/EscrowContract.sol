pragma solidity ^0.8.0;

contract Escrow {
    address public depositor;
    address public beneficiary;
    address public arbiter;
    uint256 public amount;
    bool public isReleased;
    bool public isRefunded;

    event Deposited(address indexed depositor, address indexed beneficiary, address indexed arbiter, uint256 amount);
    event Released(address indexed arbiter, uint256 amount);
    event Refunded(address indexed arbiter, uint256 amount);

    constructor(address _beneficiary, address _arbiter) payable {
        require(_beneficiary != address(0), "Beneficiary address cannot be zero");
        require(_arbiter != address(0), "Arbiter address cannot be zero");
        require(msg.value > 0, "Deposit amount must be greater than zero");

        depositor = msg.sender;
        beneficiary = _beneficiary;
        arbiter = _arbiter;
        amount = msg.value;
        isReleased = false;
        isRefunded = false;

        emit Deposited(depositor, beneficiary, arbiter, amount);
    }

    function release() external {
        require(msg.sender == arbiter, "Only arbiter can release funds");
        require(!isReleased && !isRefunded, "Funds already released or refunded");
        require(address(this).balance >= amount, "Insufficient contract balance");

        isReleased = true;
        (bool sent, ) = beneficiary.call{value: amount}("");
        require(sent, "Failed to send Ether to beneficiary");

        emit Released(arbiter, amount);
    }

    function refund() external {
        require(msg.sender == arbiter, "Only arbiter can refund funds");
        require(!isReleased && !isRefunded, "Funds already released or refunded");
        require(address(this).balance >= amount, "Insufficient contract balance");

        isRefunded = true;
        (bool sent, ) = depositor.call{value: amount}("");
        require(sent, "Failed to send Ether to depositor");

        emit Refunded(arbiter, amount);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}