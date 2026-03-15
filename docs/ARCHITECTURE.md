# GoldVault Architecture

## Overview
GoldVault allows users to deposit stablecoins (e.g. USDC) to mint `GOLD` tokens natively backed 1:1 by real-world physical gold (measured in grams). The protocol consists of three primary smart contracts built on top of the RWA Demo Day shared `BaseRWA` implementation.

## Core Smart Contracts

### 1. GoldToken.sol
- Inherits `BaseRWA` to maintain standard RWA Demo Day compliance, pausing, and role administration.
- Provides a native implementation of `getAssetPrice()` using a dynamic Chainlink XAU/USD oracle, scaling prices from Ounces to Grams (1 Troy Ounce = ~31.1034 grams).
- Enforces strict role-based `mint` functionality isolated to the `GoldVault`.

### 2. GoldVault.sol
- The primary deposit and redemption pool.
- Takes stablecoins (USDC) from users and automatically converts them to `GOLD` tokens natively backed by grams depending on real-time Chainlink oracles.
- Enables bidirectional burns (redeeming `GOLD` to reclaim USDC at the current oracle rate).

### 3. ProofOfReserves.sol
- Provides a permanent on-chain ledger mapping the synthetic total `GOLD` supply to verifiable real-world assets.
- Stores variables reflecting the latest vault audit reports such as:
  - Timestamp
  - Total Gold Grams
  - Vault Location
  - Auditor Name
  - IPFS Hash of the full PDF audit report

## Integrations
- **Chainlink Oracles**: Directly utilizes `AggregatorV3Interface` pulling `XAU/USD` (converted from Ounces to Grams internally to maintain 1:1 tokenomic peg)
- **Shared BaseRWA**: Adopts the RWA hackathon unified base layer to standardize tracking of `totalBackingValue`, generic RBAC, and `requiresKYC` validation.
