pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "./interface/IYToken.sol";
import "./OneSplitBase.sol";


contract OneSplitIearn is OneSplitBase {

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
        if (fromToken == toToken) {
            return (amount, new uint256[](4));
        }

        if (disableFlags.enabled(FLAG_IEARN)) {
            IERC20 underlying = _isIearnToken(fromToken);
            if (underlying != IERC20(-1)) {
                uint256 iearnRate = IYToken(address(fromToken)).getPricePerFullShare();

                return super.getExpectedReturn(
                    underlying,
                    toToken,
                    amount.mul(iearnRate).div(1e18),
                    parts,
                    disableFlags
                );
            }

            underlying = _isIearnToken(toToken);
            if (underlying != IERC20(-1)) {
                uint256 iearnRate = IYToken(address(toToken)).getPricePerFullShare();

                (returnAmount, distribution) = super.getExpectedReturn(
                    fromToken,
                    underlying,
                    amount,
                    parts,
                    disableFlags
                );

                returnAmount = returnAmount.mul(1e18).div(iearnRate);
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

    function _swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 disableFlags
    ) internal {
        if (fromToken == toToken) {
            return;
        }

        if (disableFlags.enabled(FLAG_IEARN)) {
            IERC20 underlying = _isIearnToken(fromToken);
            if (underlying != IERC20(-1)) {
                IYToken(address(fromToken)).withdraw(amount);
                uint256 underlyingAmount = underlying.universalBalanceOf(address(this));

                return super._swap(
                    underlying,
                    toToken,
                    underlyingAmount,
                    distribution,
                    disableFlags
                );
            }

            underlying = _isIearnToken(toToken);
            if (underlying != IERC20(-1)) {
                super._swap(
                    fromToken,
                    underlying,
                    amount,
                    distribution,
                    disableFlags
                );

                uint256 underlyingAmount = underlying.universalBalanceOf(address(this));

                _infiniteApproveIfNeeded(underlying, address(toToken));
                IYToken(address(toToken)).deposit(underlyingAmount);
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

    function _isIearnToken(IERC20 token) public view returns(IERC20) {
        if (token.isETH()) {
            return IERC20(-1);
        }

        (bool success, bytes memory data) = address(token).staticcall.gas(5000)(abi.encodeWithSelector(
            ERC20Detailed(address(token)).name.selector
        ));
        if (!success) {
            return IERC20(-1);
        }

        bool foundIearn = false;
        for (uint i = 0; i < data.length - 5; i++) {
            if (data[i + 0] == "i" &&
                data[i + 1] == "e" &&
                data[i + 2] == "a" &&
                data[i + 3] == "r" &&
                data[i + 4] == "n")
            {
                foundIearn = true;
                break;
            }
        }
        if (!foundIearn) {
            return IERC20(-1);
        }

        (success, data) = address(token).staticcall.gas(5000)(abi.encodeWithSelector(
            IYToken(address(token)).token.selector
        ));
        if (!success) {
            return IERC20(-1);
        }

        return abi.decode(data, (IERC20));
    }

}
