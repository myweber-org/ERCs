pragma solidity ^0.8.0;

contract EscrowContract {
    address public depositor;
    address public beneficiary;
    address public arbiter;
    uint256 public amount;
    bool public released;
    bool public refunded;

    event Deposited(address indexed depositor, address indexed beneficiary, address indexed arbiter, uint256 amount);
    event Released(address indexed arbiter, uint256 amount);
    event Refunded(address indexed arbiter, uint256 amount);

    constructor(address _beneficiary, address _arbiter) payable {
        require(_beneficiary != address(0), "Beneficiary cannot be zero address");
        require(_arbiter != address(0), "Arbiter cannot be zero address");
        require(msg.value > 0, "Deposit amount must be greater than zero");

        depositor = msg.sender;
        beneficiary = _beneficiary;
        arbiter = _arbiter;
        amount = msg.value;

        emit Deposited(depositor, beneficiary, arbiter, amount);
    }

    function release() external {
        require(msg.sender == arbiter, "Only arbiter can release funds");
        require(!released && !refunded, "Funds already released or refunded");
        require(address(this).balance >= amount, "Insufficient contract balance");

        released = true;
        payable(beneficiary).transfer(amount);

        emit Released(arbiter, amount);
    }

    function refund() external {
        require(msg.sender == arbiter, "Only arbiter can refund funds");
        require(!released && !refunded, "Funds already released or refunded");
        require(address(this).balance >= amount, "Insufficient contract balance");

        refunded = true;
        payable(depositor).transfer(amount);

        emit Refunded(arbiter, amount);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}