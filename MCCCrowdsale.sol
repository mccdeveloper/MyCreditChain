pragma solidity ^0.4.21;

import "./crowdsale/distribution/FinalizableCrowdsale.sol";
import "./lifecycle/Pausable.sol";
import "./fund/ICrowdsaleFund.sol";
import "./common/IEventReturn.sol";
import "./MCCToken.sol";

contract MCCCrowdsale is FinalizableCrowdsale, Pausable, IEventReturn {

    uint256 public constant TOKEN_SALES_MAX = 420000000000000000000000000;

    uint256 public constant MAINSALES_OPEN_TIME =  1530374400; // Sun July 1st 00:00:00 SGT 2018 (not confirmed yet)
    uint256 public constant MAINSALES_CLOSE_TIME = 1533052800; // Web August 1st 00:00:00 SGT 2018 (not confirmed yet)

    uint256 public constant MAXIMUM_SALE_RATE = 14000;
    uint256 public constant MAINSALES_RATE = 10000;

    uint256 public constant SOFT_CAP = 5000 ether;
    uint256 public constant HARD_CAP = 25000 ether;

    uint256 public constant MAINSALES_MIN_ETHER = 0.2 ether; // not confirmed yet

    address internal tokenOwner;

    MCCToken public token;
    ICrowdsaleFund public fund;

    int public salesCurrentTrials;       //0 - main

    struct PrivateSaleData {
        uint256 saleForMinEther;
        uint256 rate;
    }

    struct CrowdSaleInfo {
        uint256 minEtherCap; // 0.5 ether;
        uint256 openTime;
        uint256 closeTime;
        uint256 rate;
        string description;
    }

    CrowdSaleInfo[] inSalesInfoList;
    PrivateSaleData[] privateSaleDataList;

    uint256 refundCompleted;

    uint256 public soldTokensPrivateICO;
    uint256 public soldTokensMainICO;

    mapping(address => bool) public whiteList;
    mapping(address => uint256) public privateWhiteList;

    address public founderTokenWallet;
    address public advisorTokenWallet;
    address public bizDevelopTokenWallet;
    address public marketingTokenWallet;
    address public airdropTokenWallet;

    function MCCCrowdsale(
        address tokenAddress,
        address fundAddress,
        address _founderTokenWallet,
        address _advisorTokenWallet,
        address _bizDevelopTokenWallet,
        address _marketingTokenWallet,
        address _airdropTokenWallet,
        address _owner
    ) public
    Crowdsale(MAINSALES_RATE, fundAddress, ERC20(tokenAddress))
    TimedCrowdsale(MAINSALES_OPEN_TIME, MAINSALES_CLOSE_TIME)
    {
        require(tokenAddress != address(0));
        require(fundAddress != address(0));

        token = MCCToken(tokenAddress);
        fund = ICrowdsaleFund(fundAddress);

        founderTokenWallet = _founderTokenWallet;
        advisorTokenWallet = _advisorTokenWallet;
        bizDevelopTokenWallet = _bizDevelopTokenWallet;
        marketingTokenWallet = _marketingTokenWallet;
        airdropTokenWallet = _airdropTokenWallet;

        tokenOwner = _owner;

        salesCurrentTrials = -1;

        CrowdSaleInfo memory saleInfoMain;

        saleInfoMain.openTime = MAINSALES_OPEN_TIME;
        saleInfoMain.closeTime = MAINSALES_CLOSE_TIME;
        saleInfoMain.rate = MAINSALES_RATE;
        saleInfoMain.minEtherCap = MAINSALES_MIN_ETHER;
        saleInfoMain.description = "MCC Token Main Sales";

        inSalesInfoList.push(saleInfoMain);

        soldTokensPrivateICO = 0;
        soldTokensMainICO = 0;

        paused = true;
    }

   /**
   * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
   */
    modifier isWhitelisted(address _beneficiary) {
        require(whiteList[_beneficiary]);
        _;
    }

    /**
    * @dev Reverts if beneficiary is not whitelisted for private sale. Can be used when extending this contract.
    */
    modifier isPrivateWhitelisted(address _wallet) {
        require(privateWhiteList[_wallet] > 0);
        _;
    }

    /**
     * @dev Set crowdsales information. sale duration, sale tokens rate, softcap etc..
     */
    function setSaleInfo(uint _salesTrials, uint256 _openingTime, uint256 _closingTime, uint256 _rate, uint256 _minETHCap, string _desc) public onlyOwner
    {
        CrowdSaleInfo storage saleInfo = inSalesInfoList[_salesTrials];

        saleInfo.openTime = _openingTime;
        saleInfo.closeTime = _closingTime;
        saleInfo.rate = _rate;
        saleInfo.minEtherCap = _minETHCap;
        saleInfo.description = _desc;

        if (int(_salesTrials) == salesCurrentTrials) {
            openingTime = saleInfo.openTime;
            closingTime = saleInfo.closeTime;
            rate = saleInfo.rate;
        }
        emit fncReturnVAL(SUCCEED);
    }

    /**
     * @dev Get current sales information.
     */
    function getCurrentSalesInfo() public view returns (uint256, uint256, uint256, uint256, string) {
        require(salesCurrentTrials >= 0);

        CrowdSaleInfo memory saleInfo = inSalesInfoList[uint(salesCurrentTrials)];

        return (saleInfo.openTime, saleInfo.closeTime, saleInfo.rate, saleInfo.minEtherCap, saleInfo.description);
    }

    /**
     * @dev Activate crowdsale by assigining sale duration and rate
     */
    function startSales(uint _salesTrial) public onlyOwner {
        require(int(_salesTrial) >= salesCurrentTrials);

        CrowdSaleInfo memory saleInfo = inSalesInfoList[_salesTrial];

        require(0 < saleInfo.rate);
        require(now < saleInfo.closeTime);

        salesCurrentTrials = int(_salesTrial);

        openingTime = saleInfo.openTime;
        closingTime = saleInfo.closeTime;
        rate = saleInfo.rate;

        paused = false;

        emit fncReturnVAL(SUCCEED);
    }

    /**
     * @dev Add wallet to whitelist. For contract owner only.
     */
    function addToWhiteList(address _wallet) public onlyOwner {
        whiteList[_wallet] = true;
    }

    /**
    * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
    * @param _beneficiaries Addresses to be added to the whitelist
    */
    function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whiteList[_beneficiaries[i]] = true;
        }
        emit fncReturnVAL(SUCCEED);
    }

    /**
    * @dev Removes single address from whitelist.
    * @param _beneficiary Address to be removed to the whitelist
    */
    function removeFromWhitelist(address _beneficiary) external onlyOwner {
        whiteList[_beneficiary] = false;
    }

    /**
     *@dev Check if wallet is registered in whitelist.
     */
    function isRegisteredWhiteList(address _beneficiary) external view returns (bool) {
        return whiteList[_beneficiary];
    }

    /**
     * @dev buy tokens who is registered in private wallet list with arbitrary rate for private sale
     * @param _beneficiary address to handle private sale
     */
    function buyTokensPrivate(address _beneficiary) external payable isPrivateWhitelisted(msg.sender) {
        require(_beneficiary != address(0));
        uint256 privateSaleDataListIndex = privateWhiteList[msg.sender].sub(1);
        require(msg.value >= privateSaleDataList[privateSaleDataListIndex].saleForMinEther);

        uint256 weiAmount = msg.value;

        // update state
        weiRaised = weiRaised.add(weiAmount);

        uint256 _tokenAmount = weiAmount.mul(privateSaleDataList[privateSaleDataListIndex].rate);

        require(getTotalTokensSold().add(_tokenAmount) <= TOKEN_SALES_MAX);

        token.issue(_beneficiary, _tokenAmount);
        fund.processContribution.value(msg.value)(_beneficiary);
        soldTokensPrivateICO = SafeMath.add(soldTokensPrivateICO, _tokenAmount);

        whiteList[_beneficiary] = true;

        emit fncReturnVAL(SUCCEED);
    }

    /**
     * @dev Add wallet to private whitelist with minimum purchase amount and rate. For contract owner only.
     * minimum purchase amount(uint256 min) must be wei
     */
    function addToPrivateWhiteList(address _payer, uint256 _min, uint256 _rate) public onlyOwner {
        require(MAINSALES_RATE <= _rate && _rate <= MAXIMUM_SALE_RATE);

        if (privateWhiteList[_payer] > 0) {
            uint256 privateSaleDataListIndex = privateWhiteList[_payer].sub(1);
            privateSaleDataList[privateSaleDataListIndex].saleForMinEther = _min;
            privateSaleDataList[privateSaleDataListIndex].rate = _rate;
        } else {
            PrivateSaleData memory privateSaleData;

            privateSaleData.saleForMinEther = _min;
            privateSaleData.rate = _rate;

            privateSaleDataList.push(privateSaleData);

            privateWhiteList[_payer] = privateSaleDataList.length;
        }
    }

    function getPrivateSaleRate(address _payer) external view returns (uint256) {
        if (privateWhiteList[_payer] > 0) {
            return privateSaleDataList[privateWhiteList[_payer].sub(1)].rate;
        }
        return 0;
    }

    function getPrivateSaleMinumum(address _payer) external view returns (uint256) {
        if (privateWhiteList[_payer] > 0) {
            return privateSaleDataList[privateWhiteList[_payer].sub(1)].saleForMinEther;
        }
        return 0;
    }

  /**
   * @dev Checks whether the cap has been reached.
   * @return boolean value determines Whether the cap was reached
   */
    function capReached() public view returns (bool) {
        return weiRaised >= SOFT_CAP;
    }

    /**
     * @dev   Override _preValidatePurchase function.
     *        Validation of an incoming purchase. Use require statemens to revert state when conditions are not met. Use super to concatenate validations.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal whenNotPaused isWhitelisted(_beneficiary) {
        require(salesCurrentTrials >= 0);

        CrowdSaleInfo memory saleInfo = inSalesInfoList[uint(salesCurrentTrials)];
        require(_weiAmount >= saleInfo.minEtherCap);

        super._preValidatePurchase(_beneficiary, _weiAmount);

        require(weiRaised.add(_weiAmount) <= HARD_CAP);
    }

    /**
    * @dev Override _processPurchase function. Not deliver token to beneficiary yet.
    *               distribution including delivering token to beneficiary will be handled on finalization
    */
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        require(getTotalTokensSold().add(_tokenAmount) <= TOKEN_SALES_MAX);

        token.issue(msg.sender, _tokenAmount);

        soldTokensMainICO = SafeMath.add(soldTokensMainICO, _tokenAmount);
    }

    /**
    * @dev Overrides Crowdsale fund forwarding, sending funds to vault.
    */
    function _forwardFunds() internal {
        //noting called. fund already forward _processPurchase
        fund.processContribution.value(msg.value)(msg.sender);
    }

    /**
     * @dev return total number of tokens sold
    */
    function getTotalTokensSold() internal view returns (uint256) {
        return soldTokensPrivateICO.add(soldTokensMainICO);
    }

    /**
     * @dev return the number of remaining tokens
    */
    function getRemainTokensToSell() external view returns (uint256) {
        return TOKEN_SALES_MAX.sub(getTotalTokensSold());
    }

   /**
    * @dev Override finalization function. Add distributing token part
    */
    function finalization() internal {
        if (capReached()) {
            fund.onCrowdsaleEnd();
            token.setAllowTransfers(true);

            uint256 totalToken = token.totalSupply();

            token.transfer(founderTokenWallet, totalToken.mul(23).div(100));
            token.transfer(advisorTokenWallet, totalToken.mul(5).div(100));
            token.transfer(bizDevelopTokenWallet, totalToken.mul(5).div(100));
            token.transfer(marketingTokenWallet, totalToken.mul(9).div(100));
            token.transfer(airdropTokenWallet, totalToken.mul(23).div(100));

            // unsold tokens will be burned
            token.burn(token.balanceOf(this));
        } else {
            fund.enableCrowdsaleRefund();
        }
        token.finishIssuance();
    }


}
