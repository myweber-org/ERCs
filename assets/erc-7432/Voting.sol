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

    constructor() {
        owner = msg.sender;
    }

    function addCandidate(string memory _name) public onlyOwner {
        candidates.push(Candidate({
            name: _name,
            voteCount: 0
        }));
        emit CandidateAdded(_name, candidates.length - 1);
    }

    function vote(uint256 _candidateIndex) public {
        require(_candidateIndex < candidates.length, "Invalid candidate index");
        require(!hasVoted[msg.sender], "You have already voted");

        candidates[_candidateIndex].voteCount++;
        hasVoted[msg.sender] = true;

        emit VoteCast(msg.sender, _candidateIndex);
    }

    function getCandidateCount() public view returns (uint256) {
        return candidates.length;
    }

    function getCandidateDetails(uint256 _index) public view returns (string memory, uint256) {
        require(_index < candidates.length, "Invalid index");
        return (candidates[_index].name, candidates[_index].voteCount);
    }

    function getWinner() public view returns (string memory winnerName, uint256 winnerVotes) {
        require(candidates.length > 0, "No candidates available");

        winnerVotes = 0;
        uint256 winnerIndex = 0;
        bool isTie = false;

        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > winnerVotes) {
                winnerVotes = candidates[i].voteCount;
                winnerIndex = i;
                isTie = false;
            } else if (candidates[i].voteCount == winnerVotes && i != winnerIndex) {
                isTie = true;
            }
        }

        if (isTie) {
            return ("Tie", winnerVotes);
        }

        winnerName = candidates[winnerIndex].name;
    }
}