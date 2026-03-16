// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../contracts/GoldToken.sol";
import "../contracts/GoldVault.sol";
import "../contracts/ProofOfReserves.sol";
import "../test/MockV3Aggregator.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock stablecoin for testing
contract MockStablecoin is ERC20 {
    constructor() ERC20("Mock USDC", "USDC") {
        _mint(msg.sender, 1000000 * 10**6); // Mint some for testing, 6 decimals
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}

contract DeployGoldVault is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Mock Price Feed (XAU/USD, 8 decimals, 2000 USD/oz)
        MockV3Aggregator priceFeed = new MockV3Aggregator(8, 200000000000);
        console.log("MockV3Aggregator:", address(priceFeed));

        // Deploy Mock Stablecoin (USDC)
        MockStablecoin usdc = new MockStablecoin();
        console.log("MockStablecoin:", address(usdc));

        // Deploy GoldToken
        GoldToken goldToken = new GoldToken(address(priceFeed));
        console.log("GoldToken:", address(goldToken));

        // Deploy GoldVault
        GoldVault goldVault = new GoldVault(address(goldToken), address(usdc));
        console.log("GoldVault:", address(goldVault));

        // Deploy ProofOfReserves
        ProofOfReserves proofOfReserves = new ProofOfReserves();
        console.log("ProofOfReserves:", address(proofOfReserves));

        // Setup Roles
        goldToken.grantRole(goldToken.MINTER_ROLE(), address(goldVault));
        console.log("Granted MINTER_ROLE to GoldVault");
        
        // Setup initial fees (0.5% mint, 0.5% redeem)
        goldVault.setFees(50, 50);
        console.log("Set default fees to 50 bps");

        vm.stopBroadcast();
        
        // Create frontend export file
        string memory json = "{";
        json = string.concat(json, "\"MockV3Aggregator\": \"", vm.toString(address(priceFeed)), "\",");
        json = string.concat(json, "\"MockStablecoin\": \"", vm.toString(address(usdc)), "\",");
        json = string.concat(json, "\"GoldToken\": \"", vm.toString(address(goldToken)), "\",");
        json = string.concat(json, "\"GoldVault\": \"", vm.toString(address(goldVault)), "\",");
        json = string.concat(json, "\"ProofOfReserves\": \"", vm.toString(address(proofOfReserves)), "\"");
        json = string.concat(json, "}");
        
        vm.writeJson(json, "./frontend/contracts.json");
    }
}
