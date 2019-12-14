pragma solidity ^0.5.0;

import "./IKyberNetworkContract.sol";


interface IKyberNetworkProxy {

    function getExpectedRate(
        IERC20 src,
        IERC20 dest,
        uint256 srcQty
    ) external view returns(uint256 expectedRate, uint256 slippageRate);

    function tradeWithHint(
        IERC20 src,
        uint256 srcAmount,
        IERC20 dest,
        address destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address walletId,
        bytes calldata hint
    ) external payable returns(uint256);

    function kyberNetworkContract() external view returns (IKyberNetworkContract);

    // TODO: Limit usage by tx.gasPrice
    // function maxGasPrice() external view returns (uint256);

    // TODO: Limit usage by user cap
    // function getUserCapInWei(address user) external view returns (uint256);
    // function getUserCapInTokenWei(address user, IERC20 token) external view returns (uint256);
}
