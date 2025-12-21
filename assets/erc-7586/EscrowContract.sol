// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SimpleEscrow {
    address public buyer;
    address public seller;
    address public arbiter;

    uint256 public amount;
    bool public buyerConfirmed;
    bool public sellerConfirmed;
    bool public disputeRaised;
    bool public fundsReleased;

    event FundsDeposited(address indexed from, uint256 amount);
    event ConfirmationReceived(address indexed party);
    event DisputeRaised(address indexed raiser);
    event FundsReleased(address indexed to, uint256 amount);
    event DisputeResolved(address indexed winner, uint256 amount);

    modifier onlyParties() {
        require(msg.sender == buyer || msg.sender == seller || msg.sender == arbiter, "Not a party to the escrow");
        _;
    }

    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Only arbiter can call this");
        _;
    }

    constructor(address _seller, address _arbiter) payable {
        require(_seller != address(0), "Seller address cannot be zero");
        require(_arbiter != address(0), "Arbiter address cannot be zero");
        require(msg.sender != _seller, "Buyer and seller must be different");
        require(msg.sender != _arbiter, "Buyer and arbiter must be different");
        require(_seller != _arbiter, "Seller and arbiter must be different");

        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        amount = msg.value;

        emit FundsDeposited(msg.sender, msg.value);
    }

    function confirmReceipt() external {
        require(msg.sender == buyer || msg.sender == seller, "Only buyer or seller can confirm");
        require(!disputeRaised, "Dispute is raised, cannot confirm");
        require(!fundsReleased, "Funds already released");

        if (msg.sender == buyer) {
            buyerConfirmed = true;
        } else {
            sellerConfirmed = true;
        }

        emit ConfirmationReceived(msg.sender);

        if (buyerConfirmed && sellerConfirmed) {
            _releaseFunds(seller);
        }
    }

    function raiseDispute() external onlyParties {
        require(!disputeRaised, "Dispute already raised");
        require(!fundsReleased, "Funds already released");
        disputeRaised = true;
        emit DisputeRaised(msg.sender);
    }

    function resolveDispute(address payable _winner) external onlyArbiter {
        require(disputeRaised, "No dispute to resolve");
        require(!fundsReleased, "Funds already released");
        require(_winner == buyer || _winner == seller, "Winner must be buyer or seller");
        fundsReleased = true;
        payable(_winner).transfer(amount);
        emit DisputeResolved(_winner, amount);
        emit FundsReleased(_winner, amount);
    }

    function _releaseFunds(address payable _recipient) internal {
        require(!fundsReleased, "Funds already released");
        fundsReleased = true;
        payable(_recipient).transfer(amount);
        emit FundsReleased(_recipient, amount);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}