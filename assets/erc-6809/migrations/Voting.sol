pragma solidity ^0.8.0;

contract SimpleVoting {
    struct Proposal {
        string description;
        uint voteCount;
    }

    Proposal[] public proposals;
    mapping(address => bool) public hasVoted;
    address public chairperson;

    constructor(string[] memory proposalDescriptions) {
        chairperson = msg.sender;
        for (uint i = 0; i < proposalDescriptions.length; i++) {
            proposals.push(Proposal({
                description: proposalDescriptions[i],
                voteCount: 0
            }));
        }
    }

    function vote(uint proposalIndex) external {
        require(!hasVoted[msg.sender], "Already voted");
        require(proposalIndex < proposals.length, "Invalid proposal index");
        
        hasVoted[msg.sender] = true;
        proposals[proposalIndex].voteCount += 1;
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

    function winnerDescription() external view returns (string memory) {
        uint winner = winningProposal();
        return proposals[winner].description;
    }
}