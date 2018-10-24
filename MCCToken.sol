pragma solidity ^0.4.24;

import "./token/TransferLimitedToken.sol";

contract MCCToken is TransferLimitedToken {
    // =================================================================================================================
    //                                         Members
    // =================================================================================================================
    string public name = "MyCreditChain";

    string public symbol = "MCC";

    uint8 public decimals = 18;

    event Burn(address indexed burner, uint256 value);

    // =================================================================================================================
    //                                         Constructor
    // =================================================================================================================

    /**
     * @dev MCC Token
     *      To change to a token for DAICO, you must set up an ITokenEvenListener
     *      to change the voting weight setting through the listener for the
     *      transfer of the token.
     */
    function MCCToken(address _listener, address[] _owners, address _manager) public
        TransferLimitedToken(_listener, _owners, _manager)
    {
        totalSupply_ = uint256(1000000000).mul(uint256(10) ** decimals); // token total supply : 1000000000

        balances[_owners[0]] = totalSupply_;
    }

    /**
     * @dev Override ManagedToken.issue. MCCToken can not issue but it need to
     *      distribute tokens to contributors while crowding sales. So. we changed this
     *       Issue tokens to specified wallet
     * @param _to Wallet address
     * @param _value Amount of tokens
     */
    function issue(address _to, uint256 _value) external onlyOwner canIssue {
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        emit Issue(_to, _value);
        emit Transfer(msg.sender, _to, _value);
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    /**
    * @dev Burns a specific amount of tokens from the target address and decrements allowance
    * @param _from address The address which you want to send tokens from
    * @param _value uint256 The amount of token to be burned
    */
    function burnFrom(address _from, uint256 _value) public {
        require(_value <= allowed[_from][msg.sender]);
        // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
        // this function needs to emit an event with the updated approval.
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _burn(_from, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}
