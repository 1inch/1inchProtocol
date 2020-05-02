pragma solidity ^0.5.0;

import "./interface/ICompound.sol";
import "./OneSplitBase.sol";


contract OneSplitCompoundBase {
    function _getCompoundUnderlyingToken(IERC20 token) internal pure returns(IERC20) {
        if (token == IERC20(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5)) { // ETH
            return IERC20(0);
        }
        if (token == IERC20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643)) { // DAI
            return IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        }
        if (token == IERC20(0x6C8c6b02E7b2BE14d4fA6022Dfd6d75921D90E4E)) { // BAT
            return IERC20(0x0D8775F648430679A709E98d2b0Cb6250d2887EF);
        }
        if (token == IERC20(0x158079Ee67Fce2f58472A96584A73C7Ab9AC95c1)) { // REP
            return IERC20(0x1985365e9f78359a9B6AD760e32412f4a445E862);
        }
        if (token == IERC20(0x39AA39c021dfbaE8faC545936693aC917d5E7563)) { // USDC
            return IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        }
        if (token == IERC20(0xC11b1268C1A384e55C48c2391d8d480264A3A7F4)) { // WBTC
            return IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
        }
        if (token == IERC20(0xB3319f5D18Bc0D84dD1b4825Dcde5d5f7266d407)) { // ZRX
            return IERC20(0xE41d2489571d322189246DaFA5ebDe1F4699F498);
        }
        if (token == IERC20(0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9)) { // USDT
            return IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        }

        return IERC20(-1);
    }
}


contract OneSplitCompoundView is OneSplitViewWrapBase, OneSplitCompoundBase {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
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
            flags
        );
    }

    function _compoundGetExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        private
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == toToken) {
            return (amount, new uint256[](DEXES_COUNT));
        }

        if (!flags.check(FLAG_DISABLE_COMPOUND)) {
            IERC20 underlying = _getCompoundUnderlyingToken(fromToken);
            if (underlying != IERC20(-1)) {
                uint256 compoundRate = ICompoundToken(address(fromToken)).exchangeRateStored();

                return _compoundGetExpectedReturn(
                    underlying,
                    toToken,
                    amount.mul(compoundRate).div(1e18),
                    parts,
                    flags
                );
            }

            underlying = _getCompoundUnderlyingToken(toToken);
            if (underlying != IERC20(-1)) {
                uint256 compoundRate = ICompoundToken(address(toToken)).exchangeRateStored();

                (returnAmount, distribution) = super.getExpectedReturn(
                    fromToken,
                    underlying,
                    amount,
                    parts,
                    flags
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
            flags
        );
    }
}


contract OneSplitCompound is OneSplitBaseWrap, OneSplitCompoundBase {
    function _swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        _compundSwap(
            fromToken,
            toToken,
            amount,
            distribution,
            flags
        );
    }

    function _compundSwap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        if (fromToken == toToken) {
            return;
        }

        if (!flags.check(FLAG_DISABLE_COMPOUND)) {
            IERC20 underlying = _getCompoundUnderlyingToken(fromToken);
            if (underlying != IERC20(-1)) {
                ICompoundToken(address(fromToken)).redeem(amount);
                uint256 underlyingAmount = underlying.universalBalanceOf(address(this));

                return _compundSwap(
                    underlying,
                    toToken,
                    underlyingAmount,
                    distribution,
                    flags
                );
            }

            underlying = _getCompoundUnderlyingToken(toToken);
            if (underlying != IERC20(-1)) {
                super._swap(
                    fromToken,
                    underlying,
                    amount,
                    distribution,
                    flags
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
            flags
        );
    }
}
