pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IUniswapFactory.sol";
import "./interface/IKyberNetworkProxy.sol";
import "./interface/IKyberUniswapReserve.sol";
import "./interface/IKyberOasisReserve.sol";
import "./interface/IKyberBancorReserve.sol";
import "./interface/IBancorNetwork.sol";
import "./interface/IBancorContractRegistry.sol";
import "./interface/IBancorNetworkPathFinder.sol";
import "./interface/IBancorEtherToken.sol";
import "./interface/IOasisExchange.sol";
import "./interface/IWETH.sol";
import "./interface/ICurve.sol";
import "./IOneSplit.sol";
import "./UniversalERC20.sol";


library DisableFlags {
    function check(uint256 disableFlags, uint256 flag) internal pure returns(bool) {
        return (disableFlags & flag) != 0;
    }
}


contract OneSplitBaseBase {
    using SafeMath for uint256;
    using DisableFlags for uint256;

    using UniversalERC20 for IERC20;
    using UniversalERC20 for IWETH;
    using UniversalERC20 for IBancorEtherToken;

    IERC20 constant public ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    IERC20 public dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 public usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 public tusd = IERC20(0x0000000000085d4780B73119b644AE5ecd22b376);
    IERC20 public busd = IERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53);
    IERC20 public susd = IERC20(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
    IWETH public wethToken = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IBancorEtherToken public bancorEtherToken = IBancorEtherToken(0xc0829421C1d260BD3cB3E0F06cfE2D52db2cE315);

    IKyberNetworkProxy public kyberNetworkProxy = IKyberNetworkProxy(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
    IUniswapFactory public uniswapFactory = IUniswapFactory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);
    IBancorContractRegistry public bancorContractRegistry = IBancorContractRegistry(0x52Ae12ABe5D8BD778BD5397F99cA900624CfADD4);
    IBancorNetworkPathFinder bancorNetworkPathFinder = IBancorNetworkPathFinder(0x6F0cD8C4f6F06eAB664C7E3031909452b4B72861);
    IOasisExchange public oasisExchange = IOasisExchange(0x794e6e91555438aFc3ccF1c5076A74F42133d08D);
    ICurve public curveCompound = ICurve(0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56);
    ICurve public curveUsdt = ICurve(0x52EA46506B9CC5Ef470C5bf89f17Dc28bB35D85C);
    ICurve public curveY = ICurve(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51);
    ICurve public curveBinance = ICurve(0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27);
    ICurve public curveSynthetix = ICurve(0x3b12e1fBb468BEa80B492d635976809Bf950186C);
}


