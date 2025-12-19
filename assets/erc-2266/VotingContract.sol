pragma solidity ^0.8.0;

contract VotingContract {
    struct Candidate {
        string name;
        uint256 voteCount;
    }

    mapping(address => bool) public hasVoted;
    Candidate[] public candidates;
    address public owner;

    event VoteCast(address indexed voter, uint256 candidateIndex);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
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

    function vote(uint256 candidateIndex) external {
        require(candidateIndex < candidates.length, "Invalid candidate index");
        require(!hasVoted[msg.sender], "You have already voted");

        hasVoted[msg.sender] = true;
        candidates[candidateIndex].voteCount++;

        emit VoteCast(msg.sender, candidateIndex);
    }

    function getCandidateCount() external view returns (uint256) {
        return candidates.length;
    }

    function getCandidateDetails(uint256 candidateIndex) external view returns (string memory, uint256) {
        require(candidateIndex < candidates.length, "Invalid candidate index");
        Candidate memory candidate = candidates[candidateIndex];
        return (candidate.name, candidate.voteCount);
    }

    function getWinner() external view returns (string memory winnerName) {
        require(candidates.length > 0, "No candidates available");

        uint256 winningVoteCount = 0;
        uint256 winningCandidateIndex = 0;

        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                winningCandidateIndex = i;
            }
        }

        return candidates[winningCandidateIndex].name;
    }

    function addCandidate(string memory candidateName) external onlyOwner {
        candidates.push(Candidate({
            name: candidateName,
            voteCount: 0
        }));
    }
}