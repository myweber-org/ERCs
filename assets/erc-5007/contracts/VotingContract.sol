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

    function addCandidate(string memory name) public onlyOwner {
        candidates.push(Candidate({
            name: name,
            voteCount: 0
        }));
        emit CandidateAdded(name, candidates.length - 1);
    }

    function vote(uint256 candidateIndex) public {
        require(candidateIndex < candidates.length, "Invalid candidate index");
        require(!hasVoted[msg.sender], "Already voted");

        hasVoted[msg.sender] = true;
        candidates[candidateIndex].voteCount++;

        emit VoteCast(msg.sender, candidateIndex);
    }

    function getCandidateCount() public view returns (uint256) {
        return candidates.length;
    }

    function getCandidate(uint256 index) public view returns (string memory, uint256) {
        require(index < candidates.length, "Invalid index");
        Candidate memory candidate = candidates[index];
        return (candidate.name, candidate.voteCount);
    }

    function getWinner() public view returns (string memory winnerName, uint256 winnerVotes) {
        require(candidates.length > 0, "No candidates");

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
}