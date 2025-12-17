pragma solidity ^0.8.0;

contract Voting {
    struct Proposal {
        string name;
        uint voteCount;
    }

    struct Voter {
        bool voted;
        bytes32 commitment;
        uint vote;
    }

    address public owner;
    Proposal[] public proposals;
    mapping(address => Voter) public voters;
    bool public votingOpen;
    bool public revealOpen;

    event VoteCommitted(address indexed voter, bytes32 commitment);
    event VoteRevealed(address indexed voter, uint proposalIndex);
    event VotingClosed(uint winningProposalIndex);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier duringCommitPhase() {
        require(votingOpen && !revealOpen, "Not in commit phase");
        _;
    }

    modifier duringRevealPhase() {
        require(!votingOpen && revealOpen, "Not in reveal phase");
        _;
    }

    constructor(string[] memory proposalNames) {
        owner = msg.sender;
        votingOpen = true;
        revealOpen = false;

        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    function commitVote(bytes32 _commitment) external duringCommitPhase {
        require(voters[msg.sender].commitment == bytes32(0), "Already committed");
        voters[msg.sender].commitment = _commitment;
        emit VoteCommitted(msg.sender, _commitment);
    }

    function revealVote(uint _proposalIndex, bytes32 _secret) external duringRevealPhase {
        Voter storage voter = voters[msg.sender];
        require(!voter.voted, "Already revealed");
        require(voter.commitment != bytes32(0), "No commitment found");
        require(_proposalIndex < proposals.length, "Invalid proposal");

        bytes32 computedCommitment = keccak256(abi.encodePacked(_proposalIndex, _secret, msg.sender));
        require(computedCommitment == voter.commitment, "Invalid reveal");

        voter.voted = true;
        voter.vote = _proposalIndex;
        proposals[_proposalIndex].voteCount++;

        emit VoteRevealed(msg.sender, _proposalIndex);
    }

    function closeCommitPhase() external onlyOwner {
        require(votingOpen, "Commit phase already closed");
        votingOpen = false;
        revealOpen = true;
    }

    function closeRevealPhase() external onlyOwner {
        require(revealOpen, "Reveal phase already closed");
        revealOpen = false;

        uint winningProposal = 0;
        uint maxVotes = 0;

        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > maxVotes) {
                maxVotes = proposals[i].voteCount;
                winningProposal = i;
            }
        }

        emit VotingClosed(winningProposal);
    }

    function getProposalCount() external view returns (uint) {
        return proposals.length;
    }

    function getWinningProposal() external view returns (uint) {
        require(!votingOpen && !revealOpen, "Voting not finalized");
        
        uint winningProposal = 0;
        uint maxVotes = 0;

        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > maxVotes) {
                maxVotes = proposals[i].voteCount;
                winningProposal = i;
            }
        }

        return winningProposal;
    }
}