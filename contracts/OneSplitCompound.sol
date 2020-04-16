pragma solidity ^0.5.0;

import "./interface/ICompound.sol";
import "./OneSplitBase.sol";


contract OneSplitCompoundBase {
    ICompound public compound = ICompound(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    ICompoundEther public cETH = ICompoundEther(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);
}


contract OneSplitCompoundView is OneSplitBaseView, OneSplitCompoundBase {
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
        return _compoundGetExpectedReturn(
            fromToken,
            toToken,
            amount,
            parts,
            disableFlags
        );
    }

    function _compoundGetExpectedReturn(
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
            return (amount, new uint256[](DEXES_COUNT));
        }

        if (!disableFlags.check(FLAG_DISABLE_COMPOUND)) {
            IERC20 underlying = _getCompoundToken(fromToken);
            if (underlying != IERC20(0)) {
                uint256 compoundRate = ICompoundToken(address(fromToken)).exchangeRateStored();

                return _compoundGetExpectedReturn(
                    underlying,
                    toToken,
                    amount.mul(compoundRate).div(1e18),
                    parts,
                    disableFlags
                );
            }

            underlying = _getCompoundToken(toToken);
            if (underlying != IERC20(0)) {
                uint256 compoundRate = ICompoundToken(address(toToken)).exchangeRateStored();

                (returnAmount, distribution) = super.getExpectedReturn(
                    fromToken,
                    underlying,
                    amount,
                    parts,
                    disableFlags
                );

                returnAmount = returnAmount.mul(1e18).div(compoundRate);
                return (returnAmount, distribution);

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


contract OneSplitCompound is OneSplitBase, OneSplitCompoundBase {
    function _swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 disableFlags
    ) internal {
        _compundSwap(
            fromToken,
            toToken,
            amount,
            distribution,
            disableFlags
        );
    }

    function _compundSwap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 disableFlags
    ) private {
        if (fromToken == toToken) {
            return;
        }

        if (!disableFlags.check(FLAG_DISABLE_COMPOUND)) {
            IERC20 underlying = _getCompoundToken(fromToken);
            if (underlying != IERC20(0)) {
                ICompoundToken(address(fromToken)).redeem(amount);
                uint256 underlyingAmount = underlying.universalBalanceOf(address(this));

                return _compundSwap(
                    underlying,
                    toToken,
                    underlyingAmount,
                    distribution,
                    disableFlags
                );
            }

            underlying = _getCompoundToken(toToken);
            if (underlying != IERC20(0)) {
                super._swap(
                    fromToken,
                    underlying,
                    amount,
                    distribution,
                    disableFlags
                );

                uint256 underlyingAmount = underlying.universalBalanceOf(address(this));

                if (underlying.isETH()) {
                    cETH.mint.value(underlyingAmount)();
                } else {
                    _infiniteApproveIfNeeded(underlying, address(toToken));
                    ICompoundToken(address(toToken)).mint(underlyingAmount);
                }
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
