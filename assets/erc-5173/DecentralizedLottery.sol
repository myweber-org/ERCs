pragma solidity ^0.8.0;

contract DecentralizedLottery {
    address public manager;
    address payable[] public participants;
    uint256 public ticketPrice;
    uint256 public maxParticipants;
    bool public lotteryOpen;
    address public winner;

    event LotteryStarted(uint256 ticketPrice, uint256 maxParticipants);
    event TicketPurchased(address participant);
    event WinnerSelected(address winner, uint256 prizeAmount);
    event LotteryReset();

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can call this");
        _;
    }

    constructor() {
        manager = msg.sender;
    }

    function startLottery(uint256 _ticketPrice, uint256 _maxParticipants) external onlyManager {
        require(!lotteryOpen, "Lottery already running");
        require(_ticketPrice > 0, "Ticket price must be positive");
        require(_maxParticipants > 0, "Max participants must be positive");

        ticketPrice = _ticketPrice;
        maxParticipants = _maxParticipants;
        lotteryOpen = true;
        delete participants;

        emit LotteryStarted(_ticketPrice, _maxParticipants);
    }

    function buyTicket() external payable {
        require(lotteryOpen, "Lottery not active");
        require(msg.value == ticketPrice, "Incorrect ticket price");
        require(participants.length < maxParticipants, "Lottery is full");
        require(!hasParticipated(msg.sender), "Already participated");

        participants.push(payable(msg.sender));
        emit TicketPurchased(msg.sender);
    }

    function selectWinner() external onlyManager {
        require(lotteryOpen, "Lottery not active");
        require(participants.length >= 2, "Need at least 2 participants");
        require(blockhash(block.number - 1) != bytes32(0), "Blockhash not available");

        uint256 randomIndex = uint256(keccak256(abi.encodePacked(
            blockhash(block.number - 1),
            block.timestamp,
            participants.length
        ))) % participants.length;

        winner = participants[randomIndex];
        uint256 prizeAmount = address(this).balance;
        lotteryOpen = false;

        payable(winner).transfer(prizeAmount);
        emit WinnerSelected(winner, prizeAmount);
    }

    function resetLottery() external onlyManager {
        require(!lotteryOpen, "Stop lottery first");
        delete participants;
        winner = address(0);
        ticketPrice = 0;
        maxParticipants = 0;

        emit LotteryReset();
    }

    function hasParticipated(address _address) public view returns (bool) {
        for (uint256 i = 0; i < participants.length; i++) {
            if (participants[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function getParticipants() external view returns (address payable[] memory) {
        return participants;
    }

    function getParticipantsCount() external view returns (uint256) {
        return participants.length;
    }

    function getPrizePool() external view returns (uint256) {
        return address(this).balance;
    }
}