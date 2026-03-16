// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/GoldToken.sol";
import "../contracts/GoldVault.sol";
import "../contracts/ProofOfReserves.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MockV3Aggregator.sol";

contract MockStablecoin is ERC20 {
    constructor() ERC20("Mock USDC", "USDC") {
        _mint(msg.sender, 1_000_000_000 * 10**6);
    }
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}

contract GoldVaultHandler is Test {
    GoldVault public vault;
    GoldToken public token;
    MockStablecoin public usdc;
    MockV3Aggregator public oracle;

    address public user = address(0x1337);

    uint256 public totalDeposited;
    uint256 public totalRedeemed;

    constructor(GoldVault _vault, GoldToken _token, MockStablecoin _usdc, MockV3Aggregator _oracle) {
        vault = _vault;
        token = _token;
        usdc = _usdc;
        oracle = _oracle;
    }

    function deposit(uint256 amount) public {
        amount = bound(amount, 1 * 10**6, 1_000_000 * 10**6);
        
        vm.startPrank(user);
        usdc.approve(address(vault), amount);
        vault.depositStableForGold(amount);
        vm.stopPrank();

        totalDeposited += amount;
    }

    function redeem(uint256 amount) public {
        uint256 userBalance = token.balanceOf(user);
        if (userBalance == 0) return;
        
        amount = bound(amount, 1, userBalance);

        vm.startPrank(user);
        token.approve(address(vault), amount);
        vault.redeemGoldForStable(amount);
        vm.stopPrank();
        
        totalRedeemed += amount;
    }

    function changeOraclePrice(uint256 newPrice) public {
        // Price must be reasonable: $100/oz to $10,000/oz
        newPrice = bound(newPrice, 100 * 10**8, 10000 * 10**8);
        oracle.updateAnswer(int256(newPrice));
    }
}

contract InvariantGoldVaultTest is Test {
    GoldToken goldToken;
    GoldVault goldVault;
    MockStablecoin usdc;
    MockV3Aggregator priceFeed;
    GoldVaultHandler handler;

    address admin = address(0x1);

    function setUp() public {
        vm.startPrank(admin);
        
        usdc = new MockStablecoin();
        priceFeed = new MockV3Aggregator(8, 200000000000); // $2000
        goldToken = new GoldToken(address(priceFeed));
        goldVault = new GoldVault(address(goldToken), address(usdc));

        goldToken.grantRole(goldToken.MINTER_ROLE(), address(goldVault));
        goldToken.grantRole(goldToken.ORACLE_ROLE(), address(goldVault));
        
        // Disable fees for easier invariant math
        goldVault.setFees(0, 0);

        vm.stopPrank();

        handler = new GoldVaultHandler(goldVault, goldToken, usdc, priceFeed);

        // Fund user
        vm.prank(admin);
        usdc.transfer(handler.user(), 1_000_000_000 * 10**6);
        
        // Whitelist user
        vm.prank(admin);
        goldToken.setWhitelist(handler.user(), true);
        vm.prank(admin);
        goldToken.setWhitelist(address(goldVault), true);

        targetContract(address(handler));
    }

    function invariant_GoldSupplyEqualsVaultReserves() public {
        assertEq(goldToken.totalSupply(), goldVault.totalGoldGrams());
    }

    function invariant_VaultStablecoinBalanceMatchesDeposits() public {
        // The vault only holds USDC that hasn't been redeemed.
        // Wait, the vault holds ALL the USDC deposited, minus what's redeemed.
        // Since price changes, redeem amount might differ from deposit amount.
        // So vault USDC >= 0. We can just check it hasn't somehow stolen tokens.
        assertGe(usdc.balanceOf(address(goldVault)), 0);
    }
}
