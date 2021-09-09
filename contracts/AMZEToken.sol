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
    bytes32 public constant CONTRACT_MANAGER_ROLE = keccak256("CONTRACT_MANAGER_ROLE");
    bytes32 public constant RISK_MANAGER_ROLE = keccak256("RISK_MANAGER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant WHITELISTER_ROLE = keccak256("WHITELISTER_ROLE");

    uint256 private immutable _totalCap = 90000000 * (10 ** uint256(decimals()));
    uint256 private _initialSupply = 54000000 * (10 ** uint256(decimals()));

    string private _symbol = "AMZE";
    string private _name = "AMZE Token";

    bool public limitTransactions;
    mapping(address => uint) public lastTXBlock;    
    mapping(address => bool) public isTransactionsWhiteListed;

    bool public isWhitelistEnabled;
    uint256 public blackListCount;
    uint256 public whiteListCount;
    mapping(address => bool) public isBlackListed;
    mapping(address => bool) public isWhiteListed;
    mapping(address => bool) public whiteListManager;

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
     event AddedWhiteList(address _address);
     event RemovedWhiteList(address _address);

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

    function snapshot() public {
        require(hasRole(RISK_MANAGER_ROLE, _msgSender()), "Caller is not a risk manager");
        _snapshot();
    }

    function pause() public {
        require(hasRole(RISK_MANAGER_ROLE, _msgSender()), "Caller is not a risk manager");
        _pause();
    }

    function unpause() public {
        require(hasRole(RISK_MANAGER_ROLE, _msgSender()), "Caller is not a risk manager");
        _unpause();
    }

    function enableTransactionLimit() public {
        require(hasRole(CONTRACT_MANAGER_ROLE, _msgSender()), "Caller is not a contract manager");
        limitTransactions = true;
    }
    
    function disableTransactionLimit() public {
        require(hasRole(CONTRACT_MANAGER_ROLE, _msgSender()), "Caller is not a contract manager");
        limitTransactions = false;
    }

    function enableWhitelist() public {
        require(hasRole(CONTRACT_MANAGER_ROLE, _msgSender()), "Caller is not a contract manager");
        isWhitelistEnabled = true;
    }
    
    function disableWhitelist() public {
        require(hasRole(CONTRACT_MANAGER_ROLE, _msgSender()), "Caller is not a contract manager");
        isWhitelistEnabled = false;
    }    
    
    function addTransactionsWhiteList(address account) public {
        require(hasRole(CONTRACT_MANAGER_ROLE, _msgSender()), "Caller is not a contract manager");
        isTransactionsWhiteListed[account] = true;
    }
    
    function removeTransactionsWhiteList(address account) public {
        require(hasRole(CONTRACT_MANAGER_ROLE, _msgSender()), "Caller is not a contract manager");
        isTransactionsWhiteListed[account] = false;
    }

    function addBlackList(address[] memory _address) public {
        require(hasRole(RISK_MANAGER_ROLE, _msgSender()), "Caller is not a risk manager");
        for (uint256 i = 0; i < _address.length; i++) {
            require(_address[i] != address(0), 'The address is address 0');
            require(_address[i] != owner(), 'The address is the owner');
            if (!isBlackListed[_address[i]]) {
                isBlackListed[_address[i]] = true;
                blackListCount++;
                emit AddedBlackList(_address[i]);
            }
            if (isWhiteListed[_address[i]]) {
                isWhiteListed[_address[i]] = false;
                emit RemovedWhiteList(_address[i]);
            }
        }
    }   

    function removeBlackList(address[] memory _address) public {
        require(hasRole(RISK_MANAGER_ROLE, _msgSender()), "Caller is not a risk manager");
        for (uint256 i = 0; i < _address.length; i++) {
            if (isBlackListed[_address[i]]) {
                isBlackListed[_address[i]] = false;
                blackListCount--;
                emit RemovedBlackList(_address[i]);
            }
        }
    }

    function addWhiteList(address[] memory _address) public {
        require(hasRole(WHITELISTER_ROLE, _msgSender()), "Caller is not a whitelister");

        for (uint256 i = 0; i < _address.length; i++) {
            if (!isBlackListed[_address[i]]) {
                isWhiteListed[_address[i]] = true;
                whiteListCount++;
                emit AddedWhiteList(_address[i]);
            }
        }
    }

     function removeWhiteList(address[] memory _address) public {
         require(hasRole(WHITELISTER_ROLE, _msgSender()), "Caller is not a whitelister");

         for (uint256 i = 0; i < _address.length; i++) {
             if (isWhiteListed[_address[i]]) {
                 isWhiteListed[_address[i]] = false;
                 whiteListCount--;
                 emit RemovedWhiteList(_address[i]);
             }
         }
     }        

    function transferLockedTokens(address recipient, uint totalAmount, uint256 lockedAmount, uint128 startDate, uint64 timeInterval, uint256 tokenRelease) public {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Caller is not a manager");
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
        require(checkWhitelist(), "Require Wallet Whitelisting");        
        require(checkTransferLimit(), "Transfers are limited to 1 per block");
        
        uint256 senderAvailableBalance = getBalance(_msgSender()) - getTotalLockedBalance(_msgSender());
        require(_value <= senderAvailableBalance, "Transfer amount exceeds locked balance");

        return super.transfer(_to, _value);
    }     

    function transferFrom(address _from, address _to, uint256 _value) override public returns (bool success) {
        require(checkTransferLimit(), "Transfers are limited to 1 per block");
        
        uint256 senderAvailableBalance = getBalance(_from) - getTotalLockedBalance(_msgSender());
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

    function checkWhitelist() internal view returns (bool returnIsWhitelisted) {
        if (isWhitelistEnabled == true) {
            if (isWhiteListed[_msgSender()] == true) {            
                return true;
            } else {
                return false;
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
        require(checkWhitelist(), "Require Wallet Whitelisting");
        require(checkTransferLimit(), "Transfers are limited to 1 per block");        

        super._beforeTokenTransfer(from, to, amount);        
    }         
}