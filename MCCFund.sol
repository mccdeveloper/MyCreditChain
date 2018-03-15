pragma solidity ^0.4.18;

import './fund/Fund.sol';

/**
 * @title MCCVotingFund
 * @dev Fund controlled by users and oracles voting
 */
contract MCCFund is Fund {

    

    /**
     * @dev MCCVotingFund constructor
     * params - see Fund constructor
     */
    function MCCFund(
        address _teamWallet,
        address _founderTokenWallet,
        address _researchTokenWallet,
        address _bizDevelopTokenWallet,
        address _markettingTokenWallet,
        address _airdropTokenWallet,
        address[] _owners
        ) public
    Fund(_teamWallet, _founderTokenWallet, _researchTokenWallet, _bizDevelopTokenWallet, _markettingTokenWallet, _airdropTokenWallet, _owners)
    {

    }

    function forceRefund() public onlyOwner {
        enableRefund();
    }

   /**
     * @dev Callback is called after crowdsale finalization if soft cap is reached
     */
    function onCrowdsaleEnd() external onlyCrowdsale {
        state = FundState.TeamWithdraw;
        crowdsaleEndDate = now;

        uint256 amount = this.balance;
        teamWallet.transfer(amount);
        Withdraw(amount, now);
    }
}
