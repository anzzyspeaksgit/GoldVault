# GoldToken
[Git Source](https://github.com/anzzyspeaksgit/GoldVault/blob/108fc43e25297de579f61eb1a20903fe6f73c4db/contracts/GoldToken.sol)

**Inherits:**
BaseRWA

**Title:**
GoldToken

ERC20 Token backed 1:1 by physical gold. Inherits from BaseRWA.


## State Variables
### GRAMS_PER_TOKEN

```solidity
uint256 public constant GRAMS_PER_TOKEN = 1
```


### priceFeed

```solidity
AggregatorV3Interface public priceFeed
```


## Functions
### constructor


```solidity
constructor(address _priceFeed) BaseRWA("GoldVault Token", "GOLD", "Physical Gold");
```

### mint

Mint new GOLD tokens. Only callable by MINTER_ROLE (e.g., the GoldVault).


```solidity
function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) nonReentrant;
```

### setPriceFeed

Update the Chainlink price feed address.


```solidity
function setPriceFeed(address _priceFeed) external onlyRole(DEFAULT_ADMIN_ROLE);
```

### getAssetPrice

Returns the current price of 1 gram of gold in USD (scaled to 18 decimals).
Chainlink XAU/USD returns the price of 1 Troy Ounce in USD with 8 decimals.
1 Troy Ounce = 31.1034768 grams.


```solidity
function getAssetPrice() public view override returns (uint256);
```

### getCollateralizationRatio

Returns the collateralization ratio in basis points (10000 = 100%).


```solidity
function getCollateralizationRatio() public view override returns (uint256);
```

## Events
### PriceFeedUpdated

```solidity
event PriceFeedUpdated(address indexed oldFeed, address indexed newFeed);
```

