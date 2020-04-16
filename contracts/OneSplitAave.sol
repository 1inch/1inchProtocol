pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "./interface/IAaveToken.sol";
import "./OneSplitBase.sol";


contract OneSplitAaveView is OneSplitBaseView {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
        internal
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        return _aaveGetExpectedReturn(
            fromToken,
            toToken,
            amount,
            parts,
            disableFlags
        );
    }

    function _aaveGetExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
        private
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == toToken) {
            return (amount, distribution);
        }

        if (!disableFlags.check(FLAG_DISABLE_AAVE)) {
            IERC20 underlying = _getAaveUnderlyingToken(fromToken);
            if (underlying != IERC20(-1)) {
                return _aaveGetExpectedReturn(
                    underlying,
                    toToken,
                    amount,
                    parts,
                    disableFlags
                );
            }

            underlying = _getAaveUnderlyingToken(toToken);
            if (underlying != IERC20(-1)) {
                return super.getExpectedReturn(
                    fromToken,
                    underlying,
                    amount,
                    parts,
                    disableFlags
                );
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


contract OneSplitAave is OneSplitBase {
    function _swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 disableFlags
    ) internal {
        _aaveSwap(
            fromToken,
            toToken,
            amount,
            distribution,
            disableFlags
        );
    }

    function _aaveSwap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 disableFlags
    ) private {
        if (fromToken == toToken) {
            return;
        }

        if (!disableFlags.check(FLAG_DISABLE_AAVE)) {
            IERC20 underlying = _getAaveUnderlyingToken(fromToken);
            if (underlying != IERC20(-1)) {
                IAaveToken(address(fromToken)).redeem(amount);

                return _aaveSwap(
                    underlying,
                    toToken,
                    amount,
                    distribution,
                    disableFlags
                );
            }

            underlying = _getAaveUnderlyingToken(toToken);
            if (underlying != IERC20(-1)) {
                super._swap(
                    fromToken,
                    underlying,
                    amount,
                    distribution,
                    disableFlags
                );

                uint256 underlyingAmount = underlying.universalBalanceOf(address(this));

                _infiniteApproveIfNeeded(underlying, aave.core());
                aave.deposit.value(underlying.isETH() ? underlyingAmount : 0)(
                    underlying.isETH() ? ETH_ADDRESS : underlying,
                    underlyingAmount,
                    1101
                );
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
