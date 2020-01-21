pragma solidity ^0.5.0;

import "./UniversalERC20.sol";
import "./interface/IOneSplit.sol";

contract MultiSplit {

    using UniversalERC20 for IERC20;

    IOneSplit oneSplit = IOneSplit(0x00CD1b195B403a5e3D6534afD942C928fC9217f0);
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
        infiniteApproveIfNeeded(fromToken, address(oneSplit));

        oneSplit.swap.value(address(this).balance)(
            fromToken,
            ETH_ADDRESS,
            amount,
            1,
            hopDistribution,
            hopDisableFlags
        );

        IERC20 hopToken = IERC20(ETH_ADDRESS);
        infiniteApproveIfNeeded(hopToken, address(oneSplit));

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

    function infiniteApproveIfNeeded(IERC20 token, address to) internal {

        if (!token.isETH()) {

            if ((token.allowance(address(this), to) >> 255) == 0) {
                token.universalApprove(to, uint256(- 1));
            }
        }
    }

    function() external payable {

        require(msg.sender != tx.origin);
    }
}
