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
import "./IOneSplit.sol";
import "./UniversalERC20.sol";


library DisableFlags {
    function enabled(uint256 disableFlags, uint256 flag) internal pure returns(bool) {
        return (disableFlags & flag) == 0;
    }

    function disabledReserve(uint256 disableFlags, uint256 flag) internal pure returns(bool) {
        // For flag disabled by default (Kyber reserves)
        return enabled(disableFlags, flag);
    }

    function disabled(uint256 disableFlags, uint256 flag) internal pure returns(bool) {
        return (disableFlags & flag) != 0;
    }
}


contract OneSplitBase is IOneSplit {
    using SafeMath for uint256;
    using DisableFlags for uint256;

    using UniversalERC20 for IERC20;
    using UniversalERC20 for IWETH;
    using UniversalERC20 for IBancorEtherToken;

    IERC20 constant public ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    IERC20 public dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IWETH public wethToken = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IBancorEtherToken public bancorEtherToken = IBancorEtherToken(0xc0829421C1d260BD3cB3E0F06cfE2D52db2cE315);

    IKyberNetworkProxy public kyberNetworkProxy = IKyberNetworkProxy(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
    IUniswapFactory public uniswapFactory = IUniswapFactory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);
    IBancorContractRegistry public bancorContractRegistry = IBancorContractRegistry(0x52Ae12ABe5D8BD778BD5397F99cA900624CfADD4);
    IBancorNetworkPathFinder bancorNetworkPathFinder = IBancorNetworkPathFinder(0x6F0cD8C4f6F06eAB664C7E3031909452b4B72861);
    IOasisExchange public oasisExchange = IOasisExchange(0x39755357759cE0d7f32dC8dC45414CCa409AE24e);

    function() external payable {
        // solium-disable-next-line security/no-tx-origin
        require(msg.sender != tx.origin);
    }

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
        distribution = new uint256[](4);

        if (fromToken == toToken) {
            return (amount, distribution);
        }

        function(IERC20,IERC20,uint256,uint256) view returns(uint256)[4] memory reserves = [
            disableFlags.disabled(FLAG_UNISWAP) ? _calculateNoReturn : calculateUniswapReturn,
            disableFlags.disabled(FLAG_KYBER)   ? _calculateNoReturn : calculateKyberReturn,
            disableFlags.disabled(FLAG_BANCOR)  ? _calculateNoReturn : calculateBancorReturn,
            disableFlags.disabled(FLAG_OASIS)   ? _calculateNoReturn : calculateOasisReturn
        ];

        uint256[4] memory rates;
        uint256[4] memory fullRates;
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

        function(IERC20,IERC20,uint256) returns(uint256)[4] memory reserves = [
            _swapOnUniswap,
            _swapOnKyber,
            _swapOnBancor,
            _swapOnOasis
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

    // View Helpers

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

        if ((reserve == 0x31E085Afd48a1d6e51Cc193153d625e8f0514C7F && disableFlags.disabledReserve(FLAG_KYBER_UNISWAP_RESERVE)) ||
            (reserve == 0xCf1394C5e2e879969fdB1f464cE1487147863dCb && disableFlags.disabledReserve(FLAG_KYBER_OASIS_RESERVE)) ||
            (reserve == 0x053AA84FCC676113a57e0EbB0bD1913839874bE4 && disableFlags.disabledReserve(FLAG_KYBER_BANCOR_RESERVE)))
        {
            return 0;
        }

        if (disableFlags.disabledReserve(FLAG_KYBER_UNISWAP_RESERVE)) {
            (success,) = reserve.staticcall.gas(2300)(abi.encodeWithSelector(
                IKyberUniswapReserve(reserve).uniswapFactory.selector
            ));
            if (success) {
                return 0;
            }
        }

        if (disableFlags.disabledReserve(FLAG_KYBER_OASIS_RESERVE)) {
            (success,) = reserve.staticcall.gas(2300)(abi.encodeWithSelector(
                IKyberOasisReserve(reserve).otc.selector
            ));
            if (success) {
                return 0;
            }
        }

        if (disableFlags.disabledReserve(FLAG_KYBER_BANCOR_RESERVE)) {
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

    // Swap helpers

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