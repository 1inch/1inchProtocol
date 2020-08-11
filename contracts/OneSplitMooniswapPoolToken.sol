pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/Math.sol";
import "./OneSplitBase.sol";
import "./interface/IMooniswap.sol";
import "./UniversalERC20.sol";

contract OneSplitMooniswapTokenBase {
    using SafeMath for uint256;
    using Math for uint256;
    using UniversalERC20 for IERC20;

    struct TokenInfo {
        IERC20 token;
        uint256 reserve;
    }

    struct PoolDetails {
        TokenInfo[2] tokens;
        uint256 totalSupply;
    }

    function _getPoolDetails(IMooniswap pool) internal view returns (PoolDetails memory details) {
        for (uint i = 0; i < 2; i++) {
            IERC20 token = pool.tokens(i);
            details.tokens[i] = TokenInfo({
                token: token,
                reserve: token.universalBalanceOf(address(pool))
            });
        }

        details.totalSupply = IERC20(address(pool)).totalSupply();
    }
}


contract OneSplitMooniswapTokenView is OneSplitViewWrapBase, OneSplitMooniswapTokenBase {

    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns (
            uint256 returnAmount,
            uint256,
            uint256[] memory distribution
        )
    {
        if (fromToken.eq(toToken)) {
            return (amount, 0, new uint256[](DEXES_COUNT));
        }


        if (!flags.check(FLAG_DISABLE_MOONISWAP_POOL_TOKEN)) {
            bool isPoolTokenFrom = mooniswapRegistry.isPool(address(fromToken));
            bool isPoolTokenTo = mooniswapRegistry.isPool(address(toToken));

            if (isPoolTokenFrom && isPoolTokenTo) {
                (
                    uint256 returnETHAmount,
                    uint256[] memory poolTokenFromDistribution
                ) = _getExpectedReturnFromMooniswapPoolToken(
                    fromToken,
                    ETH_ADDRESS,
                    amount,
                    parts,
                    FLAG_DISABLE_MOONISWAP_POOL_TOKEN
                );

                (
                    uint256 returnPoolTokenToAmount,
                    uint256[] memory poolTokenToDistribution
                ) = _getExpectedReturnToMooniswapPoolToken(
                    ETH_ADDRESS,
                    toToken,
                    returnETHAmount,
                    parts,
                    FLAG_DISABLE_MOONISWAP_POOL_TOKEN
                );

                for (uint i = 0; i < poolTokenToDistribution.length; i++) {
                    poolTokenFromDistribution[i] |= poolTokenToDistribution[i] << 128;
                }

                return (returnPoolTokenToAmount, 0, poolTokenFromDistribution);
            }

            if (isPoolTokenFrom) {
                (returnAmount, distribution) = _getExpectedReturnFromMooniswapPoolToken(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    FLAG_DISABLE_MOONISWAP_POOL_TOKEN
                );
                return (returnAmount, 0, distribution);
            }

            if (isPoolTokenTo) {
                (returnAmount, distribution) = _getExpectedReturnToMooniswapPoolToken(
                    fromToken,
                    toToken,
                    amount,
                    parts,
                    FLAG_DISABLE_MOONISWAP_POOL_TOKEN
                );
                return (returnAmount, 0, distribution);
            }
        }

        return super.getExpectedReturnWithGas(
            fromToken,
            toToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function _getExpectedReturnFromMooniswapPoolToken(
        IERC20 poolToken,
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
        distribution = new uint256[](DEXES_COUNT);

        PoolDetails memory details = _getPoolDetails(IMooniswap(address(poolToken)));

        for (uint i = 0; i < 2; i++) {

            uint256 exchangeAmount = amount
                .mul(details.tokens[i].reserve)
                .div(details.totalSupply);

            if (toToken.eq(details.tokens[i].token)) {
                returnAmount = returnAmount.add(exchangeAmount);
                continue;
            }

            (uint256 ret, ,uint256[] memory dist) = super.getExpectedReturnWithGas(
                details.tokens[i].token,
                toToken,
                exchangeAmount,
                parts,
                flags,
                0
            );

            returnAmount = returnAmount.add(ret);
            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] |= dist[j] << (i * 8);
            }
        }

        return (returnAmount, distribution);
    }

    function _getExpectedReturnToMooniswapPoolToken(
        IERC20 fromToken,
        IERC20 poolToken,
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
        distribution = new uint256[](DEXES_COUNT);

        PoolDetails memory details = _getPoolDetails(IMooniswap(address(poolToken)));

        // will overwritten to liquidity amounts
        uint256[2] memory amounts;
        amounts[0] = amount.div(2);
        amounts[1] = amount.sub(amounts[0]);
        uint256[] memory dist = new uint256[](distribution.length);
        for (uint i = 0; i < 2; i++) {

            if (fromToken.eq(details.tokens[i].token)) {
                continue;
            }

            (amounts[i], ,dist) = super.getExpectedReturnWithGas(
                fromToken,
                details.tokens[i].token,
                amounts[i],
                parts,
                flags,
                0
            );

            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] |= dist[j] << (i * 8);
            }
        }

        returnAmount = uint256(-1);
        for (uint i = 0; i < 2; i++) {
            returnAmount = Math.min(
                returnAmount,
                details.totalSupply.mul(amounts[i]).div(details.tokens[i].reserve)
            );
        }

        return (
            returnAmount,
            distribution
        );
    }

}


