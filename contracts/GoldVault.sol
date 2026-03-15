// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./GoldToken.sol";

/**
 * @title GoldVault
 * @dev Vault for locking stablecoins/fiat value to mint GOLD tokens 1:1 with physical gold
 * Note: Real-world physical delivery triggers the mint. For demo, we mock USD stablecoin collateral.
 */
contract GoldVault is Ownable, ReentrancyGuard {
    GoldToken public goldToken;
    IERC20 public stablecoin; // USDC or similar stablecoin

    uint256 public totalGoldGrams; // Total grams stored in vault

    event GoldDeposited(address indexed user, uint256 usdAmount, uint256 goldGrams);
    event GoldRedeemed(address indexed user, uint256 goldGrams, uint256 usdAmount);
    event VaultAudited(uint256 newTotalGrams, uint256 timestamp);

    constructor(address _goldToken, address _stablecoin) Ownable() {
        goldToken = GoldToken(_goldToken);
        stablecoin = IERC20(_stablecoin);
    }

    /**
     * @dev Mint GOLD tokens by depositing stablecoins.
     */
    function depositStableForGold(uint256 usdAmount) external nonReentrant {
        require(usdAmount > 0, "Amount must be greater than zero");

        // Calculate how many grams this USD buys based on current oracle price
        uint256 goldPricePerGram = goldToken.getAssetPrice(); // 18 decimals
        require(goldPricePerGram > 0, "Invalid gold price");

        // Convert USD to GOLD (assume USD is 6 decimals, so scale up)
        uint256 usdAmountScaled = usdAmount * 10**12; 
        uint256 goldGramsToMint = (usdAmountScaled * 10**18) / goldPricePerGram;

        // Transfer stablecoin from user
        require(stablecoin.transferFrom(msg.sender, address(this), usdAmount), "Transfer failed");

        // Mint GOLD to user
        goldToken.mint(msg.sender, goldGramsToMint);
        totalGoldGrams += goldGramsToMint; // Simulate physical backing update

        emit GoldDeposited(msg.sender, usdAmount, goldGramsToMint);
    }

    /**
     * @dev Redeem GOLD tokens for stablecoins.
     */
    function redeemGoldForStable(uint256 goldAmount) external nonReentrant {
        require(goldAmount > 0, "Amount must be greater than zero");
        require(totalGoldGrams >= goldAmount, "Insufficient vault reserves");

        uint256 goldPricePerGram = goldToken.getAssetPrice(); // 18 decimals
        require(goldPricePerGram > 0, "Invalid gold price");

        // Calculate USD value of redeemed gold
        uint256 usdAmountScaled = (goldAmount * goldPricePerGram) / 10**18;
        uint256 usdAmount = usdAmountScaled / 10**12; // Back to 6 decimals

        // Burn GOLD from user
        goldToken.burnFrom(msg.sender, goldAmount);
        totalGoldGrams -= goldAmount; // Remove physical backing

        // Transfer stablecoin to user
        require(stablecoin.transfer(msg.sender, usdAmount), "Transfer failed");

        emit GoldRedeemed(msg.sender, goldAmount, usdAmount);
    }

    /**
     * @dev Oracle/Admin updates the exact physical gold amount after audits.
     */
    function updateAuditReserves(uint256 newTotalGrams) external onlyOwner {
        totalGoldGrams = newTotalGrams;
        // Optionally sync this up to GoldToken's totalBackingValue for public view
        // Using mock conversion to USD for BaseRWA compatibility
        uint256 newBackingValueUSD = (newTotalGrams * goldToken.getAssetPrice()) / 10**18;
        goldToken.updateBackingValue(newBackingValueUSD);
        emit VaultAudited(newTotalGrams, block.timestamp);
    }
}
