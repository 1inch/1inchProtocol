// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./IOneRouterView.sol";


interface ISource {
    function calculate(IERC20 fromToken, uint256[] calldata amounts, IOneRouterView.Swap calldata swap)
        external view returns(uint256[] memory rets, address dex, uint256 gas);

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 flags) external;
}
