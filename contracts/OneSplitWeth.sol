pragma solidity ^0.5.0;

import "./interface/ICompound.sol";
import "./OneSplitBase.sol";


contract OneSplitWethView is OneSplitBaseView {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        return _wethGetExpectedReturn(
            fromToken,
            toToken,
            amount,
            parts,
            disableFlags
        );
    }

    function _wethGetExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
        private
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == toToken) {
            return (amount, new uint256[](9));
        }

        if (!disableFlags.check(FLAG_DISABLE_WETH)) {
            if (fromToken == wethToken) {
                return getExpectedReturn(ETH_ADDRESS, toToken, amount, parts, disableFlags);
            }

            if (toToken == wethToken) {
                return getExpectedReturn(fromToken, ETH_ADDRESS, amount, parts, disableFlags);
            }
        }

        return super.getExpectedReturn(
            fromToken,
            toToken,
            amount,
            parts,
            disableFlags
        );
    }
}


contract OneSplitWeth is OneSplitBase {
    function _swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 disableFlags
    ) internal {
        _wethSwap(
            fromToken,
            toToken,
            amount,
            distribution,
            disableFlags
        );
    }

    function _wethSwap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 disableFlags
    ) private {
        if (fromToken == toToken) {
            return;
        }

        if (!disableFlags.check(FLAG_DISABLE_WETH)) {
            if (fromToken == wethToken) {
                wethToken.withdraw(wethToken.balanceOf(address(this)));
                _wethSwap(
                    ETH_ADDRESS,
                    toToken,
                    amount,
                    distribution,
                    disableFlags
                );
                return;
            }

            if (toToken == wethToken) {
                _wethSwap(
                    fromToken,
                    ETH_ADDRESS,
                    amount,
                    distribution,
                    disableFlags
                );
                wethToken.deposit.value(address(this).balance)();
                return;
            }
        }

        return super._swap(
            fromToken,
            toToken,
            amount,
            distribution,
            disableFlags
        );
    }
}
