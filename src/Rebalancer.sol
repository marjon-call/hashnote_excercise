pragma solidity^0.8.17;


import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./interfaces/IVault.sol";
import "./interfaces/IERC20.sol";


contract Rebalancer {

    address public uniV2RouterAddress;
    address public vaultAddress;
    address public admin;
    address public quoteAssetAddress;


    struct PreTradeData {
        uint256 tokenIndex;
        uint256 amount;
    }

    struct TradeParams {
        uint256 amountIn;
        address tokenIn;
        address tokenOut;
    }



    constructor(address _vaultAddress, address _admin, address _quoteAsset, address _routerAddress) {
        vaultAddress = _vaultAddress;
        admin = _admin;
        quoteAssetAddress = _quoteAsset;
        uniV2RouterAddress = _routerAddress;
    }


    
    // function to calculate AUM and current positons for each token
    function getVaultAUM(address[] memory _tokens) public returns (uint256[] memory, uint256) {

        // gas optimizations
        uint256 tokensInVault = _tokens.length;
        uint256 i;
        address _vault = vaultAddress;
        address _quoteAsset = quoteAssetAddress;
        uint256 quoteDecimals = 10**IERC20(_quoteAsset).decimals();

        // initialize return variables
        uint256[] memory tokenBalances = new uint256[](tokensInVault);
        uint256 aum;

        // cosntructs memory array of swap path
        address[] memory _path = new address[](2);
        _path[1] = _quoteAsset;
        

        // loops through tokens to calculate balances
        for (i; i < tokensInVault; ++i) {

            uint256 quantity = IERC20(_tokens[i]).balanceOf(_vault);

            // avoids uniswap revert
            if (quantity == 0) {
                tokenBalances[i] = 0;
                continue;
            }

            // for quote currency theres no need to get the price of the asset
            if (_tokens[i] == _quoteAsset) {
                tokenBalances[i] = quantity / quoteDecimals;
                aum += tokenBalances[i];
                continue;
            }

            _path[0] = _tokens[i];
            
            // calculates token position denominated in quote curreny and updates AUM
            uint256 price = uniV2QuotePrice(quantity, _path);
            tokenBalances[i] = price / quoteDecimals;
            aum += tokenBalances[i];
        }


        return (tokenBalances, aum);
    }


    // gets amount out for uniswapV2 pair
    function uniV2QuotePrice(uint256 _amountIn, address[] memory _path) internal view returns (uint256) {
        uint256[] memory prices = IUniswapV2Router02(uniV2RouterAddress).getAmountsOut(_amountIn, _path);
        return prices[1];
    }


    // used during executeSwap() to provide a more precise execution price
    // if neither token is the quote token we check for a better price using the quote token as an intermediary swap
    function uniV2RouteSwapPrice(uint256 _amountIn, address[] memory _path) internal view returns (uint256, address[] memory) {

        IUniswapV2Router02 routerV2 = IUniswapV2Router02(uniV2RouterAddress); 

        // gets quoted price from direct swap 
        uint256[] memory prices = routerV2.getAmountsOut(_amountIn, _path);
        uint256 price = prices[1];


        
        // checks if quoted asset already in swap path
        if (_path[0] != quoteAssetAddress && _path[1] != quoteAssetAddress) {

            // constructs new swap path
            address[] memory _path2 = new address[](3);
            _path2[0] = _path[0];
            _path2[1] = quoteAssetAddress;
            _path2[2] = _path[1];

            uint256[] memory prices2 = routerV2.getAmountsOut(_amountIn, _path2);

            // checks which swap has a better execution price
            if(prices2[2] > price) {
                return (prices2[2], _path2);
            }
        }

        return (prices[1], _path);
    }


    // used to convert tokens balance from being denominated in quote asset to original token
    function convertQuoteToBase(uint256 _amountOut, address _token) internal returns (uint256) {
        // cosntructs memory array of swap path
        address[] memory _path = new address[](2);
        _path[0] = _token;
        _path[1] = quoteAssetAddress;

        _amountOut *= 10**IERC20(quoteAssetAddress).decimals();
        uint256[] memory prices = IUniswapV2Router02(uniV2RouterAddress).getAmountsIn(_amountOut, _path);
        return prices[0];
    }


    // executes ERC20 swap on uniswap V2
    function executeSwap(uint256 _amountIn, address _tokenIn, address _tokenOut) private {

        // cosntructs memory array of swap path
        address[] memory _path = new address[](2);
        _path[0] = _tokenIn;
        _path[1] = _tokenOut;


        uint256 _amountInNativeAsset;

        
        if(_tokenIn == quoteAssetAddress) {
            // if quote currency ignore conversion
            _amountInNativeAsset = _amountIn * 10**IERC20(quoteAssetAddress).decimals();
        } else {
            // since AUM is denominated in quote currency we need to convert amount back to native asset before swap
            _amountInNativeAsset = convertQuoteToBase(_amountIn, _tokenIn);
        }


        // calls router quote price function to get _amountOutMin for swap
       (uint256 _amountOut, address[] memory _pathForSwap) = uniV2RouteSwapPrice(_amountInNativeAsset, _path);


        // withdraw liquidity from vault
        IVault vault = IVault(vaultAddress);
        vault.withdrawLiquidity(_tokenIn, _amountInNativeAsset, address(this));


        // approve router contract to spend tokens
        IERC20(_tokenIn).approve(uniV2RouterAddress, _amountInNativeAsset);

        // executes swap
        IUniswapV2Router02(uniV2RouterAddress).swapExactTokensForTokens(_amountInNativeAsset, _amountOut, _pathForSwap, vaultAddress, block.timestamp + 300); 

    }


    // function to update reserve balances of vault
    function updateReserveRatio(uint8[] calldata _reserveRatios) external {
        require(msg.sender == admin, "Rebalancer: Unauthorized user.");

        IVault vault = IVault(vaultAddress);

        // gets current vault tokens
        address[] memory _tokens = vault.getTokenAddresses();

        require(_reserveRatios.length == _tokens.length, "Rebalancer: Ratio's length do not match token's length.");


        // gets current vault reserves
        (uint256[] memory _balances, uint256 _aum) = getVaultAUM(_tokens);


        // calculate actions required to balance vault
        (PreTradeData[] memory _buys, PreTradeData[] memory _sells) = calculateTradeOrders(_reserveRatios, _balances, _aum);


        // match trade orders and create trade data
        TradeParams[] memory trades = constructTradeParams(_buys, _sells, _tokens);

        uint256 tradesLength = trades.length;
        uint256 i;

        for (i; i < tradesLength; ++i) {
            if(trades[i].amountIn == 0) {
                break;
            }

            executeSwap(trades[i].amountIn, trades[i].tokenIn, trades[i].tokenOut);

        }

    }



    // function to calculate how much the vault reserves need to be updated. Additionally, organizes tokens in buy and sell category
    function calculateTradeOrders(uint8[] calldata _reserveRatios, uint256[] memory _balances, uint256 _aum) private pure returns (PreTradeData[] memory, PreTradeData[] memory) {

        // gas optimization for for loop
        uint256 i;
        uint256 len = _reserveRatios.length;

        
        // keep track of buy and sell data
        PreTradeData[] memory buys = new PreTradeData[](len);
        PreTradeData[] memory sells = new PreTradeData[](len);

        uint256 buysIndex;
        uint256 sellsIndex;

        uint256 ratioTotal;


        // loop through ratios, find buy and sell amounts, store in struct
        for (i; i < len; ++i) {

            uint256 trgt = (_aum * _reserveRatios[i]) / 100;

            if (trgt < _balances[i]) { 
                // sell 
                sells[sellsIndex] = PreTradeData(i, (_balances[i] - trgt));
                ++sellsIndex;
            } else if(trgt > _balances[i]) { 
                // buy
                buys[buysIndex] = PreTradeData(i, (trgt - _balances[i]));
                ++buysIndex;
            }

            ratioTotal += _reserveRatios[i];

        }

        require(ratioTotal == 100, "Rebalancer: Ratio proportions do not add up to 100%.");


        return (buys, sells);
        
    }


    // function to match buy and sell orders to construct trade data
    function constructTradeParams(PreTradeData[] memory _buys, PreTradeData[] memory _sells, address[] memory _tokens) private pure returns(TradeParams[] memory) {

        uint256 i;
        uint256 j;
        uint256 tradeIndex;
        uint256 len = _buys.length;


        // array of trades needed to balance vault
        TradeParams[] memory trades = new TradeParams[](len);
        

        // loop through sells
        for (i; i < len; ++i) {

            uint256 sellAmount = _sells[i].amount;

            // if not action skip
            if (sellAmount == 0) {
                continue; 
            }

            
            // loop through buys
            for (j; j < len; ++j) {

                uint256 buyAmount = _buys[j].amount;

                // if no action skip
                if (buyAmount == 0) {
                    continue;
                }

                // buy trade order gets filled to completion
                if (sellAmount >= buyAmount) {

                    sellAmount -= buyAmount;
                    _buys[j].amount = 0;

                    // constructs trade order
                    trades[tradeIndex] = TradeParams(buyAmount, _tokens[_sells[i].tokenIndex], _tokens[_buys[j].tokenIndex]);
                    ++tradeIndex;

                } else {
                    // sell trade order gets filled to completion

                    // exit loop if no more matching neccisary
                    if (sellAmount == 0) {
                        break;
                    }

                    _buys[j].amount -= sellAmount;

                    // constructs trade amounts
                    trades[tradeIndex] = TradeParams(sellAmount, _tokens[_sells[i].tokenIndex], _tokens[_buys[j].tokenIndex]);
                    ++tradeIndex;

                    break;
                }

            }

            j = 0;

        }

        return trades;

    }


    // updates tokens in vault
    function updateVaultTokens(address[] calldata _newTokenAddresses) external {
        require(msg.sender == admin, "Rebalancer: Unauthorized user.");
        IVault(vaultAddress).updateTokenAddresses(_newTokenAddresses);
    }


    // function to update quote asset
    function updateQuoteAsset(address _newQuoteAsset) external {
        require(msg.sender == admin, "Rebalancer: Unauthorized user.");
        require(_newQuoteAsset != address(0), "Rebalancer: Can not make 0 address quote asset");
        quoteAssetAddress = _newQuoteAsset;
    }


    // function to upgrade pool Address
    function updateRouterAddress(address _newRouter) external {
        require(msg.sender == admin, "Rebalancer: Unauthorized user.");
        require(_newRouter != address(0), "Rebalancer: Can not make 0 address new router");
        uniV2RouterAddress = _newRouter;
    }


    // function to upgrade vault admin
    function updateVaultAdmin(address _newAdmin) external {
        require(msg.sender == admin, "Rebalancer: Unauthorized user.");
        IVault(vaultAddress).updateAdmin(_newAdmin);
    }
    

    // function to update rebalancer admin
    function updateAdmin(address _newAdmin) external {
        require(msg.sender == admin, "Rebalancer: Unauthorized user.");
        require(_newAdmin != address(0), "Rebalancer: Can not make 0 address admin");
        admin = _newAdmin;
    }



}

