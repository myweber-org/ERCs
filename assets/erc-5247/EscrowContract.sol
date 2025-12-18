pragma solidity ^0.8.0;

contract EscrowContract {
    address public buyer;
    address public seller;
    address public arbiter;
    uint256 public amount;
    bool public isFunded;
    bool public isReleased;
    bool public isDisputed;
    bool public isResolved;

    enum Resolution { ReleaseToSeller, RefundToBuyer }

    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsReleased(address indexed recipient, uint256 amount);
    event DisputeInitiated(address indexed initiator);
    event DisputeResolved(Resolution decision, address indexed arbiter);

    modifier onlyParticipant() {
        require(msg.sender == buyer || msg.sender == seller, "Not a participant");
        _;
    }

    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Not the arbiter");
        _;
    }

    modifier inState(bool condition, string memory message) {
        require(condition, message);
        _;
    }

    constructor(address _seller, address _arbiter) payable {
        require(_seller != address(0) && _arbiter != address(0), "Invalid addresses");
        require(_seller != _arbiter, "Seller and arbiter must be different");
        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        amount = msg.value;
        isFunded = true;
        emit FundsDeposited(msg.sender, msg.value);
    }

    function releaseFunds() public onlyParticipant inState(isFunded, "Funds not deposited") inState(!isDisputed, "Dispute in progress") {
        require(!isReleased, "Funds already released");
        isReleased = true;
        payable(seller).transfer(amount);
        emit FundsReleased(seller, amount);
    }

    function initiateDispute() public onlyParticipant inState(isFunded, "Funds not deposited") inState(!isReleased, "Funds already released") {
        require(!isDisputed, "Dispute already initiated");
        isDisputed = true;
        emit DisputeInitiated(msg.sender);
    }

    function resolveDispute(Resolution _decision) public onlyArbiter inState(isDisputed, "No active dispute") inState(!isResolved, "Dispute already resolved") {
        isResolved = true;
        isDisputed = false;

        if (_decision == Resolution.ReleaseToSeller) {
            payable(seller).transfer(amount);
            emit FundsReleased(seller, amount);
        } else {
            payable(buyer).transfer(amount);
            emit FundsReleased(buyer, amount);
        }
        emit DisputeResolved(_decision, msg.sender);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}