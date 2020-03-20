pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "./interface/IFulcrum.sol";
import "./OneSplitBase.sol";


contract OneSplitFulcrumBase {
    using UniversalERC20 for IERC20;

    function _isFulcrumToken(IERC20 token) public view returns(IERC20) {
        if (token.isETH()) {
            return IERC20(-1);
        }

        (bool success, bytes memory data) = address(token).staticcall.gas(5000)(abi.encodeWithSelector(
            ERC20Detailed(address(token)).name.selector
        ));
        if (!success) {
            return IERC20(-1);
        }

        bool foundBZX = false;
        for (uint i = 0; i < data.length - 7; i++) {
            if (data[i + 0] == "F" &&
                data[i + 1] == "u" &&
                data[i + 2] == "l" &&
                data[i + 3] == "c" &&
                data[i + 4] == "r" &&
                data[i + 5] == "u" &&
                data[i + 6] == "m")
            {
                foundBZX = true;
                break;
            }
        }
        if (!foundBZX) {
            return IERC20(-1);
        }

        (success, data) = address(token).staticcall.gas(5000)(abi.encodeWithSelector(
            IFulcrumToken(address(token)).loanTokenAddress.selector
        ));
        if (!success) {
            return IERC20(-1);
        }

        return abi.decode(data, (IERC20));
    }
}


contract OneSplitFulcrumView is OneSplitBaseView, OneSplitFulcrumBase {
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
        return _fulcrumGetExpectedReturn(
            fromToken,
            toToken,
            amount,
            parts,
            disableFlags
        );
    }

    function _fulcrumGetExpectedReturn(
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
            return (amount, new uint256[](9));
        }

        if (!disableFlags.check(FLAG_DISABLE_FULCRUM)) {
            IERC20 underlying = _isFulcrumToken(fromToken);
            if (underlying != IERC20(-1)) {
                uint256 fulcrumRate = IFulcrumToken(address(fromToken)).tokenPrice();

                return _fulcrumGetExpectedReturn(
                    underlying,
                    toToken,
                    amount.mul(fulcrumRate).div(1e18),
                    parts,
                    disableFlags
                );
            }

            underlying = _isFulcrumToken(toToken);
            if (underlying != IERC20(-1)) {
                uint256 fulcrumRate = IFulcrumToken(address(toToken)).tokenPrice();

                (returnAmount, distribution) = super.getExpectedReturn(
                    fromToken,
                    underlying,
                    amount,
                    parts,
                    disableFlags
                );

                returnAmount = returnAmount.mul(1e18).div(fulcrumRate);
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


contract OneSplitFulcrum is OneSplitBase, OneSplitFulcrumBase {
    function _swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 disableFlags
    ) internal {
        _fulcrumSwap(
            fromToken,
            toToken,
            amount,
            distribution,
            disableFlags
        );
    }

    function _fulcrumSwap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 disableFlags
    ) private {
        if (fromToken == toToken) {
            return;
        }

        if (!disableFlags.check(FLAG_DISABLE_FULCRUM)) {
            IERC20 underlying = _isFulcrumToken(fromToken);
            if (underlying != IERC20(-1)) {
                if (underlying.isETH()) {
                    IFulcrumToken(address(fromToken)).burnToEther(address(this), amount);
                } else {
                    IFulcrumToken(address(fromToken)).burn(address(this), amount);
                }

                uint256 underlyingAmount = underlying.universalBalanceOf(address(this));

                return super._swap(
                    underlying,
                    toToken,
                    underlyingAmount,
                    distribution,
                    disableFlags
                );
            }

            underlying = _isFulcrumToken(toToken);
            if (underlying != IERC20(-1)) {
                super._swap(
                    fromToken,
                    underlying,
                    amount,
                    distribution,
                    disableFlags
                );

                uint256 underlyingAmount = underlying.universalBalanceOf(address(this));

                if (underlying.isETH()) {
                    IFulcrumToken(address(toToken)).mintWithEther.value(underlyingAmount)(address(this));
                } else {
                    _infiniteApproveIfNeeded(underlying, address(toToken));
                    IFulcrumToken(address(toToken)).mint(address(this), underlyingAmount);
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
