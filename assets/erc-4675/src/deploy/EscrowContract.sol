pragma solidity ^0.8.19;

contract EscrowContract {
    address public buyer;
    address public seller;
    address public arbiter;
    uint256 public amount;
    uint256 public createdAt;
    uint256 public releaseTime;
    bool public buyerConfirmed;
    bool public sellerConfirmed;
    bool public disputed;
    bool public resolved;
    address public resolutionWinner;

    enum State { Created, Locked, Released, Disputed, Resolved }
    State public state;

    event FundsDeposited(address indexed depositor, uint256 amount);
    event BuyerConfirmed();
    event SellerConfirmed();
    event FundsReleased(address indexed recipient);
    event DisputeRaised(address indexed raiser);
    event DisputeResolved(address indexed winner);

    modifier onlyParties() {
        require(msg.sender == buyer || msg.sender == seller, "Not a party");
        _;
    }

    modifier onlyArbiter() {
        require(msg.sender == arbiter, "Not arbiter");
        _;
    }

    modifier inState(State _state) {
        require(state == _state, "Invalid state");
        _;
    }

    constructor(address _seller, address _arbiter, uint256 _releaseDelay) payable {
        require(_seller != address(0), "Invalid seller");
        require(_arbiter != address(0), "Invalid arbiter");
        require(_releaseDelay > 0, "Invalid delay");
        require(msg.value > 0, "Must send ether");

        buyer = msg.sender;
        seller = _seller;
        arbiter = _arbiter;
        amount = msg.value;
        createdAt = block.timestamp;
        releaseTime = block.timestamp + _releaseDelay;
        state = State.Created;

        emit FundsDeposited(msg.sender, msg.value);
    }

    function confirmReceipt() external onlyParties inState(State.Created) {
        if (msg.sender == buyer) {
            buyerConfirmed = true;
            emit BuyerConfirmed();
        } else if (msg.sender == seller) {
            sellerConfirmed = true;
            emit SellerConfirmed();
        }

        if (buyerConfirmed && sellerConfirmed) {
            state = State.Locked;
        }
    }

    function releaseFunds() external onlyParties inState(State.Locked) {
        require(block.timestamp >= releaseTime, "Release time not reached");
        state = State.Released;
        payable(seller).transfer(amount);
        emit FundsReleased(seller);
    }

    function raiseDispute() external onlyParties inState(State.Locked) {
        require(!disputed, "Dispute already raised");
        disputed = true;
        state = State.Disputed;
        emit DisputeRaised(msg.sender);
    }

    function resolveDispute(address _winner) external onlyArbiter inState(State.Disputed) {
        require(!resolved, "Dispute already resolved");
        require(_winner == buyer || _winner == seller, "Invalid winner");

        resolved = true;
        resolutionWinner = _winner;
        state = State.Resolved;
        
        payable(_winner).transfer(amount);
        emit DisputeResolved(_winner);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getTimeUntilRelease() external view returns (int256) {
        if (block.timestamp >= releaseTime) {
            return 0;
        }
        return int256(releaseTime - block.timestamp);
    }
}