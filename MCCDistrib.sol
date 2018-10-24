pragma solidity ^0.4.24;

import "./ownership/MultiOwnable.sol";
import "./token/ERC20/ERC20.sol";

contract MCCDistrib is MultiOwnable {

    /**
     * @dev ManagedToken constructor
     * @param _owners Owners list
     */
    function MCCDistrib(address[] _owners) public {
        _setOwners(_owners);
    }

    /**
     * @dev transferMulti 
     * @param _tokenAddr ERC20 Token Address
     */
    function transferMulti(address _tokenAddr, address[] targets, uint256[] values) public onlyOwner {
        ERC20 tokenAddr = ERC20(_tokenAddr);

        for( uint i = 0 ; i < targets.length ; i++ ) {
            tokenAddr.transfer(targets[i], values[i]);
        }
    }
}