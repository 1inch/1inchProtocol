// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IOneRouterView {
    struct Swap {
        IERC20 destToken;
        uint256 flags;
        uint256 destTokenEthPriceTimesGasPrice;
        address[] disabledDexes;
    }

    struct Path {
        Swap[] swaps;
    }

    struct SwapResult {
        uint256[] returnAmounts;
        uint256[] estimateGasAmounts;
        uint256[][] distributions;
        address[][] dexes;
    }

    struct PathResult {
        SwapResult[] swaps;
    }

    function getSwapReturn(
        IERC20 fromToken,
        uint256[] calldata amounts,
        Swap calldata swap
    )
        external
        view
        returns(SwapResult memory result);

    function getPathReturn(
        IERC20 fromToken,
        uint256[] calldata amounts,
        Path calldata path
    )
        external
        view
        returns(PathResult memory result);

    function getMultiPathReturn(
        IERC20 fromToken,
        uint256[] calldata amounts,
        Path[] calldata paths
    )
        external
        view
        returns(
            PathResult[] memory pathResults,
            SwapResult memory splitResult
        );

    function getDisjointMultiPathReturn(
        IERC20 fromToken,
        uint256[] calldata amounts,
        Path[] calldata paths
    )
        external
        view
        returns(
            PathResult[] memory pathResults,
            SwapResult memory splitResult
        );

    function getSuggestedReturn(
        IERC20 fromToken,
        uint256[] calldata amounts,
        Swap calldata swap
    )
        external
        view
        returns(
            Path[] memory paths,
            PathResult[] memory pathResults,
            SwapResult memory splitResult
        );
}
