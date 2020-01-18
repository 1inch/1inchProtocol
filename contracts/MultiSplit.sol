pragma solidity ^0.5.0;

import "./UniversalERC20.sol";
import "./interface/IOneSplit.sol";

contract MultiSplit {

    using UniversalERC20 for IERC20;

    IOneSplit oneSplit = IOneSplit(0x25C40bC17E4BF2f8C23aCc99a7A38568f0890157);
    IERC20 constant public ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
    public
    view
    returns (
        uint256 hopReturnAmount,
        uint256[] memory hopDistribution,
        uint256 returnAmount,
        uint256[] memory distribution
    ) {

        (hopReturnAmount, hopDistribution) = oneSplit.getExpectedReturn(
            fromToken,
            ETH_ADDRESS,
            amount,
            parts,
            disableFlags
        );

        (returnAmount, distribution) = oneSplit.getExpectedReturn(
            ETH_ADDRESS,
            toToken,
            hopReturnAmount,
            parts,
            disableFlags
        );
    }

    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory hopDistribution, // [Uniswap, Kyber, Bancor, Oasis]
        uint256[] memory distribution, // [Uniswap, Kyber, Bancor, Oasis]
        uint256 hopDisableFlags,
        uint256 disableFlags
    ) public payable {

        fromToken.universalTransferFrom(msg.sender, address(this), amount);
        fromToken.universalApprove(address(oneSplit), uint256(- 1));

        oneSplit.swap(
            fromToken,
            ETH_ADDRESS,
            amount,
            1,
            hopDistribution,
            hopDisableFlags
        );

        IERC20 hopToken = IERC20(ETH_ADDRESS);
        hopToken.universalApprove(address(oneSplit), uint256(- 1));

        uint256 hopAmount = hopToken.universalBalanceOf(address(this));

        oneSplit.swap.value(hopAmount)(
            ETH_ADDRESS,
            toToken,
            hopAmount,
            minReturn,
            distribution,
            disableFlags
        );

        fromToken.universalTransfer(msg.sender, fromToken.universalBalanceOf(address(this)));
        hopToken.universalTransfer(msg.sender, hopToken.universalBalanceOf(address(this)));
        toToken.universalTransfer(msg.sender, toToken.universalBalanceOf(address(this)));
    }

    function() external payable {

        require(msg.sender != tx.origin);
    }
}
