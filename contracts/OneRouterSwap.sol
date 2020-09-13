// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./libraries/Address2.sol";

import "./sources/UniswapV1Source.sol";
import "./sources/UniswapV2Source.sol";
import "./sources/MooniswapSource.sol";
import "./sources/KyberSource.sol";
import "./sources/CurveSource.sol";
// import "./sources/BalancerSource.sol";

import "./IOneRouterSwap.sol";
import "./OneRouterAudit.sol";
import "./HotSwapSources.sol";


contract OneRouterSwap is
    OneRouterConstants,
    OneRouterAudit,
    HotSwapSources,
    UniswapV1SourceSwap,
    UniswapV2SourceSwap,
    MooniswapSourceSwap,
    KyberSourceSwap,
    CurveSourceSwap
    // BalancerSourceSwap
{
    using UniERC20 for IERC20;
    using SafeMath for uint256;
    using Address2 for address;
    using FlagsChecker for uint256;

    constructor(IOneRouterView _oneRouterView)
        public
        OneRouterAudit(_oneRouterView, IOneRouterSwap(0))
    {
    }

    // Internal methods

    function _makeSwap(
        SwapInput memory input,
        IOneRouterView.Swap memory swap,
        SwapDistribution memory swapDistribution
    )
        internal
        override
    {
        function(IERC20,IERC20,uint256,uint256)[16] memory reserves = [
            _swapOnUniswapV1,
            _swapOnUniswapV2,
            _swapOnMooniswap,
            _swapOnKyber1,
            _swapOnKyber2,
            _swapOnKyber3,
            _swapOnKyber4,
            _swapOnCurveCompound,
            _swapOnCurveUSDT,
            _swapOnCurveY,
            _swapOnCurveBinance,
            _swapOnCurveSynthetix,
            _swapOnCurvePAX,
            _swapOnCurveRENBTC,
            _swapOnCurveSBTC,
            _swapOnCurve3pool
            // _swapOnBalancer1,
            // _swapOnBalancer2,
            // _swapOnBalancer3,
            // _swapOnBancor,
            // _swapOnOasis,
            // _swapOnDforceSwap,
            // _swapOnShell,
            // _swapOnMStableMUSD,
            // _swapOnBlackHoleSwap
        ];

        uint256 totalWeight = 0;
        for (uint i = 0; i < swapDistribution.weights.length; i++) {
            totalWeight = totalWeight.add(swapDistribution.weights[i]);
        }

        for (uint i = 0; i < swapDistribution.weights.length && totalWeight > 0; i++) {
            uint256 amount = input.amount.mul(swapDistribution.weights[i]).div(totalWeight);
            totalWeight = totalWeight.sub(swapDistribution.weights[i]);

            if (sources[i] != ISource(0)) {
                address(sources[i]).functionDelegateCall(
                    abi.encodeWithSelector(
                        sources[i].swap.selector,
                        input.fromToken,
                        input.destToken,
                        amount,
                        swap.flags
                    ),
                    "Delegatecall failed"
                );
            }
            else if (i < reserves.length) {
                reserves[i](input.fromToken, input.destToken, amount, swap.flags);
            }
        }
    }

    function _makePathSwap(
        SwapInput memory input,
        IOneRouterView.Path memory path,
        PathDistribution memory pathDistribution
    )
        internal
        override
    {
        for (uint s = 0; s < pathDistribution.swapDistributions.length; s++) {
            IERC20 fromToken = (s == 0) ? input.fromToken : path.swaps[s - 1].destToken;
            SwapInput memory swapInput = SwapInput({
                fromToken: fromToken,
                destToken: path.swaps[s].destToken,
                amount: fromToken.uniBalanceOf(address(this)),
                minReturn: 0,
                referral: input.referral
            });
            _makeSwap(swapInput, path.swaps[s], pathDistribution.swapDistributions[s]);
        }
    }

    function _makeMultiPathSwap(
        SwapInput memory input,
        IOneRouterView.Path[] memory paths,
        PathDistribution[] memory pathDistributions,
        SwapDistribution memory interPathsDistribution
    )
        internal
        override
    {
        uint256 interTotalWeight = 0;
        for (uint i = 0; i < interPathsDistribution.weights.length; i++) {
            interTotalWeight = interTotalWeight.add(interPathsDistribution.weights[i]);
        }

        uint256 confirmed = input.fromToken.uniBalanceOf(address(this));
        for (uint p = 0; p < pathDistributions.length && interTotalWeight > 0; p++) {
            SwapInput memory pathInput = SwapInput({
                fromToken: input.fromToken,
                destToken: input.destToken,
                amount: confirmed.mul(interPathsDistribution.weights[p]).div(interTotalWeight),
                minReturn: 0,
                referral: input.referral
            });
            interTotalWeight = interTotalWeight.sub(interPathsDistribution.weights[p]);
            _makePathSwap(pathInput, paths[p], pathDistributions[p]);
        }
    }
}
