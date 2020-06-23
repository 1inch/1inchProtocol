pragma solidity >=0.5.0;

import "./interface/IAaveToken.sol";
import "./OneSplitBase.sol";


contract OneSplitAaveBase {
    function _getAaveUnderlyingToken(IERC20 token) internal pure returns(IERC20) {
        if (token == IERC20(0x3a3A65aAb0dd2A17E3F1947bA16138cd37d08c04)) { // ETH
            return IERC20(0);
        }
        if (token == IERC20(0xfC1E690f61EFd961294b3e1Ce3313fBD8aa4f85d)) { // DAI
            return IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        }
        if (token == IERC20(0x9bA00D6856a4eDF4665BcA2C2309936572473B7E)) { // USDC
            return IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        }
        if (token == IERC20(0x625aE63000f46200499120B906716420bd059240)) { // SUSD
            return IERC20(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
        }
        if (token == IERC20(0x6Ee0f7BB50a54AB5253dA0667B0Dc2ee526C30a8)) { // BUSD
            return IERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53);
        }
        if (token == IERC20(0x4DA9b813057D04BAef4e5800E36083717b4a0341)) { // TUSD
            return IERC20(0x0000000000085d4780B73119b644AE5ecd22b376);
        }
        if (token == IERC20(0x71fc860F7D3A592A4a98740e39dB31d25db65ae8)) { // USDT
            return IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        }
        if (token == IERC20(0xE1BA0FB44CCb0D11b80F92f4f8Ed94CA3fF51D00)) { // BAT
            return IERC20(0x0D8775F648430679A709E98d2b0Cb6250d2887EF);
        }
        if (token == IERC20(0x9D91BE44C06d373a8a226E1f3b146956083803eB)) { // KNC
            return IERC20(0xdd974D5C2e2928deA5F71b9825b8b646686BD200);
        }
        if (token == IERC20(0x7D2D3688Df45Ce7C552E19c27e007673da9204B8)) { // LEND
            return IERC20(0x80fB784B7eD66730e8b1DBd9820aFD29931aab03);
        }
        if (token == IERC20(0xA64BD6C70Cb9051F6A9ba1F163Fdc07E0DfB5F84)) { // LINK
            return IERC20(0x514910771AF9Ca656af840dff83E8264EcF986CA);
        }
        if (token == IERC20(0x6FCE4A401B6B80ACe52baAefE4421Bd188e76F6f)) { // MANA
            return IERC20(0x0F5D2fB29fb7d3CFeE444a200298f468908cC942);
        }
        if (token == IERC20(0x7deB5e830be29F91E298ba5FF1356BB7f8146998)) { // MKR
            return IERC20(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
        }
        if (token == IERC20(0x71010A9D003445aC60C4e6A7017c1E89A477B438)) { // REP
            return IERC20(0x1985365e9f78359a9B6AD760e32412f4a445E862);
        }
        if (token == IERC20(0x328C4c80BC7aCa0834Db37e6600A6c49E12Da4DE)) { // SNX
            return IERC20(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F);
        }
        if (token == IERC20(0xFC4B8ED459e00e5400be803A9BB3954234FD50e3)) { // WBTC
            return IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
        }
        if (token == IERC20(0x6Fb0855c404E09c47C3fBCA25f08d4E41f9F062f)) { // ZRX
            return IERC20(0xE41d2489571d322189246DaFA5ebDe1F4699F498);
        }

        return IERC20(-1);
    }
}


contract OneSplitAaveView is OneSplitViewWrapBase, OneSplitAaveBase {
    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags, // See constants in IOneSplit.sol
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        return _aaveGetExpectedReturn(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function _aaveGetExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        private
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == destToken) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_AAVE)) {
            IERC20 underlying = _getAaveUnderlyingToken(fromToken);
            if (underlying != IERC20(-1)) {
                (returnAmount, estimateGasAmount, distribution) = _aaveGetExpectedReturn(
                    underlying,
                    destToken,
                    amount,
                    parts,
                    flags,
                    destTokenEthPriceTimesGasPrice
                );
                return (returnAmount, estimateGasAmount + 670_000, distribution);
            }

            underlying = _getAaveUnderlyingToken(destToken);
            if (underlying != IERC20(-1)) {
                (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                    fromToken,
                    underlying,
                    amount,
                    parts,
                    flags,
                    destTokenEthPriceTimesGasPrice
                );
                return (returnAmount, estimateGasAmount + 310_000, distribution);
            }
        }

        return super.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }
}


contract OneSplitAave is OneSplitBaseWrap, OneSplitAaveBase {
    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        _aaveSwap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }

    function _aaveSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        if (fromToken == destToken) {
            return;
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_AAVE)) {
            IERC20 underlying = _getAaveUnderlyingToken(fromToken);
            if (underlying != IERC20(-1)) {
                IAaveToken(address(fromToken)).redeem(amount);

                return _aaveSwap(
                    underlying,
                    destToken,
                    amount,
                    distribution,
                    flags
                );
            }

            underlying = _getAaveUnderlyingToken(destToken);
            if (underlying != IERC20(-1)) {
                super._swap(
                    fromToken,
                    underlying,
                    amount,
                    distribution,
                    flags
                );

                uint256 underlyingAmount = underlying.universalBalanceOf(address(this));

                underlying.universalApprove(aave.core(), underlyingAmount);
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
            destToken,
            amount,
            distribution,
            flags
        );
    }
}
