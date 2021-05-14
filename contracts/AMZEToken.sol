// contracts/MBTToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./access/Ownable.sol";
import "./security/Pausable.sol";
import "./access/AccessControl.sol";
import "./token/ERC20/ERC20.sol";
import "./token/ERC20/extensions/ERC20Burnable.sol";
import "./token/ERC20/extensions/ERC20Snapshot.sol";
import "./token/ERC20/extensions/draft-ERC20Permit.sol";

contract AMZEToken is ERC20, ERC20Burnable, ERC20Snapshot, Ownable, Pausable, AccessControl, ERC20Permit   {
    uint256 private _totalSupply = 270000000; 
    string private _symbol = "AMZE";
    string private _name = "AMZE Token";

    constructor() ERC20(_name, _symbol) ERC20Permit(_name)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _mint(msg.sender, _totalSupply * (10 ** uint256(decimals())));
    }    

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }   
}