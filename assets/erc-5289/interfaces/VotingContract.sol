
pragma solidity ^0.8.0;

contract VotingContract {
    struct Candidate {
        string name;
        uint256 voteCount;
    }

    Candidate[] public candidates;
    mapping(address => bool) public hasVoted;
    address public owner;

    event VoteCast(address indexed voter, uint256 candidateIndex);
    event CandidateAdded(string name, uint256 index);

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
            emit CandidateAdded(candidateNames[i], i);
        }
    }

    function vote(uint256 candidateIndex) external {
        require(candidateIndex < candidates.length, "Invalid candidate index");
        require(!hasVoted[msg.sender], "Already voted");

        hasVoted[msg.sender] = true;
        candidates[candidateIndex].voteCount++;

        emit VoteCast(msg.sender, candidateIndex);
    }

    function getCandidateCount() external view returns (uint256) {
        return candidates.length;
    }

    function getCandidateDetails(uint256 index) external view returns (string memory, uint256) {
        require(index < candidates.length, "Invalid index");
        return (candidates[index].name, candidates[index].voteCount);
    }

    function getWinner() external view returns (string memory winnerName, uint256 highestVotes) {
        require(candidates.length > 0, "No candidates");

        winnerName = candidates[0].name;
        highestVotes = candidates[0].voteCount;

        for (uint256 i = 1; i < candidates.length; i++) {
            if (candidates[i].voteCount > highestVotes) {
                winnerName = candidates[i].name;
                highestVotes = candidates[i].voteCount;
            }
        }
    }

    function addCandidate(string memory candidateName) external onlyOwner {
        candidates.push(Candidate({
            name: candidateName,
            voteCount: 0
        }));
        emit CandidateAdded(candidateName, candidates.length - 1);
    }
}