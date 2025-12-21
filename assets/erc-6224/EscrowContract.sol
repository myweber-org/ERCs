// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Escrow {
    address public buyer;
    address public seller;
    address public arbiter;
    uint256 public amount;
    bool public fundsDeposited;
    bool public completed;

    event Deposited(address indexed buyer, uint256 amount);
    event Released(address indexed seller, uint256 amount);
    event Refunded(address indexed buyer, uint256 amount);

    constructor(address _seller, address _arbiter) {
        require(_seller != address(0), "Invalid seller address");
        require(_arbiter != address(0), "Invalid arbiter address");
        require(_seller != _arbiter, "Seller and arbiter must be different");
        
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
    }

    function deposit() external payable {
        require(msg.sender == buyer, "Only buyer can deposit");
        require(msg.value > 0, "Deposit amount must be greater than 0");
        require(!fundsDeposited, "Funds already deposited");
        
        amount = msg.value;
        fundsDeposited = true;
        emit Deposited(buyer, amount);
    }

    function release() external {
        require(fundsDeposited, "No funds deposited");
        require(!completed, "Transaction already completed");
        require(msg.sender == buyer || msg.sender == arbiter, "Only buyer or arbiter can release");
        
        completed = true;
        payable(seller).transfer(amount);
        emit Released(seller, amount);
    }

    function refund() external {
        require(fundsDeposited, "No funds deposited");
        require(!completed, "Transaction already completed");
        require(msg.sender == seller || msg.sender == arbiter, "Only seller or arbiter can refund");
        
        completed = true;
        payable(buyer).transfer(amount);
        emit Refunded(buyer, amount);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}