contract OneSplitBaseView is IOneSplitView, OneSplitBaseBase {
    function log(uint256) external view {
    }

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags // 1 - Uniswap, 2 - Kyber, 4 - Bancor, 8 - Oasis, 16 - Compound, 32 - Fulcrum, 64 - Chai, 128 - Aave, 256 - SmartToken
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution // [Uniswap, Kyber, Bancor, Oasis]
        )
    {
        distribution = new uint256[](9);

        if (fromToken == toToken) {
            return (amount, distribution);
        }

        function(IERC20,IERC20,uint256,uint256) view returns(uint256)[9] memory reserves = [
            disableFlags.check(FLAG_DISABLE_UNISWAP)         ? _calculateNoReturn : calculateUniswapReturn,
            disableFlags.check(FLAG_DISABLE_KYBER)           ? _calculateNoReturn : calculateKyberReturn,
            disableFlags.check(FLAG_DISABLE_BANCOR)          ? _calculateNoReturn : calculateBancorReturn,
            disableFlags.check(FLAG_DISABLE_OASIS)           ? _calculateNoReturn : calculateOasisReturn,
            disableFlags.check(FLAG_DISABLE_CURVE_COMPOUND)  ? _calculateNoReturn : calculateCurveCompound,
            disableFlags.check(FLAG_DISABLE_CURVE_USDT)      ? _calculateNoReturn : calculateCurveUsdt,
            disableFlags.check(FLAG_DISABLE_CURVE_Y)         ? _calculateNoReturn : calculateCurveY,
            disableFlags.check(FLAG_DISABLE_CURVE_BINANCE)   ? _calculateNoReturn : calculateCurveBinance,
            disableFlags.check(FLAG_DISABLE_CURVE_SYNTHETIX) ? _calculateNoReturn : calculateCurveSynthetix
        ];

        uint256[9] memory rates;
        uint256[9] memory fullRates;
        for (uint i = 0; i < rates.length; i++) {
            rates[i] = reserves[i](fromToken, toToken, amount.div(parts), disableFlags);
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
                    srcAmount.mul(distribution[bestIndex] + 1).div(parts),
                    disableFlags
                );
                if (newRate > fullRates[bestIndex]) {
                    rates[bestIndex] = newRate.sub(fullRates[bestIndex]);
                } else {
                    rates[bestIndex] = 0;
                }
                this.log(rates[bestIndex]);
                fullRates[bestIndex] = newRate;
            }
        }
    }

    // View Helpers

    function calculateCurveCompound(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*disableFlags*/
    ) public view returns(uint256) {
        int128 i = (fromToken == dai ? 1 : 0) + (fromToken == usdc ? 2 : 0);
        int128 j = (destToken == dai ? 1 : 0) + (destToken == usdc ? 2 : 0);
        if (i == 0 || j == 0) {
            return 0;
        }

        return curveCompound.get_dy_underlying(i - 1, j - 1, amount);
    }

    function calculateCurveUsdt(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*disableFlags*/
    ) public view returns(uint256) {
        int128 i = (fromToken == dai ? 1 : 0) + (fromToken == usdc ? 2 : 0) + (fromToken == usdt ? 3 : 0);
        int128 j = (destToken == dai ? 1 : 0) + (destToken == usdc ? 2 : 0) + (destToken == usdt ? 3 : 0);
        if (i == 0 || j == 0) {
            return 0;
        }

        return curveUsdt.get_dy_underlying(i - 1, j - 1, amount);
    }

    function calculateCurveY(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*disableFlags*/
    ) public view returns(uint256) {
        int128 i = (fromToken == dai ? 1 : 0) + (fromToken == usdc ? 2 : 0) + (fromToken == usdt ? 3 : 0) + (fromToken == tusd ? 4 : 0);
        int128 j = (destToken == dai ? 1 : 0) + (destToken == usdc ? 2 : 0) + (destToken == usdt ? 3 : 0) + (destToken == tusd ? 4 : 0);
        if (i == 0 || j == 0) {
            return 0;
        }

        return curveY.get_dy_underlying(i - 1, j - 1, amount);
    }

    function calculateCurveBinance(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*disableFlags*/
    ) public view returns(uint256) {
        int128 i = (fromToken == dai ? 1 : 0) + (fromToken == usdc ? 2 : 0) + (fromToken == usdt ? 3 : 0) + (fromToken == busd ? 4 : 0);
        int128 j = (destToken == dai ? 1 : 0) + (destToken == usdc ? 2 : 0) + (destToken == usdt ? 3 : 0) + (destToken == busd ? 4 : 0);
        if (i == 0 || j == 0) {
            return 0;
        }

        return curveBinance.get_dy_underlying(i - 1, j - 1, amount);
    }

    function calculateCurveSynthetix(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*disableFlags*/
    ) public view returns(uint256) {
        int128 i = (fromToken == dai ? 1 : 0) + (fromToken == usdc ? 2 : 0) + (fromToken == usdt ? 3 : 0) + (fromToken == tusd ? 4 : 0) + (fromToken == susd ? 5 : 0);
        int128 j = (destToken == dai ? 1 : 0) + (destToken == usdc ? 2 : 0) + (destToken == usdt ? 3 : 0) + (destToken == tusd ? 4 : 0) + (destToken == susd ? 5 : 0);
        if (i == 0 || j == 0) {
            return 0;
        }

        if (fromToken != susd && destToken != susd) {
            return 0;
        }

        return curveSynthetix.get_dy_underlying(i - 1, j - 1, amount);
    }

    function calculateUniswapReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 /*disableFlags*/
    ) public view returns(uint256) {
        uint256 returnAmount = amount;

        if (!fromToken.isETH()) {
            IUniswapExchange fromExchange = uniswapFactory.getExchange(fromToken);
            if (fromExchange != IUniswapExchange(0)) {
                (bool success, bytes memory data) = address(fromExchange).staticcall.gas(200000)(
                    abi.encodeWithSelector(
                        fromExchange.getTokenToEthInputPrice.selector,
                        returnAmount
                    )
                );
                if (success) {
                    returnAmount = abi.decode(data, (uint256));
                } else {
                    returnAmount = 0;
                }
            } else {
                returnAmount = 0;
            }
        }

        if (!toToken.isETH()) {
            IUniswapExchange toExchange = uniswapFactory.getExchange(toToken);
            if (toExchange != IUniswapExchange(0)) {
                (bool success, bytes memory data) = address(toExchange).staticcall.gas(200000)(
                    abi.encodeWithSelector(
                        toExchange.getEthToTokenInputPrice.selector,
                        returnAmount
                    )
                );
                if (success) {
                    returnAmount = abi.decode(data, (uint256));
                } else {
                    returnAmount = 0;
                }
            } else {
                returnAmount = 0;
            }
        }

        return returnAmount;
    }

    function calculateKyberReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 disableFlags
    ) public view returns(uint256) {
        (bool success, bytes memory data) = address(kyberNetworkProxy).staticcall.gas(2300)(abi.encodeWithSelector(
            kyberNetworkProxy.kyberNetworkContract.selector
        ));
        if (!success) {
            return 0;
        }

        IKyberNetworkContract kyberNetworkContract = IKyberNetworkContract(abi.decode(data, (address)));

        if (fromToken.isETH() || toToken.isETH()) {
            return _calculateKyberReturnWithEth(kyberNetworkContract, fromToken, toToken, amount, disableFlags);
        }

        uint256 value = _calculateKyberReturnWithEth(kyberNetworkContract, fromToken, ETH_ADDRESS, amount, disableFlags);
        if (value == 0) {
            return 0;
        }

        return _calculateKyberReturnWithEth(kyberNetworkContract, ETH_ADDRESS, toToken, value, disableFlags);
    }

    function _calculateKyberReturnWithEth(
        IKyberNetworkContract kyberNetworkContract,
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 disableFlags
    ) public view returns(uint256) {
        require(fromToken.isETH() || toToken.isETH(), "One of the tokens should be ETH");

        (bool success, bytes memory data) = address(kyberNetworkContract).staticcall.gas(1500000)(abi.encodeWithSelector(
            kyberNetworkContract.searchBestRate.selector,
            fromToken.isETH() ? ETH_ADDRESS : fromToken,
            toToken.isETH() ? ETH_ADDRESS : toToken,
            amount,
            true
        ));
        if (!success) {
            return 0;
        }

        (address reserve, uint256 rate) = abi.decode(data, (address,uint256));

        if ((reserve == 0x31E085Afd48a1d6e51Cc193153d625e8f0514C7F && !disableFlags.check(FLAG_ENABLE_KYBER_UNISWAP_RESERVE)) ||
            (reserve == 0x1E158c0e93c30d24e918Ef83d1e0bE23595C3c0f && !disableFlags.check(FLAG_ENABLE_KYBER_OASIS_RESERVE)) ||
            (reserve == 0x053AA84FCC676113a57e0EbB0bD1913839874bE4 && !disableFlags.check(FLAG_ENABLE_KYBER_BANCOR_RESERVE)))
        {
            return 0;
        }

        if (!disableFlags.check(FLAG_ENABLE_KYBER_UNISWAP_RESERVE)) {
            (success,) = reserve.staticcall.gas(2300)(abi.encodeWithSelector(
                IKyberUniswapReserve(reserve).uniswapFactory.selector
            ));
            if (success) {
                return 0;
            }
        }

        if (!disableFlags.check(FLAG_ENABLE_KYBER_OASIS_RESERVE)) {
            (success,) = reserve.staticcall.gas(2300)(abi.encodeWithSelector(
                IKyberOasisReserve(reserve).otc.selector
            ));
            if (success) {
                return 0;
            }
        }

        if (!disableFlags.check(FLAG_ENABLE_KYBER_BANCOR_RESERVE)) {
            (success,) = reserve.staticcall.gas(2300)(abi.encodeWithSelector(
                IKyberBancorReserve(reserve).bancorEth.selector
            ));
            if (success) {
                return 0;
            }
        }

        return rate.mul(amount)
            .mul(10 ** IERC20(toToken).universalDecimals())
            .div(10 ** IERC20(fromToken).universalDecimals())
            .div(1e18);
    }

    function calculateBancorReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 /*disableFlags*/
    ) public view returns(uint256) {
        IBancorNetwork bancorNetwork = IBancorNetwork(bancorContractRegistry.addressOf("BancorNetwork"));
        address[] memory path = bancorNetworkPathFinder.generatePath(
            fromToken.isETH() ? bancorEtherToken : fromToken,
            toToken.isETH() ? bancorEtherToken : toToken
        );

        (bool success, bytes memory data) = address(bancorNetwork).staticcall.gas(500000)(
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

    function calculateOasisReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 /*disableFlags*/
    ) public view returns(uint256) {
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
        uint256 /*amount*/,
        uint256 /*disableFlags*/
    ) internal view returns(uint256) {
        this;
    }
}


