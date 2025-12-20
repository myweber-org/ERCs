pragma solidity ^0.8.0;

contract SimpleVoting {
    struct Candidate {
        string name;
        uint256 voteCount;
    }

    Candidate[] public candidates;
    mapping(address => bool) public hasVoted;
    address public owner;
    bool public votingClosed;

    event VoteCast(address indexed voter, uint256 candidateIndex);
    event VotingClosed();

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier votingOpen() {
        require(!votingClosed, "Voting is closed");
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

    function castVote(uint256 candidateIndex) external votingOpen {
        require(candidateIndex < candidates.length, "Invalid candidate index");
        require(!hasVoted[msg.sender], "You have already voted");

        candidates[candidateIndex].voteCount++;
        hasVoted[msg.sender] = true;

        emit VoteCast(msg.sender, candidateIndex);
    }

    function getCandidateCount() external view returns (uint256) {
        return candidates.length;
    }

    function getCandidate(uint256 index) external view returns (string memory name, uint256 voteCount) {
        require(index < candidates.length, "Invalid index");
        Candidate storage candidate = candidates[index];
        return (candidate.name, candidate.voteCount);
    }

    function getWinner() external view returns (string memory winnerName, uint256 winnerVotes) {
        require(votingClosed, "Voting is still open");

        uint256 winningVoteCount = 0;
        uint256 winningCandidateIndex = 0;
        bool isTie = false;

        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                winningCandidateIndex = i;
                isTie = false;
            } else if (candidates[i].voteCount == winningVoteCount && winningVoteCount > 0) {
                isTie = true;
            }
        }

        if (isTie) {
            return ("Tie", winningVoteCount);
        }

        return (candidates[winningCandidateIndex].name, winningVoteCount);
    }

    function closeVoting() external onlyOwner votingOpen {
        votingClosed = true;
        emit VotingClosed();
    }

    function getVotingStatus() external view returns (bool) {
        return votingClosed;
    }
}