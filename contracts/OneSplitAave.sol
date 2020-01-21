pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "./interface/IAaveToken.sol";
import "./OneSplitBase.sol";


contract OneSplitAave is OneSplitBase {
    IAaveLendingPool public aave = IAaveLendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

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
            return (amount, distribution);
        }

        if (disableFlags.enabled(FLAG_AAVE)) {
            IERC20 underlying = _isAaveToken(fromToken);
            if (underlying != IERC20(-1)) {
                return super.getExpectedReturn(
                    underlying,
                    toToken,
                    amount,
                    parts,
                    disableFlags
                );
            }

            underlying = _isAaveToken(toToken);
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

        if (disableFlags.enabled(FLAG_AAVE)) {
            IERC20 underlying = _isAaveToken(fromToken);
            if (underlying != IERC20(-1)) {
                IAaveToken(address(fromToken)).redeem(amount);

                return super._swap(
                    underlying,
                    toToken,
                    amount,
                    distribution,
                    disableFlags
                );
            }

            underlying = _isAaveToken(toToken);
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

    function _isAaveToken(IERC20 token) public view returns(IERC20) {
        if (token.isETH()) {
            return IERC20(-1);
        }

        (bool success, bytes memory data) = address(token).staticcall.gas(5000)(abi.encodeWithSelector(
            ERC20Detailed(address(token)).name.selector
        ));
        if (!success) {
            return IERC20(-1);
        }

        bool foundAave = false;
        for (uint i = 0; i < data.length - 4; i++) {
            if (data[i + 0] == "A" &&
                data[i + 1] == "a" &&
                data[i + 2] == "v" &&
                data[i + 3] == "e")
            {
                foundAave = true;
                break;
            }
        }
        if (!foundAave) {
            return IERC20(-1);
        }

        (success, data) = address(token).staticcall.gas(5000)(abi.encodeWithSelector(
            IAaveToken(address(token)).underlyingAssetAddress.selector
        ));
        if (!success) {
            return IERC20(-1);
        }

        return abi.decode(data, (IERC20));
    }
}
