// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IKyberStorage {
    function getReserveIdsPerTokenSrc(IERC20 token) external view returns (bytes32[] memory);
    function getReserveAddressesByReserveId(bytes32 reserveId) external view returns (IKyberReserve[] memory reserveAddresses);
}


interface IKyberReserve {
    function getConversionRate(IERC20 src, IERC20 dest, uint srcQty, uint blockNumber) external view returns(uint);
}


interface IKyberHintHandler {
    enum TradeType {
        BestOfAll,
        MaskIn,
        MaskOut,
        Split
    }

    function buildTokenToEthHint(
        IERC20 tokenSrc,
        TradeType tokenToEthType,
        bytes32[] calldata tokenToEthReserveIds,
        uint256[] calldata tokenToEthSplits
    ) external view returns (bytes memory hint);

    function buildEthToTokenHint(
        IERC20 tokenDest,
        TradeType ethToTokenType,
        bytes32[] calldata ethToTokenReserveIds,
        uint256[] calldata ethToTokenSplits
    ) external view returns (bytes memory hint);
}


interface IKyberNetworkProxy {
    function getExpectedRateAfterFee(
        IERC20 src,
        IERC20 dest,
        uint256 srcQty,
        uint256 platformFeeBps,
        bytes calldata hint
    ) external view returns (uint256 expectedRate);

    function tradeWithHintAndFee(
        IERC20 src,
        uint256 srcAmount,
        IERC20 dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable platformWallet,
        uint256 platformFeeBps,
        bytes calldata hint
    ) external payable returns (uint256 destAmount);
}
