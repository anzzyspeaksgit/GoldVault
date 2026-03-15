// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
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
    uint256 public mintingFeeBps; // Fee in basis points (10000 = 100%)
    uint256 public redemptionFeeBps; 

    address public feeCollector;

    event GoldDeposited(address indexed user, uint256 usdAmount, uint256 goldGrams, uint256 fee);
    event GoldRedeemed(address indexed user, uint256 goldGrams, uint256 usdAmount, uint256 fee);
    event VaultAudited(uint256 newTotalGrams, uint256 timestamp);
    event FeesUpdated(uint256 newMintFee, uint256 newRedeemFee);
    event FeeCollectorUpdated(address indexed newCollector);

    constructor(address _goldToken, address _stablecoin) Ownable(msg.sender) {
        goldToken = GoldToken(_goldToken);
        stablecoin = IERC20(_stablecoin);
        feeCollector = msg.sender;
    }

    /**
     * @dev Set protocol fees. Max 5% (500 bps).
     */
    function setFees(uint256 _mintingFeeBps, uint256 _redemptionFeeBps) external onlyOwner {
        require(_mintingFeeBps <= 500 && _redemptionFeeBps <= 500, "Fee too high");
        mintingFeeBps = _mintingFeeBps;
        redemptionFeeBps = _redemptionFeeBps;
        emit FeesUpdated(_mintingFeeBps, _redemptionFeeBps);
    }

    /**
     * @dev Set the fee collector address.
     */
    function setFeeCollector(address _feeCollector) external onlyOwner {
        require(_feeCollector != address(0), "Invalid address");
        feeCollector = _feeCollector;
        emit FeeCollectorUpdated(_feeCollector);
    }

    /**
     * @dev Mint GOLD tokens by depositing stablecoins.
     */
    function depositStableForGold(uint256 usdAmount) external nonReentrant {
        require(usdAmount > 0, "Amount must be greater than zero");

        uint256 fee = (usdAmount * mintingFeeBps) / 10000;
        uint256 usdAmountAfterFee = usdAmount - fee;

        uint256 goldPricePerGram = goldToken.getAssetPrice(); // 18 decimals
        require(goldPricePerGram > 0, "Invalid gold price");

        // Convert USD to GOLD (assume USD is 6 decimals, so scale up)
        uint256 usdAmountScaled = usdAmountAfterFee * 10**12; 
        uint256 goldGramsToMint = (usdAmountScaled * 10**18) / goldPricePerGram;

        // Transfer fee to collector and remaining stablecoin to vault
        if (fee > 0) {
            require(stablecoin.transferFrom(msg.sender, feeCollector, fee), "Fee transfer failed");
        }
        require(stablecoin.transferFrom(msg.sender, address(this), usdAmountAfterFee), "Transfer failed");

        // Mint GOLD to user
        goldToken.mint(msg.sender, goldGramsToMint);
        totalGoldGrams += goldGramsToMint; // Simulate physical backing update

        emit GoldDeposited(msg.sender, usdAmountAfterFee, goldGramsToMint, fee);
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

        uint256 fee = (usdAmount * redemptionFeeBps) / 10000;
        uint256 usdAmountAfterFee = usdAmount - fee;

        // Burn GOLD from user
        goldToken.burnFrom(msg.sender, goldAmount);
        totalGoldGrams -= goldAmount; // Remove physical backing

        // Transfer fee to collector and remaining stablecoin to user
        if (fee > 0) {
            require(stablecoin.transfer(feeCollector, fee), "Fee transfer failed");
        }
        require(stablecoin.transfer(msg.sender, usdAmountAfterFee), "Transfer failed");

        emit GoldRedeemed(msg.sender, goldAmount, usdAmountAfterFee, fee);
    }

    /**
     * @dev Oracle/Admin updates the exact physical gold amount after audits.
     */
    function updateAuditReserves(uint256 newTotalGrams) external onlyOwner {
        totalGoldGrams = newTotalGrams;
        uint256 newBackingValueUSD = (newTotalGrams * goldToken.getAssetPrice()) / 10**18;
        goldToken.updateBackingValue(newBackingValueUSD);
        emit VaultAudited(newTotalGrams, block.timestamp);
    }
}
