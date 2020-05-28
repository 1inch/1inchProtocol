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
//import "./interface/IBancorNetworkPathFinder.sol";
import "./interface/IBancorConverterRegistry.sol";
import "./interface/IBancorEtherToken.sol";
import "./interface/IOasisExchange.sol";
import "./interface/IWETH.sol";
import "./interface/ICurve.sol";
import "./interface/IChai.sol";
import "./interface/ICompound.sol";
import "./interface/IAaveToken.sol";
import "./interface/IMooniswap.sol";
import "./interface/IUniswapV2Factory.sol";
import "./interface/IDForceSwap.sol";
import "./interface/IShell.sol";
import "./IOneSplit.sol";
import "./UniversalERC20.sol";


contract IOneSplitView is IOneSplitConsts {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        );
}


library DisableFlags {
    function check(uint256 flags, uint256 flag) internal pure returns(bool) {
        return (flags & flag) != 0;
    }
}


contract OneSplitRoot {
    using SafeMath for uint256;
    using DisableFlags for uint256;

    using UniversalERC20 for IERC20;
    using UniversalERC20 for IWETH;
    using UniversalERC20 for IBancorEtherToken;
    using UniswapV2ExchangeLib for IUniswapV2Exchange;
    using ChaiHelper for IChai;

    uint256 constant public DEXES_COUNT = 22;
    IERC20 constant public ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    IERC20 constant public dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 constant public bnt = IERC20(0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C);
    IERC20 constant public usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 constant public usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 constant public tusd = IERC20(0x0000000000085d4780B73119b644AE5ecd22b376);
    IERC20 constant public busd = IERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53);
    IERC20 constant public susd = IERC20(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
    IERC20 constant public pax = IERC20(0x8E870D67F660D95d5be530380D0eC0bd388289E1);
    IWETH constant public weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IBancorEtherToken constant public bancorEtherToken = IBancorEtherToken(0xc0829421C1d260BD3cB3E0F06cfE2D52db2cE315);
    IChai constant public chai = IChai(0x06AF07097C9Eeb7fD685c692751D5C66dB49c215);
    IERC20 constant public renbtc = IERC20(0x93054188d876f558f4a66B2EF1d97d16eDf0895B);
    IERC20 constant public wbtc = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IERC20 constant public tbtc = IERC20(0x1bBE271d15Bb64dF0bc6CD28Df9Ff322F2eBD847);
    IERC20 constant public hbtc = IERC20(0x0316EB71485b0Ab14103307bf65a021042c6d380);

    IKyberNetworkProxy constant public kyberNetworkProxy = IKyberNetworkProxy(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
    IUniswapFactory constant public uniswapFactory = IUniswapFactory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);
    IBancorContractRegistry constant public bancorContractRegistry = IBancorContractRegistry(0x52Ae12ABe5D8BD778BD5397F99cA900624CfADD4);
    //IBancorNetworkPathFinder constant public bancorNetworkPathFinder = IBancorNetworkPathFinder(0x6F0cD8C4f6F06eAB664C7E3031909452b4B72861);
    IBancorConverterRegistry constant public bancorConverterRegistry = IBancorConverterRegistry(0xf6E2D7F616B67E46D708e4410746E9AAb3a4C518);
    IOasisExchange constant public oasisExchange = IOasisExchange(0x794e6e91555438aFc3ccF1c5076A74F42133d08D);
    ICurve constant public curveCompound = ICurve(0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56);
    ICurve constant public curveUsdt = ICurve(0x52EA46506B9CC5Ef470C5bf89f17Dc28bB35D85C);
    ICurve constant public curveY = ICurve(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51);
    ICurve constant public curveBinance = ICurve(0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27);
    ICurve constant public curveSynthetix = ICurve(0xA5407eAE9Ba41422680e2e00537571bcC53efBfD);
    ICurve constant public curvePax = ICurve(0x06364f10B501e868329afBc005b3492902d6C763);
    ICurve constant public curveRenBtc = ICurve(0x8474c1236F0Bc23830A23a41aBB81B2764bA9f4F);
    ICurve constant public curveTBtc = ICurve(0x9726e9314eF1b96E45f40056bEd61A088897313E);
    IShell constant public shell = IShell(0xA8253a440Be331dC4a7395B73948cCa6F19Dc97D);
    IAaveLendingPool constant public aave = IAaveLendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);
    ICompound constant public compound = ICompound(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    ICompoundEther constant public cETH = ICompoundEther(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);
    IMooniswapRegistry constant public mooniswapRegistry = IMooniswapRegistry(0x7079E8517594e5b21d2B9a0D17cb33F5FE2bca70);
    IUniswapV2Factory constant public uniswapV2 = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IDForceSwap constant public dforceSwap = IDForceSwap(0x03eF3f37856bD08eb47E2dE7ABc4Ddd2c19B60F2);

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

        if (fromToken == bnt || toToken == bnt) {
            path = new address[](3);
        } else {
            path = new address[](5);
        }

        address fromConverter;
        address toConverter;

        if (fromToken != bnt) {
            (bool success, bytes memory data) = address(bancorConverterRegistry).staticcall.gas(10000)(abi.encodeWithSelector(
                bancorConverterRegistry.getConvertibleTokenSmartToken.selector,
                fromToken.isETH() ? bnt : fromToken,
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

        if (toToken != bnt) {
            (bool success, bytes memory data) = address(bancorConverterRegistry).staticcall.gas(10000)(abi.encodeWithSelector(
                bancorConverterRegistry.getConvertibleTokenSmartToken.selector,
                toToken.isETH() ? bnt : toToken,
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

        if (toToken == bnt) {
            path[0] = address(fromToken);
            path[1] = fromConverter;
            path[2] = address(bnt);
            return path;
        }

        if (fromToken == bnt) {
            path[0] = address(bnt);
            path[1] = toConverter;
            path[2] = address(toToken);
            return path;
        }

        path[0] = address(fromToken);
        path[1] = fromConverter;
        path[2] = address(bnt);
        path[3] = toConverter;
        path[4] = address(toToken);
        return path;
    }

    function _getCompoundToken(IERC20 token) internal pure returns(ICompoundToken) {
        if (token.isETH()) { // ETH
            return ICompoundToken(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);
        }
        if (token == IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F)) { // DAI
            return ICompoundToken(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
        }
        if (token == IERC20(0x0D8775F648430679A709E98d2b0Cb6250d2887EF)) { // BAT
            return ICompoundToken(0x6C8c6b02E7b2BE14d4fA6022Dfd6d75921D90E4E);
        }
        if (token == IERC20(0x1985365e9f78359a9B6AD760e32412f4a445E862)) { // REP
            return ICompoundToken(0x158079Ee67Fce2f58472A96584A73C7Ab9AC95c1);
        }
        if (token == IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)) { // USDC
            return ICompoundToken(0x39AA39c021dfbaE8faC545936693aC917d5E7563);
        }
        if (token == IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599)) { // WBTC
            return ICompoundToken(0xC11b1268C1A384e55C48c2391d8d480264A3A7F4);
        }
        if (token == IERC20(0xE41d2489571d322189246DaFA5ebDe1F4699F498)) { // ZRX
            return ICompoundToken(0xB3319f5D18Bc0D84dD1b4825Dcde5d5f7266d407);
        }
        if (token == IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7)) { // USDT
            return ICompoundToken(0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9);
        }

        return ICompoundToken(0);
    }

    function _getAaveToken(IERC20 token) internal pure returns(IAaveToken) {
        if (token.isETH()) { // ETH
            return IAaveToken(0x3a3A65aAb0dd2A17E3F1947bA16138cd37d08c04);
        }
        if (token == IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F)) { // DAI
            return IAaveToken(0xfC1E690f61EFd961294b3e1Ce3313fBD8aa4f85d);
        }
        if (token == IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)) { // USDC
            return IAaveToken(0x9bA00D6856a4eDF4665BcA2C2309936572473B7E);
        }
        if (token == IERC20(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51)) { // SUSD
            return IAaveToken(0x625aE63000f46200499120B906716420bd059240);
        }
        if (token == IERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53)) { // BUSD
            return IAaveToken(0x6Ee0f7BB50a54AB5253dA0667B0Dc2ee526C30a8);
        }
        if (token == IERC20(0x0000000000085d4780B73119b644AE5ecd22b376)) { // TUSD
            return IAaveToken(0x4DA9b813057D04BAef4e5800E36083717b4a0341);
        }
        if (token == IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7)) { // USDT
            return IAaveToken(0x71fc860F7D3A592A4a98740e39dB31d25db65ae8);
        }
        if (token == IERC20(0x0D8775F648430679A709E98d2b0Cb6250d2887EF)) { // BAT
            return IAaveToken(0xE1BA0FB44CCb0D11b80F92f4f8Ed94CA3fF51D00);
        }
        if (token == IERC20(0xdd974D5C2e2928deA5F71b9825b8b646686BD200)) { // KNC
            return IAaveToken(0x9D91BE44C06d373a8a226E1f3b146956083803eB);
        }
        if (token == IERC20(0x80fB784B7eD66730e8b1DBd9820aFD29931aab03)) { // LEND
            return IAaveToken(0x7D2D3688Df45Ce7C552E19c27e007673da9204B8);
        }
        if (token == IERC20(0x514910771AF9Ca656af840dff83E8264EcF986CA)) { // LINK
            return IAaveToken(0xA64BD6C70Cb9051F6A9ba1F163Fdc07E0DfB5F84);
        }
        if (token == IERC20(0x0F5D2fB29fb7d3CFeE444a200298f468908cC942)) { // MANA
            return IAaveToken(0x6FCE4A401B6B80ACe52baAefE4421Bd188e76F6f);
        }
        if (token == IERC20(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2)) { // MKR
            return IAaveToken(0x7deB5e830be29F91E298ba5FF1356BB7f8146998);
        }
        if (token == IERC20(0x1985365e9f78359a9B6AD760e32412f4a445E862)) { // REP
            return IAaveToken(0x71010A9D003445aC60C4e6A7017c1E89A477B438);
        }
        if (token == IERC20(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F)) { // SNX
            return IAaveToken(0x328C4c80BC7aCa0834Db37e6600A6c49E12Da4DE);
        }
        if (token == IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599)) { // WBTC
            return IAaveToken(0xFC4B8ED459e00e5400be803A9BB3954234FD50e3);
        }
        if (token == IERC20(0xE41d2489571d322189246DaFA5ebDe1F4699F498)) { // ZRX
            return IAaveToken(0x6Fb0855c404E09c47C3fBCA25f08d4E41f9F062f);
        }

        return IAaveToken(0);
    }

    function _infiniteApproveIfNeeded(IERC20 token, address to) internal {
        if (!token.isETH()) {
            if ((token.allowance(address(this), to) >> 255) == 0) {
                token.universalApprove(to, uint256(- 1));
            }
        }
    }
}


