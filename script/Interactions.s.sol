// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../contracts/GoldVault.sol";
import "../contracts/ProofOfReserves.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AddAuditReport is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proofOfReservesAddr = vm.envAddress("PROOF_OF_RESERVES_ADDR");
        
        vm.startBroadcast(deployerPrivateKey);

        ProofOfReserves por = ProofOfReserves(proofOfReservesAddr);
        
        // Mock audit data for demo day
        uint256 totalGrams = 100000 * 10**18; // 100 kg
        string memory location = "Swiss Alps Vault Beta";
        string memory auditor = "RWA Hackathon Auditors LLC";
        string memory ipfsHash = "ipfs://QmDemoHash1234567890";

        por.addAuditReport(totalGrams, location, auditor, ipfsHash);
        console.log("Audit report added to Proof of Reserves");

        vm.stopBroadcast();
    }
}

contract UpdateVaultReserves is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address vaultAddr = vm.envAddress("GOLD_VAULT_ADDR");
        
        vm.startBroadcast(deployerPrivateKey);

        GoldVault vault = GoldVault(vaultAddr);
        
        // Match the audit
        uint256 totalGrams = 100000 * 10**18; // 100 kg
        vault.updateAuditReserves(totalGrams);
        console.log("Vault reserves synced with physical audit");

        vm.stopBroadcast();
    }
}
