// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapV1.sol";
import "./interfaces/IUniswapV2.sol";
import "./interfaces/IBalancer.sol";
import "./interfaces/IAaveRegistry.sol";
import "./interfaces/ICompoundRegistry.sol";
import "./IOneRouter.sol";
import "./ISource.sol";
import "./OneRouterConstants.sol";

import "./libraries/Algo.sol";
import "./libraries/Address2.sol";
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


contract PathsAdvisor is OneRouterConstants {
    using UniERC20 for IERC20;

    IAaveRegistry constant private _AAVE_REGISTRY = IAaveRegistry(0xEd8b133B7B88366E01Bb9E38305Ab11c26521494);
    ICompoundRegistry constant private _COMPOUND_REGISTRY = ICompoundRegistry(0xF451Dbd7Ba14BFa7B1B78A766D3Ed438F79EE1D1);

    function getPathsForTokens(IERC20 fromToken, IERC20 destToken) external view returns(IERC20[][] memory paths) {
        IERC20[4] memory midTokens = [_DAI, _USDC, _USDT, _WBTC];
        paths = new IERC20[][](2 + midTokens.length);

        IERC20 aFromToken = _AAVE_REGISTRY.aTokenByToken(fromToken);
        IERC20 aDestToken = _AAVE_REGISTRY.aTokenByToken(destToken);
        if (aFromToken != IERC20(0)) {
            aFromToken = _COMPOUND_REGISTRY.cTokenByToken(fromToken);
        }
        if (aDestToken != IERC20(0)) {
            aDestToken = _COMPOUND_REGISTRY.cTokenByToken(destToken);
        }

        uint index = 0;
        paths[index] = new IERC20[](0);
        index++;

        if (!fromToken.isETH() && !aFromToken.isETH() && !destToken.isETH() && !aDestToken.isETH()) {
            paths[index] = new IERC20[](1);
            paths[index][0] = UniERC20.ETH_ADDRESS;
            index++;
        }

        for (uint i = 0; i < midTokens.length; i++) {
            if (fromToken != midTokens[i] && aFromToken != midTokens[i] && destToken != midTokens[i] && aDestToken != midTokens[i]) {
                paths[index] = new IERC20[](
                    1 +
                    ((aFromToken != IERC20(0)) ? 1 : 0) +
                    ((aDestToken != IERC20(0)) ? 1 : 0)
                );

                paths[index][0] = aFromToken;
                paths[index][paths[index].length / 2] = midTokens[i];
                if (aDestToken != IERC20(0)) {
                    paths[index][paths[index].length - 1] = aDestToken;
                }
                index++;
            }
        }

        IERC20[][] memory paths2 = new IERC20[][](index);
        for (uint i = 0; i < paths2.length; i++) {
            paths2[i] = paths[i];
        }
        paths = paths2;
    }
}


contract HotSwapSources is Ownable {
    uint256 public sourcesCount = 15;
    mapping(uint256 => ISource) public sources;
    PathsAdvisor public pathsAdvisor;

    constructor() public {
        pathsAdvisor = new PathsAdvisor();
    }

    function setSource(uint256 index, ISource source) external onlyOwner {
        require(index <= sourcesCount, "Router: index is too high");
        sources[index] = source;
        sourcesCount = Math.max(sourcesCount, index + 1);
    }

    function setPathsForTokens(PathsAdvisor newPathsAdvisor) external onlyOwner {
        pathsAdvisor = newPathsAdvisor;
    }

    function _getPathsForTokens(IERC20 fromToken, IERC20 destToken) internal view returns(IERC20[][] memory paths) {
        return pathsAdvisor.getPathsForTokens(fromToken, destToken);
    }
}


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
                        disabledDexes.push(pathResults[i].swaps[j].dexes[k][t]);
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


contract OneRouter is
    OneRouterConstants,
    IOneRouter,
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

    IOneRouterView public oneRouterView;

    constructor(IOneRouterView _oneRouterView) public {
        oneRouterView = _oneRouterView;
    }

    receive() external payable {
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender != tx.origin, "ETH deposit rejected");
    }

    function getReturn(
        IERC20 fromToken,
        uint256[] calldata amounts,
        Swap calldata swap
    )
        external
        view
        override
        returns(
            Path[] memory paths,
            PathResult[] memory pathResults,
            SwapResult memory splitResult
        )
    {
        return oneRouterView.getReturn(fromToken, amounts, swap);
    }

    function getSwapReturn(
        IERC20 fromToken,
        uint256[] calldata amounts,
        Swap calldata swap
    )
        external
        view
        override
        returns(SwapResult memory result)
    {
        return oneRouterView.getSwapReturn(fromToken, amounts, swap);
    }

    function getPathReturn(
        IERC20 fromToken,
        uint256[] calldata amounts,
        Path calldata path
    )
        external
        view
        override
        returns(PathResult memory result)
    {
        return oneRouterView.getPathReturn(fromToken, amounts, path);
    }

    function getMultiPathReturn(
        IERC20 fromToken,
        uint256[] calldata amounts,
        Path[] calldata paths
    )
        external
        view
        override
        returns(
            PathResult[] memory pathResults,
            SwapResult memory splitResult
        )
    {
        return oneRouterView.getMultiPathReturn(fromToken, amounts, paths);
    }

    function makeSwap(
        SwapInput memory input,
        Swap memory swap,
        SwapDistribution memory swapDistribution
    )
        public
        payable
        override
        returns(uint256 returnAmount)
    {
        Path memory path = Path({
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
        Path memory path,
        PathDistribution memory pathDistribution
    )
        public
        payable
        override
        returns(uint256 returnAmount)
    {
        Path[] memory paths = new Path[](1);
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
        Path[] memory paths,
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
