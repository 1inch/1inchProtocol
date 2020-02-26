pragma solidity ^0.5.0;

import "./interface/ICompound.sol";
import "./OneSplitBase.sol";


contract OneSplitCompoundBase {
    ICompound public compound = ICompound(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    ICompoundEther public cETH = ICompoundEther(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);

    function _isCompoundToken(IERC20 token) internal view returns(bool) {
        if (token == cETH) {
            return true;
        }

        (bool success, bytes memory data) = address(compound).staticcall.gas(5000)(abi.encodeWithSelector(
            compound.markets.selector,
            token
        ));
        if (!success) {
            return false;
        }

        (bool isListed,) = abi.decode(data, (bool,uint256));
        return isListed;
    }

    function _compoundUnderlyingAsset(IERC20 asset) internal view returns(IERC20) {
        if (asset == cETH) {
            return IERC20(address(0));
        }

        (bool success, bytes memory data) = address(asset).staticcall.gas(5000)(abi.encodeWithSelector(
            ICompoundToken(address(asset)).underlying.selector
        ));
        if (!success) {
            return IERC20(-1);
        }

        return abi.decode(data, (IERC20));
    }
}


contract OneSplitCompoundView is OneSplitBaseView, OneSplitCompoundBase {
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
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == toToken) {
            return (amount, new uint256[](4));
        }

        if (disableFlags.enabled(FLAG_COMPOUND)) {
            if (_isCompoundToken(fromToken)) {
                IERC20 underlying = _compoundUnderlyingAsset(fromToken);
                if (underlying != IERC20(-1)) {
                    uint256 compoundRate = ICompoundToken(address(fromToken)).exchangeRateStored();

                    return _compoundGetExpectedReturn(
                        underlying,
                        toToken,
                        amount.mul(compoundRate).div(1e18),
                        parts,
                        disableFlags
                    );
                }
            }

            if (_isCompoundToken(toToken)) {
                IERC20 underlying = _compoundUnderlyingAsset(toToken);
                if (underlying != IERC20(-1)) {
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

        if (disableFlags.enabled(FLAG_COMPOUND)) {
            if (_isCompoundToken(fromToken)) {
                IERC20 underlying = _compoundUnderlyingAsset(fromToken);

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

            if (_isCompoundToken(toToken)) {
                IERC20 underlying = _compoundUnderlyingAsset(toToken);

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
