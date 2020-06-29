pragma solidity ^0.5.0;

import "./interface/IIdle.sol";
import "./OneSplitBase.sol";


contract OneSplitIdleBase {
    function _idleTokens() internal pure returns(IIdle[8] memory) {
        // https://developers.idle.finance/contracts-and-codebase
        return [
            // V3
            IIdle(0x78751B12Da02728F467A44eAc40F5cbc16Bd7934),
            IIdle(0x12B98C621E8754Ae70d0fDbBC73D6208bC3e3cA6),
            IIdle(0x63D27B3DA94A9E871222CB0A32232674B02D2f2D),
            IIdle(0x1846bdfDB6A0f5c473dEc610144513bd071999fB),
            IIdle(0xcDdB1Bceb7a1979C6caa0229820707429dd3Ec6C),
            IIdle(0x42740698959761BAF1B06baa51EfBD88CB1D862B),
            // V2
            IIdle(0x10eC0D497824e342bCB0EDcE00959142aAa766dD),
            IIdle(0xeB66ACc3d011056B00ea521F8203580C2E5d3991)
        ];
    }
}


contract OneSplitIdleView is OneSplitViewWrapBase, OneSplitIdleBase {
    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
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
        return _idleGetExpectedReturn(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function _idleGetExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        internal
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

        if (!flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == !flags.check(FLAG_DISABLE_IDLE)) {
            IIdle[8] memory tokens = _idleTokens();

            for (uint i = 0; i < tokens.length; i++) {
                if (fromToken == IERC20(tokens[i])) {
                    (returnAmount, estimateGasAmount, distribution) = _idleGetExpectedReturn(
                        tokens[i].token(),
                        destToken,
                        amount.mul(tokens[i].tokenPrice()).div(1e18),
                        parts,
                        flags,
                        destTokenEthPriceTimesGasPrice
                    );
                    return (returnAmount, estimateGasAmount + 2_400_000, distribution);
                }
            }

            for (uint i = 0; i < tokens.length; i++) {
                if (destToken == IERC20(tokens[i])) {
                    uint256 _destTokenEthPriceTimesGasPrice = destTokenEthPriceTimesGasPrice;
                    uint256 _price = tokens[i].tokenPrice();
                    IERC20 token = tokens[i].token();
                    (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                        fromToken,
                        token,
                        amount,
                        parts,
                        flags,
                        _destTokenEthPriceTimesGasPrice.mul(_price).div(1e18)
                    );
                    return (returnAmount.mul(1e18).div(_price), estimateGasAmount + 1_300_000, distribution);
                }
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


contract OneSplitIdle is OneSplitBaseWrap, OneSplitIdleBase {
    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        _idleSwap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }

    function _idleSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        if (!flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == !flags.check(FLAG_DISABLE_IDLE)) {
            IIdle[8] memory tokens = _idleTokens();

            for (uint i = 0; i < tokens.length; i++) {
                if (fromToken == IERC20(tokens[i])) {
                    IERC20 underlying = tokens[i].token();
                    uint256 minted = tokens[i].redeemIdleToken(amount, true, new uint256[](0));
                    _idleSwap(underlying, destToken, minted, distribution, flags);
                    return;
                }
            }

            for (uint i = 0; i < tokens.length; i++) {
                if (destToken == IERC20(tokens[i])) {
                    IERC20 underlying = tokens[i].token();
                    super._swap(fromToken, underlying, amount, distribution, flags);

                    uint256 underlyingBalance = underlying.balanceOf(address(this));
                    underlying.universalApprove(address(tokens[i]), underlyingBalance);
                    tokens[i].mintIdleToken(underlyingBalance, new uint256[](0));
                    return;
                }
            }
        }

        return super._swap(fromToken, destToken, amount, distribution, flags);
    }
}