contract OneSplitMooniswapToken is OneSplitBaseWrap, OneSplitMooniswapTokenBase {
    function _swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) internal {
        if (fromToken.eq(toToken)) {
            return;
        }

        if (!flags.check(FLAG_DISABLE_MOONISWAP_POOL_TOKEN)) {
            bool isPoolTokenFrom = mooniswapRegistry.isPool(address(fromToken));
            bool isPoolTokenTo = mooniswapRegistry.isPool(address(toToken));

            if (isPoolTokenFrom && isPoolTokenTo) {
                uint256[] memory dist = new uint256[](distribution.length);
                for (uint i = 0; i < distribution.length; i++) {
                    dist[i] = distribution[i] & ((1 << 128) - 1);
                }

                uint256 ethBalanceBefore = ETH_ADDRESS.universalBalanceOf(address(this));

                _swapFromMooniswapToken(
                    fromToken,
                    ETH_ADDRESS,
                    amount,
                    dist,
                    FLAG_DISABLE_MOONISWAP_POOL_TOKEN
                );

                for (uint i = 0; i < distribution.length; i++) {
                    dist[i] = distribution[i] >> 128;
                }

                uint256 ethBalanceAfter = ETH_ADDRESS.universalBalanceOf(address(this));

                return _swapToMooniswapToken(
                    ETH_ADDRESS,
                    toToken,
                    ethBalanceAfter.sub(ethBalanceBefore),
                    dist,
                    FLAG_DISABLE_MOONISWAP_POOL_TOKEN
                );
            }

            if (isPoolTokenFrom) {
                return _swapFromMooniswapToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    FLAG_DISABLE_MOONISWAP_POOL_TOKEN
                );
            }

            if (isPoolTokenTo) {
                return _swapToMooniswapToken(
                    fromToken,
                    toToken,
                    amount,
                    distribution,
                    FLAG_DISABLE_MOONISWAP_POOL_TOKEN
                );
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

    function _swapFromMooniswapToken(
        IERC20 poolToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        IERC20[2] memory tokens = [
            IMooniswap(address(poolToken)).tokens(0),
            IMooniswap(address(poolToken)).tokens(1)
        ];

        IMooniswap(address(poolToken)).withdraw(
            amount,
            new uint256[](0)
        );

        uint256[] memory dist = new uint256[](distribution.length);
        for (uint i = 0; i < 2; i++) {

            if (toToken.eq(tokens[i])) {
                continue;
            }

            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j] >> (i * 8)) & 0xFF;
            }

            super._swap(
                tokens[i],
                toToken,
                tokens[i].universalBalanceOf(address(this)),
                dist,
                flags
            );
        }
    }

    function _swapToMooniswapToken(
        IERC20 fromToken,
        IERC20 poolToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags
    ) private {
        IERC20[2] memory tokens = [
            IMooniswap(address(poolToken)).tokens(0),
            IMooniswap(address(poolToken)).tokens(1)
        ];

        // will overwritten to liquidity amounts
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount.div(2);
        amounts[1] = amount.sub(amounts[0]);
        uint256[] memory dist = new uint256[](distribution.length);
        for (uint i = 0; i < 2; i++) {

            if (fromToken.eq(tokens[i])) {
                continue;
            }

            for (uint j = 0; j < distribution.length; j++) {
                dist[j] = (distribution[j] >> (i * 8)) & 0xFF;
            }

            super._swap(
                fromToken,
                tokens[i],
                amounts[i],
                dist,
                flags
            );

            amounts[i] = tokens[i].universalBalanceOf(address(this));
            tokens[i].universalApprove(address(poolToken), amounts[i]);
        }

        uint256 ethValue = (tokens[0].isETH() ? amounts[0] : 0) + (tokens[1].isETH() ? amounts[1] : 0);
        IMooniswap(address(poolToken)).deposit.value(ethValue)(
            amounts,
            new uint256[](2)
        );

        for (uint i = 0; i < 2; i++) {
            tokens[i].universalTransfer(
                msg.sender,
                tokens[i].universalBalanceOf(address(this))
            );
        }
    }
}
