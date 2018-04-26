pragma solidity ^0.4.21;

import "./ICrowdsaleFund.sol";
import "../math/SafeMath.sol";
import "../ownership/MultiOwnable.sol";
import "../token/ManagedToken.sol";


contract Fund is ICrowdsaleFund, MultiOwnable {
    enum FundState {
        Crowdsale,
        CrowdsaleRefund,
        TeamWithdraw,
        Refund
    }

    FundState public state = FundState.Crowdsale;
    ManagedToken public token;

    address public teamWallet;
    uint256 public crowdsaleEndDate;

    address public crowdsaleAddress;
    mapping(address => uint256) public contributions;

    event RefundContributor(address tokenHolder, uint256 amountWei, uint256 timestamp);
    event RefundHolder(address tokenHolder, uint256 amountWei, uint256 tokenAmount, uint256 timestamp);
    event Withdraw(uint256 amountWei, uint256 timestamp);
    event BufferWithdraw(uint256 amountWei, uint256 timestamp);
    event RefundEnabled(address initiatorAddress);

    /**
     * @dev Fund constructor
     * @param _teamWallet Withdraw functions transfers ether to this address
     * @param _owners Contract owners
     */
    function Fund(
        address _teamWallet,
        address[] _owners
    ) public
    {
        teamWallet = _teamWallet;
        _setOwners(_owners);
    }

    /*
    * Crowdsale
    */
    modifier onlyCrowdsale() {
        require(msg.sender == crowdsaleAddress);
        _;
    }

    function setCrowdsaleAddress(address _crowdsaleAddress) public onlyOwner {
        require(crowdsaleAddress == address(0));
        crowdsaleAddress = _crowdsaleAddress;
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner {
        require(address(token) == address(0));
        token = ManagedToken(_tokenAddress);
    }

    /**
     * @dev Process crowdsale contribution
     */
    function processContribution(address contributor) external payable onlyCrowdsale {
        require(state == FundState.Crowdsale);
        uint256 totalContribution = SafeMath.add(contributions[contributor], msg.value);
        contributions[contributor] = totalContribution;
    }

    /**
     * @dev Callback is called after crowdsale finalization if soft cap is reached
     */
    function onCrowdsaleEnd() public onlyCrowdsale {
        state = FundState.TeamWithdraw;
        crowdsaleEndDate = now;
    }

    /**
     * @dev Callback is called after crowdsale finalization if soft cap is not reached
     */
    function enableCrowdsaleRefund() external onlyCrowdsale {
        require(state == FundState.Crowdsale);
        state = FundState.CrowdsaleRefund;
    }

    function getContributions() external view returns (uint256) {
        return contributions[msg.sender];
    }

    /**
    * @dev Function is called by contributor to refund payments if crowdsale failed to reach soft cap
    */
    function refundCrowdsaleContributor() external {
        require(state == FundState.CrowdsaleRefund);
        require(contributions[msg.sender] > 0);

        uint256 refundAmount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        token.destroy(msg.sender, token.balanceOf(msg.sender));
        msg.sender.transfer(refundAmount);
        emit RefundContributor(msg.sender, refundAmount, now);
    }

    /**
    * @dev Function is called by owner to refund payments if crowdsale failed to reach soft cap
    */
    function refundByOwner(address contributorAddress) external onlyOwner {
        require(state == FundState.CrowdsaleRefund);
        require(contributions[contributorAddress] > 0);

        uint256 refundAmount = contributions[contributorAddress];
        contributions[contributorAddress] = 0;
        token.destroy(contributorAddress, token.balanceOf(contributorAddress));
        contributorAddress.transfer(refundAmount);
        emit RefundContributor(contributorAddress, refundAmount, now);
    }
}
