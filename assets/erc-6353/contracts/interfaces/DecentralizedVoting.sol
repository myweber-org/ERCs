pragma solidity ^0.8.0;

contract DecentralizedVoting {
    struct Voter {
        uint weight;
        bool voted;
        address delegate;
        uint vote;
    }
    
    struct Proposal {
        string name;
        uint voteCount;
    }
    
    address public chairperson;
    mapping(address => Voter) public voters;
    Proposal[] public proposals;
    
    modifier onlyChairperson() {
        require(msg.sender == chairperson, "Only chairperson can perform this action");
        _;
    }
    
    constructor(string[] memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
        
        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }
    
    function giveRightToVote(address voter) external onlyChairperson {
        require(!voters[voter].voted, "Voter already voted");
        require(voters[voter].weight == 0, "Voter already has voting rights");
        voters[voter].weight = 1;
    }
    
    function delegate(address to) external {
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
    
    function vote(uint proposal) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted");
        sender.voted = true;
        sender.vote = proposal;
        
        proposals[proposal].voteCount += sender.weight;
    }
    
    function winningProposal() public view returns (uint winningProposal_) {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }
    
    function winnerName() external view returns (string memory winnerName_) {
        winnerName_ = proposals[winningProposal()].name;
    }
    
    function getProposalCount() external view returns (uint) {
        return proposals.length;
    }
    
    function getProposalDetails(uint index) external view returns (string memory name, uint voteCount) {
        require(index < proposals.length, "Invalid proposal index");
        Proposal storage proposal = proposals[index];
        return (proposal.name, proposal.voteCount);
    }
}