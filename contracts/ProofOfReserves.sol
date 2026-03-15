// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ProofOfReserves
 * @dev On-chain attestation of physical gold stored in real-world vaults.
 */
contract ProofOfReserves is Ownable {
    struct AuditReport {
        uint256 timestamp;
        uint256 totalGoldGrams;
        string vaultLocation;
        string auditorName;
        string ipfsHash; // Hash to PDF report
    }

    AuditReport[] public audits;

    event AuditAdded(
        uint256 indexed timestamp,
        uint256 totalGoldGrams,
        string vaultLocation,
        string auditorName,
        string ipfsHash
    );

    constructor() Ownable() {}

    /**
     * @dev Add a new physical audit report. Only the owner/oracle can call this.
     */
    function addAuditReport(
        uint256 _totalGoldGrams,
        string memory _vaultLocation,
        string memory _auditorName,
        string memory _ipfsHash
    ) external onlyOwner {
        AuditReport memory newAudit = AuditReport({
            timestamp: block.timestamp,
            totalGoldGrams: _totalGoldGrams,
            vaultLocation: _vaultLocation,
            auditorName: _auditorName,
            ipfsHash: _ipfsHash
        });

        audits.push(newAudit);

        emit AuditAdded(
            block.timestamp,
            _totalGoldGrams,
            _vaultLocation,
            _auditorName,
            _ipfsHash
        );
    }

    /**
     * @dev Get the latest audit report.
     */
    function getLatestAudit()
        external
        view
        returns (
            uint256 timestamp,
            uint256 totalGoldGrams,
            string memory vaultLocation,
            string memory auditorName,
            string memory ipfsHash
        )
    {
        require(audits.length > 0, "No audits available");
        AuditReport memory latest = audits[audits.length - 1];
        return (
            latest.timestamp,
            latest.totalGoldGrams,
            latest.vaultLocation,
            latest.auditorName,
            latest.ipfsHash
        );
    }
}
