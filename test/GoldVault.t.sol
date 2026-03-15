// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/GoldToken.sol";
import "../contracts/GoldVault.sol";
import "../contracts/ProofOfReserves.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MockV3Aggregator.sol";

// Mock stablecoin for testing
contract MockStablecoin is ERC20 {
    constructor() ERC20("Mock USDC", "USDC") {
        _mint(msg.sender, 1000000 * 10 ** 6); // Mint some for testing, 6 decimals
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
    MockV3Aggregator priceFeed;

    address admin = address(0x1);
    address user = address(0x2);
    address user2 = address(0x4);
    address oracle = address(0x3);

    function setUp() public {
        vm.startPrank(admin);

        usdc = new MockStablecoin();

        // $2000 per oz with 8 decimals: 2000 * 10^8 = 200000000000
        priceFeed = new MockV3Aggregator(8, 200000000000);

        goldToken = new GoldToken(address(priceFeed));

        goldVault = new GoldVault(address(goldToken), address(usdc));
        proofOfReserves = new ProofOfReserves();

        // Grant roles
        goldToken.grantRole(goldToken.MINTER_ROLE(), address(goldVault));
        goldToken.grantRole(goldToken.ORACLE_ROLE(), oracle);
        goldToken.grantRole(goldToken.ORACLE_ROLE(), address(goldVault));
        goldToken.grantRole(goldToken.PAUSER_ROLE(), admin);

        // Whitelist user
        goldToken.setWhitelist(user, true);
        goldToken.setWhitelist(address(goldVault), true);

        // Give user some USDC
        usdc.transfer(user, 10000 * 10 ** 6); // 10,000 USDC

        vm.stopPrank();
    }

    function test_DepositStableForGold() public {
        vm.startPrank(user);

        uint256 usdAmount = 1000 * 10 ** 6; // 1000 USDC
        usdc.approve(address(goldVault), usdAmount);

        uint256 expectedGrams = (1000 * 10 ** 18 * 10 ** 18) / goldToken.getAssetPrice();

        goldVault.depositStableForGold(usdAmount);

        assertEq(goldToken.balanceOf(user), expectedGrams);
        assertEq(goldVault.totalGoldGrams(), expectedGrams);

        vm.stopPrank();
    }

    function test_RevertIfDepositZero() public {
        vm.startPrank(user);
        vm.expectRevert("Amount must be greater than zero");
        goldVault.depositStableForGold(0);
        vm.stopPrank();
    }

    function test_RedeemGoldForStable() public {
        vm.startPrank(user);

        uint256 usdAmount = 1000 * 10 ** 6; // 1000 USDC
        usdc.approve(address(goldVault), usdAmount);

        goldVault.depositStableForGold(usdAmount);

        uint256 goldBalance = goldToken.balanceOf(user);

        goldToken.approve(address(goldVault), goldBalance);
        goldVault.redeemGoldForStable(goldBalance);

        assertEq(goldToken.balanceOf(user), 0);
        assertEq(goldVault.totalGoldGrams(), 0);

        // Assuming no fees, user should have exactly 10,000 USDC again
        // But due to minor precision loss in division, it might be slightly less
        assertApproxEqAbs(usdc.balanceOf(user), 10000 * 10 ** 6, 1);

        vm.stopPrank();
    }

    function test_RevertIfRedeemZero() public {
        vm.startPrank(user);
        vm.expectRevert("Amount must be greater than zero");
        goldVault.redeemGoldForStable(0);
        vm.stopPrank();
    }

    function test_RevertIfRedeemExceedsVault() public {
        vm.startPrank(user);
        vm.expectRevert("Insufficient vault reserves");
        goldVault.redeemGoldForStable(100);
        vm.stopPrank();
    }

    function test_ProofOfReservesAudit() public {
        vm.startPrank(admin);

        proofOfReserves.addAuditReport(
            50000 * 10 ** 18, // 50,000 grams
            "London Vault 1",
            "Deloitte",
            "QmTestHash"
        );

        (
            uint256 timestamp,
            uint256 totalGoldGrams,
            string memory vaultLocation,
            string memory auditorName,
            string memory ipfsHash
        ) = proofOfReserves.getLatestAudit();

        assertEq(totalGoldGrams, 50000 * 10 ** 18);
        assertEq(vaultLocation, "London Vault 1");
        assertEq(auditorName, "Deloitte");
        assertEq(ipfsHash, "QmTestHash");
        assertGt(timestamp, 0);

        vm.stopPrank();
    }

    function test_RevertIfNonAdminAddsAudit() public {
        vm.startPrank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        proofOfReserves.addAuditReport(50000 * 10 ** 18, "London Vault 1", "Deloitte", "QmTestHash");
        vm.stopPrank();
    }

    function test_RevertIfGetAuditWhenEmpty() public {
        vm.expectRevert("No audits available");
        proofOfReserves.getLatestAudit();
    }

    function test_KYCRevertOnTransfer() public {
        vm.startPrank(user);
        uint256 usdAmount = 1000 * 10 ** 6;
        usdc.approve(address(goldVault), usdAmount);
        goldVault.depositStableForGold(usdAmount);

        // user2 is not whitelisted
        uint256 goldBalance = goldToken.balanceOf(user);

        vm.expectRevert("KYC required");
        goldToken.transfer(user2, goldBalance);
        vm.stopPrank();
    }

    function test_KYCTransferSuccess() public {
        vm.startPrank(user);
        uint256 usdAmount = 1000 * 10 ** 6;
        usdc.approve(address(goldVault), usdAmount);
        goldVault.depositStableForGold(usdAmount);
        vm.stopPrank();

        vm.prank(admin);
        goldToken.setWhitelist(user2, true);

        vm.startPrank(user);
        uint256 goldBalance = goldToken.balanceOf(user);
        goldToken.transfer(user2, goldBalance);
        assertEq(goldToken.balanceOf(user2), goldBalance);
        vm.stopPrank();
    }

    function test_UpdateAuditReserves() public {
        vm.startPrank(admin);
        goldVault.updateAuditReserves(1000 * 10 ** 18);
        assertEq(goldVault.totalGoldGrams(), 1000 * 10 ** 18);
        vm.stopPrank();
    }

    function test_RevertIfOraclePriceZero() public {
        vm.startPrank(admin);
        priceFeed.updateAnswer(0); // 0 price
        vm.stopPrank();

        vm.startPrank(user);
        uint256 usdAmount = 1000 * 10 ** 6;
        usdc.approve(address(goldVault), usdAmount);

        vm.expectRevert("Invalid oracle price");
        goldVault.depositStableForGold(usdAmount);
        vm.stopPrank();
    }

    function test_SetPriceFeed() public {
        vm.startPrank(admin);
        address newFeed = address(0x888);
        goldToken.setPriceFeed(newFeed);
        // We can't actually call it since it's an EOA and will revert on latestRoundData,
        // but we can check if address updated in the contract manually if we want
        vm.stopPrank();
    }
}
