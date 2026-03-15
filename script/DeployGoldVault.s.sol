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
        console.log("Deployed MockV3Aggregator at:", address(priceFeed));

        // Deploy Mock Stablecoin (USDC)
        MockStablecoin usdc = new MockStablecoin();
        console.log("Deployed MockStablecoin at:", address(usdc));

        // Deploy GoldToken
        GoldToken goldToken = new GoldToken(address(priceFeed));
        console.log("Deployed GoldToken at:", address(goldToken));

        // Deploy GoldVault
        GoldVault goldVault = new GoldVault(address(goldToken), address(usdc));
        console.log("Deployed GoldVault at:", address(goldVault));

        // Deploy ProofOfReserves
        ProofOfReserves proofOfReserves = new ProofOfReserves();
        console.log("Deployed ProofOfReserves at:", address(proofOfReserves));

        // Setup Roles
        goldToken.grantRole(goldToken.MINTER_ROLE(), address(goldVault));
        console.log("Granted MINTER_ROLE to GoldVault");

        vm.stopBroadcast();
    }
}
