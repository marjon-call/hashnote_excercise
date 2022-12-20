# hashnote_excercise

```Rebalancer.sol``` is a smart contract that uses UniswapV2 to rebalance assets stored in ```Vault.sol```.

## Design Choice

UniswapV2 was chosen over UniswapV3 for 2 reasons. The first reason is because UniswapV2 is more gass efficient to quote prices on chain. The second reason is beacuse many projects have forked UniswapV2's code. This allows the admin of ```Rebalancer.sol``` to use numerous DEXs to rebalance the vault if they find liquidity has dired up on UniswapV2. 
