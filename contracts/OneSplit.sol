pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
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
import "./interface/ICompound.sol";
import "./interface/IWETH.sol";
import "./UniversalERC20.sol";


contract OneSplit {

    using SafeMath for uint256;
    using UniversalERC20 for IERC20;
    using UniversalERC20 for IWETH;
    using UniversalERC20 for IBancorEtherToken;

    IWETH wethToken = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IBancorEtherToken bancorEtherToken = IBancorEtherToken(0xc0829421C1d260BD3cB3E0F06cfE2D52db2cE315);

    ICompound public compound = ICompound(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    ICompoundEther public cETH = ICompoundEther(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);

    IKyberNetworkProxy public kyberNetworkProxy = IKyberNetworkProxy(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
    IUniswapFactory public uniswapFactory = IUniswapFactory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);
    IBancorContractRegistry public bancorContractRegistry = IBancorContractRegistry(0x52Ae12ABe5D8BD778BD5397F99cA900624CfADD4);
    IBancorNetworkPathFinder bancorNetworkPathFinder = IBancorNetworkPathFinder(0x6F0cD8C4f6F06eAB664C7E3031909452b4B72861);
    IOasisExchange public oasisExchange = IOasisExchange(0x39755357759cE0d7f32dC8dC45414CCa409AE24e);

    function log(uint256) external view {
    }

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags // 1 - Uniswap, 2 - Kyber, 4 - Bancor, 8 - Oasis, 16 - Compound
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
            returnAmount = amount;
            return (returnAmount, distribution);
        }

        if ((disableFlags & 16 == 0) && _isCompoundToken(fromToken)) {
            IERC20 underlying = _compoundUnderlyingAsset(fromToken);
            uint256 compoundRate = ICompoundToken(address(fromToken)).exchangeRateStored();

            return getExpectedReturn(
                underlying,
                toToken,
                amount.mul(compoundRate).div(1e18),
                parts,
                disableFlags
            );
        }

        if ((disableFlags & 16 == 0) && _isCompoundToken(toToken)) {
            IERC20 underlying = _compoundUnderlyingAsset(toToken);
            uint256 compoundRate = ICompoundToken(address(toToken)).exchangeRateStored();

            (returnAmount, distribution) = getExpectedReturn(
                fromToken,
                underlying,
                amount,
                parts,
                disableFlags
            );

            returnAmount = returnAmount.mul(1e18).div(compoundRate);
            return (returnAmount, distribution);
        }

        function(IERC20,IERC20,uint256) view returns(uint256)[4] memory reserves = [
            uint256(disableFlags & 1) != 0 ? _calculateNoReturn : _calculateUniswapReturn,
            uint256(disableFlags & 2) != 0 ? _calculateNoReturn : _calculateKyberReturn,
            uint256(disableFlags & 4) != 0 ? _calculateNoReturn : _calculateBancorReturn,
            uint256(disableFlags & 8) != 0 ? _calculateNoReturn : _calculateOasisReturn
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

    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution, // [Uniswap, Kyber, Bancor, Oasis]
        uint256 disableFlags // 16 - Compound
    ) public payable {
        fromToken.universalTransferFrom(msg.sender, address(this), amount);

        _swap(fromToken, toToken, amount, distribution, disableFlags);

        uint256 returnAmount = toToken.universalBalanceOf(address(this));
        require(returnAmount >= minReturn, "OneSplit: actual return amount is less than minReturn");
        toToken.universalTransfer(msg.sender, returnAmount);
        fromToken.universalTransfer(msg.sender, fromToken.universalBalanceOf(address(this)));
    }

    function _swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution, // [Uniswap, Kyber, Bancor, Oasis]
        uint256 disableFlags // 16 - Compound
    ) internal {
        if (fromToken == toToken) {
            return;
        }

        if ((disableFlags & 16 == 0) && _isCompoundToken(fromToken)) {
            IERC20 underlying = _compoundUnderlyingAsset(fromToken);

            ICompoundToken(address(fromToken)).redeem(amount);
            uint256 underlyingAmount = underlying.universalBalanceOf(address(this));

            return _swap(
                underlying,
                toToken,
                underlyingAmount,
                distribution,
                disableFlags
            );
        }

        if ((disableFlags & 16 == 0) && _isCompoundToken(toToken)) {
            IERC20 underlying = _compoundUnderlyingAsset(toToken);

            _swap(
                fromToken,
                underlying,
                amount,
                distribution,
                disableFlags
            );

            uint256 underlyingAmount = underlying.universalBalanceOf(address(this));

            if (underlying.isETH()) {
                cETH.mint.value(underlyingAmount)();
            } else {
                _infiniteApproveIfNeeded(underlying, address(toToken));
                ICompoundToken(address(toToken)).mint(underlyingAmount);
            }
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

    function goodSwap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 minReturn,
        uint256 parts,
        uint256 disableFlags // 1 - Uniswap, 2 - Kyber, 4 - Bancor, 8 - Oasis, 16 - Compound
    ) public payable {
        (, uint256[] memory distribution) = getExpectedReturn(fromToken, toToken, amount, parts, disableFlags);
        swap(
            fromToken,
            toToken,
            amount,
            minReturn,
            distribution,
            disableFlags
        );
    }

    // View Helpers

    function _calculateUniswapReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) internal view returns(uint256) {
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

        // Check for Uniswap, Oasis and Bancor reserves
        if (reserve == 0x54A4a1167B004b004520c605E3f01906f683413d ||
            reserve == 0xCf1394C5e2e879969fdB1f464cE1487147863dCb ||
            reserve == 0x053AA84FCC676113a57e0EbB0bD1913839874bE4)
        {
            return 0;
        }

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

        // Check for Bancor reserve
        (success,) = reserve.staticcall.gas(2300)(abi.encodeWithSelector(
            IKyberBancorReserve(reserve).bancorEth.selector
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
        address[] memory path = bancorNetworkPathFinder.generatePath(
            fromToken.isETH() ? bancorEtherToken : fromToken,
            toToken.isETH() ? bancorEtherToken : toToken
        );

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
    }

    // Swap Helpers

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
            fromToken.isETH() ? IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) : fromToken,
            amount,
            toToken.isETH() ? IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) : toToken,
            address(this),
            1 << 255,
            0,
            address(0),
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

    function _isCompoundToken(IERC20 token) internal view returns(bool) {
        if (token == cETH) {
            return true;
        }
        (bool isListed,) = compound.markets(address(token));
        return isListed;
    }

    function _compoundUnderlyingAsset(IERC20 asset) internal view returns(IERC20) {
        if (asset == cETH) {
            return IERC20(address(0));
        }
        return IERC20(ICompoundToken(address(asset)).underlying());
    }
}
