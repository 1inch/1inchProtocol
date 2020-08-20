// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IUniswapV1.sol";
import "../IOneRouter.sol";
import "../ISource.sol";

import "../libraries/UniERC20.sol";


contract UniswapV1SourceView {
    using SafeMath for uint256;
    using UniERC20 for IERC20;

    IUniswapV1Factory constant private _FACTORY = IUniswapV1Factory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);

    function _calculateUniswap1Formula(uint256 fromBalance, uint256 toBalance, uint256 amount) private pure returns(uint256) {
        if (amount > 0) {
            return amount.mul(toBalance).mul(997).div(
                fromBalance.mul(1000).add(amount.mul(997))
            );
        }
    }

    function _calculateUniswapV1(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) internal view returns(uint256[] memory rets, address dex, uint256 gas) {
        rets = new uint256[](amounts.length);

        if (fromToken.isETH() || swap.destToken.isETH()) {
            IUniswapV1Exchange exchange = _FACTORY.getExchange(fromToken.isETH() ? swap.destToken : fromToken);
            if (exchange != IUniswapV1Exchange(0)) {
                uint256 fromBalance = fromToken.uniBalanceOf(address(exchange));
                uint256 destBalance = swap.destToken.uniBalanceOf(address(exchange));
                for (uint i = 0; i < amounts.length; i++) {
                    rets[i] = _calculateUniswap1Formula(fromBalance, destBalance, amounts[i]);
                }
                return (rets, address(exchange), 60_000);
            }
        }
    }
}


contract UniswapV1SourceSwap {
    using UniERC20 for IERC20;

    IUniswapV1Factory constant private _FACTORY = IUniswapV1Factory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);

    function _swapOnUniswapV1(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        IUniswapV1Exchange exchange = _FACTORY.getExchange(fromToken.isETH() ? destToken : fromToken);
        fromToken.uniApprove(address(exchange), amount);
        if (fromToken.isETH()) {
            exchange.tokenToEthSwapInput(amount, 1, block.timestamp);
        } else {
            exchange.ethToTokenSwapInput{ value: amount }(1, block.timestamp);
        }
    }
}


contract UniswapV1SourcePublic is ISource, UniswapV1SourceView, UniswapV1SourceSwap {
    function calculate(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap) public view override returns(uint256[] memory rets, address dex, uint256 gas) {
        return _calculateUniswapV1(fromToken, amounts, swap);
    }

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) public override {
        return _swapOnUniswapV1(fromToken, destToken, amount, flags);
    }
}
