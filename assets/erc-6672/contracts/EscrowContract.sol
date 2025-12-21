// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract EscrowContract {
    address public buyer;
    address public seller;
    address public arbiter;
    uint256 public amount;
    bool public isFunded;
    bool public isCompleted;

    enum State { AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETED, REFUNDED }
    State public contractState;

    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsReleased(address indexed recipient, uint256 amount);
    event FundsRefunded(address indexed recipient, uint256 amount);
    event StateChanged(State newState);

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call this function");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can call this function");
        _;
    }

    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Only arbiter can call this function");
        _;
    }

    modifier onlyParties() {
        require(
            msg.sender == buyer || msg.sender == seller || msg.sender == arbiter,
            "Only buyer, seller, or arbiter can call this function"
        );
        _;
    }

    modifier inState(State _state) {
        require(contractState == _state, "Invalid contract state for this operation");
        _;
    }

    constructor(address _seller, address _arbiter) {
        require(_seller != address(0), "Seller address cannot be zero");
        require(_arbiter != address(0), "Arbiter address cannot be zero");
        require(_seller != _arbiter, "Seller and arbiter must be different addresses");

        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        contractState = State.AWAITING_PAYMENT;
    }

    function deposit() external payable onlyBuyer inState(State.AWAITING_PAYMENT) {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        require(!isFunded, "Funds already deposited");

        amount = msg.value;
        isFunded = true;
        contractState = State.AWAITING_DELIVERY;

        emit FundsDeposited(msg.sender, msg.value);
        emit StateChanged(contractState);
    }

    function confirmDelivery() external onlyBuyer inState(State.AWAITING_DELIVERY) {
        contractState = State.COMPLETED;
        isCompleted = true;

        emit StateChanged(contractState);
    }

    function releaseFunds() external onlyBuyer inState(State.COMPLETED) {
        require(isFunded, "No funds to release");
        require(!isCompleted, "Funds already released");

        isCompleted = true;
        uint256 paymentAmount = amount;
        amount = 0;

        (bool success, ) = payable(seller).call{value: paymentAmount}("");
        require(success, "Failed to transfer funds to seller");

        emit FundsReleased(seller, paymentAmount);
    }

    function requestRefund(string calldata reason) external onlyBuyer inState(State.AWAITING_DELIVERY) {
        contractState = State.REFUNDED;

        emit StateChanged(contractState);
    }

    function approveRefund() external onlyArbiter inState(State.REFUNDED) {
        require(isFunded, "No funds to refund");

        isFunded = false;
        uint256 refundAmount = amount;
        amount = 0;

        (bool success, ) = payable(buyer).call{value: refundAmount}("");
        require(success, "Failed to transfer refund to buyer");

        emit FundsRefunded(buyer, refundAmount);
    }

    function denyRefund() external onlyArbiter inState(State.REFUNDED) {
        contractState = State.AWAITING_DELIVERY;

        emit StateChanged(contractState);
    }

    function getContractBalance() external view onlyParties returns (uint256) {
        return address(this).balance;
    }

    function getContractDetails() external view onlyParties returns (
        address _buyer,
        address _seller,
        address _arbiter,
        uint256 _amount,
        bool _isFunded,
        bool _isCompleted,
        State _contractState
    ) {
        return (buyer, seller, arbiter, amount, isFunded, isCompleted, contractState);
    }
}