contract OneSplitViewWrapBase is IOneSplitView, OneSplitRoot {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        return _getExpectedReturnFloor(
            fromToken,
            toToken,
            amount,
            parts,
            flags
        );
    }

    function _getExpectedReturnFloor(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
    )
        internal
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        );
}


contract OneSplitView is IOneSplitView, OneSplitRoot {
    function _findBestDistribution(
        uint256 s,                            // parts
        uint256[][DEXES_COUNT] memory amounts // exchangesReturns
    ) internal pure returns(uint256 returnAmount, uint256[] memory distribution) {
        uint256 n = amounts.length;

        uint256[][] memory answer = new uint256[][](n); // int[n][s+1]
        uint256[][] memory parent = new uint256[][](n); // int[n][s+1]

        for (uint i = 0; i < n; i++) {
            answer[i] = new uint256[](s + 1);
            parent[i] = new uint256[](s + 1);
        }

        for (uint j = 0; j <= s; j++) {
            answer[0][j] = amounts[0][j];
            parent[0][j] = 0;
        }

        for (uint i = 1; i < n; i++) {

            for (uint j = 0; j <= s; j++) {

                answer[i][j] = answer[i - 1][j];
                parent[i][j] = j;

                for (uint k = 1; k <= j; k++) {

                    if (answer[i - 1][j - k].add(amounts[i][k]) > answer[i][j]) {

                        answer[i][j] = answer[i - 1][j - k].add(amounts[i][k]);
                        parent[i][j] = j - k;
                    }
                }
            }
        }

        distribution = new uint256[](DEXES_COUNT);

        uint256 partsLeft = s;
        for (uint curExchange = n - 1; partsLeft > 0; curExchange--) {
            distribution[curExchange] = partsLeft - parent[curExchange][partsLeft];
            partsLeft = parent[curExchange][partsLeft];
        }

        returnAmount = answer[n - 1][s];
    }

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        return getExpectedReturnRespectingGas(
            fromToken,
            toToken,
            amount,
            parts,
            flags,
            0
        );
    }

    function getExpectedReturnRespectingGas(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags, // See constants in IOneSplit.sol
        uint256 toTokenEthPrice
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        distribution = new uint256[](DEXES_COUNT);

        if (fromToken == toToken) {
            return (amount, distribution);
        }

        function(IERC20,IERC20,uint256,uint256,uint256,uint256) view returns(uint256[] memory)[DEXES_COUNT] memory reserves = _getAllReserves(flags);

        uint256[][DEXES_COUNT] memory matrix;
        for (uint i = 0; i < DEXES_COUNT; i++) {
            matrix[i] = reserves[i](fromToken, toToken, amount, parts, flags, toTokenEthPrice);
        }

        return _findBestDistribution(parts, matrix);
    }

    function _getAllReserves(uint256 flags)
        internal
        pure
        returns(function(IERC20,IERC20,uint256,uint256,uint256,uint256) view returns(uint256[] memory)[DEXES_COUNT] memory)
    {
        bool invert = flags.check(FLAG_DISABLE_ALL_SPLIT_SOURCES);
        return [
            invert != flags.check(FLAG_DISABLE_UNISWAP)          ? _calculateNoReturn : calculateUniswapReturn,
            invert != flags.check(FLAG_DISABLE_KYBER)            ? _calculateNoReturn : calculateKyberReturn,
            invert != flags.check(FLAG_DISABLE_BANCOR)           ? _calculateNoReturn : calculateBancorReturn,
            invert != flags.check(FLAG_DISABLE_OASIS)            ? _calculateNoReturn : calculateOasisReturn,
            invert != flags.check(FLAG_DISABLE_CURVE_COMPOUND)   ? _calculateNoReturn : calculateCurveCompound,
            invert != flags.check(FLAG_DISABLE_CURVE_USDT)       ? _calculateNoReturn : calculateCurveUsdt,
            invert != flags.check(FLAG_DISABLE_CURVE_Y)          ? _calculateNoReturn : calculateCurveY,
            invert != flags.check(FLAG_DISABLE_CURVE_BINANCE)    ? _calculateNoReturn : calculateCurveBinance,
            invert != flags.check(FLAG_DISABLE_CURVE_SYNTHETIX)  ? _calculateNoReturn : calculateCurveSynthetix,
            (true) != flags.check(FLAG_ENABLE_UNISWAP_COMPOUND)  ? _calculateNoReturn : calculateUniswapCompound,
            (true) != flags.check(FLAG_ENABLE_UNISWAP_CHAI)      ? _calculateNoReturn : calculateUniswapChai,
            (true) != flags.check(FLAG_ENABLE_UNISWAP_AAVE)      ? _calculateNoReturn : calculateUniswapAave,
            invert != flags.check(FLAG_DISABLE_MOONISWAP)        ? _calculateNoReturn : calculateMooniswap,
            invert != flags.check(FLAG_DISABLE_UNISWAP_V2)       ? _calculateNoReturn : calculateUniswapV2,
            invert != flags.check(FLAG_DISABLE_UNISWAP_V2_ETH)   ? _calculateNoReturn : calculateUniswapV2ETH,
            invert != flags.check(FLAG_DISABLE_UNISWAP_V2_DAI)   ? _calculateNoReturn : calculateUniswapV2DAI,
            invert != flags.check(FLAG_DISABLE_UNISWAP_V2_USDC)  ? _calculateNoReturn : calculateUniswapV2USDC,
            invert != flags.check(FLAG_DISABLE_CURVE_PAX)        ? _calculateNoReturn : calculateCurvePax,
            invert != flags.check(FLAG_DISABLE_CURVE_RENBTC)     ? _calculateNoReturn : calculateCurveRenBtc,
            invert != flags.check(FLAG_DISABLE_CURVE_TBTC)       ? _calculateNoReturn : calculateCurveTBtc,
            invert != flags.check(FLAG_DISABLE_DFORCE_SWAP)      ? _calculateNoReturn : calculateDforceSwap,
            invert != flags.check(FLAG_DISABLE_SHELL)            ? _calculateNoReturn : calculateShell
        ];
    }

    function _calculateNoGas(
        IERC20 /*fromToken*/,
        IERC20 /*destToken*/,
        uint256 /*amount*/,
        uint256 /*parts*/,
        uint256 /*toTokenEthPrice*/,
        uint256 /*flags*/,
        uint256 /*destTokenEthPrice*/
    ) internal view returns(uint256[] memory /*rets*/) {
        this;
    }

    function _subGas(uint256 value, uint256 gas, uint256 toTokenEthPrice) internal pure returns(uint256) {
        uint256 toGas = uint256(gas).mul(toTokenEthPrice).div(1e18);
        if (value > toGas) {
            return value - toGas;
        }
    }

    // View Helpers

    function _interpolateValueWithGas(
        uint256 value,
        uint256 parts,
        uint256 gas,
        uint256 toTokenEthPrice
    ) internal pure returns(uint256[] memory rets) {
        rets = new uint256[](parts);
        for (uint i = 0; i < parts; i++) {
            rets[i] = value.mul(i + 1).div(parts);
        }
        rets[0] = _subGas(rets[0], gas, toTokenEthPrice);
    }

    function _calculateCurveSelector(
        ICurve curve,
        bytes4 sel,
        IERC20[] memory tokens,
        uint256 gas,
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 toTokenEthPrice,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets) {
        int128 i = 0;
        int128 j = 0;
        for (uint t = 0; t < tokens.length; t++) {
            if (fromToken == tokens[t]) {
                i = int128(t + 1);
            }
            if (destToken == tokens[t]) {
                j = int128(t + 1);
            }
        }

        if (i == 0 || j == 0) {
            return new uint256[](parts);
        }

        // curve.get_dy(i - 1, j - 1, amount);
        // curve.get_dy_underlying(i - 1, j - 1, amount);
        (bool success, bytes memory data) = address(curve).staticcall(abi.encodeWithSelector(sel, i - 1, j - 1, amount));
        uint256 maxRet = (!success || data.length == 0) ? 0 : abi.decode(data, (uint256));

        return _interpolateValueWithGas(maxRet, parts, gas, toTokenEthPrice);
    }

    function _calculateCurveUnderlying(
        ICurve curve,
        IERC20[] memory tokens,
        uint256 gas,
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 toTokenEthPrice,
        uint256 flags
    ) internal view returns(uint256[] memory rets) {
        return _calculateCurveSelector(
            curveCompound,
            curveCompound.get_dy_underlying.selector,
            tokens,
            720_000,
            fromToken,
            destToken,
            amount,
            parts,
            toTokenEthPrice,
            flags
        );
    }

    function _calculateCurve(
        ICurve curve,
        IERC20[] memory tokens,
        uint256 gas,
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 toTokenEthPrice,
        uint256 flags
    ) internal view returns(uint256[] memory rets) {
        return _calculateCurveSelector(
            curveCompound,
            curveCompound.get_dy.selector,
            tokens,
            720_000,
            fromToken,
            destToken,
            amount,
            parts,
            toTokenEthPrice,
            flags
        );
    }

    function calculateCurveCompound(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 toTokenEthPrice,
        uint256 flags
    ) public view returns(uint256[] memory rets) {
        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = dai;
        tokens[1] = usdc;
        return _calculateCurveUnderlying(
            curveCompound,
            tokens,
            720_000,
            fromToken,
            destToken,
            amount,
            parts,
            toTokenEthPrice,
            flags
        );
    }

    function calculateCurveUsdt(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 toTokenEthPrice,
        uint256 flags
    ) public view returns(uint256[] memory rets) {
        IERC20[] memory tokens = new IERC20[](3);
        tokens[0] = dai;
        tokens[1] = usdc;
        tokens[2] = usdt;
        return _calculateCurveUnderlying(
            curveUsdt,
            tokens,
            720_000,
            fromToken,
            destToken,
            amount,
            parts,
            toTokenEthPrice,
            flags
        );
    }

    function calculateCurveY(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 toTokenEthPrice,
        uint256 flags
    ) public view returns(uint256[] memory rets) {
        IERC20[] memory tokens = new IERC20[](4);
        tokens[0] = dai;
        tokens[1] = usdc;
        tokens[2] = usdt;
        tokens[3] = tusd;
        return _calculateCurveUnderlying(
            curveY,
            tokens,
            1_400_000,
            fromToken,
            destToken,
            amount,
            parts,
            toTokenEthPrice,
            flags
        );
    }

    function calculateCurveBinance(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 toTokenEthPrice,
        uint256 flags
    ) public view returns(uint256[] memory rets) {
        IERC20[] memory tokens = new IERC20[](4);
        tokens[0] = dai;
        tokens[1] = usdc;
        tokens[2] = usdt;
        tokens[3] = busd;
        return _calculateCurveUnderlying(
            curveBinance,
            tokens,
            1_400_000,
            fromToken,
            destToken,
            amount,
            parts,
            toTokenEthPrice,
            flags
        );
    }

    function calculateCurveSynthetix(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 toTokenEthPrice,
        uint256 flags
    ) public view returns(uint256[] memory rets) {
        IERC20[] memory tokens = new IERC20[](4);
        tokens[0] = dai;
        tokens[1] = usdc;
        tokens[2] = usdt;
        tokens[3] = susd;
        return _calculateCurveUnderlying(
            curveSynthetix,
            tokens,
            200_000,
            fromToken,
            destToken,
            amount,
            parts,
            toTokenEthPrice,
            flags
        );
    }

    function calculateCurvePax(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 toTokenEthPrice,
        uint256 flags
    ) public view returns(uint256[] memory rets) {
        IERC20[] memory tokens = new IERC20[](4);
        tokens[0] = dai;
        tokens[1] = usdc;
        tokens[2] = usdt;
        tokens[3] = pax;
        return _calculateCurveUnderlying(
            curvePax,
            tokens,
            1_000_000,
            fromToken,
            destToken,
            amount,
            parts,
            toTokenEthPrice,
            flags
        );
    }

    function calculateCurveRenBtc(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 toTokenEthPrice,
        uint256 flags
    ) public view returns(uint256[] memory rets) {
        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = renbtc;
        tokens[1] = wbtc;
        return _calculateCurve(
            curveRenBtc,
            tokens,
            130_000,
            fromToken,
            destToken,
            amount,
            parts,
            toTokenEthPrice,
            flags
        );
    }

    function calculateCurveTBtc(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 toTokenEthPrice,
        uint256 flags
    ) public view returns(uint256[] memory rets) {
        IERC20[] memory tokens = new IERC20[](3);
        tokens[0] = tbtc;
        tokens[1] = wbtc;
        tokens[2] = hbtc;
        return _calculateCurve(
            curveTBtc,
            tokens,
            145_000,
            fromToken,
            destToken,
            amount,
            parts,
            toTokenEthPrice,
            flags
        );
    }

    function calculateShell(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 toTokenEthPrice,
        uint256 /*flags*/
    ) public view returns(uint256[] memory rets) {
        (bool success, bytes memory data) = address(shell).staticcall(abi.encodeWithSelector(
            shell.viewOriginTrade.selector,
            fromToken,
            destToken,
            amount
        ));

        if (!success || data.length == 0) {
            return new uint256[](parts);
        }

        uint256 maxRet = abi.decode(data, (uint256));
        return _interpolateValueWithGas(maxRet, parts, 300_000, toTokenEthPrice);
    }

    function calculateDforceSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 toTokenEthPrice,
        uint256 /*flags*/
    ) public view returns(uint256[] memory rets) {
        (bool success, bytes memory data) = address(dforceSwap).staticcall(
            abi.encodeWithSelector(
                dforceSwap.getAmountByInput.selector,
                fromToken,
                destToken,
                amount
            )
        );
        if (!success || data.length == 0) {
            return new uint256[](parts);
        }

        uint256 maxRet = abi.decode(data, (uint256));
        uint256 available = destToken.universalBalanceOf(address(dforceSwap));
        if (maxRet > available) {
            return new uint256[](parts);
        }

        return _interpolateValueWithGas(maxRet, parts, 160_000, toTokenEthPrice);
    }

    function _calculateUniswapFormula(uint256 fromBalance, uint256 toBalance, uint256 amount) internal view returns(uint256) {
        return amount.mul(toBalance).mul(997).div(
            fromBalance.mul(1000).add(amount.mul(997))
        );
    }

    function _calculateUniswapReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256[] memory amounts,
        uint256 parts,
        uint256 toTokenEthPrice,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets) {
        rets = amounts;

        if (!fromToken.isETH()) {
            IUniswapExchange fromExchange = uniswapFactory.getExchange(fromToken);
            if (fromExchange == IUniswapExchange(0)) {
                return new uint256[](parts);
            }

            uint256 fromTokenBalance = fromToken.balanceOf(address(fromExchange));
            uint256 fromEtherBalance = address(fromExchange).balance;

            for (uint i = 0; i < parts; i++) {
                rets[i] = _calculateUniswapFormula(fromTokenBalance, fromEtherBalance, rets[i]);
            }
        }

        if (!toToken.isETH()) {
            IUniswapExchange toExchange = uniswapFactory.getExchange(toToken);
            if (toExchange == IUniswapExchange(0)) {
                return new uint256[](parts);
            }

            uint256 toEtherBalance = address(toExchange).balance;
            uint256 toTokenBalance = toToken.balanceOf(address(toExchange));

            for (uint i = 0; i < parts; i++) {
                rets[i] = _calculateUniswapFormula(toEtherBalance, toTokenBalance, rets[i]);
            }
        }

        uint256 gas = fromToken.isETH() || toToken.isETH() ? 60_000 : 100_000;
        rets[0] = _subGas(rets[0], gas, toTokenEthPrice);
        return rets;
    }

    function calculateUniswapReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 toTokenEthPrice,
        uint256 flags
    ) public view returns(uint256[] memory rets) {
        rets = new uint256[](parts);
        for (uint i = 0; i < parts; i++) {
            rets[i] = amount.mul(i + 1).div(parts);
        }

        return _calculateUniswapReturn(
            fromToken,
            destToken,
            rets,
            parts,
            toTokenEthPrice,
            flags
        );
    }

    function calculateUniswapCompound(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 toTokenEthPrice,
        uint256 flags
    ) public view returns(uint256[] memory rets) {
        rets = new uint256[](parts);

        if (!fromToken.isETH() && !destToken.isETH()) {
            return rets;
        }

        if (!fromToken.isETH()) {
            ICompoundToken fromCompound = _getCompoundToken(fromToken);
            if (fromCompound != ICompoundToken(0)) {
                uint256 compoundExchangeRate = fromCompound.exchangeRateStored();
                for (uint i = 0; i < parts; i++) {
                    rets[i] = amount
                        .mul(i + 1).div(parts)
                        .mul(1e18).div(compoundExchangeRate);
                }

                rets = _calculateUniswapReturn(
                    fromCompound,
                    destToken,
                    rets,
                    parts,
                    toTokenEthPrice,
                    flags
                );
                rets[0] = _subGas(rets[0], 200_000, toTokenEthPrice);
                return rets;
            }
        }
        else {
            ICompoundToken destCompound = _getCompoundToken(destToken);
            if (destCompound != ICompoundToken(0)) {
                for (uint i = 0; i < parts; i++) {
                    rets[i] = amount.mul(i + 1).div(parts);
                }

                rets = _calculateUniswapReturn(
                    fromToken,
                    destCompound,
                    rets,
                    parts,
                    0,
                    flags
                );

                uint256 compoundExchangeRate = destCompound.exchangeRateStored();
                for (uint i = 0; i < parts; i++) {
                    rets[i] = rets[i].mul(compoundExchangeRate).div(1e18);
                }
                rets[0] = _subGas(rets[0], 60_000 + 200_000, toTokenEthPrice);
                return rets;
            }
        }

        return rets;
    }

    function calculateUniswapChai(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 toTokenEthPrice,
        uint256 flags
    ) public view returns(uint256[] memory rets) {
        rets = new uint256[](parts);

        if (fromToken == dai && destToken.isETH()) {
            uint256 chaiPrice = chai.chaiPrice();
            for (uint i = 0; i < parts; i++) {
                rets[i] = amount
                    .mul(i + 1).div(parts)
                    .mul(1e18).div(chaiPrice);
            }

            rets = _calculateUniswapReturn(
                chai,
                destToken,
                rets,
                parts,
                toTokenEthPrice,
                flags
            );
            rets[0] = _subGas(rets[0], 180_000, toTokenEthPrice);
            return rets;
        }

        if (fromToken.isETH() && destToken == dai) {
            for (uint i = 0; i < parts; i++) {
                rets[i] = amount.mul(i + 1).div(parts);
            }

            rets = _calculateUniswapReturn(
                fromToken,
                chai,
                rets,
                parts,
                0,
                flags
            );

            uint256 chaiPrice = chai.chaiPrice();
            for (uint i = 0; i < parts; i++) {
                rets[i] = rets[i].mul(chaiPrice).div(1e18);
            }
            rets[0] = _subGas(rets[0], 60_000 + 160_000, toTokenEthPrice);
            return rets;
        }

        return rets;
    }

    function calculateUniswapAave(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 toTokenEthPrice,
        uint256 flags
    ) public view returns(uint256[] memory rets) {
        rets = new uint256[](parts);

        if (!fromToken.isETH() && !destToken.isETH()) {
            return rets;
        }

        if (!fromToken.isETH()) {
            IAaveToken fromAave = _getAaveToken(fromToken);
            if (fromAave != IAaveToken(0)) {
                for (uint i = 0; i < parts; i++) {
                    rets[i] = amount.mul(i + 1).div(parts);
                }

                rets = _calculateUniswapReturn(
                    fromAave,
                    destToken,
                    rets,
                    parts,
                    toTokenEthPrice,
                    flags
                );
                rets[0] = _subGas(rets[0], 300_007, toTokenEthPrice); // TODO: gas check
                return rets;
            }
        } else {
            IAaveToken destAave = _getAaveToken(destToken);
            if (destAave != IAaveToken(0)) {
                for (uint i = 0; i < parts; i++) {
                    rets[i] = amount.mul(i + 1).div(parts);
                }

                rets = _calculateUniswapReturn(
                    fromToken,
                    destAave,
                    rets,
                    parts,
                    0,
                    flags
                );

                rets[0] = _subGas(rets[0], 60_000 + 300_007, toTokenEthPrice);
                return rets;
            }
        }

        return rets;
    }

    function calculateKyberReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 toTokenEthPrice,
        uint256 flags
    ) public view returns(uint256[] memory rets) {
        rets = new uint256[](parts);

        uint256 maxRet;
        uint256 gas;
        uint j = parts;
        while (j > 0) {
            (maxRet, gas) = _calculateKyberReturn(fromToken, destToken, amount.mul(j).div(parts), flags);
            if (maxRet == 0) {
                j = j / 2;
            }
        }

        if (j == 0) {
            return rets;
        }

        for (uint i = 0; i < j; i++) {
            rets[i] = maxRet.mul(i + 1).div(j);
        }
        rets[0] = _subGas(rets[0], gas, toTokenEthPrice);
        return rets;
    }

    function _calculateKyberReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 flags
    ) internal view returns(uint256, uint256) {
        (bool success, bytes memory data) = address(kyberNetworkProxy).staticcall.gas(2300)(abi.encodeWithSelector(
            kyberNetworkProxy.kyberNetworkContract.selector
        ));
        if (!success) {
            return (0, 0);
        }

        IKyberNetworkContract kyberNetworkContract = IKyberNetworkContract(abi.decode(data, (address)));

        if (fromToken.isETH() || toToken.isETH()) {
            return _calculateKyberReturnWithEth(kyberNetworkContract, fromToken, toToken, amount, flags);
        }

        (uint256 value, uint256 gasFee) = _calculateKyberReturnWithEth(kyberNetworkContract, fromToken, ETH_ADDRESS, amount, flags);
        if (value == 0) {
            return (0, 0);
        }

        (uint256 value2, uint256 gasFee2) =  _calculateKyberReturnWithEth(kyberNetworkContract, ETH_ADDRESS, toToken, value, flags);
        return (value2, gasFee + gasFee2);
    }

    function _calculateKyberReturnWithEth(
        IKyberNetworkContract kyberNetworkContract,
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 flags
    ) internal view returns(uint256, uint256) {
        require(fromToken.isETH() || toToken.isETH(), "One of the tokens should be ETH");

        (bool success, bytes memory data) = address(kyberNetworkContract).staticcall.gas(1500000)(abi.encodeWithSelector(
            kyberNetworkContract.searchBestRate.selector,
            fromToken.isETH() ? ETH_ADDRESS : fromToken,
            toToken.isETH() ? ETH_ADDRESS : toToken,
            amount,
            true
        ));
        if (!success) {
            return (0, 0);
        }

        (address reserve, uint256 ret) = abi.decode(data, (address,uint256));

        if (ret == 0) {
            return (0, 0);
        }

        if ((reserve == 0x31E085Afd48a1d6e51Cc193153d625e8f0514C7F && !flags.check(FLAG_ENABLE_KYBER_UNISWAP_RESERVE)) ||
            (reserve == 0x1E158c0e93c30d24e918Ef83d1e0bE23595C3c0f && !flags.check(FLAG_ENABLE_KYBER_OASIS_RESERVE)) ||
            (reserve == 0x053AA84FCC676113a57e0EbB0bD1913839874bE4 && !flags.check(FLAG_ENABLE_KYBER_BANCOR_RESERVE)))
        {
            return (0, 0);
        }

        if (!flags.check(FLAG_ENABLE_KYBER_UNISWAP_RESERVE)) {
            (success,) = reserve.staticcall.gas(2300)(abi.encodeWithSelector(
                IKyberUniswapReserve(reserve).uniswapFactory.selector
            ));
            if (success) {
                return (0, 0);
            }
        }

        if (!flags.check(FLAG_ENABLE_KYBER_OASIS_RESERVE)) {
            (success,) = reserve.staticcall.gas(2300)(abi.encodeWithSelector(
                IKyberOasisReserve(reserve).otc.selector
            ));
            if (success) {
                return (0, 0);
            }
        }

        if (!flags.check(FLAG_ENABLE_KYBER_BANCOR_RESERVE)) {
            (success,) = reserve.staticcall.gas(2300)(abi.encodeWithSelector(
                IKyberBancorReserve(reserve).bancorEth.selector
            ));
            if (success) {
                return (0, 0);
            }
        }

        return (
            ret.mul(amount)
                .mul(10 ** IERC20(toToken).universalDecimals())
                .div(10 ** IERC20(fromToken).universalDecimals())
                .div(1e18),
            700_000
        );
    }

    function calculateBancorReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 toTokenEthPrice,
        uint256 flags
    ) public view returns(uint256[] memory rets) {
        IBancorNetwork bancorNetwork = IBancorNetwork(bancorContractRegistry.addressOf("BancorNetwork"));
        address[] memory path = _buildBancorPath(fromToken, destToken);

        (bool success, bytes memory data) = address(bancorNetwork).staticcall.gas(500000)(
            abi.encodeWithSelector(
                bancorNetwork.getReturnByPath.selector,
                path,
                amount
            )
        );
        if (!success) {
            return new uint256[](parts);
        }

        (uint256 maxRet,) = abi.decode(data, (uint256,uint256));
        return _interpolateValueWithGas(maxRet, parts, path.length.mul(150_000), toTokenEthPrice);
    }

    function calculateOasisReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 toTokenEthPrice,
        uint256 flags
    ) public view returns(uint256[] memory rets) {
        (bool success, bytes memory data) = address(oasisExchange).staticcall.gas(500000)(
            abi.encodeWithSelector(
                oasisExchange.getBuyAmount.selector,
                destToken.isETH() ? weth : destToken,
                fromToken.isETH() ? weth : fromToken,
                amount
            )
        );

        if (!success) {
            return new uint256[](parts);
        }

        uint256 maxRet = abi.decode(data, (uint256));
        return _interpolateValueWithGas(maxRet, parts, 500_000, toTokenEthPrice);
    }

    function calculateMooniswap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 toTokenEthPrice,
        uint256 flags
    ) public view returns(uint256[] memory rets) {
        IMooniswap mooniswap = mooniswapRegistry.target();
        (bool success, bytes memory data) = address(mooniswap).staticcall.gas(1000000)(
            abi.encodeWithSelector(
                mooniswap.getReturn.selector,
                fromToken,
                destToken,
                amount
            )
        );

        if (!success) {
            return new uint256[](parts);
        }

        uint256 maxRet = abi.decode(data, (uint256));
        return _interpolateValueWithGas(maxRet, parts, 1_000_000, toTokenEthPrice);
    }

    function calculateUniswapV2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 toTokenEthPrice,
        uint256 flags
    ) public view returns(uint256[] memory rets) {
        for (uint i = 0; i < parts; i++) {
            rets[i] = amount.mul(i + 1).div(parts);
        }
        uint256 gas;
        (rets, gas) = _calculateUniswapV2(fromToken, destToken, rets, flags);
        rets[0] = _subGas(rets[0], gas, toTokenEthPrice);
        return rets;
    }

    function calculateUniswapV2ETH(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 toTokenEthPrice,
        uint256 flags
    ) public view returns(uint256[] memory rets) {
        rets = new uint256[](parts);

        if (fromToken.isETH() || fromToken == weth || destToken.isETH() || destToken == weth) {
            return rets;
        }

        return _calculateUniswapV2OverMidToken(
            fromToken,
            weth,
            destToken,
            amount,
            parts,
            toTokenEthPrice,
            flags
        );
    }

    function calculateUniswapV2DAI(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 toTokenEthPrice,
        uint256 flags
    ) public view returns(uint256[] memory rets) {
        rets = new uint256[](parts);

        if (fromToken == dai || destToken == dai) {
            return rets;
        }

        return _calculateUniswapV2OverMidToken(
            fromToken,
            dai,
            destToken,
            amount,
            parts,
            toTokenEthPrice,
            flags
        );
    }

    function calculateUniswapV2USDC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 toTokenEthPrice,
        uint256 flags
    ) public view returns(uint256[] memory rets) {
        rets = new uint256[](parts);

        if (fromToken == usdc || destToken == usdc) {
            return rets;
        }

        return _calculateUniswapV2OverMidToken(
            fromToken,
            usdc,
            destToken,
            amount,
            parts,
            toTokenEthPrice,
            flags
        );
    }

    function _calculateUniswapV2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256[] memory amounts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        rets = new uint256[](amounts.length);

        IERC20 fromTokenReal = fromToken.isETH() ? weth : fromToken;
        IERC20 destTokenReal = destToken.isETH() ? weth : destToken;
        IUniswapV2Exchange exchange = uniswapV2.getPair(fromTokenReal, destTokenReal);
        if (exchange != IUniswapV2Exchange(0)) {
            uint256 fromTokenBalance = fromTokenReal.universalBalanceOf(address(exchange));
            uint256 destTokenBalance = destTokenReal.universalBalanceOf(address(exchange));
            for (uint i = 0; i < amounts.length; i++) {
                rets[i] = _calculateUniswapFormula(fromTokenBalance, destTokenBalance, amounts[i]);
            }
            return (rets, 50_000);
        }
    }

    function _calculateUniswapV2OverMidToken(
        IERC20 fromToken,
        IERC20 midToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 toTokenEthPrice,
        uint256 flags
    ) public view returns(uint256[] memory rets) {
        rets = new uint256[](parts);
        for (uint i = 0 ; i < parts; i++) {
            rets[i] = amount.mul(i + 1).div(parts);
        }

        uint256 gas1;
        uint256 gas2;
        (rets, gas1) = _calculateUniswapV2(fromToken, midToken, rets, flags);
        (rets, gas2) = _calculateUniswapV2(midToken, destToken, rets, flags);
        rets[0] = _subGas(rets[0], gas1 + gas2, toTokenEthPrice);
        return rets;
    }

    function _calculateNoReturn(
        IERC20 /*fromToken*/,
        IERC20 /*toToken*/,
        uint256 /*amount*/,
        uint256 parts,
        uint256 /*toTokenEthPrice*/,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets) {
        return new uint256[](parts);
    }
}


