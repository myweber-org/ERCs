pragma solidity ^0.8.0;

contract SimpleVoting {
    struct Proposal {
        string name;
        uint voteCount;
    }

    Proposal[] public proposals;
    mapping(address => bool) public hasVoted;
    address public owner;

    event VoteCast(address indexed voter, uint proposalIndex);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier hasNotVoted() {
        require(!hasVoted[msg.sender], "You have already voted");
        _;
    }

    constructor(string[] memory proposalNames) {
        owner = msg.sender;
        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    function vote(uint proposalIndex) external hasNotVoted {
        require(proposalIndex < proposals.length, "Invalid proposal index");
        
        proposals[proposalIndex].voteCount++;
        hasVoted[msg.sender] = true;
        
        emit VoteCast(msg.sender, proposalIndex);
    }

    function winningProposal() public view returns (uint winningProposalIndex) {
        uint winningVoteCount = 0;
        
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposalIndex = i;
            }
        }
    }

    function winnerName() external view returns (string memory winnerName_) {
        uint winningIndex = winningProposal();
        winnerName_ = proposals[winningIndex].name;
    }

    function getProposalCount() external view returns (uint) {
        return proposals.length;
    }

    function getProposalDetails(uint index) external view returns (string memory name, uint voteCount) {
        require(index < proposals.length, "Invalid proposal index");
        Proposal storage proposal = proposals[index];
        return (proposal.name, proposal.voteCount);
    }

    function addProposal(string memory proposalName) external onlyOwner {
        proposals.push(Proposal({
            name: proposalName,
            voteCount: 0
        }));
    }
}