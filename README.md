# hashnote_excercise

```Rebalancer.sol``` is a smart contract that uses UniswapV2 to rebalance assets stored in ```Vault.sol```.

## Design Choice

UniswapV2 was chosen over UniswapV3 for 2 reasons. The first reason is because UniswapV2 is more gass efficient to quote prices on chain. The second reason is beacuse many projects have forked UniswapV2's code. This allows the admin of ```Rebalancer.sol``` to use a variety of DEXs to rebalance the vault if they find liquidity has dried up on UniswapV2. In production I would consider performing most of the calculations with UniswapV3 off chain to save on gas costs. However if on chain transparency is a priority, I believe the current model works the best.


## Vault.sol
```Vault.sol``` is a simple vault smart contract that custodies assets. The following describes the ABI of ```Vault.sol```: <br>

```address[] public tokenAddresses```: An array of addresses that the vault uses to store the official tokens in the vault. <br>
```address public admin```: The admin of the vault is in charge of accessing all non-view functions. This is a security measure to keep the assets safe. <br>
```addLiquidity(address _inputToken, uint256 _amountIn) external```: This is a simple function that allows the admin to add liquidity to the vault. <br>

```withdrawLiquidity(address _tokenOut, uint256 _amountOut, address _reciever) external```: Allows the admin to withdraw tokens from the vault. <br>
```updateTokenAddresses(address[] calldata _newTokenAddresses) external```: Allows the admin to update the tokens in the vault by passing in an array of tokens. Note that the admin must include tokens previously stored in the vault, when calling this function, for them to be included. <br>
```function getReserves() external view returns(uint256[] memory)```: This function allows a user to view the reserves of tokens stored in the vault. <br>
```function getTokenAddresses() external view returns (address[] memory) ```: This function allows a user to view the token addresses of official tokens stored in the vault. <br>


## Rebalancer.sol
```Reabalancer.sol```'s main functionality is to keep ```Vaul.sol```'s tokens in a desired ratio. For ```Reabalancer.sol``` to work properly, it must be the admin of ```Vault.sol```. The following describes the ABI of ```Rebalancer.sol```: <br>

```address public uniV2RouterAddress```: The address of the UniswapV2 router contract. Note this does not have to be Uniswap's router address and can be from any DEX that forked UniswapV2. <br>
```address public vaultAddress```: The address of ```Vault.sol```. <br>
```address public admin```: The admin of ```Rebalancer.sol```. <br>
```address public quoteAssetAddress```: The address of the quote currency used in ```Rebalancer.sol```. <br>
```PreTradeData.tokenIndex```: A uint256 representing the index of a token in ```Vault.sol```'s ```tokenAddresses```. <br>
```PreTradeData.amount```: A uint256 that represents the amount of a token that is required to either be bought or sold. <br>
```TradeParams.amountIn```: A uint256 representing the amount of tokens needed to be sold for a swap. <br>
```TradeParams.tokenIn```: An address representing the token that is being swaped in a swap. <br>
```TradeParams.tokenOut```: An address representing the token that is being purchased in a swap.<br>

```function getVaultAUM(address[] memory _tokens) public returns (uint256[] memory, uint256)```: Given the input of tokens stored in ```Vault.sol```, this function calculates the balances per token and AUM of ```Vault.sol```. This function denominates AUM and balances in terms of the quote currency. <br>
```function uniV2QuotePrice(uint256 _amountIn, address[] memory _path) internal view returns (uint256)```: Given an input amount and path for swap, this function returns the swap price for a trade. <br>
```function uniV2RouteSwapPrice(uint256 _amountIn, address[] memory _path) internal view returns (uint256, address[] memory)```: This function acts similarly to ```uniV2QuotePrice()```, but we additionaly check for an alternative price using the quote currency as an intermediary swap. It is only utlilized in ```executeSwap()``` and contributes to a more precise swap execution. <br>
```function convertQuoteToBase(uint256 _amountOut, address _token) internal returns (uint256)```: Since AUM is denominated in the quote currency, we use this function to get the balance of an asset in its native currency. This is utilized in ```executeSwap()```. <br>
```function executeSwap(uint256 _amountIn, address _tokenIn, address _tokenOut) private```: This function executes a swap on UniswapV2 given an amout to swap, the token that needs to be swapped, and the token that is being swapped into. <br>
```function updateReserveRatio(uint8[] calldata _reserveRatios) external```: This function must be called by the admin. It rebalances ```Vault.sol``` by calling various helper functions. The input is an array representing the percentage of the corresponding tokens in ```Vault.sol```. The percentage must be a whole number. <br>
```function calculateTradeOrders(uint8[] calldata _reserveRatios, uint256[] memory _balances, uint256 _aum) private pure returns```: This helper function calculates the amount each asset must either be bought or sold in order to rebalance ```Vault.sol```. It returns 2 arrays of ```PreTradeData``` representing bids and asks. <br>
```function constructTradeParams(PreTradeData[] memory _buys, PreTradeData[] memory _sells, address[] memory _tokens) private pure returns(TradeParams[] memory)```: Given the ouput of ```calculateTradeOrders()```, this function matchs bids and asks to return an array of ```TradeParams``` used by ```executeSwap()```. <br>
```function updateVaultTokens(address[] calldata _newTokenAddresses) external```: Since ```Rebalancer.sol``` is the admin of ```Vault.sol```, we use this function to update the vault's tokens. It can only be called by the admin. <br>
```function updateQuoteAsset(address _newQuoteAsset) external```: This function updates the quote currency. It must be called by the admin. <br>
```function updateRouterAddress(address _newRouter) external```: This function updates the router contract address. It can only be called by the admin. <br>
```function updateVaultAdmin(address _newAdmin) external```: This function can only be called by the admin. It updates the admin of ```Vault.sol```.
```function updateAdmin(address _newAdmin) external```: This function, only callable by the admin, allows us to update the admin of ```Rebalancer.sol```.
