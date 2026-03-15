// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../shared/contracts/BaseRWA.sol";

/**
 * @title GoldToken
 * @dev ERC20 Token backed 1:1 by physical gold. Inherits from BaseRWA.
 */
contract GoldToken is BaseRWA {
    uint256 public constant GRAMS_PER_TOKEN = 1; // 1 GOLD = 1 gram of physical gold
    
    // Chainlink price feed for XAU/USD
    address public priceFeed;

    event PriceFeedUpdated(address indexed oldFeed, address indexed newFeed);

    constructor(address _priceFeed) BaseRWA("GoldVault Token", "GOLD", "Physical Gold") {
        require(_priceFeed != address(0), "Invalid price feed address");
        priceFeed = _priceFeed;
        requiresKYC = true; // Gold requires KYC
    }

    /**
     * @dev Mint new GOLD tokens. Only callable by MINTER_ROLE (e.g., the GoldVault).
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) nonReentrant {
        _mint(to, amount);
    }

    /**
     * @dev Update the Chainlink price feed address.
     */
    function setPriceFeed(address _priceFeed) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_priceFeed != address(0), "Invalid price feed address");
        address oldFeed = priceFeed;
        priceFeed = _priceFeed;
        emit PriceFeedUpdated(oldFeed, _priceFeed);
    }

    /**
     * @dev Returns the current price of 1 gram of gold in USD (scaled to 18 decimals).
     * In a full implementation, this calls the Chainlink price feed.
     */
    function getAssetPrice() public view override returns (uint256) {
        // Mock implementation for hackathon (XAU/USD per oz -> converted to gram)
        // 1 troy ounce = 31.1034768 grams
        // Assuming mock price of $2000 per oz -> $64.30 per gram
        return 6430 * 10**16; // $64.30 scaled
    }

    /**
     * @dev Returns the collateralization ratio in basis points (10000 = 100%).
     */
    function getCollateralizationRatio() public view override returns (uint256) {
        if (totalSupply() == 0) return 10000;
        // Total backing value is updated via ORACLE_ROLE based on physical vault audits.
        uint256 totalTokenValue = (totalSupply() * getAssetPrice()) / 10**18;
        if (totalTokenValue == 0) return 0;
        return (totalBackingValue * 10000) / totalTokenValue;
    }
}
