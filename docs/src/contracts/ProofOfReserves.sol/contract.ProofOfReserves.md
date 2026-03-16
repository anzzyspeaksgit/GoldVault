# ProofOfReserves
[Git Source](https://github.com/anzzyspeaksgit/GoldVault/blob/108fc43e25297de579f61eb1a20903fe6f73c4db/contracts/ProofOfReserves.sol)

**Inherits:**
Ownable

**Title:**
ProofOfReserves

On-chain attestation of physical gold stored in real-world vaults.


## State Variables
### audits

```solidity
AuditReport[] public audits
```


## Functions
### constructor


```solidity
constructor() Ownable(msg.sender);
```

### addAuditReport

Add a new physical audit report. Only the owner/oracle can call this.


```solidity
function addAuditReport(
    uint256 _totalGoldGrams,
    string memory _vaultLocation,
    string memory _auditorName,
    string memory _ipfsHash
) external onlyOwner;
```

### getLatestAudit

Get the latest audit report.


```solidity
function getLatestAudit()
    external
    view
    returns (
        uint256 timestamp,
        uint256 totalGoldGrams,
        string memory vaultLocation,
        string memory auditorName,
        string memory ipfsHash
    );
```

## Events
### AuditAdded

```solidity
event AuditAdded(
    uint256 indexed timestamp, uint256 totalGoldGrams, string vaultLocation, string auditorName, string ipfsHash
);
```

## Structs
### AuditReport

```solidity
struct AuditReport {
    uint256 timestamp;
    uint256 totalGoldGrams;
    string vaultLocation;
    string auditorName;
    string ipfsHash; // Hash to PDF report
}
```

