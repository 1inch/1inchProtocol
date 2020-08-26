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
import "./HotSwapSources.sol";


contract OneRouterSwap is
    OneRouterConstants,
    IOneRouterSwap,
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

    receive() external payable {
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender != tx.origin, "ETH deposit rejected");
    }

    function makeSwap(
        SwapInput memory input,
        IOneRouterView.Swap memory swap,
        SwapDistribution memory swapDistribution
    )
        public
        payable
        override
        returns(uint256 returnAmount)
    {
        IOneRouterView.Path memory path = IOneRouterView.Path({
            swaps: new IOneRouterView.Swap[](1)
        });
        path.swaps[0] = swap;

        PathDistribution memory pathDistribution = PathDistribution({
            swapDistributions: new SwapDistribution[](1)
        });
        pathDistribution.swapDistributions[0] = swapDistribution;

        return makePathSwap(input, path, pathDistribution);
    }

    function makePathSwap(
        SwapInput memory input,
        IOneRouterView.Path memory path,
        PathDistribution memory pathDistribution
    )
        public
        payable
        override
        returns(uint256 returnAmount)
    {
        IOneRouterView.Path[] memory paths = new IOneRouterView.Path[](1);
        paths[0] = path;

        PathDistribution[] memory pathDistributions = new PathDistribution[](1);
        pathDistributions[0] = pathDistribution;

        SwapDistribution memory swapDistribution = SwapDistribution({
            weights: new uint256[](1)
        });
        swapDistribution.weights[0] = 1;

        return makeMultiPathSwap(input, paths, pathDistributions, swapDistribution);
    }

    struct Indexes {
        uint p; // path
        uint s; // swap
        uint i; // index
    }

    function makeMultiPathSwap(
        SwapInput memory input,
        IOneRouterView.Path[] memory paths,
        PathDistribution[] memory pathDistributions,
        SwapDistribution memory interPathsDistribution
    )
        public
        payable
        override
        returns(uint256 returnAmount)
    {
        require(msg.value == (input.fromToken.isETH() ? input.amount : 0), "Wrong msg.value");
        require(paths.length == pathDistributions.length, "Wrong arrays length");
        require(paths.length == interPathsDistribution.weights.length, "Wrong arrays length");

        input.fromToken.uniTransferFromSender(address(this), input.amount);

        function(IERC20,IERC20,uint256,uint256)[15] memory reserves = [
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
            _swapOnCurveSBTC
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

        uint256 interTotalWeight = 0;
        for (uint i = 0; i < interPathsDistribution.weights.length; i++) {
            interTotalWeight = interTotalWeight.add(interPathsDistribution.weights[i]);
        }

        Indexes memory z;
        for (z.p = 0; z.p < pathDistributions.length && interTotalWeight > 0; z.p++) {
            uint256 confirmed = input.fromToken.uniBalanceOf(address(this))
                    .mul(interPathsDistribution.weights[z.p])
                    .div(interTotalWeight);
            interTotalWeight = interTotalWeight.sub(interPathsDistribution.weights[z.p]);

            IERC20 token = input.fromToken;
            for (z.s = 0; z.s < pathDistributions[z.p].swapDistributions.length; z.s++) {
                uint256 totalSwapWeight = 0;
                for (z.i = 0; z.i < pathDistributions[z.p].swapDistributions[z.s].weights.length; z.i++) {
                    totalSwapWeight = totalSwapWeight.add(pathDistributions[z.p].swapDistributions[z.s].weights[z.i]);
                }

                for (z.i = 0; z.i < pathDistributions[z.p].swapDistributions[z.s].weights.length && totalSwapWeight > 0; z.i++) {
                    uint256 amount = ((z.s == 0) ? confirmed : token.uniBalanceOf(address(this)))
                        .mul(pathDistributions[z.p].swapDistributions[z.s].weights[z.i])
                        .div(totalSwapWeight);
                    totalSwapWeight = totalSwapWeight.sub(pathDistributions[z.p].swapDistributions[z.s].weights[z.i]);

                    if (sources[z.i] != ISource(0)) {
                        address(sources[z.i]).functionDelegateCall(
                            abi.encodeWithSelector(
                                sources[z.i].swap.selector,
                                input.fromToken,
                                input.destToken,
                                amount,
                                paths[z.p].swaps[z.s].flags
                            ),
                            "Delegatecall failed"
                        );
                    }
                    else if (z.i < reserves.length) {
                        reserves[z.i](input.fromToken, input.destToken, amount, paths[z.p].swaps[z.s].flags);
                    }
                }

                token = paths[z.p].swaps[z.s].destToken;
            }
        }

        uint256 remaining = input.fromToken.uniBalanceOf(address(this));
        returnAmount = input.destToken.uniBalanceOf(address(this));
        require(returnAmount >= input.minReturn, "Min returns is not enough");
        input.fromToken.uniTransfer(msg.sender, remaining);
        input.destToken.uniTransfer(msg.sender, returnAmount);
    }
}
