// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOneRouterView.sol";


interface IOneRouterSwap {
    struct Referral {
        address payable ref;
        uint256 fee;
    }

    struct SwapInput {
        IERC20 fromToken;
        IERC20 destToken;
        uint256 amount;
        uint256 minReturn;
        Referral referral;
    }

    struct SwapDistribution {
        uint256[] weights;
    }

    struct PathDistribution {
        SwapDistribution[] swapDistributions;
    }

    function makeSwap(
        SwapInput calldata input,
        IOneRouterView.Swap calldata swap,
        SwapDistribution calldata swapDistribution
    )
        external
        payable
        returns(uint256 returnAmount);

    function makePathSwap(
        SwapInput calldata input,
        IOneRouterView.Path calldata path,
        PathDistribution calldata pathDistribution
    )
        external
        payable
        returns(uint256 returnAmount);

    function makeMultiPathSwap(
        SwapInput calldata input,
        IOneRouterView.Path[] calldata paths,
        PathDistribution[] calldata pathDistributions,
        SwapDistribution calldata interPathsDistribution
    )
        external
        payable
        returns(uint256 returnAmount);
}
