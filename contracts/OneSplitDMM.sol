pragma solidity ^0.5.0;

import "./interface/IDMM.sol";
import "./OneSplitBase.sol";


contract OneSplitDMMBase {
    IDMMController internal constant _dmmController = IDMMController(0x4CB120Dd1D33C9A3De8Bc15620C7Cd43418d77E2);

    function _getDMMUnderlyingToken(IERC20 token) internal view returns(IERC20) {
        (bool success, bytes memory data) = address(_dmmController).staticcall(
            abi.encodeWithSelector(
                _dmmController.getUnderlyingTokenForDmm.selector,
                token
            )
        );

        if (!success || data.length == 0) {
            return IERC20(-1);
        }

        return abi.decode(data, (IERC20));
    }

    function _getDMMExchangeRate(IDMM dmm) internal view returns(uint256) {
        (bool success, bytes memory data) = address(dmm).staticcall(
            abi.encodeWithSelector(
                dmm.getCurrentExchangeRate.selector
            )
        );

        if (!success || data.length == 0) {
            return 0;
        }

        return abi.decode(data, (uint256));
    }
}


contract OneSplitDMMView is OneSplitViewWrapBase, OneSplitDMMBase {
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
        return _dmmGetExpectedReturn(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function _dmmGetExpectedReturn(
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

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_DMM)) {
            IERC20 underlying = _getDMMUnderlyingToken(fromToken);
            if (underlying != IERC20(-1)) {
                if (underlying == weth) {
                    underlying = ETH_ADDRESS;
                }
                IERC20 _fromToken = fromToken;
                (returnAmount, estimateGasAmount, distribution) = _dmmGetExpectedReturn(
                    underlying,
                    destToken,
                    amount.mul(_getDMMExchangeRate(IDMM(address(_fromToken)))).div(1e18),
                    parts,
                    flags,
                    destTokenEthPriceTimesGasPrice
                );
                return (returnAmount, estimateGasAmount + 295_000, distribution);
            }

            underlying = _getDMMUnderlyingToken(destToken);
            if (underlying != IERC20(-1)) {
                if (underlying == weth) {
                    underlying = ETH_ADDRESS;
                }
                uint256 price = _getDMMExchangeRate(IDMM(address(destToken)));
                (returnAmount, estimateGasAmount, distribution) = super.getExpectedReturnWithGas(
                    fromToken,
                    underlying,
                    amount,
                    parts,
                    flags,
                    destTokenEthPriceTimesGasPrice.mul(price).div(1e18)
                );
                return (
                    returnAmount.mul(1e18).div(price),
                    estimateGasAmount + 430_000,
                    distribution
                );
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


contract OneSplitDMM is OneSplitBaseWrap, OneSplitDMMBase {
    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        _dmmSwap(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }

    function _dmmSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        if (fromToken == destToken) {
            return;
        }

        if (flags.check(FLAG_DISABLE_ALL_WRAP_SOURCES) == flags.check(FLAG_DISABLE_DMM)) {
            IERC20 underlying = _getDMMUnderlyingToken(fromToken);
            if (underlying != IERC20(-1)) {
                IDMM(address(fromToken)).redeem(amount);
                uint256 balance = underlying.universalBalanceOf(address(this));
                if (underlying == weth) {
                    weth.withdraw(balance);
                }
                _dmmSwap(
                    (underlying == weth) ? ETH_ADDRESS : underlying,
                    destToken,
                    balance,
                    distribution,
                    flags
                );
            }

            underlying = _getDMMUnderlyingToken(destToken);
            if (underlying != IERC20(-1)) {
                super._swap(
                    fromToken,
                    (underlying == weth) ? ETH_ADDRESS : underlying,
                    amount,
                    distribution,
                    flags
                );

                uint256 underlyingAmount = ((underlying == weth) ? ETH_ADDRESS : underlying).universalBalanceOf(address(this));
                if (underlying == weth) {
                    weth.deposit.value(underlyingAmount);
                }

                underlying.universalApprove(address(destToken), underlyingAmount);
                IDMM(address(destToken)).mint(underlyingAmount);
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
