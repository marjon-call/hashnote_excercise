// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/Rebalancer.sol";
import "../src/Vault.sol";


contract AccessControlTest is  Test {


    Rebalancer public reb;
    Vault public vault;

    address usdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address daiAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address linkAddress = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address wbtcAddress = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    address usdcWhale = 0x38abab9766e0b27d2912718a884292b8E7eb2803;
    address daiWhale = 0x075e72a5eDf65F0A5f44699c7654C1a76941Ddc8;
    address linkWhale = 0x0D4f1ff895D12c34994D6B65FaBBeEFDc1a9fb39;
    address wethWhale = 0xF04a5cC80B1E94C69B48f5ee68a08CD2F09A7c3E;
    address wbtcWhale = 0x218B95BE3ed99141b0144Dba6cE88807c4AD7C09;



    function setUp() public {
        // create vault & rebalancer contracts
        vault = new Vault(address(this));
        reb = new Rebalancer(address(vault), address(this), usdcAddress, 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);


        // assign tokens to vault
        address[] memory tokens = new address[](3);
        tokens[0] = wethAddress;
        tokens[1] = wbtcAddress;
        tokens[2] = usdcAddress;
        vault.updateTokenAddresses(tokens);

        // transfer usdc to rebalancer contract
        vm.prank(usdcWhale);
        IERC20(usdcAddress).transfer(address(vault), 123456 * 10**6);

        // transfer dai to rebalancer contract
        vm.prank(wethWhale);
        IERC20(wethAddress).transfer(address(vault), 50 ether);

        // transfer dai to rebalancer contract
        vm.prank(wbtcWhale);
        IERC20(wbtcAddress).transfer(address(vault), 5 * 10**8);


        // make rebalancer vault admin
        vault.updateAdmin(address(reb));
    }


    // ===============
    // | VAULT TESTS |
    // ===============

    // tests that only vault admin can withdraw Liquidity
    function testVAULTAttemptToWithdrawLiquidityUA() external {
        vm.expectRevert(bytes("Vault: Unauthorized user."));
        vm.prank(usdcWhale);
        vault.withdrawLiquidity(usdcAddress, 100 * 10**6, address(this));
    }

    // test that only vault admin can update admin and cannot make admin 0 address
    function testVAULTAttemptToUpdateAdminUAAnd0Address() external {
        vm.expectRevert(bytes("Vault: Unauthorized user."));
        vm.prank(usdcWhale);
        vault.updateAdmin(usdcWhale);

        vm.expectRevert(bytes("Vault: Can not make 0 address admin"));
        reb.updateVaultAdmin(address(0));
    }

    // tests that only vault admin can update vault tokens
    function testVAULTAttemptToUpdateTokensUA() external {
        vm.expectRevert(bytes("Vault: Unauthorized user."));
        vm.prank(usdcWhale);
        // assign tokens to vault
        address[] memory tokens = new address[](2);
        tokens[0] = wethAddress;
        tokens[1] = wbtcAddress;
        vault.updateTokenAddresses(tokens);
    }



    // ====================
    // | REBALANCER TESTS |
    // ====================


    // tests that only rebalancer admin can update admin and cannot make admin 0 address
    function testREBAttemptToUpdateAdminUAAnd0Address() external {
        vm.expectRevert(bytes("Rebalancer: Unauthorized user."));
        vm.prank(usdcWhale);
        reb.updateAdmin(usdcWhale);

        vm.expectRevert(bytes("Rebalancer: Can not make 0 address admin"));
        reb.updateAdmin(address(0));
    }

    // tests that only rebalancer admin can update vault admin
    function testREBAttemptToUpdateVaultAdminUA() external {
        vm.expectRevert(bytes("Rebalancer: Unauthorized user."));
        vm.prank(usdcWhale);
        reb.updateVaultAdmin(usdcWhale);
    }

    // tests that only rebalancer admin can update router and cannot make router 0 address
    function testREBAttemptToUpdateRouterUAAnd0Address() external {
        vm.expectRevert(bytes("Rebalancer: Unauthorized user."));
        vm.prank(usdcWhale);
        reb.updateRouterAddress(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac);

        vm.expectRevert(bytes("Rebalancer: Can not make 0 address new router"));
        reb.updateRouterAddress(address(0));
    }

    // tests that only rebalancer admin can update quote asset and cannot make quote asset 0 address
    function testREBAttemptToUpdateQuoteAssetUAAnd0Address() external {
        vm.expectRevert(bytes("Rebalancer: Unauthorized user."));
        vm.prank(usdcWhale);
        reb.updateQuoteAsset(linkAddress);

        vm.expectRevert(bytes("Rebalancer: Can not make 0 address quote asset"));
        reb.updateQuoteAsset(address(0));
    }


    // tests that only rebalancer admin can update vault tokens
    function testREBUpdateTokensUA() external {
        vm.expectRevert(bytes("Rebalancer: Unauthorized user."));
        vm.prank(usdcWhale);
        // assign tokens to vault
        address[] memory tokens = new address[](2);
        tokens[0] = linkAddress;
        tokens[1] = wbtcAddress;
        reb.updateVaultTokens(tokens);
    }



    // tests that only rebalancer admin can update reserve ratios
    function testREBAttemptToUpdateRatiosUA() external {
        vm.expectRevert(bytes("Rebalancer: Unauthorized user."));
        vm.prank(usdcWhale);
        uint8[] memory newRatio = new uint8[](2);
        newRatio[0] = 50;
        newRatio[1] = 50;
        reb.updateReserveRatio(newRatio);

    }
    

}