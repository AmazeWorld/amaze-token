// contracts/MBTToken.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

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

    bool public limitTransactions;
    //uint256 public blackListCount;
    mapping (address => bool) public limitTransactionsWhiteList;
    mapping (address => uint) public lastTXBlock;
    mapping(address => bool) public isBlackListed;
    
    constructor() ERC20(_name, _symbol) ERC20Permit(_name)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _mint(_msgSender(), _totalSupply * (10 ** uint256(decimals())));
    }    

     event AddedBlackList(address _address);
     event RemovedBlackList(address _address);

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function enableTXLimit() public onlyOwner {
        limitTransactions = true;
    }
    
    function disableTXLimit() public onlyOwner {
        limitTransactions = false;
    }
    
    function includeTransactionsWhiteList(address account) public onlyOwner {
        limitTransactionsWhiteList[account] = true;
    }
    
    function removeTransactionsWhiteList(address account) public onlyOwner {
        limitTransactionsWhiteList[account] = false;
    }

    function addBlackList(address[] memory _address) public onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            require(_address[i] != address(0), 'The address is address 0');
            require(_address[i] != owner(), 'The address is the owner');
            if (!isBlackListed[_address[i]]) {
                isBlackListed[_address[i]] = true;
                emit AddedBlackList(_address[i]);
            }
        }
    }    

    function removeBlackList(address[] memory _address) public onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            if (isBlackListed[_address[i]]) {
                isBlackListed[_address[i]] = false;
                emit RemovedBlackList(_address[i]);
            }
        }
    }  

    function checkTransferLimit() internal returns (bool txAllowed) {
        if (limitTransactions == true && limitTransactionsWhiteList[_msgSender()] != true) {
            if (lastTXBlock[_msgSender()] == block.number) {
                return false;
            } else {
                lastTXBlock[_msgSender()] = block.number;
                return true;
            }
        } else {
            return true;
        }
    }

    function transferLockedTokens(address recipient, uint totalAmount, uint256 lockedAmount, uint128 startDate, uint64 timeInterval, uint256 tokenRelease) public onlyOwner{
        timeLocks[recipient] = TimeLock(totalAmount, lockedAmount, uint128(startDate), timeInterval, tokenRelease);
        transfer(recipient, totalAmount);
    }    

    function releaseTokens(address account) public {
        uint256 timeDiff = block.timestamp - uint256(timeLocks[account].startDate);
        require(timeDiff > uint256(timeLocks[account].timeInterval), "Unlock point not reached yet");
        uint256 steps = (timeDiff / uint256(timeLocks[account].timeInterval));
        uint256 unlockableAmount = (uint256(timeLocks[account].tokenRelease) * steps);
        if (unlockableAmount >=  timeLocks[account].totalAmount) {
            timeLocks[account].lockedAmount = 0;
        } else {
            timeLocks[account].lockedAmount = timeLocks[account].totalAmount - unlockableAmount;
        }
    }           

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override(ERC20, ERC20Snapshot)
    {
        require(!isBlackListed[from], 'Transfers not allowed');
        require(!isBlackListed[to], 'Transfers not allowed');
        require(checkTransferLimit(), "Transfers are limited to 1 per block");

        super._beforeTokenTransfer(from, to, amount);        
    }         
}