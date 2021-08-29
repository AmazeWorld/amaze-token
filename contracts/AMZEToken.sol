// contracts/AMZEToken.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./access/Ownable.sol";
import "./access/AccessControl.sol";
import "./security/Pausable.sol";
import "./token/ERC20/ERC20.sol";
import "./token/ERC20/extensions/ERC20Snapshot.sol";

contract AMZEToken is Ownable, AccessControl, Pausable, ERC20, ERC20Snapshot {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    uint256 private immutable _totalCap = 90000000 * (10 ** uint256(decimals()));
    uint256 private _initialSupply = 54000000 * (10 ** uint256(decimals()));

    string private _symbol = "AMZE";
    string private _name = "AMZE Token";

    bool public limitTransactions;
    mapping (address => uint) public lastTXBlock;    
    mapping (address => bool) public isTransactionsWhiteListed;
    mapping (address => bool) public isBlackListed;
    
    struct TimeLock {
        uint256 totalAmount;
        uint256 lockedAmount;
        uint128 startDate; // Unix Epoch timestamp
        uint64 timeInterval; // Unix Epoch timestamp
        uint256 tokenRelease;
    }
    mapping (address => TimeLock[]) public timeLocks;  

    constructor() ERC20(_name, _symbol)
    {       
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _mint(_msgSender(), _initialSupply);
    }    

     event AddedBlackList(address _address);
     event RemovedBlackList(address _address);

    function mint(address account, uint256 amount) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "Caller is not a minter");        
        require((ERC20.totalSupply() + amount) <= _totalCap, "Total supply can not exceeded total cap");
        _mint(account, amount);
    }   

    function burn(uint256 amount) public {
        require(hasRole(BURNER_ROLE, _msgSender()), "Caller is not a burner");
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public {
        require(hasRole(BURNER_ROLE, _msgSender()), "Caller is not a burner");
        
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "Burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
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

    function enableTransactionLimit() public onlyOwner {
        limitTransactions = true;
    }
    
    function disableTransactionLimit() public onlyOwner {
        limitTransactions = false;
    }
    
    function addTransactionsWhiteList(address account) public onlyOwner {
        isTransactionsWhiteListed[account] = true;
    }
    
    function removeTransactionsWhiteList(address account) public onlyOwner {
        isTransactionsWhiteListed[account] = false;
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

    function sendLockedTokens(address recipient, uint totalAmount, uint256 lockedAmount, uint128 startDate, uint64 timeInterval, uint256 tokenRelease) public onlyOwner{
        timeLocks[recipient].push(TimeLock(totalAmount, lockedAmount, uint128(startDate), timeInterval, tokenRelease));
        transfer(recipient, totalAmount);
    }

    function getLockedBalanceLength(address account) public view returns (uint) {
        return timeLocks[account].length;
    }

    function getTotalLockedBalance(address account) public view returns (uint256) {
        uint256 lockedBalance = 0;
        for(uint i = 0 ; i<getLockedBalanceLength(account); i++) {
            lockedBalance += timeLocks[account][i].lockedAmount;
        }        
        return lockedBalance;
    }      

    function cap() public view virtual returns (uint256) {
        return _totalCap;
    }

    function getBalance(address account) internal view virtual returns (uint256) {
        return super.balanceOf(account);
    }        

    function transfer(address _to, uint256 _value) override public returns (bool success) {
        require(checkTransferLimit(), "Transfers are limited to 1 per block");

        uint256 senderAvailableBalance = getBalance(_msgSender()) - getTotalLockedBalance(_msgSender());//timeLocks[_msgSender()].lockedAmount;
        require(_value <= senderAvailableBalance, "Transfer amount exceeds locked balance");

        return super.transfer(_to, _value);
    }     

    function transferFrom(address _from, address _to, uint256 _value) override public returns (bool success) {
        require(checkTransferLimit(), "Transfers are limited to 1 per block");

        uint256 senderAvailableBalance = getBalance(_from) - getTotalLockedBalance(_msgSender());//timeLocks[_from].lockedAmount;
        require(_value <= senderAvailableBalance, "Transfer amount exceeds locked balance");

        return super.transferFrom(_from, _to, _value);
    }

    function checkTransferLimit() internal returns (bool txAllowed) {
        if (limitTransactions == true && isTransactionsWhiteListed[_msgSender()] != true) {
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

    function releaseLockedTokens(address account) public {
        for(uint i = 0 ; i<getLockedBalanceLength(account); i++) {        
            uint256 timeDiff = block.timestamp - uint256(timeLocks[account][i].startDate);
            uint256 steps = (timeDiff / uint256(timeLocks[account][i].timeInterval));
            uint256 unlockableAmount = (uint256(timeLocks[account][i].tokenRelease) * steps);
            if (unlockableAmount >= timeLocks[account][i].totalAmount) {
                timeLocks[account][i].lockedAmount = 0;
            } else {
                timeLocks[account][i].lockedAmount = timeLocks[account][i].totalAmount - unlockableAmount;
            }
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