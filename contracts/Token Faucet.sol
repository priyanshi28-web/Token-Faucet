// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenFaucet is ERC20, Ownable {
    // Constants
    uint256 public constant FAUCET_AMOUNT = 100 * 10**18; // 100 tokens
    uint256 public constant COOLDOWN_PERIOD = 24 hours;
    uint256 public constant MAX_SUPPLY = 1000000 * 10**18; // 1M tokens
    
    // State variables
    mapping(address => uint256) public lastRequestTime;
    mapping(address => uint256) public totalRequested;
    bool public faucetActive;
    
    // Events
    event TokensRequested(address indexed user, uint256 amount, uint256 timestamp);
    event FaucetToggled(bool active);
    event FaucetRefilled(uint256 amount);
    
    constructor() ERC20("FaucetToken", "FAUCET") Ownable(msg.sender) {
        faucetActive = true;
        // Mint initial supply to contract
        _mint(address(this), MAX_SUPPLY);
    }
    
    /**
     * @dev Core function 1: Request tokens from faucet
     * Users can request tokens once per cooldown period
     */
    function requestTokens() external {
        require(faucetActive, "Faucet is currently inactive");
        require(
            block.timestamp >= lastRequestTime[msg.sender] + COOLDOWN_PERIOD,
            "Cooldown period not met. Try again later"
        );
        require(
            balanceOf(address(this)) >= FAUCET_AMOUNT,
            "Insufficient tokens in faucet"
        );
        
        // Update user's last request time
        lastRequestTime[msg.sender] = block.timestamp;
        totalRequested[msg.sender] += FAUCET_AMOUNT;
        
        // Transfer tokens to user
        _transfer(address(this), msg.sender, FAUCET_AMOUNT);
        
        emit TokensRequested(msg.sender, FAUCET_AMOUNT, block.timestamp);
    }
    
    /**
     * @dev Core function 2: Check eligibility for token request
     * Returns time remaining until next request is possible
     */
    function checkEligibility(address user) external view returns (
        bool eligible,
        uint256 timeRemaining,
        uint256 tokensAvailable
    ) {
        uint256 nextRequestTime = lastRequestTime[user] + COOLDOWN_PERIOD;
        
        if (block.timestamp >= nextRequestTime) {
            eligible = true;
            timeRemaining = 0;
        } else {
            eligible = false;
            timeRemaining = nextRequestTime - block.timestamp;
        }
        
        tokensAvailable = balanceOf(address(this));
    }
    
    /**
     * @dev Core function 3: Admin function to manage faucet
     * Toggle faucet active/inactive and refill if needed
     */
    function manageFaucet(bool _active) external onlyOwner {
        faucetActive = _active;
        emit FaucetToggled(_active);
    }
    
    /**
     * @dev Refill faucet with additional tokens (only owner)
     */
    function refillFaucet(uint256 amount) external onlyOwner {
        require(
            totalSupply() + amount <= MAX_SUPPLY,
            "Would exceed maximum supply"
        );
        _mint(address(this), amount);
        emit FaucetRefilled(amount);
    }
    
    /**
     * @dev Get user statistics
     */
    function getUserStats(address user) external view returns (
        uint256 totalTokensRequested,
        uint256 lastRequest,
        uint256 nextEligibleTime
    ) {
        totalTokensRequested = totalRequested[user];
        lastRequest = lastRequestTime[user];
        nextEligibleTime = lastRequestTime[user] + COOLDOWN_PERIOD;
    }
    
    /**
     * @dev Get faucet statistics
     */
    function getFaucetStats() external view returns (
        uint256 remainingTokens,
        bool isActive,
        uint256 faucetAmount,
        uint256 cooldownHours
    ) {
        remainingTokens = balanceOf(address(this));
        isActive = faucetActive;
        faucetAmount = FAUCET_AMOUNT;
        cooldownHours = COOLDOWN_PERIOD / 3600;
    }
    
    /**
     * @dev Emergency withdraw function (only owner)
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = balanceOf(address(this));
        _transfer(address(this), owner(), balance);
    }
}
