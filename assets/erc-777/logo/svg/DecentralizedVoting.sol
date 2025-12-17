// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedVoting {
    struct Proposal {
        string description;
        uint voteCount;
    }
    
    struct Voter {
        bool voted;
        uint vote;
        uint weight;
        address delegate;
    }
    
    address public chairperson;
    mapping(address => Voter) public voters;
    Proposal[] public proposals;
    bool public votingClosed;
    
    modifier onlyChairperson() {
        require(msg.sender == chairperson, "Only chairperson can perform this action");
        _;
    }
    
    modifier votingOpen() {
        require(!votingClosed, "Voting is closed");
        _;
    }
    
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
    
    function giveRightToVote(address voter) public onlyChairperson votingOpen {
        require(!voters[voter].voted, "The voter already voted");
        require(voters[voter].weight == 0, "Voter already has voting rights");
        voters[voter].weight = 1;
    }
    
    function delegate(address to) public votingOpen {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted");
        require(to != msg.sender, "Self-delegation is disallowed");
        
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;
            require(to != msg.sender, "Found loop in delegation");
        }
        
        sender.voted = true;
        sender.delegate = to;
        
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            delegate_.weight += sender.weight;
        }
    }
    
    function vote(uint proposal) public votingOpen {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted");
        require(proposal < proposals.length, "Invalid proposal index");
        
        sender.voted = true;
        sender.vote = proposal;
        proposals[proposal].voteCount += sender.weight;
    }
    
    function winningProposal() public view returns (uint winningProposal_) {
        require(votingClosed, "Voting is still open");
        uint winningVoteCount = 0;
        
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }
    
    function winnerDescription() public view returns (string memory) {
        require(votingClosed, "Voting is still open");
        return proposals[winningProposal()].description;
    }
    
    function closeVoting() public onlyChairperson {
        require(!votingClosed, "Voting already closed");
        votingClosed = true;
    }
    
    function getProposalCount() public view returns (uint) {
        return proposals.length;
    }
    
    function getProposalDetails(uint index) public view returns (string memory description, uint voteCount) {
        require(index < proposals.length, "Invalid proposal index");
        Proposal storage proposal = proposals[index];
        return (proposal.description, proposal.voteCount);
    }
}