pragma solidity^0.8.17;

interface IVault {
    function addLiquidity(address _inputToken, uint256 _amountIn) external;
    function withdrawLiquidity(address _tokenOut, uint256 _amountOut, address _reciever) external;
    function updateTokenAddresses(address[] calldata _newTokenAddresses) external;
    function updateAdmin(address _newAdmin) external;
    function getReserves() external view returns(uint256[] memory, uint256);
    function getTokenAddresses() external view returns (address[] memory);
}