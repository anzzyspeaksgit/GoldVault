// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// interface for MockStablecoin
interface IMockStablecoin is IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract MintStablecoin is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address stablecoinAddr = vm.envAddress("STABLECOIN_ADDR");
        address recipientAddr = vm.envAddress("RECIPIENT_ADDR");
        
        vm.startBroadcast(deployerPrivateKey);

        IMockStablecoin stablecoin = IMockStablecoin(stablecoinAddr);
        
        // Mint/transfer 10,000 USDC (6 decimals)
        uint256 amount = 10000 * 10**6;
        stablecoin.transfer(recipientAddr, amount);
        
        console.log("Transferred 10,000 mock USDC to:", recipientAddr);

        vm.stopBroadcast();
    }
}
