pragma solidity^0.8.17;


import "./interfaces/IERC20.sol";


contract Vault {

    address[] public tokenAddresses;
    address public admin;

   
    constructor(address _admin) {
        admin = _admin;
    }


    // adds liquidity to the vault
    function addLiquidity(address _inputToken, uint256 _amountIn) external {
        // possibly add require to limit max token balance
        IERC20(_inputToken).transferFrom(msg.sender, address(this), _amountIn);
    }


    // withrdraws liquidity from vault
    function withdrawLiquidity(address _tokenOut, uint256 _amountOut, address _reciever) external {
        require(msg.sender == admin, "Vault: Unauthorized user.");
        IERC20(_tokenOut).transfer(_reciever, _amountOut);
    }


    // updates tokens in vault
    function updateTokenAddresses(address[] calldata _newTokenAddresses) external {
        require(msg.sender == admin, "Vault: Unauthorized user.");
        tokenAddresses = _newTokenAddresses;
    }

    
    // updates admin
    function updateAdmin(address _newAdmin) external {
        require(msg.sender == admin, "Vault: Unauthorized user.");
        require(_newAdmin != address(0), "Vault: Can not make 0 address admin");
        admin = _newAdmin;
    }


    // function to get current reserves of vault
    function getReserves() external view returns(uint256[] memory) {
        // gas optimization for for loop
        address[] memory _tokenAddresses = tokenAddresses;
        uint256 i;
        uint256 tokensInVault = tokenAddresses.length;

        uint256[] memory balances = new uint256[](tokensInVault);

        // itterates tokens to get balances and total balance
        for (i; i < tokensInVault; ++i) {
            balances[i] = IERC20(_tokenAddresses[i]).balanceOf(address(this));
        }

        return balances;

    }


    // function to get vault tokens
    function getTokenAddresses() external view returns (address[] memory) {
        return tokenAddresses;
    }


}
