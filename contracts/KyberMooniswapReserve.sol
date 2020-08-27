// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./IOneRouterView.sol";
import "./libraries/UniERC20.sol";
import "./sources/MooniswapSource.sol";


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
        address payable destAddress,
        uint256 conversionRate,
        bool validate
    ) external payable returns(bool);
}


contract KyberMooniswapReserve is IKyberReserve, MooniswapSourceView, MooniswapSourceSwap {
    using UniERC20 for IERC20;

    address public constant KYBER_NETWORK = 0x7C66550C9c730B6fdd4C03bc2e73c5462c5F7ACC;

    function getConversionRate(
        IERC20 src,
        IERC20 dst,
        uint256 srcQty,
        uint256 /*blockNumber*/
    ) external view override returns(uint256) {
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = srcQty;
        (uint256[] memory results,,) = _calculateMooniswap(src, amounts, IOneRouterView.Swap({
            destToken: dst,
            flags: 0,
            destTokenEthPriceTimesGasPrice: 0,
            disabledDexes: new address[](0)
        }));
        if (results.length == 0 || results[0] == 0) {
            return 0;
        }

        return _convertAmountToRate(src, dst, results[0]);
    }

    function trade(
        IERC20 src,
        uint256 srcAmount,
        IERC20 dst,
        address payable destAddress,
        uint256 conversionRate,
        bool validate
    ) external payable override returns(bool) {
        require(msg.sender == KYBER_NETWORK, "Access denied");

        src.uniTransferFromSender(payable(address(this)), srcAmount);
        if (validate) {
            require(conversionRate > 0, "Wrong conversionRate");
            if (src.isETH()) {
                require(msg.value == srcAmount, "Wrong msg.value or srcAmount");
            } else {
                require(msg.value == 0, "Wrong non zero msg.value");
            }
        }

        _swapOnMooniswapRef(src, dst, srcAmount, 0, 0x8180a5CA4E3B94045e05A9313777955f7518D757);

        uint256 returnAmount = dst.uniBalanceOf(address(this));
        uint256 actualRate = _convertAmountToRate(src, dst, returnAmount);
        require(actualRate <= conversionRate, "Rate exceeded conversionRate");

        dst.uniTransfer(destAddress, returnAmount);
        return true;
    }

    function _convertAmountToRate(IERC20 src, IERC20 dst, uint256 amount) private view returns(uint256) {
        return amount.mul(1e18)
            .mul(10 ** src.uniDecimals())
            .div(10 ** dst.uniDecimals());
    }
}
