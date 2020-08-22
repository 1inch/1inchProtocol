pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/Math.sol";
import "./OneSplitBase.sol";
import "./interface/IMooniswap.sol";
import "./interface/IUniswapV2Exchange.sol";
import "./UniversalERC20.sol";

contract OneSplitMooniswapMigrationBase {
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

    function _getMooniswapPoolDetails(IMooniswap pool) internal view returns (PoolDetails memory details) {
        for (uint i = 0; i < 2; i++) {
            IERC20 token = pool.tokens(i);
            details.tokens[i] = TokenInfo({
                token: token,
                reserve: token.universalBalanceOf(address(pool))
            });
        }

        details.totalSupply = IERC20(address(pool)).totalSupply();
    }

    function _getUniswapV2PoolDetails(IUniswapV2Exchange pair) internal view returns (PoolDetails memory details) {
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();

        details.tokens[0] = TokenInfo({
            token: pair.token0(),
            reserve: reserve0
        });
        details.tokens[1] = TokenInfo({
            token: pair.token1(),
            reserve: reserve1
        });

        details.totalSupply = IERC20(address(pair)).totalSupply();
    }

    function isUniswapV2LiquidityPool(IERC20 token) internal view returns (bool) {
        (bool success, bytes memory data) = address(token).staticcall.gas(2000)(
            abi.encode(IUniswapV2Exchange(address(token)).factory.selector)
        );
        if (!success || data.length == 0) {
            return false;
        }
        return abi.decode(data, (address)) == 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    }
}


contract OneSplitMooniswapMigrationView is OneSplitViewWrapBase, OneSplitMooniswapMigrationBase {

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

        if (
            flags.check(FLAG_DISABLE_MOONISWAP_MIGRATION) ||
            !isUniswapV2LiquidityPool(fromToken)
        ) {
            return super.getExpectedReturnWithGas(
                fromToken,
                toToken,
                amount,
                parts,
                flags,
                destTokenEthPriceTimesGasPrice
            );
        }

        distribution = new uint256[](DEXES_COUNT);
        returnAmount = uint256(-1);

        PoolDetails memory uniswapV2Details = _getUniswapV2PoolDetails(IUniswapV2Exchange(address(fromToken)));

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount.mul(uniswapV2Details.tokens[0].reserve).div(uniswapV2Details.totalSupply);
        amounts[1] = amount.mul(uniswapV2Details.tokens[1].reserve).div(uniswapV2Details.totalSupply);

        if (!mooniswapRegistry.isPool(address(toToken))) {
            returnAmount = uint256(1000).mul(99);
            for (uint i = 0; i < 2; i++) {
                returnAmount = Math.max(returnAmount, amounts[i]);
            }
            return (returnAmount, 0, distribution);
        }

        uint256 indexOfWeth = (
            (address(uniswapV2Details.tokens[0].token) == address(weth) ? 1 : 0) |
            (address(uniswapV2Details.tokens[1].token) == address(weth) ? 2 : 0)
        );

        PoolDetails memory mooniswapDetails = _getMooniswapPoolDetails(IMooniswap(address(toToken)));
        if (indexOfWeth == 0 || indexOfWeth == 1 || address(mooniswapDetails.tokens[0].token) != address(0)) {
            for (uint i = 0; i < 2; i++) {
                returnAmount = Math.min(
                    returnAmount,
                    mooniswapDetails.totalSupply.mul(amounts[i]).div(mooniswapDetails.tokens[i].reserve)
                );
            }
        } else {
            for (uint i = 0; i < 2; i++) {
                returnAmount = Math.min(
                    returnAmount,
                    mooniswapDetails.totalSupply.mul(amounts[1 - i]).div(mooniswapDetails.tokens[i].reserve)
                );
            }
        }

        return (returnAmount, 0, distribution);
    }
}


contract OneSplitMooniswapMigration is OneSplitBaseWrap, OneSplitMooniswapMigrationBase {
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

        if (
            flags.check(FLAG_DISABLE_MOONISWAP_MIGRATION) ||
            !isUniswapV2LiquidityPool(fromToken)
        ) {
            return super._swap(
                fromToken,
                toToken,
                amount,
                distribution,
                flags
            );
        }

        fromToken.transfer(address(fromToken), amount);
        uint256[2] memory returnAmounts = IUniswapV2Exchange(address(fromToken)).burn(address(this));
        IERC20[2] memory tokens = [
            IUniswapV2Exchange(address(fromToken)).token0(),
            IUniswapV2Exchange(address(fromToken)).token1()
        ];

        uint256 indexOfWeth = (
            (address(tokens[0]) == address(weth) ? 1 : 0) |
            (address(tokens[1]) == address(weth) ? 2 : 0)
        );

        if (!mooniswapRegistry.isPool(address(toToken))) {
            toToken = mooniswapRegistry.deploy(
                indexOfWeth != 0 ? IERC20(address(0)) : tokens[0],
                indexOfWeth == 2 ? tokens[0] : tokens[1]
            );
        }

        uint256 ethValue;
        if (indexOfWeth > 0 && address(IMooniswap(address(toToken)).tokens(0)) == address(0)) {
            weth.withdraw(returnAmounts[indexOfWeth - 1]);
            ethValue = returnAmounts[indexOfWeth - 1];
            tokens[1 - (indexOfWeth - 1)].universalApprove(address(toToken), returnAmounts[1 - (indexOfWeth - 1)]);
        } else {
            tokens[0].universalApprove(address(toToken), returnAmounts[0]);
            tokens[1].universalApprove(address(toToken), returnAmounts[1]);
        }

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = indexOfWeth != 2 ?  returnAmounts[0] : returnAmounts[1];
        amounts[1] = indexOfWeth != 2 ?  returnAmounts[1] : returnAmounts[0];
        IMooniswap(address(toToken)).deposit.value(ethValue)(
            amounts,
            new uint256[](2)
        );

        for (uint i = 0; i < 2; i++) {
            IERC20 token = ethValue != 0 && (indexOfWeth - 1 == i) ? ETH_ADDRESS : tokens[i];
            token.universalTransfer(
                tx.origin,
                token.universalBalanceOf(address(this))
            );
        }
    }
}