contract OneSplitBaseWrap is IOneSplit, OneSplitRoot {
    function _swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags // See constants in IOneSplit.sol
    ) internal {
        if (fromToken == toToken) {
            return;
        }

        _swapFloor(
            fromToken,
            toToken,
            amount,
            distribution,
            flags
        );
    }

    function _swapFloor(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 /*flags*/ // See constants in IOneSplit.sol
    ) internal;
}


contract OneSplit is IOneSplit, OneSplitRoot {
    IOneSplitView public oneSplitView;

    constructor(IOneSplitView _oneSplitView) public {
        oneSplitView = _oneSplitView;
    }

    function() external payable {
        // solium-disable-next-line security/no-tx-origin
        require(msg.sender != tx.origin);
    }

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        )
    {
        return oneSplitView.getExpectedReturn(
            fromToken,
            toToken,
            amount,
            parts,
            flags
        );
    }

    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 /*minReturn*/,
        uint256[] memory distribution,
        uint256 /*flags*/  // See constants in IOneSplit.sol
    ) public payable {
        if (fromToken == toToken) {
            return;
        }

        function(IERC20,IERC20,uint256) returns(uint256)[DEXES_COUNT] memory reserves = [
            _swapOnUniswap,
            _swapOnKyber,
            _swapOnBancor,
            _swapOnOasis,
            _swapOnCurveCompound,
            _swapOnCurveUsdt,
            _swapOnCurveY,
            _swapOnCurveBinance,
            _swapOnCurveSynthetix,
            _swapOnUniswapCompound,
            _swapOnUniswapChai,
            _swapOnUniswapAave,
            _swapOnMooniswap,
            _swapOnUniswapV2,
            _swapOnUniswapV2ETH,
            _swapOnUniswapV2DAI,
            _swapOnUniswapV2USDC,
            _swapOnCurvePax,
            _swapOnCurveRenBtc,
            _swapOnCurveTBtc,
            _swapOnDforceSwap,
            _swapOnShell
        ];

        require(distribution.length <= reserves.length, "OneSplit: Distribution array should not exceed reserves array size");

        uint256 parts = 0;
        uint256 lastNonZeroIndex = 0;
        for (uint i = 0; i < distribution.length; i++) {
            if (distribution[i] > 0) {
                parts = parts.add(distribution[i]);
                lastNonZeroIndex = i;
            }
        }

        require(parts > 0, "OneSplit: distribution should contain non-zeros");

        uint256 remainingAmount = amount;
        for (uint i = 0; i < distribution.length; i++) {
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
        int128 i = (fromToken == dai ? 1 : 0) +
            (fromToken == usdc ? 2 : 0) +
            (fromToken == usdt ? 3 : 0);
        int128 j = (destToken == dai ? 1 : 0) +
            (destToken == usdc ? 2 : 0) +
            (destToken == usdt ? 3 : 0);
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
        int128 i = (fromToken == dai ? 1 : 0) +
            (fromToken == usdc ? 2 : 0) +
            (fromToken == usdt ? 3 : 0) +
            (fromToken == tusd ? 4 : 0);
        int128 j = (destToken == dai ? 1 : 0) +
            (destToken == usdc ? 2 : 0) +
            (destToken == usdt ? 3 : 0) +
            (destToken == tusd ? 4 : 0);
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
        int128 i = (fromToken == dai ? 1 : 0) +
            (fromToken == usdc ? 2 : 0) +
            (fromToken == usdt ? 3 : 0) +
            (fromToken == busd ? 4 : 0);
        int128 j = (destToken == dai ? 1 : 0) +
            (destToken == usdc ? 2 : 0) +
            (destToken == usdt ? 3 : 0) +
            (destToken == busd ? 4 : 0);
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
        int128 i = (fromToken == dai ? 1 : 0) +
            (fromToken == usdc ? 2 : 0) +
            (fromToken == usdt ? 3 : 0) +
            (fromToken == susd ? 4 : 0);
        int128 j = (destToken == dai ? 1 : 0) +
            (destToken == usdc ? 2 : 0) +
            (destToken == usdt ? 3 : 0) +
            (destToken == susd ? 4 : 0);
        if (i == 0 || j == 0) {
            return 0;
        }

        _infiniteApproveIfNeeded(fromToken, address(curveSynthetix));
        curveSynthetix.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurvePax(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {
        int128 i = (fromToken == dai ? 1 : 0) +
            (fromToken == usdc ? 2 : 0) +
            (fromToken == usdt ? 3 : 0) +
            (fromToken == pax ? 4 : 0);
        int128 j = (destToken == dai ? 1 : 0) +
            (destToken == usdc ? 2 : 0) +
            (destToken == usdt ? 3 : 0) +
            (destToken == pax ? 4 : 0);
        if (i == 0 || j == 0) {
            return 0;
        }

        _infiniteApproveIfNeeded(fromToken, address(curvePax));
        curvePax.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnShell(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) internal returns (uint256) {
        _infiniteApproveIfNeeded(fromToken, address(shell));
        return shell.swapByOrigin(
            address(fromToken),
            address(toToken),
            amount,
            0,
            now + 50
        );
    }

    function _swapOnCurveRenBtc(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {
        int128 i = (fromToken == renbtc ? 1 : 0) +
            (fromToken == wbtc ? 2 : 0);
        int128 j = (destToken == renbtc ? 1 : 0) +
            (destToken == wbtc ? 2 : 0);
        if (i == 0 || j == 0) {
            return 0;
        }

        _infiniteApproveIfNeeded(fromToken, address(curveRenBtc));
        curveRenBtc.exchange(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurveTBtc(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {
        int128 i = (fromToken == tbtc ? 1 : 0) +
            (fromToken == wbtc ? 2 : 0) +
            (fromToken == hbtc ? 3 : 0);
        int128 j = (destToken == tbtc ? 1 : 0) +
            (destToken == wbtc ? 2 : 0) +
            (destToken == hbtc ? 3 : 0);
        if (i == 0 || j == 0) {
            return 0;
        }

        _infiniteApproveIfNeeded(fromToken, address(curveTBtc));
        curveTBtc.exchange(i - 1, j - 1, amount, 0);
    }

    function _swapOnDforceSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal returns(uint256) {
        _infiniteApproveIfNeeded(fromToken, address(dforceSwap));
        dforceSwap.swap(fromToken, destToken, amount);
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

    function _swapOnUniswapCompound(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) internal returns(uint256) {
        if (!fromToken.isETH()) {
            ICompoundToken fromCompound = _getCompoundToken(fromToken);
            _infiniteApproveIfNeeded(fromToken, address(fromCompound));
            fromCompound.mint(amount);
            return _swapOnUniswap(IERC20(fromCompound), toToken, IERC20(fromCompound).universalBalanceOf(address(this)));
        }

        if (!toToken.isETH()) {
            ICompoundToken toCompound = _getCompoundToken(toToken);
            uint256 compoundAmount = _swapOnUniswap(fromToken, IERC20(toCompound), amount);
            toCompound.redeem(compoundAmount);
            return toToken.universalBalanceOf(address(this));
        }

        return 0;
    }

    function _swapOnUniswapChai(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) internal returns(uint256) {
        if (fromToken == dai) {
            _infiniteApproveIfNeeded(fromToken, address(chai));
            chai.join(address(this), amount);
            return _swapOnUniswap(IERC20(chai), toToken, IERC20(chai).universalBalanceOf(address(this)));
        }

        if (toToken == dai) {
            uint256 chaiAmount = _swapOnUniswap(fromToken, IERC20(chai), amount);
            chai.exit(address(this), chaiAmount);
            return toToken.universalBalanceOf(address(this));
        }

        return 0;
    }

    function _swapOnUniswapAave(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) internal returns(uint256) {
        if (!fromToken.isETH()) {
            IAaveToken fromAave = _getAaveToken(fromToken);
            _infiniteApproveIfNeeded(fromToken, aave.core());
            aave.deposit(fromToken, amount, 1101);
            return _swapOnUniswap(IERC20(fromAave), toToken, IERC20(fromAave).universalBalanceOf(address(this)));
        }

        if (!toToken.isETH()) {
            IAaveToken toAave = _getAaveToken(toToken);
            uint256 aaveAmount = _swapOnUniswap(fromToken, IERC20(toAave), amount);
            toAave.redeem(aaveAmount);
            return aaveAmount;
        }

        return 0;
    }

    function _swapOnMooniswap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) internal returns(uint256) {
        IMooniswap mooniswap = mooniswapRegistry.target();
        _infiniteApproveIfNeeded(fromToken, address(mooniswap));
        return mooniswap.swap.value(fromToken.isETH() ? amount : 0)(
            fromToken,
            toToken,
            amount,
            0
        );
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
        address[] memory path = _buildBancorPath(fromToken, toToken);

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
            weth.deposit.value(amount)();
        }

        _infiniteApproveIfNeeded(fromToken.isETH() ? weth : fromToken, address(oasisExchange));
        uint256 returnAmount = oasisExchange.sellAllAmount(
            fromToken.isETH() ? weth : fromToken,
            amount,
            toToken.isETH() ? weth : toToken,
            1
        );

        if (toToken.isETH()) {
            weth.withdraw(weth.balanceOf(address(this)));
        }

        return returnAmount;
    }

    function _swapOnUniswapV2Internal(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) internal returns(uint256 returnAmount) {
        if (fromToken.isETH()) {
            weth.deposit.value(amount)();
        }

        IERC20 fromTokenReal = fromToken.isETH() ? weth : fromToken;
        IERC20 toTokenReal = toToken.isETH() ? weth : toToken;
        IUniswapV2Exchange exchange = uniswapV2.getPair(fromTokenReal, toTokenReal);
        returnAmount = exchange.getReturn(fromTokenReal, toTokenReal, amount);

        fromTokenReal.universalTransfer(address(exchange), amount);
        if (uint256(address(fromTokenReal)) < uint256(address(toTokenReal))) {
            exchange.swap(0, returnAmount, address(this), "");
        } else {
            exchange.swap(returnAmount, 0, address(this), "");
        }

        if (toToken.isETH()) {
            weth.withdraw(weth.balanceOf(address(this)));
        }
    }

    function _swapOnUniswapV2OverMid(
        IERC20 fromToken,
        IERC20 midToken,
        IERC20 toToken,
        uint256 amount
    ) internal returns(uint256) {
        return _swapOnUniswapV2Internal(
            midToken,
            toToken,
            _swapOnUniswapV2Internal(
                fromToken,
                midToken,
                amount
            )
        );
    }

    function _swapOnUniswapV2(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) internal returns(uint256) {
        return _swapOnUniswapV2Internal(
            fromToken,
            toToken,
            amount
        );
    }

    function _swapOnUniswapV2ETH(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) internal returns(uint256) {
        return _swapOnUniswapV2OverMid(
            fromToken,
            weth,
            toToken,
            amount
        );
    }

    function _swapOnUniswapV2DAI(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) internal returns(uint256) {
        return _swapOnUniswapV2OverMid(
            fromToken,
            dai,
            toToken,
            amount
        );
    }

    function _swapOnUniswapV2USDC(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount
    ) internal returns(uint256) {
        return _swapOnUniswapV2OverMid(
            fromToken,
            usdc,
            toToken,
            amount
        );
    }
}
