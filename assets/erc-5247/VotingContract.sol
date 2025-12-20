pragma solidity ^0.8.0;

contract VotingContract {
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    mapping(uint => Candidate) public candidates;
    mapping(address => bool) public voters;
    uint public candidatesCount;

    event Voted(address indexed voter, uint candidateId);

    constructor(string[] memory candidateNames) {
        for (uint i = 0; i < candidateNames.length; i++) {
            addCandidate(candidateNames[i]);
        }
    }

    function addCandidate(string memory name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, name, 0);
    }

    function vote(uint candidateId) public {
        require(!voters[msg.sender], "Already voted.");
        require(candidateId > 0 && candidateId <= candidatesCount, "Invalid candidate.");

        voters[msg.sender] = true;
        candidates[candidateId].voteCount++;

        emit Voted(msg.sender, candidateId);
    }

    function getWinner() public view returns (string memory winnerName, uint winnerVotes) {
        uint winningVoteCount = 0;
        uint winningCandidateId = 0;

        for (uint i = 1; i <= candidatesCount; i++) {
            if (candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                winningCandidateId = i;
            }
        }

        require(winningCandidateId > 0, "No votes cast yet.");
        winnerName = candidates[winningCandidateId].name;
        winnerVotes = winningVoteCount;
    }
}