contract OneSplitBase is IOneSplit, OneSplitBaseBase {
    function() external payable {
        // solium-disable-next-line security/no-tx-origin
        require(msg.sender != tx.origin);
    }

    function _swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution, // [Uniswap, Kyber, Bancor, Oasis]
        uint256 /*disableFlags*/ // 16 - Compound, 32 - Fulcrum, 64 - Chai, 128 - Aave, 256 - SmartToken
    ) internal {
        if (fromToken == toToken) {
            return;
        }

        function(IERC20,IERC20,uint256) returns(uint256)[9] memory reserves = [
            _swapOnUniswap,
            _swapOnKyber,
            _swapOnBancor,
            _swapOnOasis,
            _swapOnCurveCompound,
            _swapOnCurveUsdt,
            _swapOnCurveY,
            _swapOnCurveBinance,
            _swapOnCurveSynthetix
        ];

        uint256 parts = 0;
        uint256 lastNonZeroIndex = 0;
        for (uint i = 0; i < reserves.length; i++) {
            if (distribution[i] > 0) {
                parts = parts.add(distribution[i]);
                lastNonZeroIndex = i;
            }
        }

        require(parts > 0, "OneSplit: distribution should contain non-zeros");

        uint256 remainingAmount = amount;
        for (uint i = 0; i < reserves.length; i++) {
            if (distribution[i] == 0) {
                continue;
            }

            uint256 swapAmount = amount.mul(distribution[i]).div(parts);
            if (i == lastNonZeroIndex) {
                swapAmount = remainingAmount;
            }
            remainingAmount -= swapAmount;
            reserves[i](fromToken, toToken, swapAmount);
        }
    }

    // Swap helpers

    function _swapOnCurveCompound(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {
        int128 i = (fromToken == dai ? 1 : 0) + (fromToken == usdc ? 2 : 0);
        int128 j = (destToken == dai ? 1 : 0) + (destToken == usdc ? 2 : 0);
        if (i == 0 || j == 0) {
            return 0;
        }

        _infiniteApproveIfNeeded(fromToken, address(curveCompound));
        curveCompound.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurveUsdt(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {
        int128 i = (fromToken == dai ? 1 : 0) + (fromToken == usdc ? 2 : 0) + (fromToken == usdt ? 3 : 0);
        int128 j = (destToken == dai ? 1 : 0) + (destToken == usdc ? 2 : 0) + (destToken == usdt ? 3 : 0);
        if (i == 0 || j == 0) {
            return 0;
        }

        _infiniteApproveIfNeeded(fromToken, address(curveUsdt));
        curveUsdt.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurveY(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {
        int128 i = (fromToken == dai ? 1 : 0) + (fromToken == usdc ? 2 : 0) + (fromToken == usdt ? 3 : 0) + (fromToken == tusd ? 4 : 0);
        int128 j = (destToken == dai ? 1 : 0) + (destToken == usdc ? 2 : 0) + (destToken == usdt ? 3 : 0) + (destToken == tusd ? 4 : 0);
        if (i == 0 || j == 0) {
            return 0;
        }

        _infiniteApproveIfNeeded(fromToken, address(curveY));
        curveY.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurveBinance(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {
        int128 i = (fromToken == dai ? 1 : 0) + (fromToken == usdc ? 2 : 0) + (fromToken == usdt ? 3 : 0) + (fromToken == busd ? 4 : 0);
        int128 j = (destToken == dai ? 1 : 0) + (destToken == usdc ? 2 : 0) + (destToken == usdt ? 3 : 0) + (destToken == busd ? 4 : 0);
        if (i == 0 || j == 0) {
            return 0;
        }

        _infiniteApproveIfNeeded(fromToken, address(curveBinance));
        curveBinance.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurveSynthetix(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {
        int128 i = (fromToken == dai ? 1 : 0) + (fromToken == usdc ? 2 : 0) + (fromToken == usdt ? 3 : 0) + (fromToken == tusd ? 4 : 0) + (fromToken == susd ? 5 : 0);
        int128 j = (destToken == dai ? 1 : 0) + (destToken == usdc ? 2 : 0) + (destToken == usdt ? 3 : 0) + (destToken == tusd ? 4 : 0) + (destToken == susd ? 5 : 0);
        if (i == 0 || j == 0) {
            return 0;
        }

        if (fromToken != susd && destToken != susd) {
            return 0;
        }

        _infiniteApproveIfNeeded(fromToken, address(curveSynthetix));
        curveSynthetix.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnUniswap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) internal returns(uint256) {

        uint256 returnAmount = amount;

        if (!fromToken.isETH()) {
            IUniswapExchange fromExchange = uniswapFactory.getExchange(fromToken);
            if (fromExchange != IUniswapExchange(0)) {
                _infiniteApproveIfNeeded(fromToken, address(fromExchange));
                returnAmount = fromExchange.tokenToEthSwapInput(returnAmount, 1, now);
            }
        }

        if (!toToken.isETH()) {
            IUniswapExchange toExchange = uniswapFactory.getExchange(toToken);
            if (toExchange != IUniswapExchange(0)) {
                returnAmount = toExchange.ethToTokenSwapInput.value(returnAmount)(1, now);
            }
        }

        return returnAmount;
    }

    function _swapOnKyber(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) internal returns(uint256) {
        _infiniteApproveIfNeeded(fromToken, address(kyberNetworkProxy));
        return kyberNetworkProxy.tradeWithHint.value(fromToken.isETH() ? amount : 0)(
            fromToken.isETH() ? ETH_ADDRESS : fromToken,
            amount,
            toToken.isETH() ? ETH_ADDRESS : toToken,
            address(this),
            1 << 255,
            0,
            0x4D37f28D2db99e8d35A6C725a5f1749A085850a3,
            ""
        );
    }

    function _swapOnBancor(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) internal returns(uint256) {
        if (fromToken.isETH()) {
            bancorEtherToken.deposit.value(amount)();
        }

        IBancorNetwork bancorNetwork = IBancorNetwork(bancorContractRegistry.addressOf("BancorNetwork"));
        address[] memory path = bancorNetworkPathFinder.generatePath(
            fromToken.isETH() ? bancorEtherToken : fromToken,
            toToken.isETH() ? bancorEtherToken : toToken
        );

        _infiniteApproveIfNeeded(fromToken.isETH() ? bancorEtherToken : fromToken, address(bancorNetwork));
        uint256 returnAmount = bancorNetwork.claimAndConvert(path, amount, 1);

        if (toToken.isETH()) {
            bancorEtherToken.withdraw(bancorEtherToken.balanceOf(address(this)));
        }

        return returnAmount;
    }

    function _swapOnOasis(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) internal returns(uint256) {
        if (fromToken.isETH()) {
            wethToken.deposit.value(amount)();
        }

        _infiniteApproveIfNeeded(fromToken.isETH() ? wethToken : fromToken, address(oasisExchange));
        uint256 returnAmount = oasisExchange.sellAllAmount(
            fromToken.isETH() ? wethToken : fromToken,
            amount,
            toToken.isETH() ? wethToken : toToken,
            1
        );

        if (toToken.isETH()) {
            wethToken.withdraw(wethToken.balanceOf(address(this)));
        }

        return returnAmount;
    }

    // Helpers

    function _infiniteApproveIfNeeded(IERC20 token, address to) internal {
        if (!token.isETH()) {
            if ((token.allowance(address(this), to) >> 255) == 0) {
                token.universalApprove(to, uint256(- 1));
            }
        }
    }
}
