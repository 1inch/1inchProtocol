// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IOneRouter.sol";
import "./libraries/UniERC20.sol";


contract OneRouterAudit is IOneRouter, Ownable {
    using UniERC20 for IERC20;
    using SafeMath for uint256;

    IOneRouter public oneRouterImpl;

    constructor(IOneRouter oneRouter) public {
        oneRouterImpl = oneRouter;
    }

    function setOneRouterImpl(IOneRouter oneRouter) public onlyOwner {
        oneRouterImpl = oneRouter;
    }

    receive() external payable {
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender != tx.origin, "ETH deposit rejected");
    }

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
        return oneRouterImpl.getReturn(fromToken, amounts, swap);
    }

    function getSwapReturn(IERC20 fromToken, uint256[] memory amounts, Swap memory swap)
        public
        view
        override
        returns(SwapResult memory result)
    {
        return oneRouterImpl.getSwapReturn(fromToken, amounts, swap);
    }

    function getPathReturn(IERC20 fromToken, uint256[] memory amounts, Path memory path)
        public
        view
        override
        returns(PathResult memory result)
    {
        return oneRouterImpl.getPathReturn(fromToken, amounts, path);
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
        return oneRouterImpl.getMultiPathReturn(fromToken, amounts, paths);
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
        _claimInput(input);
        input.fromToken.uniApprove(address(oneRouterImpl), input.amount);
        oneRouterImpl.makeSwap{ value: input.fromToken.isETH() ? input.amount : 0 }(input, swap, swapDistribution);
        return _checkMinReturn(input);
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
        _claimInput(input);
        input.fromToken.uniApprove(address(oneRouterImpl), input.amount);
        oneRouterImpl.makePathSwap{ value: input.fromToken.isETH() ? input.amount : 0 }(input, path, pathDistribution);
        return _checkMinReturn(input);
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
        _claimInput(input);
        input.fromToken.uniApprove(address(oneRouterImpl), input.amount);
        oneRouterImpl.makeMultiPathSwap{ value: input.fromToken.isETH() ? input.amount : 0 }(input, paths, pathDistributions, interPathsDistribution);
        return _checkMinReturn(input);
    }

    function _claimInput(SwapInput memory input) internal {
        input.fromToken.uniTransferFromSender(address(this), input.amount);
        input.amount = input.fromToken.uniBalanceOf(address(this));
    }

    function _checkMinReturn(SwapInput memory input) internal returns(uint256 returnAmount) {
        uint256 remaining = input.fromToken.uniBalanceOf(address(this));
        returnAmount = input.destToken.uniBalanceOf(address(this));
        require(returnAmount >= input.minReturn, "Min returns is not enough");
        input.fromToken.uniTransfer(msg.sender, remaining);
        input.destToken.uniTransfer(msg.sender, returnAmount);
    }
}
