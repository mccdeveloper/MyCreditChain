pragma solidity ^0.4.21;

import "./fund/Fund.sol";

/**
 * @title MCCFund
 * @dev manage MCC CrowdSale Fund
 */
contract MCCFund is Fund {

    /**
     * @dev MCCFund constructor
     * params - see Fund constructor
     */
    function MCCFund(
        address _teamWallet,
        address[] _owners
        ) public
    Fund(_teamWallet, _owners)
    {
    }

   /**
     * @dev Callback is called after crowdsale finalization if soft cap is reached
     */
    function onCrowdsaleEnd() public onlyCrowdsale {
        super.onCrowdsaleEnd();

        uint256 amount = address(this).balance;
        teamWallet.transfer(amount);
        emit Withdraw(amount, now);
    }
}
