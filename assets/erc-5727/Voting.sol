pragma solidity ^0.8.19;

contract SimpleVoting {
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

    modifier hasNotVoted() {
        require(!hasVoted[msg.sender], "You have already voted");
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

    function vote(uint256 candidateIndex) public hasNotVoted {
        require(candidateIndex < candidates.length, "Invalid candidate index");
        
        candidates[candidateIndex].voteCount++;
        hasVoted[msg.sender] = true;
        
        emit VoteCast(msg.sender, candidateIndex);
    }

    function getCandidateCount() public view returns (uint256) {
        return candidates.length;
    }

    function getCandidate(uint256 index) public view returns (string memory, uint256) {
        require(index < candidates.length, "Invalid candidate index");
        Candidate memory candidate = candidates[index];
        return (candidate.name, candidate.voteCount);
    }

    function getWinner() public view returns (string memory) {
        require(candidates.length > 0, "No candidates available");
        
        uint256 winningVoteCount = 0;
        uint256 winningCandidateIndex = 0;
        bool isTie = false;
        
        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                winningCandidateIndex = i;
                isTie = false;
            } else if (candidates[i].voteCount == winningVoteCount && i != winningCandidateIndex) {
                isTie = true;
            }
        }
        
        if (isTie) {
            return "Tie";
        }
        
        return candidates[winningCandidateIndex].name;
    }

    function getTotalVotes() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < candidates.length; i++) {
            total += candidates[i].voteCount;
        }
        return total;
    }
}