pragma solidity ^0.8.19;

contract VotingContract {
    struct Candidate {
        string name;
        uint256 voteCount;
    }

    address public owner;
    mapping(address => bool) public hasVoted;
    Candidate[] public candidates;
    bool public votingActive;

    event VoteCast(address indexed voter, uint256 candidateIndex);
    event VotingStarted();
    event VotingEnded();

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier votingIsActive() {
        require(votingActive, "Voting is not active");
        _;
    }

    constructor(string[] memory candidateNames) {
        owner = msg.sender;
        for (uint256 i = 0; i < candidateNames.length; i++) {
            candidates.push(Candidate({
                name: candidateNames[i],
                voteCount: 0
            }));
        }
    }

    function startVoting() external onlyOwner {
        require(!votingActive, "Voting is already active");
        votingActive = true;
        emit VotingStarted();
    }

    function endVoting() external onlyOwner {
        require(votingActive, "Voting is not active");
        votingActive = false;
        emit VotingEnded();
    }

    function castVote(uint256 candidateIndex) external votingIsActive {
        require(candidateIndex < candidates.length, "Invalid candidate index");
        require(!hasVoted[msg.sender], "You have already voted");

        hasVoted[msg.sender] = true;
        candidates[candidateIndex].voteCount++;

        emit VoteCast(msg.sender, candidateIndex);
    }

    function getCandidateCount() external view returns (uint256) {
        return candidates.length;
    }

    function getCandidateDetails(uint256 index) external view returns (string memory, uint256) {
        require(index < candidates.length, "Invalid index");
        Candidate memory candidate = candidates[index];
        return (candidate.name, candidate.voteCount);
    }

    function getWinner() external view returns (string memory winnerName, uint256 winnerVotes) {
        require(!votingActive, "Voting is still active");
        require(candidates.length > 0, "No candidates available");

        winnerVotes = 0;
        uint256 winnerIndex = 0;

        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > winnerVotes) {
                winnerVotes = candidates[i].voteCount;
                winnerIndex = i;
            }
        }

        winnerName = candidates[winnerIndex].name;
    }

    function getTotalVotes() external view returns (uint256 totalVotes) {
        totalVotes = 0;
        for (uint256 i = 0; i < candidates.length; i++) {
            totalVotes += candidates[i].voteCount;
        }
    }
}