pragma solidity ^0.8.0;

contract VotingSystem {
    struct Candidate {
        string name;
        uint256 voteCount;
    }

    mapping(uint256 => Candidate) public candidates;
    mapping(address => bool) public hasVoted;
    uint256 public candidateCount;

    event VoteCasted(address indexed voter, uint256 candidateId);

    constructor(string[] memory candidateNames) {
        require(candidateNames.length > 0, "At least one candidate is required");
        for (uint256 i = 0; i < candidateNames.length; i++) {
            candidates[i] = Candidate({
                name: candidateNames[i],
                voteCount: 0
            });
            candidateCount++;
        }
    }

    function castVote(uint256 candidateId) external {
        require(candidateId < candidateCount, "Invalid candidate ID");
        require(!hasVoted[msg.sender], "You have already voted");

        hasVoted[msg.sender] = true;
        candidates[candidateId].voteCount++;

        emit VoteCasted(msg.sender, candidateId);
    }

    function getCandidate(uint256 candidateId) external view returns (string memory name, uint256 voteCount) {
        require(candidateId < candidateCount, "Invalid candidate ID");
        Candidate memory candidate = candidates[candidateId];
        return (candidate.name, candidate.voteCount);
    }

    function getWinner() external view returns (string memory winnerName) {
        uint256 winningVoteCount = 0;
        uint256 winningCandidateId = 0;

        for (uint256 i = 0; i < candidateCount; i++) {
            if (candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                winningCandidateId = i;
            }
        }

        require(winningVoteCount > 0, "No votes have been cast yet");
        return candidates[winningCandidateId].name;
    }
}