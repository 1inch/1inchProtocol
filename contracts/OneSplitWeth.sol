pragma solidity ^0.5.0;

import "./interface/ICompound.sol";
import "./OneSplitBase.sol";


contract OneSplitWethView is OneSplitViewWrapBase {
    function getExpectedReturnRespectingGas(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 toTokenEthPriceTimesGasPrice
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        return _wethGetExpectedReturn(
            fromToken,
            toToken,
            amount,
            parts,
            flags,
            toTokenEthPriceTimesGasPrice
        );
    }

    function _wethGetExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 toTokenEthPriceTimesGasPrice
    )
        private
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        if (fromToken == toToken) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_WETH)) {
            if (fromToken == weth || fromToken == bancorEtherToken) {
                return super.getExpectedReturnRespectingGas(ETH_ADDRESS, toToken, amount, parts, flags, toTokenEthPriceTimesGasPrice);
            }

            if (toToken == weth || toToken == bancorEtherToken) {
                return super.getExpectedReturnRespectingGas(fromToken, ETH_ADDRESS, amount, parts, flags, toTokenEthPriceTimesGasPrice);
            }
        }

        return super.getExpectedReturnRespectingGas(
            fromToken,
            toToken,
            amount,
            parts,
            flags,
            toTokenEthPriceTimesGasPrice
        );
    }
}


contract OneSplitWeth is OneSplitBaseWrap {
    function _swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        _wethSwap(
            fromToken,
            toToken,
            amount,
            distribution,
            flags
        );
    }

    function _wethSwap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        if (fromToken == toToken) {
            return;
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_WETH)) {
            if (fromToken == weth) {
                weth.withdraw(weth.balanceOf(address(this)));
                super._swap(
                    ETH_ADDRESS,
                    toToken,
                    amount,
                    distribution,
                    flags
                );
                return;
            }

            if (fromToken == bancorEtherToken) {
                bancorEtherToken.withdraw(bancorEtherToken.balanceOf(address(this)));
                super._swap(
                    ETH_ADDRESS,
                    toToken,
                    amount,
                    distribution,
                    flags
                );
                return;
            }

            if (toToken == weth) {
                _wethSwap(
                    fromToken,
                    ETH_ADDRESS,
                    amount,
                    distribution,
                    flags
                );
                weth.deposit.value(address(this).balance)();
                return;
            }

            if (toToken == bancorEtherToken) {
                _wethSwap(
                    fromToken,
                    ETH_ADDRESS,
                    amount,
                    distribution,
                    flags
                );
                bancorEtherToken.deposit.value(address(this).balance)();
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
