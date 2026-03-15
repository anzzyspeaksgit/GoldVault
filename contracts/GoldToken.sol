// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../shared/contracts/BaseRWA.sol";
import "@chainlink/contracts/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title GoldToken
 * @dev ERC20 Token backed 1:1 by physical gold. Inherits from BaseRWA.
 */
contract GoldToken is BaseRWA {
    uint256 public constant GRAMS_PER_TOKEN = 1; // 1 GOLD = 1 gram of physical gold
    
    // Chainlink price feed for XAU/USD
    AggregatorV3Interface public priceFeed;

    event PriceFeedUpdated(address indexed oldFeed, address indexed newFeed);

    constructor(address _priceFeed) BaseRWA("GoldVault Token", "GOLD", "Physical Gold") {
        require(_priceFeed != address(0), "Invalid price feed address");
        priceFeed = AggregatorV3Interface(_priceFeed);
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
        address oldFeed = address(priceFeed);
        priceFeed = AggregatorV3Interface(_priceFeed);
        emit PriceFeedUpdated(oldFeed, _priceFeed);
    }

    /**
     * @dev Returns the current price of 1 gram of gold in USD (scaled to 18 decimals).
     * Chainlink XAU/USD returns the price of 1 Troy Ounce in USD with 8 decimals.
     * 1 Troy Ounce = 31.1034768 grams.
     */
    function getAssetPrice() public view override returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid oracle price");
        
        // Price is for 1 Troy Ounce with 8 decimals.
        // Convert to 18 decimals: price * 10**10
        uint256 pricePerOz18Decimals = uint256(price) * 10**10;
        
        // Convert per ounce to per gram:
        // 1 oz = 31.1034768 grams
        // Price per gram = Price per oz / 31.1034768
        uint256 pricePerGram = (pricePerOz18Decimals * 1e8) / 3110347680;
        
        return pricePerGram;
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
