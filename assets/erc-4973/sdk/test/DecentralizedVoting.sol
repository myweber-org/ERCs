// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DecentralizedVoting {
    struct Proposal {
        string description;
        uint voteCount;
    }
    
    struct Voter {
        bool voted;
        uint vote;
        address delegate;
        uint weight;
    }
    
    address public chairperson;
    mapping(address => Voter) public voters;
    Proposal[] public proposals;
    
    event VoteCast(address indexed voter, uint proposalIndex);
    event VoteDelegated(address indexed from, address indexed to);
    
    constructor(string[] memory proposalDescriptions) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
        
        for (uint i = 0; i < proposalDescriptions.length; i++) {
            proposals.push(Proposal({
                description: proposalDescriptions[i],
                voteCount: 0
            }));
        }
    }
    
    function giveRightToVote(address voter) external {
        require(msg.sender == chairperson, "Only chairperson can give voting rights");
        require(!voters[voter].voted, "Voter already voted");
        require(voters[voter].weight == 0, "Voter already has voting rights");
        
        voters[voter].weight = 1;
    }
    
    function delegate(address to) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight > 0, "No voting rights");
        require(!sender.voted, "Already voted");
        require(to != msg.sender, "Self-delegation not allowed");
        
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;
            require(to != msg.sender, "Circular delegation detected");
        }
        
        Voter storage delegate_ = voters[to];
        
        if (delegate_.voted) {
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            delegate_.weight += sender.weight;
        }
        
        sender.voted = true;
        sender.delegate = to;
        
        emit VoteDelegated(msg.sender, to);
    }
    
    function vote(uint proposalIndex) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight > 0, "No voting rights");
        require(!sender.voted, "Already voted");
        require(proposalIndex < proposals.length, "Invalid proposal index");
        
        sender.voted = true;
        sender.vote = proposalIndex;
        proposals[proposalIndex].voteCount += sender.weight;
        
        emit VoteCast(msg.sender, proposalIndex);
    }
    
    function winningProposal() public view returns (uint winningProposal_) {
        uint winningVoteCount = 0;
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposal_ = i;
            }
        }
    }
    
    function winnerName() external view returns (string memory winnerName_) {
        winnerName_ = proposals[winningProposal()].description;
    }
    
    function getProposalCount() external view returns (uint) {
        return proposals.length;
    }
    
    function getProposalDetails(uint index) external view returns (string memory description, uint voteCount) {
        require(index < proposals.length, "Invalid index");
        Proposal storage proposal = proposals[index];
        return (proposal.description, proposal.voteCount);
    }
}