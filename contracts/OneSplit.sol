pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interface/IUniswapFactory.sol";
import "./interface/IKyberNetworkProxy.sol";
import "./interface/IKyberUniswapReserve.sol";
import "./interface/IKyberOasisReserve.sol";
import "./interface/IBancorNetwork.sol";
import "./interface/IBancorContractRegistry.sol";
import "./interface/IBancorConverterRegistry.sol";
import "./interface/IOasisExchange.sol";
import "./UniversalERC20.sol";


contract OneSplit {

    using SafeMath for uint256;
    using UniversalERC20 for IERC20;

    IERC20 wethToken = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 bntToken = IERC20(0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C);
    IERC20 bancorEtherToken = IERC20(0xc0829421C1d260BD3cB3E0F06cfE2D52db2cE315);

    IKyberNetworkProxy public kyberNetworkProxy = IKyberNetworkProxy(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
    IUniswapFactory public uniswapFactory = IUniswapFactory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);
    IBancorContractRegistry public bancorContractRegistry = IBancorContractRegistry(0x52Ae12ABe5D8BD778BD5397F99cA900624CfADD4);
    IBancorConverterRegistry public bancorConverterRegistry = IBancorConverterRegistry(0xf6E2D7F616B67E46D708e4410746E9AAb3a4C518);
    IOasisExchange public oasisExchange = IOasisExchange(0x39755357759cE0d7f32dC8dC45414CCa409AE24e);

    function log(uint256) external view {
    }

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags // 1 - Uniswap, 2 - Kyber, 4 - Bancor, 8 - Oasis
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint[4] memory distribution // [Uniswap, Kyber, Bancor, Oasis]
        )
    {
        function(IERC20,IERC20,uint256) view returns(uint256)[4] memory reserves = [
            ((disableFlags & 1) != 0) ? _calculateNoReturn : _calculateUniswapReturn,
            ((disableFlags & 2) != 0) ? _calculateNoReturn : _calculateKyberReturn,
            ((disableFlags & 4) != 0) ? _calculateNoReturn : _calculateBancorReturn,
            ((disableFlags & 8) != 0) ? _calculateNoReturn : _calculateOasisReturn
        ];

        uint256[4] memory rates;
        uint256[4] memory fullRates;
        for (uint i = 0; i < rates.length; i++) {
            rates[i] = reserves[i](fromToken, toToken, amount.div(parts));
            this.log(rates[i]);
            fullRates[i] = rates[i];
        }

        for (uint j = 0; j < parts; j++) {
            // Find best part
            uint256 bestIndex = 0;
            for (uint i = 1; i < rates.length; i++) {
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
                this.log(rates[bestIndex]);
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
        uint256 returnAmount = amount;

        if (!fromToken.isETH()) {
            IUniswapExchange fromExchange = uniswapFactory.getExchange(fromToken);
            if (fromExchange != IUniswapExchange(0)) {
                returnAmount = fromExchange.getTokenToEthInputPrice(returnAmount);
            }
        }

        if (!toToken.isETH()) {
            IUniswapExchange toExchange = uniswapFactory.getExchange(toToken);
            if (toExchange != IUniswapExchange(0)) {
                returnAmount = toExchange.getEthToTokenInputPrice(returnAmount);
            }
        }

        return returnAmount;
    }

    function _calculateKyberReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) internal view returns(uint256) {
        (bool success, bytes memory data) = address(kyberNetworkProxy).staticcall.gas(2300)(abi.encodeWithSelector(
            kyberNetworkProxy.kyberNetworkContract.selector
        ));
        if (!success) {
            return 0;
        }

        IKyberNetworkContract kyberNetworkContract = IKyberNetworkContract(abi.decode(data, (address)));

        (success, data) = address(kyberNetworkContract).staticcall.gas(200000)(abi.encodeWithSelector(
            kyberNetworkContract.searchBestRate.selector,
            fromToken.isETH() ? IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) : fromToken,
            toToken.isETH() ? IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) : toToken,
            amount,
            true
        ));
        if (!success) {
            return 0;
        }

        (address reserve, uint256 rate) = abi.decode(data, (address,uint256));

        // Check for Uniswap reserve
        (success,) = reserve.staticcall.gas(2300)(abi.encodeWithSelector(
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

    function _calculateBancorReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) internal view returns(uint256) {
        IBancorNetwork bancorNetwork = IBancorNetwork(bancorContractRegistry.addressOf("BancorNetwork"));
        address[] memory path = _buildBancorPath(fromToken, toToken);

        (bool success, bytes memory data) = address(bancorNetwork).staticcall.gas(200000)(
            abi.encodeWithSelector(
                bancorNetwork.getReturnByPath.selector,
                path,
                amount
            )
        );
        if (!success) {
            return 0;
        }

        (uint256 returnAmount,) = abi.decode(data, (uint256,uint256));
        return returnAmount;
    }

    function _calculateOasisReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) internal view returns(uint256) {
        (bool success, bytes memory data) = address(oasisExchange).staticcall.gas(500000)(
            abi.encodeWithSelector(
                oasisExchange.getBuyAmount.selector,
                toToken.isETH() ? wethToken : toToken,
                fromToken.isETH() ? wethToken : fromToken,
                amount
            )
        );
        if (!success) {
            return 0;
        }

        return abi.decode(data, (uint256));
    }

    function _calculateNoReturn(
        IERC20 /*fromToken*/,
        IERC20 /*toToken*/,
        uint256 /*amount*/
    ) internal view returns(uint256) {
        this;
        return 0;
    }

    function _buildBancorPath(
        IERC20 fromToken,
        IERC20 toToken
    ) internal view returns(address[] memory path) {
        if (fromToken == toToken) {
            return new address[](0);
        }

        if (fromToken.isETH()) {
            fromToken = bancorEtherToken;
        }
        if (toToken.isETH()) {
            toToken = bancorEtherToken;
        }

        if (fromToken == bntToken || toToken == bntToken) {
            path = new address[](3);
        } else {
            path = new address[](5);
        }

        address fromConverter;
        address toConverter;

        if (fromToken != bntToken) {
            (bool success, bytes memory data) = address(bancorConverterRegistry).staticcall.gas(10000)(abi.encodeWithSelector(
                bancorConverterRegistry.getConvertibleTokenSmartToken.selector,
                fromToken.isETH() ? bntToken : fromToken,
                0
            ));
            if (!success) {
                return new address[](0);
            }

            fromConverter = abi.decode(data, (address));
            if (fromConverter == address(0)) {
                return new address[](0);
            }
        }

        if (toToken != bntToken) {
            (bool success, bytes memory data) = address(bancorConverterRegistry).staticcall.gas(10000)(abi.encodeWithSelector(
                bancorConverterRegistry.getConvertibleTokenSmartToken.selector,
                toToken.isETH() ? bntToken : toToken,
                0
            ));
            if (!success) {
                return new address[](0);
            }

            toConverter = abi.decode(data, (address));
            if (toConverter == address(0)) {
                return new address[](0);
            }
        }

        if (toToken == bntToken) {
            path[0] = address(fromToken);
            path[1] = fromConverter;
            path[2] = address(bntToken);
            return path;
        }

        if (fromToken == bntToken) {
            path[0] = address(bntToken);
            path[1] = toConverter;
            path[2] = address(toToken);
            return path;
        }

        path[0] = address(fromToken);
        path[1] = fromConverter;
        path[2] = address(bntToken);
        path[3] = toConverter;
        path[4] = address(toToken);
        return path;
    }
}
