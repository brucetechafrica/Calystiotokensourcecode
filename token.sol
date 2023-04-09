// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // Importing the ReentrancyGuard module from OpenZeppelin

contract Token is ReentrancyGuard { using SafeMath for uint256; // Using SafeMath with uint256 data type
// Defining the main contract, which inherits from ReentrancyGuard

    mapping(address => uint) public balances; // Mapping to store token balances for each address
    mapping(address => mapping(address => uint)) public allowance; // Mapping to store token allowances (i.e. amounts allowed to be spent by someone else) for each address
    uint constant public totalSupply = 30000000 * 10 ** 18; // Total supply of tokens, stored as a constant (in wei)
    uint public maxTxAmount = 150000 * 10 ** 18; // Maximum amount of tokens that can be transferred in one transaction, stored as a variable (in wei)
    uint public maxWalletAmount = 200000 * 10 ** 18; // Maximum amount of tokens that can be held in one wallet, stored as a variable (in wei)
    string public name = "Caly"; // Token name
    string public symbol = "CALY"; // Token symbol 
    uint constant public decimals = 18; // Number of decimal places for token units
    address public owner; // Address of the contract owner
    bool public paused = false; // Flag to indicate if trading has been paused
    mapping(address => bool) public blacklist; // Mapping to store blacklisted addresses (i.e. addresses banned from trading)

// Declare a mutex to prevent reentry attacks
    bool private mutex = false;
    
    event Transfer(address indexed from, address indexed to, uint value); // Event emitted when tokens are transferred
    event Approval(address indexed owner, address indexed spender, uint value); // Event emitted when token approval is given
    event Burn(address indexed burner, uint256 value); // Event emitted when tokens are burned
    event Pause(); // Event emitted when trading is paused
    event Unpause(); // Event emitted when trading is unpaused
    event AddedToBlacklist(address indexed account); // Event emitted when an address is added to the blacklist
    event RemovedFromBlacklist(address indexed account); // Event emitted when an address is removed from the blacklist
    event MaxTokenPerTxUpdated(uint _maxTxAmount); // Event emitted when the maximum transaction amount is updated
    event MaxTokenPerWalletUpdated(uint _maxWalletAmount); // Event emitted when the maximum wallet amount is updated

    modifier onlyOwner() { // Modifier to restrict certain actions to the contract owner
        require(msg.sender == owner, "Only owner can perform this action"); // Throws an error if the caller is not the owner
        _; // Continues with the function code
    }

    modifier whenNotPaused() { // Modifier to ensure that certain functions can't be called when trading is paused
        require(!paused, "Trading is paused"); // Throws an error if trading is currently paused
        _; // Continues with the function code
    }
    
    constructor() { // Constructor function that runs when the contract is deployed
        owner = msg.sender; // Sets the contract owner to the deploying address
        balances[msg.sender] = totalSupply; // Assigns the entire token supply to the contract owner
    }

    function balanceOf(address owner) public view returns (uint) { // Function to retrieve the balance of a specific address
        return balances[owner]; // Returns the balance of the specified address
    }

    function transfer(address to, uint value) public nonReentrant whenNotPaused returns(bool) { // Function to transfer tokens between addresses
        require(to != address(0), "Cannot transfer to zero address");
        require(!blacklist[msg.sender], "Address is blacklisted"); // Throws an error if the sender is blacklisted
        require(!blacklist[to], "Recipient is blacklisted"); // Throws an error if the recipient is blacklisted
        require(value <= maxTxAmount, "Transfer amount exceeds the maxTxAmount."); // Throws an error if the transfer amount exceeds the maximum transaction limit
        require(balances[msg.sender] >= value, "Not enough balance."); // Throws an error if the sender does not have sufficient funds
        
        // Acquire a lock to prevent reentry attack
        require(!mutex, "Reentrant call");
        mutex = true;

        balances[msg.sender] -= value; // Deducts the transfer amount from the sender's balance
        balances[to] += value; // Adds the transfer amount to the recipient's balance
        emit Transfer(msg.sender, to, value); // Emits a transfer event

        // Release the lock
        mutex = false;

        return true; // Returns a success flag
    }

    function transferFrom(address from, address to, uint value) public nonReentrant whenNotPaused returns(bool) { // Function to allow for transferring tokens on behalf of another address
        require(to != address(0), "Cannot transfer to zero address");
        require(!blacklist[from], "Sender is blacklisted"); // Throws an error if the sender is blacklisted
        require(!blacklist[to], "Recipient is blacklisted"); // Throws an error if the recipient is black 
        require(value <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        require(balances[msg.sender] >= value, "Not enough balance.");
        require(allowance[from][msg.sender] >= value, "Allowance too low");
        
        // Acquire a lock to prevent reentry attack
        require(!mutex, "Reentrant call");
        mutex = true;
        
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);

        // Release the lock
        mutex = false;

        return true;

    }


// Function to approve the transfer of tokens to another address
   function approve(address spender, uint value) public nonReentrant whenNotPaused returns (bool) {
           allowance[msg.sender][spender] = value;
           emit Approval(msg.sender, spender, value);
           return true;
       }
   

// Function to burn tokens 
    function burn(uint256 value) public whenNotPaused returns (bool) {
        require(balances[msg.sender] >= value, "balance too low");
        balances[msg.sender] -= value;
        totalSupply -= value;
        emit Burn(msg.sender, value);
        emit Transfer(msg.sender, address(0), value);
        return true;
    }
// Function to pause trading
    function pause() public onlyOwner {
        paused = true;
        emit Pause();
    }
// Function to unpause trading
    function unpause() public onlyOwner {
        paused = false;
        emit Unpause();
    }
// Function to add an address to the blacklist
    function addAddressToBlackList(address account) public onlyOwner {
        require(!blacklist[account], "Account is already blacklisted");
        blacklist[account] = true;
        emit AddedToBlacklist(account);
    }
// Function to remove an address from the blacklist
    function removeAddressFromBlackList(address account) public onlyOwner {
        require(blacklist[account], "Account is not blacklisted");
        blacklist[account] = false;
        emit RemovedFromBlacklist(account);
    }
    
// Function to check if an address is blacklisted
    function isBlacklisted(address account) public view returns (bool) {
        return blacklist[account];
    }
// Function to update the maximum transaction amount
    function maxTokenPerTx(uint _maxTxAmount) external {
        require(msg.sender == address(this), "Only contract owner can update the maxTxAmount");
        maxTxAmount = _maxTxAmount;
        emit MaxTokenPerTxUpdated(maxTxAmount);
    }
// Function to update the maximum wallet amount 
    function maxTokenPerWallet(uint _maxWalletAmount) external {
        require(msg.sender == address(this), "Only contract owner can update the maxWalletAmount");
        maxWalletAmount = _maxWalletAmount;
        emit MaxTokenPerWalletUpdated(maxWalletAmount);
    }
}
