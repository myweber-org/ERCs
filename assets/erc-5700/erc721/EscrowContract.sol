// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract EscrowContract {
    address public buyer;
    address public seller;
    address public arbiter;
    uint256 public amount;
    bool public fundsDeposited;
    bool public completed;

    enum State { Created, Locked, Released, Refunded }
    State public state;

    event FundsDeposited(address indexed buyer, uint256 amount);
    event FundsReleased(address indexed seller, uint256 amount);
    event FundsRefunded(address indexed buyer, uint256 amount);
    event DisputeRaised(address indexed party, string reason);

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

    modifier inState(State _state) {
        require(state == _state, "Invalid state");
        _;
    }

    constructor(address _seller, address _arbiter) {
        require(_seller != address(0), "Invalid seller address");
        require(_arbiter != address(0), "Invalid arbiter address");
        require(_seller != _arbiter, "Seller and arbiter must be different");

        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        state = State.Created;
    }

    function deposit() external payable onlyBuyer inState(State.Created) {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        amount = msg.value;
        fundsDeposited = true;
        state = State.Locked;
        
        emit FundsDeposited(msg.sender, msg.value);
    }

    function confirmDelivery() external onlyBuyer inState(State.Locked) {
        state = State.Released;
        completed = true;
        
        payable(seller).transfer(amount);
        
        emit FundsReleased(seller, amount);
    }

    function raiseDispute(string memory reason) external inState(State.Locked) {
        require(
            msg.sender == buyer || msg.sender == seller,
            "Only buyer or seller can raise dispute"
        );
        
        emit DisputeRaised(msg.sender, reason);
    }

    function releaseFunds() external onlyArbiter inState(State.Locked) {
        state = State.Released;
        completed = true;
        
        payable(seller).transfer(amount);
        
        emit FundsReleased(seller, amount);
    }

    function refundBuyer() external onlyArbiter inState(State.Locked) {
        state = State.Refunded;
        
        payable(buyer).transfer(amount);
        
        emit FundsRefunded(buyer, amount);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getContractDetails() external view returns (
        address,
        address,
        address,
        uint256,
        State,
        bool
    ) {
        return (
            buyer,
            seller,
            arbiter,
            amount,
            state,
            completed
        );
    }
}