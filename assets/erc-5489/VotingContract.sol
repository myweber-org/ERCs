pragma solidity ^0.8.0;

contract VotingContract {
    struct Proposal {
        string description;
        uint voteCount;
        bool exists;
    }

    mapping(uint => Proposal) public proposals;
    mapping(address => mapping(uint => bool)) public hasVoted;
    uint public proposalCount;
    address public owner;

    event ProposalCreated(uint indexed proposalId, string description);
    event VoteCast(address indexed voter, uint indexed proposalId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createProposal(string memory _description) public onlyOwner {
        proposalCount++;
        proposals[proposalCount] = Proposal({
            description: _description,
            voteCount: 0,
            exists: true
        });
        emit ProposalCreated(proposalCount, _description);
    }

    function vote(uint _proposalId) public {
        require(proposals[_proposalId].exists, "Proposal does not exist");
        require(!hasVoted[msg.sender][_proposalId], "Already voted for this proposal");

        proposals[_proposalId].voteCount++;
        hasVoted[msg.sender][_proposalId] = true;

        emit VoteCast(msg.sender, _proposalId);
    }

    function getProposal(uint _proposalId) public view returns (string memory description, uint voteCount) {
        require(proposals[_proposalId].exists, "Proposal does not exist");
        Proposal memory proposal = proposals[_proposalId];
        return (proposal.description, proposal.voteCount);
    }
}