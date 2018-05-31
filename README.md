# MyCreditChain(MCC) ICO

MyCreditChain(MCC) is a blockchain platform of personal credit information. This project aims to bring the ownership of credit information back to individuals. MCC revolutionizes the all process of how personal credit information is gathered and used. Moreover, MCC can further revolutionize our interaction with one another in one global network. 

# Smart Contract

- ## MCCFund

    - MCCFund contract manages funds and provides refund functionality. For refunding, MCCFund maintains investor wallet list and funds
    - MCCFund contract applies "MultiOwnable". "MultiOwnable" system prevents that fund is abused by a specified person

- ## MCCToken
    - MCCToken is based on ERC20 standard.
    - To prevent overflow with arithmetic operations, MCCToken uses SafeMath library
    - MCCToken has functionalities for token distribution and blocking token transfer handled by Crowdsale contract
    - Blocking token transfer that locks MCC token of specific token owener is added to prevent unfortunate accident like hacking
    - MCCToken contract also applies "MultiOwnable" to prevent that fund is abused by a specified person
    - MCCToken defines the token standard will be used for MCC service

    - Public Variables:

        1. **name**     - token name   (ERC20 option)
        2. **symbol**   - token symbol (ERC20 option)
        3. **decimals** - number of digits the cryptocurrency has after the decimal point (ERC20 option)

    - Functions:

        1. **issue(address _to, uint256 _value) external  onlyOwner canIssue** - CCToken can not issue but it need to distribute tokens to contributors while crowding sales. So. we changed this Issue tokens to specified wallet
        2. **destroy(address _from, uint256 _value) external** - Destroy tokens on specified address (Called by owner or token holder). Fund contract address must be in the list of owners to recall token during refund
        3. **increaseApproval(address _spender, uint _addedValue) public returns (bool)** - Increase the amount of tokens that an owner allowed to a spender. approve should be called when allowed[_spender] == 0. To increment allowed value is better to use this function to avoid 2 calls (and wait until the first transaction is mined)
        4. **decreaseApproval(address _spender, uint _subtractedValue) public returns (bool)** - Decrease the amount of tokens that an owner allowed to a spender. approve should be called when allowed[_spender] == 0. To decrement allowed value is better to use this function to avoid 2 calls (and wait until the first transaction is mined)

- ## MCCCrowdsale
    - MCCCrowdsale manages crowdsale functionality like buying tokens, setting sale duration, starting sale, finalizing sale and so on
    - MCCCrowdsale only allow the investors who is registered in whitelist to join the sales in sale duration
    - Finalize functionality has two side. MCC token distribution will start in the case the sales reaches soft cap or else refund will start

    - Public Constants:

        1.  **TOKEN_SALES_MAX**        - token total supply amount
        2.  **MAINSALES_OPEN_TIME**    - Sun July 1st 00:00:00 SGT 2018 (not confirmed yet)
        3.  **MAINSALES_CLOSE_TIME**   - Web August 1st 00:00:00 SGT 2018 (not confirmed yet)
        4.  **MAXIMUM_SALE_RATE**      - the limitation oftoken distribution rate, MCC 14000 per 1 ETH
        5.  **MAINSALES_RATE**         - main sales distribution rate, MCC 10000 per 1 ETH
        6.  **SOFT_CAP**               - ico soft cap. 5000 ETH
        7. **HARD_CAP**                - ico hard cap, 25000 ETH;
        8. **MAINSALES_MIN_ETHER**     - mainsales minimum amount to purchase, 0.2 ETH

    - Functions:

        1. **setSaleInfo(uint _salesTrials, uint256 _openingTime, uint256 _closingTime, uint256 _rate, uint256 _minETHCap, string _desc) public onlyOwner** - Set crowdsales information. sale duration, sale tokens rate, softcap etc..
        2. **startSales(uint _salesTrial) public onlyOwner** - Activate crowdsale by assigining sale duration and rate
        3. **addToWhiteList(address _wallet) public onlyOwner** - Add wallet to whitelist. For contract owner only.
        4. **buyTokensPrivate(address _beneficiary) external payable isPrivateWhitelisted(msg.sender)** - buy tokens who is registered in private wallet list
        5. **buyTokensEvent(address _beneficiary) external payable isPrivateWhitelisted(msg.sender)** - buy tokens who is registered in private wallet list with arbitrary rate for event sale
        6. **buyTokens(address _beneficiary) public payable** - low level token purchase
        7. **finalization() internal** - make token transfer available and distribute MCC token

# Future Plans
![Alt text](https://www.mycreditchain.org/images/mcc-eco.png "MCC ECO SYSTEM")

The services provided by MyCreditChain can be summarized as follows.

- The B2P credit information transaction is expected to be the most active within the MCC network. MyCreditChain provides a platform for individuals and companies to make direct transaction of information.

- In the MCC network, individuals can start a P2P financing business. Its platform can be used to make and exchange contracts for private transactions between individuals. With mutual consents, each party can look through other party’s credit information to identify reliability.

- Individuals can submit various official documents online when they apply for services from financial institutions.

- In the MCC network, non-financial data(Alternative Data) can be used for the credit evaluations, thus giving open chances for those who lack proper financial information.
