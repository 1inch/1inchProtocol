// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./IOneRouterView.sol";
import "./ISource.sol";
import "./OneRouterConstants.sol";
import "./HotSwapSources.sol";

import "./libraries/Algo.sol";
import "./libraries/UniERC20.sol";
import "./libraries/RevertReason.sol";
import "./libraries/FlagsChecker.sol";
import "./libraries/DynamicMemoryArray.sol";

import "./sources/UniswapV1Source.sol";
import "./sources/UniswapV2Source.sol";
import "./sources/MooniswapSource.sol";
import "./sources/KyberSource.sol";
import "./sources/CurveSource.sol";
// import "./sources/BalancerSource.sol";


contract OneRouterView is
    OneRouterConstants,
    IOneRouterView,
    HotSwapSources,
    UniswapV1SourceView,
    UniswapV2SourceView,
    MooniswapSourceView,
    KyberSourceView,
    CurveSourceView
    // BalancerSourceView
{
    using UniERC20 for IERC20;
    using SafeMath for uint256;
    using FlagsChecker for uint256;
    using DynamicMemoryArray for DynamicMemoryArray.Addresses;

    function getReturn(IERC20 fromToken, uint256[] memory amounts, Swap memory swap)
        public
        view
        override
        returns(
            Path[] memory paths,
            PathResult[] memory pathResults,
            SwapResult memory splitResult
        )
    {
        IERC20[][] memory midTokens = _getPathsForTokens(fromToken, swap.destToken);

        paths = new Path[](midTokens.length);
        pathResults = new PathResult[](paths.length);
        DynamicMemoryArray.Addresses memory disabledDexes;
        for (uint i = 0; i < paths.length; i++) {
            paths[i] = Path({swaps: new Swap[](1 + midTokens[i - 1].length)});
            for (uint j = 0; j < midTokens[i - 1].length; j++) {
                if (fromToken == midTokens[i - 1][j] || swap.destToken == midTokens[i - 1][j]) {
                    paths[i] = Path({swaps: new Swap[](1)});
                    break;
                }

                paths[i].swaps[j] = Swap({
                    destToken: midTokens[i - 1][j],
                    flags: swap.flags,
                    destTokenEthPriceTimesGasPrice: _scaleDestTokenEthPriceTimesGasPrice(fromToken, midTokens[i - 1][j], swap.destTokenEthPriceTimesGasPrice),
                    disabledDexes: disabledDexes.copy()
                });
            }
            paths[i].swaps[paths[i].swaps.length - 1] = swap;

            pathResults[i] = getPathReturn(fromToken, amounts, paths[i]);
            for (uint j = 0; j < pathResults[i].swaps.length; j++) {
                for (uint k = 0; k < pathResults[i].swaps[j].dexes.length; k++) {
                    for (uint t = 0; t < pathResults[i].swaps[j].dexes[k].length; t++) {
                        if (pathResults[i].swaps[j].dexes[k][t] != address(0)) {
                            disabledDexes.push(pathResults[i].swaps[j].dexes[k][t]);
                        }
                    }
                }
            }
        }

        splitResult = bestDistributionAmongPaths(paths, pathResults);
    }

    function getMultiPathReturn(IERC20 fromToken, uint256[] memory amounts, Path[] memory paths)
        public
        view
        override
        returns(
            PathResult[] memory pathResults,
            SwapResult memory splitResult
        )
    {
        pathResults = new PathResult[](paths.length);
        for (uint i = 0; i < paths.length; i++) {
            pathResults[i] = getPathReturn(fromToken, amounts, paths[i]);
        }
        splitResult = bestDistributionAmongPaths(paths, pathResults);
    }

    function bestDistributionAmongPaths(Path[] memory paths, PathResult[] memory pathResults) public pure returns(SwapResult memory) {
        uint256[][] memory input = new uint256[][](paths.length);
        uint256[][] memory gases = new uint256[][](paths.length);
        uint256[][] memory costs = new uint256[][](paths.length);
        for (uint i = 0; i < pathResults.length; i++) {
            Swap memory subSwap = paths[i].swaps[paths[i].swaps.length - 1];
            SwapResult memory swapResult = pathResults[i].swaps[pathResults[i].swaps.length - 1];

            input[i] = new uint256[](swapResult.returnAmounts.length);
            gases[i] = new uint256[](swapResult.returnAmounts.length);
            costs[i] = new uint256[](swapResult.returnAmounts.length);
            for (uint j = 0; j < swapResult.returnAmounts.length; j++) {
                input[i][j] = swapResult.returnAmounts[j];
                gases[i][j] = swapResult.estimateGasAmounts[j];
                costs[i][j] = swapResult.estimateGasAmounts[j].mul(subSwap.destTokenEthPriceTimesGasPrice).div(1e18);
            }
        }
        return _findBestDistribution(input, costs, gases, input[0].length);
    }

    function getPathReturn(IERC20 fromToken, uint256[] memory amounts, Path memory path)
        public
        view
        override
        returns(PathResult memory result)
    {
        result.swaps = new SwapResult[](path.swaps.length);

        for (uint i = 0; i < path.swaps.length; i++) {
            result.swaps[i] = getSwapReturn(fromToken, amounts, path.swaps[i]);
            fromToken = path.swaps[i].destToken;
            amounts = result.swaps[i].returnAmounts;
        }
    }

    function getSwapReturn(IERC20 fromToken, uint256[] memory amounts, Swap memory swap)
        public
        view
        override
        returns(SwapResult memory result)
    {
        if (fromToken == swap.destToken) {
            result.returnAmounts = amounts;
            return result;
        }

        function(IERC20,uint256[] memory,Swap memory) view returns(uint256[] memory, address, uint256)[15] memory reserves = [
            _calculateUniswapV1,
            _calculateUniswapV2,
            _calculateMooniswap,
            _calculateKyber1,
            _calculateKyber2,
            _calculateKyber3,
            _calculateKyber4,
            _calculateCurveCompound,
            _calculateCurveUSDT,
            _calculateCurveY,
            _calculateCurveBinance,
            _calculateCurveSynthetix,
            _calculateCurvePAX,
            _calculateCurveRENBTC,
            _calculateCurveSBTC
            // _calculateBalancer1,
            // _calculateBalancer2,
            // _calculateBalancer3,
            // calculateBancor,
            // calculateOasis,
            // calculateDforceSwap,
            // calculateShell,
            // calculateMStableMUSD,
            // calculateBlackHoleSwap
        ];

        uint256[][] memory input = new uint256[][](sourcesCount);
        uint256[][] memory gases = new uint256[][](sourcesCount);
        uint256[][] memory costs = new uint256[][](sourcesCount);
        bool disableAll = swap.flags.check(_FLAG_DISABLE_ALL_SOURCES);
        for (uint i = 0; i < sourcesCount; i++) {
            uint256 gas;
            if (disableAll == swap.flags.check(1 << i)) {
                if (sources[i] != ISource(0)) {
                    (input[i], , gas) = sources[i].calculate(fromToken, amounts, swap);
                }
                else if (i < reserves.length) {
                    (input[i], , gas) = reserves[i](fromToken, amounts, swap);
                }
            }

            gases[i] = new uint256[](amounts.length);
            costs[i] = new uint256[](amounts.length);
            uint256 fee = gas.mul(swap.destTokenEthPriceTimesGasPrice).div(1e18);
            for (uint j = 0; j < amounts.length; j++) {
                gases[i][j] = gas;
                costs[i][j] = fee;
            }
        }

        result = _findBestDistribution(input, costs, gases, amounts.length);
    }

    function _calculateNoReturn(IERC20 fromToken, uint256[] memory amounts, IOneRouterView.Swap memory swap)
        private view returns(uint256[] memory rets, uint256 gas)
    {
    }

    function _scaleDestTokenEthPriceTimesGasPrice(IERC20 fromToken, IERC20 destToken, uint256 destTokenEthPriceTimesGasPrice) private view returns(uint256) {
        if (fromToken == destToken) {
            return destTokenEthPriceTimesGasPrice;
        }

        uint256 mul = _cheapGetPrice(UniERC20.ETH_ADDRESS, destToken, 0.001 ether);
        uint256 div = _cheapGetPrice(UniERC20.ETH_ADDRESS, fromToken, 0.001 ether);
        return (div == 0) ? 0 : destTokenEthPriceTimesGasPrice.mul(mul).div(div);
    }

    function _cheapGetPrice(IERC20 fromToken, IERC20 destToken, uint256 amount) private view returns(uint256 returnAmount) {
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        uint256 flags = _FLAG_DISABLE_RECALCULATION |
            _FLAG_DISABLE_ALL_SOURCES |
            _FLAG_DISABLE_UNISWAP_V1 |
            _FLAG_DISABLE_UNISWAP_V2;

        return this.getSwapReturn(
            fromToken,
            amounts,
            Swap({
                destToken: destToken,
                flags: flags,
                destTokenEthPriceTimesGasPrice: 0,
                disabledDexes: new address[](0)
            })
        ).returnAmounts[0];
    }

    function _findBestDistribution(uint256[][] memory input, uint256[][] memory costs, uint256[][] memory gases, uint256 parts)
        private pure returns(SwapResult memory result)
    {
        int256[][] memory matrix = new int256[][](input.length);
        for (uint i = 0; i < input.length; i++) {
            matrix[i] = new int256[](1 + parts);
            matrix[i][0] = Algo.VERY_NEGATIVE_VALUE;
            for (uint j = 0; j < parts; j++) {
                matrix[i][j + 1] =
                    (j < input[i].length && input[i][j] != 0)
                    ? int256(input[i][j]) - int256(costs[i][j])
                    : Algo.VERY_NEGATIVE_VALUE;
            }
        }

        (, result.distributions) = Algo.findBestDistribution(matrix, parts);

        result.returnAmounts = new uint256[](parts);
        result.estimateGasAmounts = new uint256[](parts);
        for (uint i = 0; i < input.length; i++) {
            for (uint j = 0; j < parts; j++) {
                if (result.distributions[j][i] > 0) {
                    uint256 index = result.distributions[j][i] - 1;
                    result.returnAmounts[j] = result.returnAmounts[j].add(index < input[i].length ? input[i][index] : 0);
                    result.estimateGasAmounts[j] = result.estimateGasAmounts[j].add(gases[i][j]);
                }
            }
        }
    }
}
