// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/GoldToken.sol";
import "../contracts/GoldVault.sol";
import "../contracts/ProofOfReserves.sol";
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

contract GoldVaultTest is Test {
    GoldToken goldToken;
    GoldVault goldVault;
    ProofOfReserves proofOfReserves;
    MockStablecoin usdc;

    address admin = address(0x1);
    address user = address(0x2);
    address oracle = address(0x3);

    function setUp() public {
        vm.startPrank(admin);
        
        usdc = new MockStablecoin();
        
        // Use a dummy address for the price feed for now
        goldToken = new GoldToken(address(0x999));
        
        goldVault = new GoldVault(address(goldToken), address(usdc));
        proofOfReserves = new ProofOfReserves();

        // Grant roles
        goldToken.grantRole(goldToken.MINTER_ROLE(), address(goldVault));
        goldToken.grantRole(goldToken.ORACLE_ROLE(), oracle);

        // Whitelist user
        goldToken.setWhitelist(user, true);
        goldToken.setWhitelist(address(goldVault), true);

        // Give user some USDC
        usdc.transfer(user, 10000 * 10**6); // 10,000 USDC

        vm.stopPrank();
    }

    function test_DepositStableForGold() public {
        vm.startPrank(user);

        uint256 usdAmount = 1000 * 10**6; // 1000 USDC
        usdc.approve(address(goldVault), usdAmount);

        // $1000 / $64.30 (mock price) = ~15.55 grams
        uint256 expectedGrams = (1000 * 10**18 * 10**18) / goldToken.getAssetPrice();

        goldVault.depositStableForGold(usdAmount);

        assertEq(goldToken.balanceOf(user), expectedGrams);
        assertEq(goldVault.totalGoldGrams(), expectedGrams);

        vm.stopPrank();
    }

    function test_RedeemGoldForStable() public {
        vm.startPrank(user);

        uint256 usdAmount = 1000 * 10**6; // 1000 USDC
        usdc.approve(address(goldVault), usdAmount);
        
        goldVault.depositStableForGold(usdAmount);

        uint256 goldBalance = goldToken.balanceOf(user);
        
        goldToken.approve(address(goldVault), goldBalance);
        goldVault.redeemGoldForStable(goldBalance);

        assertEq(goldToken.balanceOf(user), 0);
        assertEq(goldVault.totalGoldGrams(), 0);
        
        // Assuming no fees, user should have exactly 10,000 USDC again
        // But due to minor precision loss in division, it might be slightly less
        assertApproxEqAbs(usdc.balanceOf(user), 10000 * 10**6, 1);

        vm.stopPrank();
    }

    function test_ProofOfReservesAudit() public {
        vm.startPrank(admin);

        proofOfReserves.addAuditReport(
            50000 * 10**18, // 50,000 grams
            "London Vault 1",
            "Deloitte",
            "QmTestHash"
        );

        (uint256 timestamp, uint256 totalGoldGrams, string memory vaultLocation, string memory auditorName, string memory ipfsHash) = proofOfReserves.getLatestAudit();

        assertEq(totalGoldGrams, 50000 * 10**18);
        assertEq(vaultLocation, "London Vault 1");
        assertEq(auditorName, "Deloitte");
        assertEq(ipfsHash, "QmTestHash");
        assertGt(timestamp, 0);

        vm.stopPrank();
    }
}
