pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interface/IKyberNetworkProxy.sol";
import "./interface/IKyberUniswapReserve.sol";
import "./interface/IKyberOasisReserve.sol";
import "./interface/IUniswapFactory.sol";
import "./UniversalERC20.sol";


contract OneSplit {

    using SafeMath for uint256;
    using UniversalERC20 for IERC20;

    IKyberNetworkProxy public kyberNetworkProxy = IKyberNetworkProxy(0xbFC22E3B81Bddc185eB7c50765a9F445589A12AE);
    IUniswapFactory public uniswapFactory = IUniswapFactory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);

    function getConversionRate(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint[4] memory distribution // [Uniswap, Kyber, Bancor, Oasis]
        )
    {
        function(IERC20,IERC20,uint256) view returns (uint256)[4] memory reserves = [
            _calculateUniswapReturn,
            _calculateKyberReturn,
            _calculateNothingReturn,
            _calculateNothingReturn
        ];

        uint256[4] memory rates;
        uint256[4] memory fullRates;
        for (uint i = 0; i < rates.length; i++) {
            rates[i] = reserves[i](fromToken, toToken, amount.mul(i).div(parts));
            fullRates[i] = rates[i];
        }

        for (uint j = 0; j < parts; j++) {

            // Find best part
            uint256 bestIndex = 0;
            for (uint i = 0; i < rates.length; i++) {
                if (rates[i] > rates[bestIndex]) {
                    bestIndex = i;
                }
            }

            // Add best part
            returnAmount = returnAmount.add(rates[bestIndex]);
            distribution[bestIndex]++;

            // Avoid CompilerError: Stack too deep
            uint256 srcAmount = amount;

            // Recalc part if needed
            if (j + 1 < parts) {
                uint256 newRate = reserves[bestIndex](
                    fromToken,
                    toToken,
                    srcAmount.mul(distribution[bestIndex] + 1).div(parts)
                );
                rates[bestIndex] = newRate.sub(fullRates[bestIndex]);
                fullRates[bestIndex] = newRate;
            }
        }
    }

    // Helpers

    function _calculateUniswapReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) internal view returns(uint256) {
        IUniswapExchange fromExchange = IUniswapExchange(uniswapFactory.getExchange(fromToken));
        IUniswapExchange toExchange = IUniswapExchange(uniswapFactory.getExchange(toToken));

        if (address(toExchange) == address(0) && address(fromExchange) == address(0)) {
            return amount;
        }

        if (fromToken == IERC20(0)) {
            return toExchange.getEthToTokenInputPrice(amount);
        }

        if (toToken == IERC20(0)) {
            return fromExchange.getTokenToEthInputPrice(amount);
        }

        return toExchange.getEthToTokenInputPrice(
            fromExchange.getTokenToEthInputPrice(amount)
        );
    }

    function _calculateKyberReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) internal view returns(uint256) {
        IKyberNetworkContract kyberNetworkContract = kyberNetworkProxy.kyberNetworkContract();

        (address reserve, uint256 rate) = kyberNetworkContract.searchBestRate(
            fromToken,
            toToken,
            amount,
            true
        );

        // Check for Uniswap reserve
        (bool success,) = reserve.staticcall.gas(2300)(abi.encodeWithSelector(
            IKyberUniswapReserve(reserve).uniswapFactory.selector
        ));
        if (success) {
            return 0;
        }

        // Check for Oasis reserve
        (success,) = reserve.staticcall.gas(2300)(abi.encodeWithSelector(
            IKyberOasisReserve(reserve).otc.selector
        ));
        if (success) {
            return 0;
        }

        return rate.mul(amount)
            .mul(10 ** IERC20(toToken).universalDecimals())
            .div(10 ** IERC20(fromToken).universalDecimals())
            .div(1e18);
    }

    function _calculateNothingReturn(
        IERC20 /*fromToken*/,
        IERC20 /*toToken*/,
        uint256 /*amount*/
    ) internal view returns(uint256) {
        this;
        return 0;
    }
}
