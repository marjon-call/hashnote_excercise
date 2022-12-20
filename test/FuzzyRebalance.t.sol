// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/Rebalancer.sol";
import "../src/Vault.sol";


contract FuzzyRebalancerTest is  Test {


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

        // make rebalancer vault admin
        vault.updateAdmin(address(reb));
    }

    // tests random ratio rebalance with 2 assets
    function testFuzzyRebalanceVault2Assets(uint8 ratio0, uint8 ratio1) external {

        // too complex for vm.assume()
        if (uint16(ratio0) + uint16(ratio1) == 100) {


            // transfer usdc to rebalancer contract
            vm.prank(usdcWhale);
            IERC20(usdcAddress).transfer(address(vault), 200000 * 10**6);

            // transfer weth to rebalancer contract
            vm.prank(wethWhale);
            IERC20(wethAddress).transfer(address(vault), 15000 * 1 ether);


            // assign tokens to vault
            address[] memory tokens = new address[](2);
            tokens[0] = usdcAddress;
            tokens[1] = wethAddress;
            reb.updateVaultTokens(tokens);


            address[] memory _tokens = vault.getTokenAddresses();


            // construct calldata
            uint8[] memory newRatio = new uint8[](2);
            newRatio[0] = ratio0;
            newRatio[1] = ratio1;


            

            // call reblance function
            reb.updateReserveRatio(newRatio);


            // get end reserve balances
            (uint256[] memory endReserves, uint256 endBalance) = reb.getVaultAUM(_tokens);


            uint256 maxDelta = 0.01 ether;

            
            uint256 t1prct = (endReserves[0] * 10000) / endBalance;
            uint256 t1trgt = uint256(newRatio[0]) * 100;

            uint256 t2prct = (endReserves[1] * 10000) / endBalance;
            uint256 t2trgt = uint256(newRatio[1]) * 100;

        

            assertApproxEqRel(t1prct, t1trgt, maxDelta, "Ratio more than 1% off of expected value.");
            assertApproxEqRel(t2prct, t2trgt, maxDelta, "Ratio more than 1% off of expected value.");

        }

    }

    // tests random ratio rebalance with 3 assets
    function testFuzzyRebalanceVault3Assets(uint8 ratio0, uint8 ratio1, uint8 ratio2) external {

        // too complex for vm.assume()
        if (uint16(ratio0) + uint16(ratio1) + uint16(ratio2) == 100) {


            // transfer usdc to rebalancer contract
            vm.prank(usdcWhale);
            IERC20(usdcAddress).transfer(address(vault), 200000 * 10**6);

            // transfer weth to rebalancer contract
            vm.prank(wethWhale);
            IERC20(wethAddress).transfer(address(vault), 15000 * 1 ether);

            // transfer wbtc to rebalancer contract
            vm.prank(wbtcWhale);
            IERC20(wbtcAddress).transfer(address(vault), 12 * 10**8);


            // assign tokens to vault
            address[] memory tokens = new address[](3);
            tokens[0] = usdcAddress;
            tokens[1] = wethAddress;
            tokens[2] = wbtcAddress;
            reb.updateVaultTokens(tokens);


            address[] memory _tokens = vault.getTokenAddresses();


            // construct calldata
            uint8[] memory newRatio = new uint8[](3);
            newRatio[0] = ratio0;
            newRatio[1] = ratio1;
            newRatio[2] = ratio2;


            

            // call reblance function
            reb.updateReserveRatio(newRatio);


            // get end reserve balances
            (uint256[] memory endReserves, uint256 endBalance) = reb.getVaultAUM(_tokens);


            uint256 maxDelta = 0.015 ether;

            
            uint256 t1prct = (endReserves[0] * 10000) / endBalance;
            uint256 t1trgt = uint256(newRatio[0]) * 100;

            uint256 t2prct = (endReserves[1] * 10000) / endBalance;
            uint256 t2trgt = uint256(newRatio[1]) * 100;

            uint256 t3prct = (endReserves[2] * 10000) / endBalance;
            uint256 t3trgt = uint256(newRatio[2]) * 100;

        

            assertApproxEqRel(t1prct, t1trgt, maxDelta, "Ratio more than 1.5% off of expected value.");
            assertApproxEqRel(t2prct, t2trgt, maxDelta, "Ratio more than 1.5% off of expected value.");
            assertApproxEqRel(t3prct, t3trgt, maxDelta, "Ratio more than 1.5% off of expected value.");

        }

    }



    // tests random ratio rebalance with 4 assets
    function testFuzzyRebalanceVault4Assets(uint8 ratio0, uint8 ratio1, uint8 ratio2, uint8 ratio3) external {

        // too complex for vm.assume()
        if (uint16(ratio0) + uint16(ratio1) + uint16(ratio2) + uint16(ratio3) == 100) {


            // transfer usdc to rebalancer contract
            vm.prank(usdcWhale);
            IERC20(usdcAddress).transfer(address(vault), 100000 * 10**6);

            // transfer weth to rebalancer contract
            vm.prank(wethWhale);
            IERC20(wethAddress).transfer(address(vault), 7000 * 1 ether);

            // transfer wbtc to rebalancer contract
            vm.prank(wbtcWhale);
            IERC20(wbtcAddress).transfer(address(vault), 6 * 10**8);

            // transfer dai to rebalancer contract
            vm.prank(daiWhale);
            IERC20(daiAddress).transfer(address(vault), 100000 * 1 ether);


            // assign tokens to vault
            address[] memory tokens = new address[](4);
            tokens[0] = usdcAddress;
            tokens[1] = wethAddress;
            tokens[2] = wbtcAddress;
            tokens[3] = daiAddress;
            reb.updateVaultTokens(tokens);


            address[] memory _tokens = vault.getTokenAddresses();


            // construct calldata
            uint8[] memory newRatio = new uint8[](4);
            newRatio[0] = ratio0;
            newRatio[1] = ratio1;
            newRatio[2] = ratio2;
            newRatio[3] = ratio3;


            

            // call reblance function
            reb.updateReserveRatio(newRatio);


            // get end reserve balances
            (uint256[] memory endReserves, uint256 endBalance) = reb.getVaultAUM(_tokens);


            uint256 maxDelta = 0.015 ether;

            
            uint256 t1prct = (endReserves[0] * 10000) / endBalance;
            uint256 t1trgt = uint256(newRatio[0]) * 100;

            uint256 t2prct = (endReserves[1] * 10000) / endBalance;
            uint256 t2trgt = uint256(newRatio[1]) * 100;

            uint256 t3prct = (endReserves[2] * 10000) / endBalance;
            uint256 t3trgt = uint256(newRatio[2]) * 100;

            uint256 t4prct = (endReserves[3] * 10000) / endBalance;
            uint256 t4trgt = uint256(newRatio[3]) * 100;

        

            assertApproxEqRel(t1prct, t1trgt, maxDelta, "Ratio more than 1.5% off of expected value.");
            assertApproxEqRel(t2prct, t2trgt, maxDelta, "Ratio more than 1.5% off of expected value.");
            assertApproxEqRel(t3prct, t3trgt, maxDelta, "Ratio more than 1.5% off of expected value.");
            assertApproxEqRel(t4prct, t4trgt, maxDelta, "Ratio more than 1.5% off of expected value.");

        }

    }



    // tests random ratio rebalance with 5 assets
    function testFuzzyRebalanceVault5Assets(uint8 ratio0, uint8 ratio1, uint8 ratio2, uint8 ratio3, uint8 ratio4) external {

        // too complex for vm.assume()
        if (uint16(ratio0) + uint16(ratio1) + uint16(ratio2) + uint16(ratio3) + uint16(ratio4) == 100) {


            // transfer usdc to rebalancer contract
            vm.prank(usdcWhale);
            IERC20(usdcAddress).transfer(address(vault), 20000 * 10**6);

            // transfer weth to rebalancer contract
            vm.prank(wethWhale);
            IERC20(wethAddress).transfer(address(vault), 1500 * 1 ether);

            // transfer wbtc to rebalancer contract
            vm.prank(wbtcWhale);
            IERC20(wbtcAddress).transfer(address(vault), 2 * 10**8);

            // transfer dai to rebalancer contract
            vm.prank(daiWhale);
            IERC20(daiAddress).transfer(address(vault), 20000 * 1 ether);

            // transfer link to rebalancer contract
            vm.prank(linkWhale);
            IERC20(linkAddress).transfer(address(vault), 2500 * 1 ether);


            // assign tokens to vault
            address[] memory tokens = new address[](5);
            tokens[0] = usdcAddress;
            tokens[1] = wethAddress;
            tokens[2] = wbtcAddress;
            tokens[3] = daiAddress;
            tokens[4] = linkAddress;
            reb.updateVaultTokens(tokens);


            address[] memory _tokens = vault.getTokenAddresses();


            // construct calldata
            uint8[] memory newRatio = new uint8[](5);
            newRatio[0] = ratio0;
            newRatio[1] = ratio1;
            newRatio[2] = ratio2;
            newRatio[3] = ratio3;
            newRatio[4] = ratio4;


            

            // call reblance function
            reb.updateReserveRatio(newRatio);


            // get end reserve balances
            (uint256[] memory endReserves, uint256 endBalance) = reb.getVaultAUM(_tokens);


            uint256 maxDelta = 0.02 ether;

            
            uint256 t1prct = (endReserves[0] * 10000) / endBalance;
            uint256 t1trgt = uint256(newRatio[0]) * 100;

            uint256 t2prct = (endReserves[1] * 10000) / endBalance;
            uint256 t2trgt = uint256(newRatio[1]) * 100;

            uint256 t3prct = (endReserves[2] * 10000) / endBalance;
            uint256 t3trgt = uint256(newRatio[2]) * 100;

            uint256 t4prct = (endReserves[3] * 10000) / endBalance;
            uint256 t4trgt = uint256(newRatio[3]) * 100;
            
            uint256 t5prct = (endReserves[4] * 10000) / endBalance;
            uint256 t5trgt = uint256(newRatio[4]) * 100;

        

            assertApproxEqRel(t1prct, t1trgt, maxDelta, "Ratio more than 2% off of expected value.");
            assertApproxEqRel(t2prct, t2trgt, maxDelta, "Ratio more than 2% off of expected value.");
            assertApproxEqRel(t3prct, t3trgt, maxDelta, "Ratio more than 2% off of expected value.");
            assertApproxEqRel(t4prct, t4trgt, maxDelta, "Ratio more than 2% off of expected value.");
            assertApproxEqRel(t5prct, t5trgt, maxDelta, "Ratio more than 2% off of expected value.");

        }

    }


    


   



}