pragma solidity ^0.8.19;

contract SimpleVoting {
    struct Proposal {
        string description;
        uint voteCount;
    }

    Proposal[] public proposals;
    mapping(address => bool) public hasVoted;

    event ProposalCreated(uint indexed proposalId, string description);
    event VoteCast(address indexed voter, uint indexed proposalId);

    function createProposal(string memory _description) public {
        proposals.push(Proposal({
            description: _description,
            voteCount: 0
        }));
        emit ProposalCreated(proposals.length - 1, _description);
    }

    function vote(uint _proposalId) public {
        require(_proposalId < proposals.length, "Invalid proposal ID");
        require(!hasVoted[msg.sender], "Already voted");

        proposals[_proposalId].voteCount++;
        hasVoted[msg.sender] = true;

        emit VoteCast(msg.sender, _proposalId);
    }

    function getProposalCount() public view returns (uint) {
        return proposals.length;
    }

    function getProposal(uint _proposalId) public view returns (string memory, uint) {
        require(_proposalId < proposals.length, "Invalid proposal ID");
        Proposal memory p = proposals[_proposalId];
        return (p.description, p.voteCount);
    }
}