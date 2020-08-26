// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./IOneRouterView.sol";


interface IKyberReserve {
    function getConversionRate(
        IERC20 src,
        IERC20 dst,
        uint256 srcQty,
        uint256 blockNumber
    ) external view returns(uint);

    function trade(
        IERC20 srcToken,
        uint256 srcAmount,
        IERC20 dstToken,
        address destAddress,
        uint256 conversionRate,
        bool validate
    ) external payable returns(bool);
}


contract KyberMooniswapReserve {

}
