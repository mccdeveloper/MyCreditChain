pragma solidity ^0.4.18;

import './ICrowdsaleFund.sol';
import '../math/SafeMath.sol';
import '../ownership/MultiOwnable.sol';
import '../token/ManagedToken.sol';


contract Fund is ICrowdsaleFund, MultiOwnable {
    enum FundState {
        Crowdsale,
        CrowdsaleRefund,
        TeamWithdraw,
        Refund
    }

    FundState public state = FundState.Crowdsale;
    ManagedToken public token;

    uint256 public constant INITIAL_TAP = 115740740740740; // (wei/sec) == 300 ether/month

    address public teamWallet;
    uint256 public crowdsaleEndDate;

    address public founderTokenWallet;
    address public researchTokenWallet;
    address public bizDevelopTokenWallet;
    address public markettingTokenWallet;
    address public airdropTokenWallet;

    uint256 public tap;
    uint256 public lastWithdrawTime = 0;
    uint256 public overheadBufferAmount;


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
     * @param _founderTokenWallet Founder wallet address
     * @param _researchTokenWallet Research wallet address
     * @param _bizDevelopTokenWallet Developer wallet address
     * @param _markettingTokenWallet marketting wallet address
     * @param _airdropTokenWallet airdrop wallet address
     * @param _owners Contract owners
     */
    function Fund(
        address _teamWallet,
        address _founderTokenWallet,
        address _researchTokenWallet,
        address _bizDevelopTokenWallet,
        address _markettingTokenWallet,
        address _airdropTokenWallet,
        address[] _owners
    ) public
    {
        teamWallet = _teamWallet;

        founderTokenWallet = _founderTokenWallet;
        researchTokenWallet = _researchTokenWallet;
        bizDevelopTokenWallet = _bizDevelopTokenWallet;
        markettingTokenWallet = _markettingTokenWallet;
        airdropTokenWallet = _airdropTokenWallet;

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
    function onCrowdsaleEnd() external onlyCrowdsale {
        state = FundState.TeamWithdraw;
        lastWithdrawTime = now;
        tap = INITIAL_TAP;
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
        RefundContributor(msg.sender, refundAmount, now);
    }

    /**
     * @dev Decrease tap amount
     * @param _tap New tap value
     */
    function decTap(uint256 _tap) external onlyOwner {
        require(state == FundState.TeamWithdraw);
        require(_tap < tap);
        tap = _tap;
    }

    function getCurrentTapAmount() public constant returns(uint256) {
        if(state != FundState.TeamWithdraw) {
            return 0;
        }
        return calcTapAmount();
    }

    function calcTapAmount() internal view returns(uint256) {
        uint256 amount = SafeMath.mul(SafeMath.sub(now, lastWithdrawTime), tap);
        if(this.balance < amount) {
            amount = this.balance;
        }
        return amount;
    }

    /**
     * @dev Withdraw tap amount
     */
    function withdraw() public onlyOwner {
        require(state == FundState.TeamWithdraw);
        uint256 amount = calcTapAmount();
        lastWithdrawTime = now;
        teamWallet.transfer(amount);
        Withdraw(amount, now);
    }

    /**
     * @dev Withdraw overhead buffer amount
     */
    function withdrawOverheadBuffer() public onlyOwner {
        require(state == FundState.TeamWithdraw);
        require(overheadBufferAmount > 0);

        uint256 amount = overheadBufferAmount;
        overheadBufferAmount = 0;

        teamWallet.transfer(amount);
        BufferWithdraw(amount, now);
    }

    // Refund
    /**
     * @dev Called to start refunding
     */
    function enableRefund() internal {
        require(state == FundState.TeamWithdraw);
        state = FundState.Refund;
        token.setAllowTransfers(false);
        token.destroy(founderTokenWallet, token.balanceOf(founderTokenWallet));
        token.destroy(researchTokenWallet, token.balanceOf(researchTokenWallet));
        token.destroy(bizDevelopTokenWallet, token.balanceOf(bizDevelopTokenWallet));
        token.destroy(markettingTokenWallet, token.balanceOf(markettingTokenWallet));
        token.destroy(airdropTokenWallet, token.balanceOf(airdropTokenWallet));
        RefundEnabled(msg.sender);
    }

    /**
    * @dev Function is called by contributor to refund
    * Buy user tokens for refundTokenPrice and destroy them
    */
    function refundTokenHolder() public {
        require(state == FundState.Refund);

        uint256 tokenBalance = token.balanceOf(msg.sender);
        require(tokenBalance > 0);
        uint256 refundAmount = SafeMath.div(SafeMath.mul(tokenBalance, this.balance), token.totalSupply());
        require(refundAmount > 0);

        token.destroy(msg.sender, tokenBalance);
        msg.sender.transfer(refundAmount);

        RefundHolder(msg.sender, refundAmount, tokenBalance, now);
    }
}
