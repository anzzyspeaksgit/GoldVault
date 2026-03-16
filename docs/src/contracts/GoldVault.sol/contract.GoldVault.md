# GoldVault
[Git Source](https://github.com/anzzyspeaksgit/GoldVault/blob/108fc43e25297de579f61eb1a20903fe6f73c4db/contracts/GoldVault.sol)

**Inherits:**
Ownable, ReentrancyGuard, Pausable

**Title:**
GoldVault

Vault for locking stablecoins/fiat value to mint GOLD tokens 1:1 with physical gold
Note: Real-world physical delivery triggers the mint. For demo, we mock USD stablecoin collateral.


## State Variables
### goldToken

```solidity
GoldToken public goldToken
```


### stablecoin

```solidity
IERC20 public stablecoin
```


### totalGoldGrams

```solidity
uint256 public totalGoldGrams
```


### mintingFeeBps

```solidity
uint256 public mintingFeeBps
```


### redemptionFeeBps

```solidity
uint256 public redemptionFeeBps
```


### feeCollector

```solidity
address public feeCollector
```


## Functions
### constructor


```solidity
constructor(address _goldToken, address _stablecoin) Ownable(msg.sender);
```

### pause

Pause all deposits and redemptions.


```solidity
function pause() external onlyOwner;
```

### unpause

Unpause all deposits and redemptions.


```solidity
function unpause() external onlyOwner;
```

### setFees

Set protocol fees. Max 5% (500 bps).


```solidity
function setFees(uint256 _mintingFeeBps, uint256 _redemptionFeeBps) external onlyOwner;
```

### setFeeCollector

Set the fee collector address.


```solidity
function setFeeCollector(address _feeCollector) external onlyOwner;
```

### depositStableForGold

Mint GOLD tokens by depositing stablecoins.


```solidity
function depositStableForGold(uint256 usdAmount) external nonReentrant whenNotPaused;
```

### redeemGoldForStable

Redeem GOLD tokens for stablecoins.


```solidity
function redeemGoldForStable(uint256 goldAmount) external nonReentrant whenNotPaused;
```

### updateAuditReserves

Oracle/Admin updates the exact physical gold amount after audits.


```solidity
function updateAuditReserves(uint256 newTotalGrams) external onlyOwner;
```

## Events
### GoldDeposited

```solidity
event GoldDeposited(address indexed user, uint256 usdAmount, uint256 goldGrams, uint256 fee);
```

### GoldRedeemed

```solidity
event GoldRedeemed(address indexed user, uint256 goldGrams, uint256 usdAmount, uint256 fee);
```

### VaultAudited

```solidity
event VaultAudited(uint256 newTotalGrams, uint256 timestamp);
```

### FeesUpdated

```solidity
event FeesUpdated(uint256 newMintFee, uint256 newRedeemFee);
```

### FeeCollectorUpdated

```solidity
event FeeCollectorUpdated(address indexed newCollector);
```

