// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract EscrowContract {
    address public depositor;
    address public beneficiary;
    address public arbiter;
    
    bool public isFundsDeposited;
    bool public isFundsReleased;
    bool public isFundsRefunded;
    
    event FundsDeposited(address indexed from, uint256 amount);
    event FundsReleased(address indexed to, uint256 amount);
    event FundsRefunded(address indexed to, uint256 amount);
    
    constructor(address _beneficiary, address _arbiter) {
        require(_beneficiary != address(0), "Beneficiary cannot be zero address");
        require(_arbiter != address(0), "Arbiter cannot be zero address");
        require(_beneficiary != _arbiter, "Beneficiary and arbiter must be different");
        
        depositor = msg.sender;
        beneficiary = _beneficiary;
        arbiter = _arbiter;
    }
    
    function depositFunds() external payable {
        require(msg.sender == depositor, "Only depositor can deposit funds");
        require(msg.value > 0, "Deposit amount must be greater than zero");
        require(!isFundsDeposited, "Funds already deposited");
        require(!isFundsReleased, "Funds already released");
        require(!isFundsRefunded, "Funds already refunded");
        
        isFundsDeposited = true;
        emit FundsDeposited(msg.sender, msg.value);
    }
    
    function releaseFunds() external {
        require(msg.sender == arbiter, "Only arbiter can release funds");
        require(isFundsDeposited, "No funds deposited");
        require(!isFundsReleased, "Funds already released");
        require(!isFundsRefunded, "Funds already refunded");
        
        isFundsReleased = true;
        uint256 contractBalance = address(this).balance;
        
        (bool success, ) = beneficiary.call{value: contractBalance}("");
        require(success, "Funds transfer failed");
        
        emit FundsReleased(beneficiary, contractBalance);
    }
    
    function refundFunds() external {
        require(msg.sender == arbiter, "Only arbiter can refund funds");
        require(isFundsDeposited, "No funds deposited");
        require(!isFundsReleased, "Funds already released");
        require(!isFundsRefunded, "Funds already refunded");
        
        isFundsRefunded = true;
        uint256 contractBalance = address(this).balance;
        
        (bool success, ) = depositor.call{value: contractBalance}("");
        require(success, "Funds transfer failed");
        
        emit FundsRefunded(depositor, contractBalance);
    }
    
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    function getContractState() external view returns (
        bool deposited,
        bool released,
        bool refunded,
        uint256 balance
    ) {
        return (
            isFundsDeposited,
            isFundsReleased,
            isFundsRefunded,
            address(this).balance
        );
    }
}