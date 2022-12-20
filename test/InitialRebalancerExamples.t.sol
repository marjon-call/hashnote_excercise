// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/Rebalancer.sol";
import "../src/Vault.sol";


contract RebalancerTest is  Test {


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
        address[] memory tokens = new address[](2);
        tokens[0] = usdcAddress;
        tokens[1] = daiAddress;
        vault.updateTokenAddresses(tokens);


        // make rebalancer vault admin
        vault.updateAdmin(address(reb));
    }


    
    // test for a vault with  2 stablecoins
    function testRebalance2Stablecoins() public {

        

        // transfer usdc to rebalancer contract
        vm.prank(usdcWhale);
        IERC20(usdcAddress).transfer(address(vault), 200 * 1000000);

        // transfer dai to rebalancer contract
        vm.prank(daiWhale);
        IERC20(daiAddress).transfer(address(vault), 100 ether);





        address[] memory _tokens = vault.getTokenAddresses();


        // get start reserve balances
        (uint256[] memory startReserves, uint256 startBalance) = reb.getVaultAUM(_tokens);

        // construct calldata
        uint8[] memory newRatio = new uint8[](2);
        newRatio[0] = 25;
        newRatio[1] = 75;

        // call reblance function
        reb.updateReserveRatio(newRatio);


        // get end reserve balances
        (uint256[] memory endReserves, uint256 endBalance) = reb.getVaultAUM(_tokens);


        emit log_named_uint("Start Balance: ", startBalance);
        emit log_named_uint("Start USDC Balance: ", startReserves[0]);
        emit log_named_uint("Start DAI Balance: ", startReserves[1]);

        emit log("");

        emit log_named_uint("End Balance: ", endBalance);
        emit log_named_uint("End USDC Balance: ", endReserves[0]);
        emit log_named_uint("End DAI Balance: ", endReserves[1]);


        emit log("");

        emit log_named_int("Delta Balance: ", int256(endBalance) - int256(startBalance));
        emit log_named_int("Delta USDC Balance: ", int256(endReserves[0]) - int256(startReserves[0]));
        emit log_named_int("Delta DAI Balance: ", int256(endReserves[1]) - int256(startReserves[1]));


        

        emit log("");
        


        emit log("START:");
        emit log_named_uint("USDC % ", (startReserves[0] * 10000) / startBalance);
        emit log_named_uint("DAI % ",  (startReserves[1] * 10000) / startBalance);

        emit log("");

        emit log("END:");
        emit log_named_uint("USDC % ", (endReserves[0] * 10000) / endBalance);
        emit log_named_uint("DAI % ",  (endReserves[1] * 10000) / endBalance);


        emit log("");


        emit log("TARGET:");
        emit log_named_uint("USDC % ", newRatio[0]);
        emit log_named_uint("DAI % ",  newRatio[1]);



    }

    // test for vault with 2 uncorrelated assets
    function testRebalance2Assets() public {
        

        // transfer usdc to rebalancer contract
        vm.prank(usdcWhale);
        IERC20(usdcAddress).transfer(address(vault), 25873874521);

        // transfer dai to rebalancer contract
        vm.prank(wethWhale);
        IERC20(wethAddress).transfer(address(vault), 30 ether);
        // IERC20(wethAddress).transfer(address(vault), 0 ether);


        // assign tokens to vault
        address[] memory tokens = new address[](2);
        tokens[0] = usdcAddress;
        tokens[1] = wethAddress;


        reb.updateVaultTokens(tokens);


        address[] memory _tokens = vault.getTokenAddresses();


        // get start reserve balances
        (uint256[] memory startReserves, uint256 startBalance) = reb.getVaultAUM(_tokens);



        // construct calldata
        uint8[] memory newRatio = new uint8[](2);
        newRatio[0] = 64;
        newRatio[1] = 36;


        // call reblance function
        reb.updateReserveRatio(newRatio);



        // get end reserve balances
        (uint256[] memory endReserves, uint256 endBalance) = reb.getVaultAUM(_tokens);


        emit log_named_uint("Start Balance: ", startBalance);
        emit log_named_uint("Start USDC Balance: ", startReserves[0]);
        emit log_named_uint("Start WETH Balance: ", startReserves[1]);

        emit log("");

        emit log_named_uint("End Balance: ", endBalance);
        emit log_named_uint("End USDC Balance: ", endReserves[0]);
        emit log_named_uint("End WETH Balance: ", endReserves[1]);


        emit log("");

        emit log_named_int("Delta Balance: ", int256(endBalance) - int256(startBalance));
        emit log_named_int("Delta USDC Balance: ", int256(endReserves[0]) - int256(startReserves[0]));
        emit log_named_int("Delta WETH Balance: ", int256(endReserves[1]) - int256(startReserves[1]));

        emit log("");
        


        emit log("START:");
        emit log_named_uint("USDC % ", (startReserves[0] * 10000) / startBalance);
        emit log_named_uint("WETH % ",  (startReserves[1] * 10000) / startBalance);

        emit log("");

        emit log("END:");
        emit log_named_uint("USDC % ", (endReserves[0] * 10000) / endBalance);
        emit log_named_uint("WETH % ",  (endReserves[1] * 10000) / endBalance);


        emit log("");


        emit log("TARGET:");
        emit log_named_uint("USDC % ", newRatio[0]);
        emit log_named_uint("WETH % ",  newRatio[1]);



    }


    // test for vault with 3 uncorrelated assets
    function testRebalance3Assets() public {
        

        // transfer usdc to rebalancer contract
        vm.prank(usdcWhale);
        IERC20(usdcAddress).transfer(address(vault), 123456 * 10**6);

        // transfer dai to rebalancer contract
        vm.prank(wethWhale);
        IERC20(wethAddress).transfer(address(vault), 50 ether);

        // transfer dai to rebalancer contract
        vm.prank(wbtcWhale);
        IERC20(wbtcAddress).transfer(address(vault), 5 * 10**8);

        // sets quote asset to weth
        reb.updateQuoteAsset(wethAddress);


        // assign tokens to vault
        address[] memory tokens = new address[](3);
        tokens[0] = wethAddress;
        tokens[1] = wbtcAddress;
        tokens[2] = usdcAddress;


        reb.updateVaultTokens(tokens);


        address[] memory _tokens = vault.getTokenAddresses();

        
        // get start reserve balances
        (uint256[] memory startReserves, uint256 startBalance) = reb.getVaultAUM(_tokens);


        // construct calldata
        uint8[] memory newRatio = new uint8[](3);
        newRatio[0] = 52;
        newRatio[1] = 45;
        newRatio[2] = 3;

        // call reblance function
        reb.updateReserveRatio(newRatio);



        // get end reserve balances
        (uint256[] memory endReserves, uint256 endBalance) = reb.getVaultAUM(_tokens);


        emit log_named_uint("Start Balance: ", startBalance);
        
        emit log_named_uint("Start WETH Balance: ", startReserves[0]);
        emit log_named_uint("Start WBTC Balance: ", startReserves[1]);
        emit log_named_uint("Start USDC Balance: ", startReserves[2]);

        emit log("");

        emit log_named_uint("End Balance: ", endBalance);
        emit log_named_uint("Start WETH Balance: ", endReserves[0]);
        emit log_named_uint("Start WBTC Balance: ", endReserves[1]);
        emit log_named_uint("Start USDC Balance: ", endReserves[2]);


        emit log("");

        emit log_named_int("Delta Balance: ", int256(endBalance) - int256(startBalance));
        emit log_named_int("Delta WETH Balance: ", int256(endReserves[0]) - int256(startReserves[0]));
        emit log_named_int("Delta WBTC Balance: ", int256(endReserves[1]) - int256(startReserves[1]));
        emit log_named_int("Delta USDC Balance: ", int256(endReserves[2]) - int256(startReserves[2]));

        emit log("");
        


        emit log("START:");
        emit log_named_uint("WETH % ",  (startReserves[0] * 10000) / startBalance);
        emit log_named_uint("WBTC % ",  (startReserves[1] * 10000) / startBalance);
        emit log_named_uint("USDC % ", (startReserves[2] * 10000) / startBalance);
        

        emit log("");

        emit log("END:");
        emit log_named_uint("WETH % ",  (endReserves[0] * 10000) / endBalance);
        emit log_named_uint("WBTC % ",  (endReserves[1] * 10000) / endBalance);
        emit log_named_uint("USDC % ", (endReserves[2] * 10000) / endBalance);


        emit log("");


        emit log("TARGET:");
        emit log_named_uint("WETH % ", newRatio[0]);
        emit log_named_uint("WBTC % ",  newRatio[1]);
        emit log_named_uint("USDC % ",  newRatio[2]);



    }


    // test for vault with 4 uncorelated assets
    function testRebalance4Assets() public {

        
        

        // transfer usdc to rebalancer contract
        vm.prank(usdcWhale);
        // IERC20(usdcAddress).transfer(address(vault), 45000 * 10**6);
        IERC20(usdcAddress).transfer(address(vault), 0);

        // transfer dai to rebalancer contract
        vm.prank(wethWhale);
        IERC20(wethAddress).transfer(address(vault), 15 ether);

        // transfer dai to rebalancer contract
        vm.prank(wbtcWhale);
        // IERC20(wbtcAddress).transfer(address(vault), 1 * 10**8); 
        IERC20(wbtcAddress).transfer(address(vault), 336789145);

        // transfer dai to rebalancer contract
        vm.prank(daiWhale);
        IERC20(daiAddress).transfer(address(vault), 3000 ether);





        // assign tokens to vault
        address[] memory tokens = new address[](4);
        tokens[0] = wethAddress;
        tokens[1] = wbtcAddress;
        tokens[2] = usdcAddress;
        tokens[3] = daiAddress;


        reb.updateVaultTokens(tokens);


        address[] memory _tokens = vault.getTokenAddresses();



        // get start reserve balances
        (uint256[] memory startReserves, uint256 startBalance) = reb.getVaultAUM(_tokens);


        // construct calldata
        uint8[] memory newRatio = new uint8[](4);


        newRatio[0] = 22;
        newRatio[1] = 18;
        newRatio[2] = 43;
        newRatio[3] = 17;


        

        // call reblance function
        reb.updateReserveRatio(newRatio);




        // get end reserve balances
        (uint256[] memory endReserves, uint256 endBalance) = reb.getVaultAUM(_tokens);


        emit log_named_uint("Start Balance: ", startBalance);
        
        emit log_named_uint("Start WETH Balance: ", startReserves[0]);
        emit log_named_uint("Start WBTC Balance: ", startReserves[1]);
        emit log_named_uint("Start USDC Balance: ", startReserves[2]);
        emit log_named_uint("Start DAI Balance: ", startReserves[3]);

        emit log("");

        emit log_named_uint("End Balance: ", endBalance);
        emit log_named_uint("Start WETH Balance: ", endReserves[0]);
        emit log_named_uint("Start WBTC Balance: ", endReserves[1]);
        emit log_named_uint("Start USDC Balance: ", endReserves[2]);
        emit log_named_uint("Start DAI Balance: ", endReserves[3]);


        emit log("");

        emit log_named_int("Delta Balance: ", int256(endBalance) - int256(startBalance));
        emit log_named_int("Delta WETH Balance: ", int256(endReserves[0]) - int256(startReserves[0]));
        emit log_named_int("Delta WBTC Balance: ", int256(endReserves[1]) - int256(startReserves[1]));
        emit log_named_int("Delta USDC Balance: ", int256(endReserves[2]) - int256(startReserves[2]));
        emit log_named_int("Delta DAI Balance: ", int256(endReserves[3]) - int256(startReserves[3]));

        emit log("");
        


        emit log("START:");
        emit log_named_uint("WETH % ",  (startReserves[0] * 10000) / startBalance);
        emit log_named_uint("WBTC % ",  (startReserves[1] * 10000) / startBalance);
        emit log_named_uint("USDC % ", (startReserves[2] * 10000) / startBalance);
        emit log_named_uint("DAI % ", (startReserves[3] * 10000) / startBalance);

        

        emit log("");

        emit log("END:");
        emit log_named_uint("WETH % ",  (endReserves[0] * 10000) / endBalance);
        emit log_named_uint("WBTC % ",  (endReserves[1] * 10000) / endBalance);
        emit log_named_uint("USDC % ", (endReserves[2] * 10000) / endBalance);
        emit log_named_uint("DAI % ", (endReserves[3] * 10000) / endBalance);


        emit log("");


        emit log("TARGET:");
        emit log_named_uint("WETH % ", newRatio[0]);
        emit log_named_uint("WBTC % ",  newRatio[1]);
        emit log_named_uint("USDC % ",  newRatio[2]);
        emit log_named_uint("DAI % ",  newRatio[3]);

    }


    // test for vault with 5 uncorrelated assets
    function testRebalance5Assets() public {

        
        

        // transfer usdc to rebalancer contract
        vm.prank(usdcWhale);
        IERC20(usdcAddress).transfer(address(vault), 45000 * 10**6);
        // IERC20(usdcAddress).transfer(address(vault), 0);

        // transfer dai to rebalancer contract
        vm.prank(wethWhale);
        IERC20(wethAddress).transfer(address(vault), 15 ether);

        // transfer dai to rebalancer contract
        vm.prank(wbtcWhale);
        IERC20(wbtcAddress).transfer(address(vault), 1 * 10**8); // 336789145

        // transfer dai to rebalancer contract
        vm.prank(daiWhale);
        IERC20(daiAddress).transfer(address(vault), 3000 ether);

        

        // transfer dai to rebalancer contract
        vm.prank(linkWhale);

        IERC20(linkAddress).transfer(address(vault), 10000 ether);




        // assign tokens to vault
        address[] memory tokens = new address[](5);
        tokens[0] = wethAddress;
        tokens[1] = wbtcAddress;
        tokens[2] = usdcAddress;
        tokens[3] = linkAddress;
        tokens[4] = daiAddress;


        reb.updateVaultTokens(tokens);


        address[] memory _tokens = vault.getTokenAddresses();


        // get start reserve balances
        (uint256[] memory startReserves, uint256 startBalance) = reb.getVaultAUM(_tokens);



        // construct calldata
        uint8[] memory newRatio = new uint8[](5);


        newRatio[0] = 15;
        newRatio[1] = 25;
        newRatio[2] = 33;
        newRatio[3] = 17;
        newRatio[4] = 10;

        

        // call reblance function
        reb.updateReserveRatio(newRatio);




        // get end reserve balances
        (uint256[] memory endReserves, uint256 endBalance) = reb.getVaultAUM(_tokens);


        emit log_named_uint("Start Balance: ", startBalance);
        
        emit log_named_uint("Start WETH Balance: ", startReserves[0]);
        emit log_named_uint("Start WBTC Balance: ", startReserves[1]);
        emit log_named_uint("Start USDC Balance: ", startReserves[2]);
        emit log_named_uint("Start LINK Balance: ", startReserves[3]);
        emit log_named_uint("Start DAI Balance: ", startReserves[4]);

        emit log("");

        emit log_named_uint("End Balance: ", endBalance);
        emit log_named_uint("Start WETH Balance: ", endReserves[0]);
        emit log_named_uint("Start WBTC Balance: ", endReserves[1]);
        emit log_named_uint("Start USDC Balance: ", endReserves[2]);
        emit log_named_uint("Start LINK Balance: ", endReserves[3]);
        emit log_named_uint("Start DAI Balance: ", endReserves[4]);


        emit log("");

        emit log_named_int("Delta Balance: ", int256(endBalance) - int256(startBalance));
        emit log_named_int("Delta WETH Balance: ", int256(endReserves[0]) - int256(startReserves[0]));
        emit log_named_int("Delta WBTC Balance: ", int256(endReserves[1]) - int256(startReserves[1]));
        emit log_named_int("Delta USDC Balance: ", int256(endReserves[2]) - int256(startReserves[2]));
        emit log_named_int("Delta LINK Balance: ", int256(endReserves[3]) - int256(startReserves[3]));
        emit log_named_int("Delta DAI Balance: ", int256(endReserves[4]) - int256(startReserves[4]));

        emit log("");
        


        emit log("START:");
        emit log_named_uint("WETH % ",  (startReserves[0] * 10000) / startBalance);
        emit log_named_uint("WBTC % ",  (startReserves[1] * 10000) / startBalance);
        emit log_named_uint("USDC % ", (startReserves[2] * 10000) / startBalance);
        emit log_named_uint("LINK % ", (startReserves[3] * 10000) / startBalance);
        emit log_named_uint("DAI % ", (startReserves[4] * 10000) / startBalance);
        

        emit log("");

        emit log("END:");
        emit log_named_uint("WETH % ",  (endReserves[0] * 10000) / endBalance);
        emit log_named_uint("WBTC % ",  (endReserves[1] * 10000) / endBalance);
        emit log_named_uint("USDC % ", (endReserves[2] * 10000) / endBalance);
        emit log_named_uint("LINK % ", (endReserves[3] * 10000) / endBalance);
        emit log_named_uint("DAI % ", (endReserves[4] * 10000) / endBalance);


        emit log("");


        emit log("TARGET:");
        emit log_named_uint("WETH % ", newRatio[0]);
        emit log_named_uint("WBTC % ",  newRatio[1]);
        emit log_named_uint("USDC % ",  newRatio[2]);
        emit log_named_uint("LINK % ",  newRatio[3]);
        emit log_named_uint("DAI % ",  newRatio[4]);



    }


    
    // test for update router to sushiswap vault with 2 uncorrelated assets
    function testMakeSushiRouterRebalance2Assets() public {
        

        // transfer usdc to rebalancer contract
        vm.prank(usdcWhale);
        IERC20(usdcAddress).transfer(address(vault), 2 * 10**8);

        // transfer dai to rebalancer contract
        vm.prank(wethWhale);
        IERC20(wethAddress).transfer(address(vault), 30 ether);
        // IERC20(wethAddress).transfer(address(vault), 0 ether);


        // assign tokens to vault
        address[] memory tokens = new address[](2);
        tokens[0] = usdcAddress;
        tokens[1] = wethAddress;


        reb.updateVaultTokens(tokens);
        reb.updateRouterAddress(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);


        address[] memory _tokens = vault.getTokenAddresses();


        // get start reserve balances
        (uint256[] memory startReserves, uint256 startBalance) = reb.getVaultAUM(_tokens);



        // construct calldata
        uint8[] memory newRatio = new uint8[](2);
        newRatio[0] = 50;
        newRatio[1] = 50;


        // call reblance function
        reb.updateReserveRatio(newRatio);



        // get end reserve balances
        (uint256[] memory endReserves, uint256 endBalance) = reb.getVaultAUM(_tokens);


        emit log_named_uint("Start Balance: ", startBalance);
        emit log_named_uint("Start USDC Balance: ", startReserves[0]);
        emit log_named_uint("Start WETH Balance: ", startReserves[1]);

        emit log("");

        emit log_named_uint("End Balance: ", endBalance);
        emit log_named_uint("End USDC Balance: ", endReserves[0]);
        emit log_named_uint("End WETH Balance: ", endReserves[1]);


        emit log("");

        emit log_named_int("Delta Balance: ", int256(endBalance) - int256(startBalance));
        emit log_named_int("Delta USDC Balance: ", int256(endReserves[0]) - int256(startReserves[0]));
        emit log_named_int("Delta WETH Balance: ", int256(endReserves[1]) - int256(startReserves[1]));

        emit log("");
        


        emit log("START:");
        emit log_named_uint("USDC % ", (startReserves[0] * 10000) / startBalance);
        emit log_named_uint("WETH % ",  (startReserves[1] * 10000) / startBalance);

        emit log("");

        emit log("END:");
        emit log_named_uint("USDC % ", (endReserves[0] * 10000) / endBalance);
        emit log_named_uint("WETH % ",  (endReserves[1] * 10000) / endBalance);


        emit log("");


        emit log("TARGET:");
        emit log_named_uint("USDC % ", newRatio[0]);
        emit log_named_uint("WETH % ",  newRatio[1]);



    }



    




}
    