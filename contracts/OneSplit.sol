pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
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
import "./interface/IFulcrum.sol";
import "./interface/IWETH.sol";
import "./interface/IChai.sol";
import "./interface/IAaveToken.sol";
import "./UniversalERC20.sol";


library DisableFlags {
    function enabled(uint256 disableFlags, uint256 flag) internal pure returns(bool) {
        return (disableFlags & flag) == 0;
    }

    function disabled(uint256 disableFlags, uint256 flag) internal pure returns(bool) {
        return (disableFlags & flag) != 0;
    }
}


contract OneSplit {

    using SafeMath for uint256;
    using DisableFlags for uint256;
    using ChaiHelper for IChai;
    using UniversalERC20 for IERC20;
    using UniversalERC20 for IWETH;
    using UniversalERC20 for IBancorEtherToken;

    //
    // disableFlags = FLAG_UNISWAP + FLAG_KYBER + ...
    //
    uint256 constant public FLAG_UNISWAP = 0x01;
    uint256 constant public FLAG_KYBER = 0x02;
    uint256 constant public FLAG_BANCOR = 0x04;
    uint256 constant public FLAG_OASIS = 0x08;
    uint256 constant public FLAG_COMPOUND = 0x10;
    uint256 constant public FLAG_FULCRUM = 0x20;
    uint256 constant public FLAG_CHAI = 0x40;
    uint256 constant public FLAG_AAVE = 0x80;

    IERC20 constant public ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    IWETH wethToken = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IBancorEtherToken bancorEtherToken = IBancorEtherToken(0xc0829421C1d260BD3cB3E0F06cfE2D52db2cE315);

    ICompound public compound = ICompound(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    ICompoundEther public cETH = ICompoundEther(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);

    IERC20 public dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IChai public chai = IChai(0x06AF07097C9Eeb7fD685c692751D5C66dB49c215);
    IAaveLendingPool public aave = IAaveLendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

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

    function getAllRatesForDEX(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    ) public view returns(uint256[] memory results) {
        results = new uint256[](parts);
        for (uint i = 0; i < parts; i++) {
            (results[i],) = getExpectedReturn(
                fromToken,
                toToken,
                amount.mul(i + 1).div(parts),
                1,
                disableFlags
            );
        }
    }

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags // 1 - Uniswap, 2 - Kyber, 4 - Bancor, 8 - Oasis, 16 - Compound, 32 - Fulcrum
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

        if (disableFlags.enabled(FLAG_COMPOUND)) {
            if (_isCompoundToken(fromToken)) {
                IERC20 underlying = _compoundUnderlyingAsset(fromToken);
                if (underlying != IERC20(-1)) {
                    uint256 compoundRate = ICompoundToken(address(fromToken)).exchangeRateStored();

                    return getExpectedReturn(
                        underlying,
                        toToken,
                        amount.mul(compoundRate).div(1e18),
                        parts,
                        disableFlags
                    );
                }
            }

            if (_isCompoundToken(toToken)) {
                IERC20 underlying = _compoundUnderlyingAsset(toToken);
                if (underlying != IERC20(-1)) {
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
            }
        }

        if (disableFlags.enabled(FLAG_FULCRUM)) {
            IERC20 underlying = _isFulcrumToken(fromToken);
            if (underlying != IERC20(-1)) {
                uint256 fulcrumRate = IFulcrumToken(address(fromToken)).tokenPrice();

                return getExpectedReturn(
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

                (returnAmount, distribution) = getExpectedReturn(
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

        if (disableFlags.enabled(FLAG_CHAI)) {
            if (fromToken == IERC20(chai)) {
                return getExpectedReturn(
                    dai,
                    toToken,
                    chai.chaiToDai(amount),
                    parts,
                    disableFlags
                );
            }

            if (toToken == IERC20(chai)) {
                (returnAmount, distribution) = getExpectedReturn(
                    fromToken,
                    dai,
                    amount,
                    parts,
                    disableFlags
                );
                return (chai.daiToChai(returnAmount), distribution);
            }
        }

        if (disableFlags.enabled(FLAG_AAVE)) {
            IERC20 underlying = _isAaveToken(fromToken);
            if (underlying != IERC20(-1)) {
                return getExpectedReturn(
                    underlying,
                    toToken,
                    amount,
                    parts,
                    disableFlags
                );
            }

            underlying = _isAaveToken(toToken);
            if (underlying != IERC20(-1)) {
                return getExpectedReturn(
                    fromToken,
                    underlying,
                    amount,
                    parts,
                    disableFlags
                );
            }
        }

        function(IERC20,IERC20,uint256) view returns(uint256)[4] memory reserves = [
            disableFlags.disabled(FLAG_UNISWAP) ? _calculateNoReturn : calculateUniswapReturn,
            disableFlags.disabled(FLAG_KYBER)   ? _calculateNoReturn : calculateKyberReturn,
            disableFlags.disabled(FLAG_BANCOR)  ? _calculateNoReturn : calculateBancorReturn,
            disableFlags.disabled(FLAG_OASIS)   ? _calculateNoReturn : calculateOasisReturn
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
        uint256 disableFlags // 16 - Compound, 32 - Fulcrum
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

        if (disableFlags.enabled(FLAG_COMPOUND)) {
            if (_isCompoundToken(fromToken)) {
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

            if (_isCompoundToken(toToken)) {
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
        }

        if (disableFlags.enabled(FLAG_FULCRUM)) {
            IERC20 underlying = _isFulcrumToken(fromToken);
            if (underlying != IERC20(-1)) {
                if (underlying.isETH()) {
                    IFulcrumToken(address(fromToken)).burnToEther(address(this), amount);
                } else {
                    IFulcrumToken(address(fromToken)).burn(address(this), amount);
                }

                uint256 underlyingAmount = underlying.universalBalanceOf(address(this));

                return _swap(
                    underlying,
                    toToken,
                    underlyingAmount,
                    distribution,
                    disableFlags
                );
            }

            underlying = _isFulcrumToken(toToken);
            if (underlying != IERC20(-1)) {
                _swap(
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

        if (disableFlags.enabled(FLAG_CHAI)) {
            if (fromToken == IERC20(chai)) {
                chai.exit(address(this), amount);

                return _swap(
                    dai,
                    toToken,
                    dai.balanceOf(address(this)),
                    distribution,
                    disableFlags
                );
            }

            if (toToken == IERC20(chai)) {
                _swap(
                    fromToken,
                    dai,
                    amount,
                    distribution,
                    disableFlags
                );

                _infiniteApproveIfNeeded(dai, address(chai));
                chai.join(address(this), dai.balanceOf(address(this)));
                return;
            }
        }

        if (disableFlags.enabled(FLAG_AAVE)) {
            IERC20 underlying = _isAaveToken(fromToken);
            if (underlying != IERC20(-1)) {
                IAaveToken(address(fromToken)).redeem(amount);

                return _swap(
                    underlying,
                    toToken,
                    amount,
                    distribution,
                    disableFlags
                );
            }

            underlying = _isAaveToken(toToken);
            if (underlying != IERC20(-1)) {
                _swap(
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
        uint256 disableFlags // 1 - Uniswap, 2 - Kyber, 4 - Bancor, 8 - Oasis, 16 - Compound, 32 - Fulcrum
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

    function calculateUniswapReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
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

    function calculateKyberReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) public view returns(uint256) {
        (bool success, bytes memory data) = address(kyberNetworkProxy).staticcall.gas(2300)(abi.encodeWithSelector(
            kyberNetworkProxy.kyberNetworkContract.selector
        ));
        if (!success) {
            return 0;
        }

        IKyberNetworkContract kyberNetworkContract = IKyberNetworkContract(abi.decode(data, (address)));

        if (fromToken.isETH() || toToken.isETH()) {
            return _calculateKyberReturnWithEth(kyberNetworkContract, fromToken, toToken, amount);
        }

        uint256 value = _calculateKyberReturnWithEth(kyberNetworkContract, fromToken, ETH_ADDRESS, amount);
        if (value == 0) {
            return 0;
        }

        return _calculateKyberReturnWithEth(kyberNetworkContract, ETH_ADDRESS, toToken, value);
    }

    function _calculateKyberReturnWithEth(
        IKyberNetworkContract kyberNetworkContract,
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) public view returns(uint256) {
        (bool success, bytes memory data) = address(kyberNetworkContract).staticcall.gas(200000)(abi.encodeWithSelector(
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

        if (reserve == 0x54A4a1167B004b004520c605E3f01906f683413d || // Uniswap
            reserve == 0xCf1394C5e2e879969fdB1f464cE1487147863dCb || // Oasis
            reserve == 0x053AA84FCC676113a57e0EbB0bD1913839874bE4)   // Bancor
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

    function calculateBancorReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) public view returns(uint256) {
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

    function calculateOasisReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
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

    function _isCompoundToken(IERC20 token) internal view returns(bool) {
        if (token == cETH) {
            return true;
        }

        (bool success, bytes memory data) = address(compound).staticcall.gas(5000)(abi.encodeWithSelector(
            compound.markets.selector,
            token
        ));
        if (!success) {
            return false;
        }

        (bool isListed,) = abi.decode(data, (bool,uint256));
        return isListed;
    }

    function _compoundUnderlyingAsset(IERC20 asset) internal view returns(IERC20) {
        if (asset == cETH) {
            return IERC20(address(0));
        }

        (bool success, bytes memory data) = address(asset).staticcall.gas(5000)(abi.encodeWithSelector(
            ICompoundToken(address(asset)).underlying.selector
        ));
        if (!success) {
            return IERC20(-1);
        }

        return abi.decode(data, (IERC20));
    }

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
