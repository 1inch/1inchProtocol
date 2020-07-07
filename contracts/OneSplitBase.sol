pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IUniswapFactory.sol";
import "./interface/IKyberNetworkProxy.sol";
import "./interface/IKyberStorage.sol";
import "./interface/IKyberHintHandler.sol";
import "./interface/IBancorNetwork.sol";
import "./interface/IBancorContractRegistry.sol";
import "./interface/IBancorNetworkPathFinder.sol";
import "./interface/IBancorConverterRegistry.sol";
import "./interface/IBancorEtherToken.sol";
import "./interface/IBancorFinder.sol";
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
import "./interface/IMStable.sol";
import "./interface/IBalancerRegistry.sol";
import "./IOneSplit.sol";
import "./UniversalERC20.sol";


contract IOneSplitView is IOneSplitConsts {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
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

    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        );
}


library DisableFlags {
    function check(uint256 flags, uint256 flag) internal pure returns(bool) {
        return (flags & flag) != 0;
    }
}


contract OneSplitRoot is IOneSplitView {
    using SafeMath for uint256;
    using DisableFlags for uint256;

    using UniversalERC20 for IERC20;
    using UniversalERC20 for IWETH;
    using UniswapV2ExchangeLib for IUniswapV2Exchange;
    using ChaiHelper for IChai;

    uint256 constant internal DEXES_COUNT = 31;
    IERC20 constant internal ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    IBancorEtherToken constant internal bancorEtherToken = IBancorEtherToken(0xc0829421C1d260BD3cB3E0F06cfE2D52db2cE315);
    IWETH constant internal weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IChai constant internal chai = IChai(0x06AF07097C9Eeb7fD685c692751D5C66dB49c215);
    IERC20 constant internal dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 constant internal bnt = IERC20(0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C);
    IERC20 constant internal usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 constant internal usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 constant internal tusd = IERC20(0x0000000000085d4780B73119b644AE5ecd22b376);
    IERC20 constant internal busd = IERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53);
    IERC20 constant internal susd = IERC20(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
    IERC20 constant internal pax = IERC20(0x8E870D67F660D95d5be530380D0eC0bd388289E1);
    IERC20 constant internal renbtc = IERC20(0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D);
    IERC20 constant internal wbtc = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IERC20 constant internal tbtc = IERC20(0x1bBE271d15Bb64dF0bc6CD28Df9Ff322F2eBD847);
    IERC20 constant internal hbtc = IERC20(0x0316EB71485b0Ab14103307bf65a021042c6d380);
    IERC20 constant internal sbtc = IERC20(0xfE18be6b3Bd88A2D2A7f928d00292E7a9963CfC6);
    IERC20 constant internal comp = IERC20(0xc00e94Cb662C3520282E6f5717214004A7f26888);
    IERC20 constant internal abyss = IERC20(0x0E8d6b471e332F140e7d9dbB99E5E3822F728DA6);
    IERC20 constant internal equad = IERC20(0xC28e931814725BbEB9e670676FaBBCb694Fe7DF2);
    IERC20 constant internal mln = IERC20(0xec67005c4E498Ec7f55E092bd1d35cbC47C91892);
    IERC20 constant internal ren = IERC20(0x408e41876cCCDC0F92210600ef50372656052a38);
    IERC20 constant internal gen = IERC20(0x543Ff227F64Aa17eA132Bf9886cAb5DB55DCAddf);
    IERC20 constant internal gno = IERC20(0x6810e776880C02933D47DB1b9fc05908e5386b96);
    IERC20 constant internal myb = IERC20(0x5d60d8d7eF6d37E16EBABc324de3bE57f135e0BC);
    IERC20 constant internal bam = IERC20(0x22B3FAaa8DF978F6bAFe18aaDe18DC2e3dfA0e0C);
    IERC20 constant internal spn = IERC20(0x20F7A3DdF244dc9299975b4Da1C39F8D5D75f05A);
    IERC20 constant internal upp = IERC20(0xC86D054809623432210c107af2e3F619DcFbf652);
    IERC20 constant internal snx = IERC20(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F);
    IERC20 constant internal tkn = IERC20(0xaAAf91D9b90dF800Df4F55c205fd6989c977E73a);
    IERC20 constant internal rae = IERC20(0xE5a3229CCb22b6484594973A03a3851dCd948756);
    IERC20 constant internal spike = IERC20(0xA7fC5D2453E3F68aF0cc1B78bcFEe94A1B293650);
    IERC20 constant internal san = IERC20(0x7C5A0CE9267ED19B22F8cae653F198e3E8daf098);
    IERC20 constant internal knc = IERC20(0xdd974D5C2e2928deA5F71b9825b8b646686BD200);
    IERC20 constant internal ekg = IERC20(0x6A9b3E36436B7abde8C4E2E2a98Ea40455E615cf);
    IERC20 constant internal ant = IERC20(0x960b236A07cf122663c4303350609A66A7B288C0);
    IERC20 constant internal gdc = IERC20(0x301C755bA0fcA00B1923768Fffb3Df7f4E63aF31);
    IERC20 constant internal ampl = IERC20(0xD46bA6D942050d489DBd938a2C909A5d5039A161);
    IERC20 constant internal met = IERC20(0xa3d58c4E56fedCae3a7c43A725aeE9A71F0ece4e);
    IERC20 constant internal mfg = IERC20(0x6710c63432A2De02954fc0f851db07146a6c0312);
    IERC20 constant internal ubt = IERC20(0x8400D94A5cb0fa0D041a3788e395285d61c9ee5e);
    IERC20 constant internal pbtc = IERC20(0x5228a22e72ccC52d415EcFd199F99D0665E7733b);
    IERC20 constant internal ogn = IERC20(0x8207c1FfC5B6804F6024322CcF34F29c3541Ae26);
    IERC20 constant internal band = IERC20(0xBA11D00c5f74255f56a5E366F4F77f5A186d7f55);
    IERC20 constant internal rsv = IERC20(0x1C5857e110CD8411054660F60B5De6a6958CfAE2);
    IERC20 constant internal key = IERC20(0x4CC19356f2D37338b9802aa8E8fc58B0373296E7);
    IERC20 constant internal pnk = IERC20(0x93ED3FBe21207Ec2E8f2d3c3de6e058Cb73Bc04d);
    IERC20 constant internal cnd = IERC20(0xd4c435F5B09F855C3317c8524Cb1F586E42795fa);
    IERC20 constant internal tryb = IERC20(0x2C537E5624e4af88A7ae4060C022609376C8D0EB);
    IERC20 constant internal twokey = IERC20(0xE48972fCd82a274411c01834e2f031D4377Fa2c0);
    IERC20 constant internal plr = IERC20(0xe3818504c1B32bF1557b16C238B2E01Fd3149C17);
    IERC20 constant internal qnt = IERC20(0x4a220E6096B25EADb88358cb44068A3248254675);
    IERC20 constant internal pnt = IERC20(0x89Ab32156e46F46D02ade3FEcbe5Fc4243B9AAeD);
    IERC20 constant internal req = IERC20(0x8f8221aFbB33998d8584A2B05749bA73c37a938a);
    IERC20 constant internal rsr = IERC20(0x8762db106B2c2A0bccB3A80d1Ed41273552616E8);

    IKyberNetworkProxy constant internal kyberNetworkProxy = IKyberNetworkProxy(0x9AAb3f75489902f3a48495025729a0AF77d4b11e);
    IKyberStorage constant internal kyberStorage = IKyberStorage(0xC8fb12402cB16970F3C5F4b48Ff68Eb9D1289301);
    IKyberHintHandler constant internal kyberHintHandler = IKyberHintHandler(0xa1C0Fa73c39CFBcC11ec9Eb1Afc665aba9996E2C);
    IUniswapFactory constant internal uniswapFactory = IUniswapFactory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);
    IBancorContractRegistry constant internal bancorContractRegistry = IBancorContractRegistry(0x52Ae12ABe5D8BD778BD5397F99cA900624CfADD4);
    IBancorNetworkPathFinder constant internal bancorNetworkPathFinder = IBancorNetworkPathFinder(0x6F0cD8C4f6F06eAB664C7E3031909452b4B72861);
    //IBancorConverterRegistry constant internal bancorConverterRegistry = IBancorConverterRegistry(0xf6E2D7F616B67E46D708e4410746E9AAb3a4C518);
    IBancorFinder constant internal bancorFinder = IBancorFinder(0x2B344e14dc2641D11D338C053C908c7A7D4c30B9);
    IOasisExchange constant internal oasisExchange = IOasisExchange(0x794e6e91555438aFc3ccF1c5076A74F42133d08D);
    ICurve constant internal curveCompound = ICurve(0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56);
    ICurve constant internal curveUSDT = ICurve(0x52EA46506B9CC5Ef470C5bf89f17Dc28bB35D85C);
    ICurve constant internal curveY = ICurve(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51);
    ICurve constant internal curveBinance = ICurve(0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27);
    ICurve constant internal curveSynthetix = ICurve(0xA5407eAE9Ba41422680e2e00537571bcC53efBfD);
    ICurve constant internal curvePAX = ICurve(0x06364f10B501e868329afBc005b3492902d6C763);
    ICurve constant internal curveRenBTC = ICurve(0x93054188d876f558f4a66B2EF1d97d16eDf0895B);
    ICurve constant internal curveTBTC = ICurve(0x9726e9314eF1b96E45f40056bEd61A088897313E);
    ICurve constant internal curveSBTC = ICurve(0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714);
    IShell constant internal shell = IShell(0xA8253a440Be331dC4a7395B73948cCa6F19Dc97D);
    IAaveLendingPool constant internal aave = IAaveLendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);
    ICompound constant internal compound = ICompound(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    ICompoundEther constant internal cETH = ICompoundEther(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);
    IMooniswapRegistry constant internal mooniswapRegistry = IMooniswapRegistry(0x7079E8517594e5b21d2B9a0D17cb33F5FE2bca70);
    IUniswapV2Factory constant internal uniswapV2 = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IDForceSwap constant internal dforceSwap = IDForceSwap(0x03eF3f37856bD08eb47E2dE7ABc4Ddd2c19B60F2);
    IMStable constant internal musd = IMStable(0xe2f2a5C287993345a840Db3B0845fbC70f5935a5);
    IMassetRedemptionValidator constant internal musd_helper = IMassetRedemptionValidator(0x4c5e03065bC52cCe84F3ac94DF14bbAC27eac89b);
    IBalancerRegistry constant internal balancerRegistry = IBalancerRegistry(0x65e67cbc342712DF67494ACEfc06fe951EE93982);
    ICurveCalculator constant internal curveCalculator = ICurveCalculator(0xc1DB00a8E5Ef7bfa476395cdbcc98235477cDE4E);
    ICurveRegistry constant internal curveRegistry = ICurveRegistry(0x7002B727Ef8F5571Cb5F9D70D13DBEEb4dFAe9d1);

    int256 internal constant VERY_NEGATIVE_VALUE = -1e72;

    function _findBestDistribution(
        uint256 s,                // parts
        int256[][] memory amounts // exchangesReturns
    )
        internal
        pure
        returns(
            int256 returnAmount,
            uint256[] memory distribution
        )
    {
        uint256 n = amounts.length;

        int256[][] memory answer = new int256[][](n); // int[n][s+1]
        uint256[][] memory parent = new uint256[][](n); // int[n][s+1]

        for (uint i = 0; i < n; i++) {
            answer[i] = new int256[](s + 1);
            parent[i] = new uint256[](s + 1);
        }

        for (uint j = 0; j <= s; j++) {
            answer[0][j] = amounts[0][j];
            for (uint i = 1; i < n; i++) {
                answer[i][j] = -1e72;
            }
            parent[0][j] = 0;
        }

        for (uint i = 1; i < n; i++) {
            for (uint j = 0; j <= s; j++) {
                answer[i][j] = answer[i - 1][j];
                parent[i][j] = j;

                for (uint k = 1; k <= j; k++) {
                    if (answer[i - 1][j - k] + amounts[i][k] > answer[i][j]) {
                        answer[i][j] = answer[i - 1][j - k] + amounts[i][k];
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

        returnAmount = (answer[n - 1][s] == VERY_NEGATIVE_VALUE) ? 0 : answer[n - 1][s];
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

    function _isSingleTokenKyberReserve(address reserve) private pure returns(bool) {
        address[5] memory badReserves = [
            0x63825c174ab367968EC60f061753D3bbD36A0D8F, // Reserve 1
            0x7a3370075a54B187d7bD5DceBf0ff2B5552d4F7D, // Reserve 2
            0x4f32BbE8dFc9efD54345Fc936f9fEF1048746fCF, // Reserve 3
            0x1E158c0e93c30d24e918Ef83d1e0bE23595C3c0f, // Eth2Dai
            0x31E085Afd48a1d6e51Cc193153d625e8f0514C7F  // Uniswap
        ];

        for (uint i = 0; i < badReserves.length; i++) {
            if (reserve == badReserves[i]) {
                return false;
            }
        }

        return true;
    }

    function _kyberReserveIdByTokens(
        IERC20 fromToken,
        IERC20 destToken
    ) internal pure returns(bytes32) {
        if (!fromToken.isETH() && !destToken.isETH()) {
            return 0;
        }

        address[] memory reserves = kyberStorage.getReserveAddressesPerTokenSrc(fromToken.isETH() ? destToken : fromToken, 0, 10);
        for (uint i = 0; i < reserves.length; i++) {
            if (_isSingleTokenKyberReserve(reserves[i])) {
                return reserves[i];
            }
        }

        return 0;

        // if (fromToken == abyss || destToken == abyss) {
        //     return 0xaa41627973730000000000000000000000000000000000000000000000000000; // 0x3e9FFBA3C3eB91f501817b031031a71de2d3163B
        // }
        // if (fromToken == equad || destToken == equad) {
        //     return 0xaa65515541440000000000000000000000000000000000000000000000000000; // 0xC28e931814725BbEB9e670676FaBBCb694Fe7DF2
        // }
        // if (fromToken == mln || destToken == mln) {
        //     return 0xaa4d656c6f6e706f727400000000000000000000000000000000000000000000; // 0xa33c7c22d0BB673c2aEa2C048BB883b679fa1BE9
        // }
        // if (fromToken == ren || destToken == ren) {
        //     return 0xaa72656e00000000000000000000000000000000000000000000000000000000; // 0x45eb33D008801d547990cAF3b63B4F8aE596EA57
        // }
        // if (fromToken == usdc || destToken == usdc) {
        //     return 0xaa55534443303041505200000000000000000000000000000000000000000000; // 0x1670DFb52806DE7789D5cF7D5c005cf7083f9A5D
        // }
        // if (fromToken == gen || destToken == gen) {
        //     return 0xaa47454e00000000000000000000000000000000000000000000000000000000; // 0xAA14DCAA0AdbE79cBF00edC6cC4ED17ed39240AC
        // }
        // if (fromToken == gno || destToken == gno) {
        //     return 0xaa4b4e4320474e4f000000000000000000000000000000000000000000000000; // 0x05461124C86C0AD7C5d8E012e1499fd9109fFb7d
        // }
        // if (fromToken == myb || destToken == myb) {
        //     return 0xaa4d594200000000000000000000000000000000000000000000000000000000; // 0x1833AD67362249823515B59A8aA8b4f6B4358d1B
        // }
        // if (fromToken == bam || destToken == bam) {
        //     return 0xaa42414d00000000000000000000000000000000000000000000000000000000; // 0x302B35bd0B01312ec2652783c04955D7200C3D9b
        // }
        // if (fromToken == spn || destToken == spn) {
        //     return 0xaa48756d616e7320466972737400000000000000000000000000000000000000; // 0x6b84DBd29643294703dBabf8Ed97cDef74EDD227
        // }
        // if (fromToken == upp || destToken == upp) {
        //     return 0xaa55505000000000000000000000000000000000000000000000000000000000; // 0x7e2fd015616263Add31a2AcC2A437557cEe80Fc4
        // }
        // if (fromToken == snx || destToken == snx) {
        //     return 0xaa534e5800000000000000000000000000000000000000000000000000000000; // 0xa107dfa919c3f084a7893A260b99586981beb528
        // }
        // if (fromToken == tkn || destToken == tkn) {
        //     return 0xaa97aad58d5670d74ffb37e8c6272b3463f08be662718f7681c6e5bffc1b05c0; // 0x3480E12B6C2438e02319e34b4c23770679169190
        // }
        // if (fromToken == rae || destToken == rae) {
        //     return 0xaa52414520415052000000000000000000000000000000000000000000000000; // 0x751Eea622edd1E3D768C18afbCaeC7DcE7750C65
        // }
        // if (fromToken == susd || destToken == susd) {
        //     return 0xaa73555344000000000000000000000000000000000000000000000000000000; // 0x4Cb01bd05E4652CbB9F312aE604f4549D2bf2C99
        // }
        // if (fromToken == spike || destToken == spike) {
        //     return 0xaa88888888888888888888888888888888888888888888888888888888888888; // 0x8ea5CF9f61824E8A3cA8AA370AB37e0202B2CC7D
        // }
        // if (fromToken == san || destToken == san) {
        //     return 0xaa53414e20415052000000000000000000000000000000000000000000000000; // 0xa9742Ee9a5407f4C2f8a49f65E3a440f3694960a
        // }
        // if (fromToken == knc || destToken == knc) {
        //     return 0xaa4b4e435f4d4547414c41444f4e000000000000000000000000000000000000; // 0x607d7751d9F4845C5a1dE9eeD39c56f4fC0F855d
        // }
        // if (fromToken == bnt || destToken == bnt) {
        //     return 0xbb42414e434f5230305632000000000000000000000000000000000000000000; // 0x1fE867bFE9cbE0045467605B959A355223E3885D
        // }
        // if (fromToken == ekg || destToken == ekg) {
        //     return 0xff454b4700000000000000000000000000000000000000000000000000000000; // 0x4e6d0F492fd139151DE4728caC47dAce56C56Af4
        // }
        // if (fromToken == ant || destToken == ant) {
        //     return 0xaa414e5400000000000000000000000000000000000000000000000000000000; // 0x0994c18Ed0C328F38d2C451B2a2e1cEb1Ae6A812
        // }
        // if (fromToken == gdc || destToken == gdc) {
        //     return 0xaa676463746f6b656e0000000000000000000000000000000000000000000000; // 0x2485a4e3Dd95a3Ef445B786acf7bacc5C99986F7
        // }
        // if (fromToken == ampl || destToken == ampl) {
        //     return 0xaad46ba6d942050d489dbd938a2c909a5d5039a1610000000000000000000000; // 0x977c9ABB01Ed3E99e9953fD1F472aE9f459E7E70
        // }
        // if (fromToken == met || destToken == met) {
        //     return 0xaa4d455400000000000000000000000000000000000000000000000000000000; // 0x2Ed6F2bC006DA5897A0C3cD2686283C05e50C573
        // }
        // if (fromToken == mfg || destToken == mfg) {
        //     return 0xaa6d6667546f6b656e0000000000000000000000000000000000000000000000; // 0x55a8fda671a257b80258d2a03abd6e0e1e3dbe79
        // }
        // if (fromToken == ubt || destToken == ubt) {
        //     return 0xaa55425400000000000000000000000000000000000000000000000000000000; // 0xfe06bc8BC12595C1c871fF7c2ea9CadC42735d7D
        // }
        // if (fromToken == pbtc || destToken == pbtc) {
        //     return 0xff50425443000000000000000000000000000000000000000000000000000000; // 0x0Ce59E811024C4aA040389fb8917dD9EDAEf1693
        // }
        // if (fromToken == ogn || destToken == ogn) {
        //     return 0xaa4f474e00000000000000000000000000000000000000000000000000000000; // 0xb89f41CD2C8B6cba8b851289198b06Be8B4Dec65
        // }
        // if (fromToken == band || destToken == band) {
        //     return 0xaa42414e44000000000000000000000000000000000000000000000000000000; // 0xb06Cf173DA7E297aa6268139c7Cb67C53D8E4f90
        // }
        // if (fromToken == rsv || destToken == rsv) {
        //     return 0xaa525356546f6b656e0000000000000000000000000000000000000000000000; // 0x141104687b51985D6210Eb4b398F1DC5b5b9e9F5
        // }
        // if (fromToken == key || destToken == key) {
        //     return 0xaa4b455900000000000000000000000000000000000000000000000000000000; // 0x3e59c69952a4cFEaF653EedF8ff907D4b6b8762D
        // }
        // if (fromToken == pnk || destToken == pnk) {
        //     return 0xaa504e4b00000000000000000000000000000000000000000000000000000000; // 0x10db2A136ee3E0C963d82aF4C86Ca483199f2816
        // }
        // if (fromToken == cnd || destToken == cnd) {
        //     return 0xaa434e4400000000000000000000000000000000000000000000000000000000; // 0xAD84a44a673Be4FdcD5e39Ebd15eBC404E87F314
        // }
        // if (fromToken == tryb || destToken == tryb) {
        //     return 0xaa54525942000000000000000000000000000000000000000000000000000000; // 0xe96b41aF3DA574A991582dC54cC35535550a3f8d
        // }
        // if (fromToken == twokey || destToken == twokey) {
        //     return 0xaacfefe57c1e0f781f9864fe27287980a2097e60c0ee0c5e71083e32cecd1c9c; // 0x00Cd2388C86C960A646D640bE44FC8F83b78cEC9
        // }
        // if (fromToken == plr || destToken == plr) {
        //     return 0xaa504c5200000000000000000000000000000000000000000000000000000000; // 0x71eb6edF770b25Fcd60Ad9790AA20C422F0f4a0d
        // }
        // if (fromToken == qnt || destToken == qnt) {
        //     return 0xaa514e5452657365727665000000000000000000000000000000000000000000; // 0x773A58C0ae122f56d6747BC1264F00174B3144c3
        // }
        // if (fromToken == pnt || destToken == pnt) {
        //     return 0xff504e5400000000000000000000000000000000000000000000000000000000; // 0x89b3F60A17789Aa7c7061Af6f5e9efA407153C03
        // }
        // if (fromToken == req || destToken == req) {
        //     return 0xaa52455100000000000000000000000000000000000000000000000000000000; // 0x23Fe3C603BE19d3a1155766358071CAcEFe14537
        // }
        // if (fromToken == rsr || destToken == rsr) {
        //     return 0xaa525352546f6b656e0000000000000000000000000000000000000000000000; // 0x0b798B89155eA31f1312791b9fdFAae7c5F48460
        // }
    }

    function _scaleDestTokenEthPriceTimesGasPrice(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 destTokenEthPriceTimesGasPrice
    ) internal view returns(uint256) {
        if (fromToken == destToken) {
            return destTokenEthPriceTimesGasPrice;
        }

        uint256 mul = _cheapGetPrice(ETH_ADDRESS, destToken, 0.01 ether);
        uint256 div = _cheapGetPrice(ETH_ADDRESS, fromToken, 0.01 ether);
        if (div > 0) {
            return destTokenEthPriceTimesGasPrice.mul(mul).div(div);
        }
        return 0;
    }

    function _cheapGetPrice(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal view returns(uint256 returnAmount) {
        (returnAmount,,) = this.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            1,
            FLAG_DISABLE_SPLIT_RECALCULATION |
            FLAG_DISABLE_ALL_SPLIT_SOURCES |
            FLAG_DISABLE_UNISWAP_V2_ALL |
            FLAG_DISABLE_UNISWAP,
            0
        );
    }

    function _linearInterpolation(
        uint256 value,
        uint256 parts
    ) internal pure returns(uint256[] memory rets) {
        rets = new uint256[](parts);
        for (uint i = 0; i < parts; i++) {
            rets[i] = value.mul(i + 1).div(parts);
        }
    }

    function _tokensEqual(IERC20 tokenA, IERC20 tokenB) internal pure returns(bool) {
        return ((tokenA.isETH() && tokenB.isETH()) || tokenA == tokenB);
    }
}


contract OneSplitViewWrapBase is IOneSplitView, OneSplitRoot {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
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
        (returnAmount, , distribution) = this.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            0
        );
    }

    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        return _getExpectedReturnRespectingGasFloor(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function _getExpectedReturnRespectingGasFloor(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags, // See constants in IOneSplit.sol
        uint256 destTokenEthPriceTimesGasPrice
    )
        internal
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        );
}


contract OneSplitView is IOneSplitView, OneSplitRoot {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
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
        (returnAmount, , distribution) = getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            0
        );
    }

    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags, // See constants in IOneSplit.sol
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        distribution = new uint256[](DEXES_COUNT);

        if (fromToken == destToken) {
            return (amount, 0, distribution);
        }

        function(IERC20,IERC20,uint256,uint256,uint256) view returns(uint256[] memory, uint256)[DEXES_COUNT] memory reserves = _getAllReserves(flags);

        int256[][] memory matrix = new int256[][](DEXES_COUNT);
        uint256[DEXES_COUNT] memory gases;
        bool atLeastOnePositive = false;
        for (uint i = 0; i < DEXES_COUNT; i++) {
            uint256[] memory rets;
            (rets, gases[i]) = reserves[i](fromToken, destToken, amount, parts, flags);

            // Prepend zero and sub gas
            int256 gas = int256(gases[i].mul(destTokenEthPriceTimesGasPrice).div(1e18));
            matrix[i] = new int256[](parts + 1);
            for (uint j = 0; j < parts; j++) {
                matrix[i][j + 1] = int256(rets[j]) - gas;
                atLeastOnePositive = atLeastOnePositive || (matrix[i][j + 1] > 0);
            }
        }

        if (!atLeastOnePositive) {
            for (uint i = 0; i < DEXES_COUNT; i++) {
                for (uint j = 1; j < parts + 1; j++) {
                    if (matrix[i][j] == 0) {
                        matrix[i][j] = VERY_NEGATIVE_VALUE;
                    }
                }
            }
        }

        (, distribution) = _findBestDistribution(parts, matrix);

        (returnAmount, estimateGasAmount) = _getReturnAndGasByDistribution(
            Args({
                fromToken: fromToken,
                destToken: destToken,
                amount: amount,
                parts: parts,
                flags: flags,
                destTokenEthPriceTimesGasPrice: destTokenEthPriceTimesGasPrice,
                distribution: distribution,
                matrix: matrix,
                gases: gases,
                reserves: reserves
            })
        );
        return (returnAmount, estimateGasAmount, distribution);
    }

    struct Args {
        IERC20 fromToken;
        IERC20 destToken;
        uint256 amount;
        uint256 parts;
        uint256 flags;
        uint256 destTokenEthPriceTimesGasPrice;
        uint256[] distribution;
        int256[][] matrix;
        uint256[DEXES_COUNT] gases;
        function(IERC20,IERC20,uint256,uint256,uint256) view returns(uint256[] memory, uint256)[DEXES_COUNT] reserves;
    }

    function _getReturnAndGasByDistribution(
        Args memory args
    ) internal view returns(uint256 returnAmount, uint256 estimateGasAmount) {
        bool[DEXES_COUNT] memory exact = [
            true,  // "Uniswap",
            false, // "Kyber",
            false, // "Bancor",
            false, // "Oasis",
            true,  // "Curve Compound",
            true,  // "Curve USDT",
            true,  // "Curve Y",
            true,  // "Curve Binance",
            true,  // "Curve Synthetix",
            true,  // "Uniswap Compound",
            true,  // "Uniswap CHAI",
            true,  // "Uniswap Aave",
            false, // "Mooniswap",
            true,  // "Uniswap V2",
            true,  // "Uniswap V2 (ETH)",
            true,  // "Uniswap V2 (DAI)",
            true,  // "Uniswap V2 (USDC)",
            true,  // "Curve Pax",
            true,  // "Curve RenBTC",
            true,  // "Curve tBTC",
            true,  // "Dforce XSwap",
            false, // "Shell",
            true,  // "mStable",
            true,  // "Curve sBTC"
            true,  // "Balancer 1"
            true,  // "Balancer 2"
            true,  // "Balancer 3"
            true,  // "Kyber 1"
            true,  // "Kyber 2"
            true,  // "Kyber 3"
            true   // "Kyber 4"
        ];

        for (uint i = 0; i < DEXES_COUNT; i++) {
            if (args.distribution[i] > 0) {
                if (args.distribution[i] == args.parts || exact[i] || args.flags.check(FLAG_DISABLE_SPLIT_RECALCULATION)) {
                    estimateGasAmount = estimateGasAmount.add(args.gases[i]);
                    int256 value = args.matrix[i][args.distribution[i]];
                    returnAmount = returnAmount.add(uint256(
                        (value == VERY_NEGATIVE_VALUE ? 0 : value) +
                        int256(args.gases[i].mul(args.destTokenEthPriceTimesGasPrice).div(1e18))
                    ));
                }
                else {
                    (uint256[] memory rets, uint256 gas) = args.reserves[i](args.fromToken, args.destToken, args.amount.mul(args.distribution[i]).div(args.parts), 1, args.flags);
                    estimateGasAmount = estimateGasAmount.add(gas);
                    returnAmount = returnAmount.add(rets[0]);
                }
            }
        }
    }

    function _getAllReserves(uint256 flags)
        internal
        pure
        returns(function(IERC20,IERC20,uint256,uint256,uint256) view returns(uint256[] memory, uint256)[DEXES_COUNT] memory)
    {
        bool invert = flags.check(FLAG_DISABLE_ALL_SPLIT_SOURCES);
        return [
            invert != flags.check(FLAG_DISABLE_UNISWAP_ALL | FLAG_DISABLE_UNISWAP)            ? _calculateNoReturn : calculateUniswap,
            _calculateNoReturn, // invert != flags.check(FLAG_DISABLE_KYBER) ? _calculateNoReturn : calculateKyber,
            invert != flags.check(FLAG_DISABLE_BANCOR)                                        ? _calculateNoReturn : calculateBancor,
            invert != flags.check(FLAG_DISABLE_OASIS)                                         ? _calculateNoReturn : calculateOasis,
            invert != flags.check(FLAG_DISABLE_CURVE_ALL | FLAG_DISABLE_CURVE_COMPOUND)       ? _calculateNoReturn : calculateCurveCompound,
            invert != flags.check(FLAG_DISABLE_CURVE_ALL | FLAG_DISABLE_CURVE_USDT)           ? _calculateNoReturn : calculateCurveUSDT,
            invert != flags.check(FLAG_DISABLE_CURVE_ALL | FLAG_DISABLE_CURVE_Y)              ? _calculateNoReturn : calculateCurveY,
            invert != flags.check(FLAG_DISABLE_CURVE_ALL | FLAG_DISABLE_CURVE_BINANCE)        ? _calculateNoReturn : calculateCurveBinance,
            invert != flags.check(FLAG_DISABLE_CURVE_ALL | FLAG_DISABLE_CURVE_SYNTHETIX)      ? _calculateNoReturn : calculateCurveSynthetix,
            invert != flags.check(FLAG_DISABLE_UNISWAP_ALL | FLAG_DISABLE_UNISWAP_COMPOUND)   ? _calculateNoReturn : calculateUniswapCompound,
            invert != flags.check(FLAG_DISABLE_UNISWAP_ALL | FLAG_DISABLE_UNISWAP_CHAI)       ? _calculateNoReturn : calculateUniswapChai,
            invert != flags.check(FLAG_DISABLE_UNISWAP_ALL | FLAG_DISABLE_UNISWAP_AAVE)       ? _calculateNoReturn : calculateUniswapAave,
            invert != flags.check(FLAG_DISABLE_MOONISWAP)                                     ? _calculateNoReturn : calculateMooniswap,
            invert != flags.check(FLAG_DISABLE_UNISWAP_V2_ALL | FLAG_DISABLE_UNISWAP_V2)      ? _calculateNoReturn : calculateUniswapV2,
            invert != flags.check(FLAG_DISABLE_UNISWAP_V2_ALL | FLAG_DISABLE_UNISWAP_V2_ETH)  ? _calculateNoReturn : calculateUniswapV2ETH,
            invert != flags.check(FLAG_DISABLE_UNISWAP_V2_ALL | FLAG_DISABLE_UNISWAP_V2_DAI)  ? _calculateNoReturn : calculateUniswapV2DAI,
            invert != flags.check(FLAG_DISABLE_UNISWAP_V2_ALL | FLAG_DISABLE_UNISWAP_V2_USDC) ? _calculateNoReturn : calculateUniswapV2USDC,
            invert != flags.check(FLAG_DISABLE_CURVE_ALL | FLAG_DISABLE_CURVE_PAX)            ? _calculateNoReturn : calculateCurvePAX,
            invert != flags.check(FLAG_DISABLE_CURVE_ALL | FLAG_DISABLE_CURVE_RENBTC)         ? _calculateNoReturn : calculateCurveRenBTC,
            invert != flags.check(FLAG_DISABLE_CURVE_ALL | FLAG_DISABLE_CURVE_TBTC)           ? _calculateNoReturn : calculateCurveTBTC,
            invert != flags.check(FLAG_DISABLE_DFORCE_SWAP)                                   ? _calculateNoReturn : calculateDforceSwap,
            invert != flags.check(FLAG_DISABLE_SHELL)                                         ? _calculateNoReturn : calculateShell,
            invert != flags.check(FLAG_DISABLE_MSTABLE_MUSD)                                  ? _calculateNoReturn : calculateMStableMUSD,
            invert != flags.check(FLAG_DISABLE_CURVE_ALL | FLAG_DISABLE_CURVE_SBTC)           ? _calculateNoReturn : calculateCurveSBTC,
            invert != flags.check(FLAG_DISABLE_BALANCER_ALL | FLAG_DISABLE_BALANCER_1)        ? _calculateNoReturn : calculateBalancer1,
            invert != flags.check(FLAG_DISABLE_BALANCER_ALL | FLAG_DISABLE_BALANCER_2)        ? _calculateNoReturn : calculateBalancer2,
            invert != flags.check(FLAG_DISABLE_BALANCER_ALL | FLAG_DISABLE_BALANCER_3)        ? _calculateNoReturn : calculateBalancer3,
            invert != flags.check(FLAG_DISABLE_KYBER_ALL | FLAG_DISABLE_KYBER_1)              ? _calculateNoReturn : calculateKyber1,
            invert != flags.check(FLAG_DISABLE_KYBER_ALL | FLAG_DISABLE_KYBER_2)              ? _calculateNoReturn : calculateKyber2,
            invert != flags.check(FLAG_DISABLE_KYBER_ALL | FLAG_DISABLE_KYBER_3)              ? _calculateNoReturn : calculateKyber3,
            invert != flags.check(FLAG_DISABLE_KYBER_ALL | FLAG_DISABLE_KYBER_4)              ? _calculateNoReturn : calculateKyber4
        ];
    }

    function _calculateNoGas(
        IERC20 /*fromToken*/,
        IERC20 /*destToken*/,
        uint256 /*amount*/,
        uint256 /*parts*/,
        uint256 /*destTokenEthPriceTimesGasPrice*/,
        uint256 /*flags*/,
        uint256 /*destTokenEthPrice*/
    ) internal view returns(uint256[] memory /*rets*/, uint256 /*gas*/) {
        this;
    }

    // View Helpers

    function _calculateBalancer(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/,
        uint256 poolIndex
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        rets = new uint256[](parts);

        address[] memory pools = balancerRegistry.getBestPoolsWithLimit(
            address(fromToken.isETH() ? weth : fromToken),
            address(destToken.isETH() ? weth : destToken),
            poolIndex + 1
        );
        if (poolIndex >= pools.length) {
            return (rets, 0);
        }

        (bool success, bytes memory result) = address(balancerRegistry).staticcall(
            abi.encodeWithSelector(
                balancerRegistry.getPoolReturns.selector,
                pools[poolIndex],
                address(fromToken.isETH() ? weth : fromToken),
                address(destToken.isETH() ? weth : destToken),
                _linearInterpolation(amount, parts)
            )
        );

        if (!success || result.length == 0) {
            return (rets, 0);
        }

        return (
            abi.decode(result, (uint256[])),
            100_000
        );
    }

    function calculateBalancer1(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        return _calculateBalancer(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            0
        );
    }

    function calculateBalancer2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        return _calculateBalancer(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            1
        );
    }

    function calculateBalancer3(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        return _calculateBalancer(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            2
        );
    }

    function calculateMStableMUSD(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        rets = new uint256[](parts);

        if ((fromToken != usdc && fromToken != dai && fromToken != usdt && fromToken != tusd) ||
            (destToken != usdc && destToken != dai && destToken != usdt && destToken != tusd))
        {
            return (rets, 0);
        }

        for (uint i = 1; i <= parts; i *= 2) {
            (bool success, bytes memory data) = address(musd).staticcall(abi.encodeWithSelector(
                musd.getSwapOutput.selector,
                fromToken,
                destToken,
                amount.mul(parts.div(i)).div(parts)
            ));

            if (success && data.length > 0) {
                (,, uint256 maxRet) = abi.decode(data, (bool,string,uint256));
                if (maxRet > 0) {
                    for (uint j = 0; j < parts.div(i); j++) {
                        rets[j] = maxRet.mul(j + 1).div(parts.div(i));
                    }
                    break;
                }
            }
        }

        return (
            rets,
            700_000
        );
    }

    function _getCurvePoolInfo(
        ICurve curve,
        bool haveUnderlying
    ) internal view returns(
        uint256[8] memory balances,
        uint256[8] memory precisions,
        uint256[8] memory rates,
        uint256 amp,
        uint256 fee
    ) {
        uint256[8] memory underlying_balances;
        uint256[8] memory decimals;
        uint256[8] memory underlying_decimals;

        (
            balances,
            underlying_balances,
            decimals,
            underlying_decimals,
            /*address lp_token*/,
            amp,
            fee
        ) = curveRegistry.get_pool_info(address(curve));

        for (uint k = 0; k < 8 && balances[k] > 0; k++) {
            precisions[k] = 10 ** (18 - (haveUnderlying ? underlying_decimals : decimals)[k]);
            if (haveUnderlying) {
                rates[k] = underlying_balances[k].mul(1e18).div(balances[k]);
            } else {
                rates[k] = 1e18;
            }
        }
    }

    function _calculateCurveSelector(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        ICurve curve,
        bool haveUnderlying,
        IERC20[] memory tokens
    ) internal view returns(uint256[] memory rets) {
        rets = new uint256[](parts);

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
            return rets;
        }

        bytes memory data = abi.encodePacked(
            uint256(haveUnderlying ? 1 : 0),
            uint256(i - 1),
            uint256(j - 1),
            _linearInterpolation100(amount, parts)
        );

        (
            uint256[8] memory balances,
            uint256[8] memory precisions,
            uint256[8] memory rates,
            uint256 amp,
            uint256 fee
        ) = _getCurvePoolInfo(curve, haveUnderlying);

        bool success;
        (success, data) = address(curveCalculator).staticcall(
            abi.encodePacked(
                abi.encodeWithSelector(
                    curveCalculator.get_dy.selector,
                    tokens.length,
                    balances,
                    amp,
                    fee,
                    rates,
                    precisions
                ),
                data
            )
        );

        if (!success || data.length == 0) {
            return rets;
        }

        uint256[100] memory dy = abi.decode(data, (uint256[100]));
        for (uint t = 0; t < parts; t++) {
            rets[t] = dy[t];
        }
    }

    function _linearInterpolation100(
        uint256 value,
        uint256 parts
    ) internal pure returns(uint256[100] memory rets) {
        for (uint i = 0; i < parts; i++) {
            rets[i] = value.mul(i + 1).div(parts);
        }
    }

    function calculateCurveCompound(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = dai;
        tokens[1] = usdc;
        return (_calculateCurveSelector(
            fromToken,
            destToken,
            amount,
            parts,
            curveCompound,
            true,
            tokens
        ), 720_000);
    }

    function calculateCurveUSDT(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](3);
        tokens[0] = dai;
        tokens[1] = usdc;
        tokens[2] = usdt;
        return (_calculateCurveSelector(
            fromToken,
            destToken,
            amount,
            parts,
            curveUSDT,
            true,
            tokens
        ), 720_000);
    }

    function calculateCurveY(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](4);
        tokens[0] = dai;
        tokens[1] = usdc;
        tokens[2] = usdt;
        tokens[3] = tusd;
        return (_calculateCurveSelector(
            fromToken,
            destToken,
            amount,
            parts,
            curveY,
            true,
            tokens
        ), 1_400_000);
    }

    function calculateCurveBinance(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](4);
        tokens[0] = dai;
        tokens[1] = usdc;
        tokens[2] = usdt;
        tokens[3] = busd;
        return (_calculateCurveSelector(
            fromToken,
            destToken,
            amount,
            parts,
            curveBinance,
            true,
            tokens
        ), 1_400_000);
    }

    function calculateCurveSynthetix(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](4);
        tokens[0] = dai;
        tokens[1] = usdc;
        tokens[2] = usdt;
        tokens[3] = susd;
        return (_calculateCurveSelector(
            fromToken,
            destToken,
            amount,
            parts,
            curveSynthetix,
            true,
            tokens
        ), 200_000);
    }

    function calculateCurvePAX(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](4);
        tokens[0] = dai;
        tokens[1] = usdc;
        tokens[2] = usdt;
        tokens[3] = pax;
        return (_calculateCurveSelector(
            fromToken,
            destToken,
            amount,
            parts,
            curvePAX,
            true,
            tokens
        ), 1_000_000);
    }

    function calculateCurveRenBTC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = renbtc;
        tokens[1] = wbtc;
        return (_calculateCurveSelector(
            fromToken,
            destToken,
            amount,
            parts,
            curveRenBTC,
            false,
            tokens
        ), 130_000);
    }

    function calculateCurveTBTC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](3);
        tokens[0] = tbtc;
        tokens[1] = wbtc;
        tokens[2] = hbtc;
        return (_calculateCurveSelector(
            fromToken,
            destToken,
            amount,
            parts,
            curveTBTC,
            false,
            tokens
        ), 145_000);
    }

    function calculateCurveSBTC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20[] memory tokens = new IERC20[](3);
        tokens[0] = renbtc;
        tokens[1] = wbtc;
        tokens[2] = sbtc;
        return (_calculateCurveSelector(
            fromToken,
            destToken,
            amount,
            parts,
            curveSBTC,
            false,
            tokens
        ), 150_000);
    }

    function calculateShell(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        (bool success, bytes memory data) = address(shell).staticcall(abi.encodeWithSelector(
            shell.viewOriginTrade.selector,
            fromToken,
            destToken,
            amount
        ));

        if (!success || data.length == 0) {
            return (new uint256[](parts), 0);
        }

        uint256 maxRet = abi.decode(data, (uint256));
        return (_linearInterpolation(maxRet, parts), 300_000);
    }

    function calculateDforceSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        (bool success, bytes memory data) = address(dforceSwap).staticcall(
            abi.encodeWithSelector(
                dforceSwap.getAmountByInput.selector,
                fromToken,
                destToken,
                amount
            )
        );
        if (!success || data.length == 0) {
            return (new uint256[](parts), 0);
        }

        uint256 maxRet = abi.decode(data, (uint256));
        uint256 available = destToken.universalBalanceOf(address(dforceSwap));
        if (maxRet > available) {
            return (new uint256[](parts), 0);
        }

        return (_linearInterpolation(maxRet, parts), 160_000);
    }

    function _calculateUniswapFormula(uint256 fromBalance, uint256 toBalance, uint256 amount) internal pure returns(uint256) {
        if (amount == 0) {
            return 0;
        }
        return amount.mul(toBalance).mul(997).div(
            fromBalance.mul(1000).add(amount.mul(997))
        );
    }

    function _calculateUniswap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256[] memory amounts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        rets = amounts;

        if (!fromToken.isETH()) {
            IUniswapExchange fromExchange = uniswapFactory.getExchange(fromToken);
            if (fromExchange == IUniswapExchange(0)) {
                return (new uint256[](rets.length), 0);
            }

            uint256 fromTokenBalance = fromToken.universalBalanceOf(address(fromExchange));
            uint256 fromEtherBalance = address(fromExchange).balance;

            for (uint i = 0; i < rets.length; i++) {
                rets[i] = _calculateUniswapFormula(fromTokenBalance, fromEtherBalance, rets[i]);
            }
        }

        if (!destToken.isETH()) {
            IUniswapExchange toExchange = uniswapFactory.getExchange(destToken);
            if (toExchange == IUniswapExchange(0)) {
                return (new uint256[](rets.length), 0);
            }

            uint256 toEtherBalance = address(toExchange).balance;
            uint256 toTokenBalance = destToken.universalBalanceOf(address(toExchange));

            for (uint i = 0; i < rets.length; i++) {
                rets[i] = _calculateUniswapFormula(toEtherBalance, toTokenBalance, rets[i]);
            }
        }

        return (rets, fromToken.isETH() || destToken.isETH() ? 60_000 : 100_000);
    }

    function calculateUniswap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        return _calculateUniswap(
            fromToken,
            destToken,
            _linearInterpolation(amount, parts),
            flags
        );
    }

    function _calculateUniswapWrapped(
        IERC20 fromToken,
        IERC20 midToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 midTokenPrice,
        uint256 flags,
        uint256 gas1,
        uint256 gas2
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        if (!fromToken.isETH() && destToken.isETH()) {
            (rets, gas) = _calculateUniswap(
                midToken,
                destToken,
                _linearInterpolation(amount.mul(1e18).div(midTokenPrice), parts),
                flags
            );
            return (rets, gas + gas1);
        }
        else if (fromToken.isETH() && !destToken.isETH()) {
            (rets, gas) = _calculateUniswap(
                fromToken,
                midToken,
                _linearInterpolation(amount, parts),
                flags
            );

            for (uint i = 0; i < parts; i++) {
                rets[i] = rets[i].mul(midTokenPrice).div(1e18);
            }
            return (rets, gas + gas2);
        }

        return (new uint256[](parts), 0);
    }

    function calculateUniswapCompound(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20 midPreToken;
        if (!fromToken.isETH() && destToken.isETH()) {
            midPreToken = fromToken;
        }
        else if (!destToken.isETH() && fromToken.isETH()) {
            midPreToken = destToken;
        }

        if (!midPreToken.isETH()) {
            ICompoundToken midToken = _getCompoundToken(midPreToken);
            if (midToken != ICompoundToken(0)) {
                return _calculateUniswapWrapped(
                    fromToken,
                    midToken,
                    destToken,
                    amount,
                    parts,
                    midToken.exchangeRateStored(),
                    flags,
                    200_000,
                    200_000
                );
            }
        }

        return (new uint256[](parts), 0);
    }

    function calculateUniswapChai(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        if (fromToken == dai && destToken.isETH() ||
            fromToken.isETH() && destToken == dai)
        {
            return _calculateUniswapWrapped(
                fromToken,
                chai,
                destToken,
                amount,
                parts,
                chai.chaiPrice(),
                flags,
                180_000,
                160_000
            );
        }

        return (new uint256[](parts), 0);
    }

    function calculateUniswapAave(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IERC20 midPreToken;
        if (!fromToken.isETH() && destToken.isETH()) {
            midPreToken = fromToken;
        }
        else if (!destToken.isETH() && fromToken.isETH()) {
            midPreToken = destToken;
        }

        if (!midPreToken.isETH()) {
            IAaveToken midToken = _getAaveToken(midPreToken);
            if (midToken != IAaveToken(0)) {
                return _calculateUniswapWrapped(
                    fromToken,
                    midToken,
                    destToken,
                    amount,
                    parts,
                    1e18,
                    flags,
                    310_000,
                    670_000
                );
            }
        }

        return (new uint256[](parts), 0);
    }

    function calculateKyber1(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        return _calculateKyber(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            0xff4b796265722046707200000000000000000000000000000000000000000000 // 0x63825c174ab367968EC60f061753D3bbD36A0D8F
        );
    }

    function calculateKyber2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        return _calculateKyber(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            0xffabcd0000000000000000000000000000000000000000000000000000000000 // 0x7a3370075a54B187d7bD5DceBf0ff2B5552d4F7D
        );
    }

    function calculateKyber3(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        return _calculateKyber(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            0xff4f6e65426974205175616e7400000000000000000000000000000000000000 // 0x4f32BbE8dFc9efD54345Fc936f9fEF1048746fCF
        );
    }

    function calculateKyber4(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        if (!fromToken.isETH() && !destToken.isETH()) {
            return (new uint256[](0), 0);
        }

        bytes32 reserveId = _kyberReserveIdByTokens(fromToken, destToken);
        if (reserveId == 0) {
            return (new uint256[](0), 0);
        }

        return _calculateKyber(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            reserveId
        );
    }

    function _kyberGetReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags,
        bytes memory hint
    ) private view returns(uint256) {
        (, bytes memory data) = address(kyberNetworkProxy).staticcall(
            abi.encodeWithSelector(
                kyberNetworkProxy.getExpectedRateAfterFee.selector,
                fromToken,
                destToken,
                amount,
                flags.check(1 << 255) ? 10 : 0,
                hint
            )
        );

        return (data.length == 32) ? abi.decode(data, (uint256)) : 0;
    }

    function _calculateKyber(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        bytes32 reserveId
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        bytes memory fromHint;
        bytes memory destHint;
        {
            bytes32[] memory reserveIds = new bytes32[](1);
            reserveIds[0] = reserveId;

            fromHint = kyberHintHandler.buildTokenToEthHint(
                fromToken,
                IKyberHintHandler.TradeType.MaskIn,
                reserveIds,
                new uint256[](0)
            );

            destHint = kyberHintHandler.buildEthToTokenHint(
                destToken,
                IKyberHintHandler.TradeType.MaskIn,
                reserveIds,
                new uint256[](0)
            );
        }

        uint256 fromTokenDecimals = 10 ** IERC20(fromToken).universalDecimals();
        uint256 destTokenDecimals = 10 ** IERC20(destToken).universalDecimals();
        rets = new uint256[](parts);
        for (uint i = 0; i < parts; i++) {
            if (i > 0 && rets[i - 1] == 0) {
                break;
            }
            rets[i] = amount.mul(i + 1).div(parts);

            if (!fromToken.isETH()) {
                rets[i] = _kyberGetReturn(
                    fromToken,
                    ETH_ADDRESS,
                    rets[i],
                    flags,
                    fromHint
                );
                rets[i] = rets[i].mul(amount).div(fromTokenDecimals);
            }

            if (!destToken.isETH() && rets[i] > 0) {
                rets[i] = _kyberGetReturn(
                    ETH_ADDRESS,
                    destToken,
                    rets[i],
                    flags.check(1 << 255) ? 10 : 0,
                    destHint
                );
                rets[i] = rets[i].mul(amount).div(destTokenDecimals).div(1e36);
            }
        }

        return (rets, 200_000);
    }

    function calculateBancor(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IBancorNetwork bancorNetwork = IBancorNetwork(bancorContractRegistry.addressOf("BancorNetwork"));

        address[] memory path = bancorFinder.buildBancorPath(
            fromToken.isETH() ? bancorEtherToken : fromToken,
            destToken.isETH() ? bancorEtherToken : destToken
        );

        rets = _linearInterpolation(amount, parts);
        for (uint i = 0; i < parts; i++) {
            (bool success, bytes memory data) = address(bancorNetwork).staticcall.gas(500000)(
                abi.encodeWithSelector(
                    bancorNetwork.getReturnByPath.selector,
                    path,
                    rets[i]
                )
            );
            if (!success || data.length == 0) {
                for (; i < parts; i++) {
                    rets[i] = 0;
                }
                break;
            } else {
                (uint256 ret,) = abi.decode(data, (uint256,uint256));
                rets[i] = ret;
            }
        }

        return (rets, path.length.mul(150_000));
    }

    function calculateOasis(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        rets = _linearInterpolation(amount, parts);
        for (uint i = 0; i < parts; i++) {
            (bool success, bytes memory data) = address(oasisExchange).staticcall.gas(500000)(
                abi.encodeWithSelector(
                    oasisExchange.getBuyAmount.selector,
                    destToken.isETH() ? weth : destToken,
                    fromToken.isETH() ? weth : fromToken,
                    rets[i]
                )
            );

            if (!success || data.length == 0) {
                for (; i < parts; i++) {
                    rets[i] = 0;
                }
                break;
            } else {
                rets[i] = abi.decode(data, (uint256));
            }
        }

        return (rets, 500_000);
    }

    function calculateMooniswap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        IMooniswap mooniswap = mooniswapRegistry.target();
        (bool success, bytes memory data) = address(mooniswap).staticcall.gas(1000000)(
            abi.encodeWithSelector(
                mooniswap.getReturn.selector,
                fromToken,
                destToken,
                amount
            )
        );

        if (!success || data.length == 0) {
            return (new uint256[](parts), 0);
        }

        uint256 maxRet = abi.decode(data, (uint256));
        return (_linearInterpolation(maxRet, parts), 1_000_000);
    }

    function calculateUniswapV2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        return _calculateUniswapV2(
            fromToken,
            destToken,
            _linearInterpolation(amount, parts),
            flags
        );
    }

    function calculateUniswapV2ETH(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        if (fromToken.isETH() || fromToken == weth || destToken.isETH() || destToken == weth) {
            return (new uint256[](parts), 0);
        }

        return _calculateUniswapV2OverMidToken(
            fromToken,
            weth,
            destToken,
            amount,
            parts,
            flags
        );
    }

    function calculateUniswapV2DAI(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        if (fromToken == dai || destToken == dai) {
            return (new uint256[](parts), 0);
        }

        return _calculateUniswapV2OverMidToken(
            fromToken,
            dai,
            destToken,
            amount,
            parts,
            flags
        );
    }

    function calculateUniswapV2USDC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        if (fromToken == usdc || destToken == usdc) {
            return (new uint256[](parts), 0);
        }

        return _calculateUniswapV2OverMidToken(
            fromToken,
            usdc,
            destToken,
            amount,
            parts,
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
        uint256 flags
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        rets = _linearInterpolation(amount, parts);

        uint256 gas1;
        uint256 gas2;
        (rets, gas1) = _calculateUniswapV2(fromToken, midToken, rets, flags);
        (rets, gas2) = _calculateUniswapV2(midToken, destToken, rets, flags);
        return (rets, gas1 + gas2);
    }

    function _calculateNoReturn(
        IERC20 /*fromToken*/,
        IERC20 /*destToken*/,
        uint256 /*amount*/,
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns(uint256[] memory rets, uint256 gas) {
        this;
        return (new uint256[](parts), 0);
    }
}


contract OneSplitBaseWrap is IOneSplit, OneSplitRoot {
    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags // See constants in IOneSplit.sol
    ) internal {
        if (fromToken == destToken) {
            return;
        }

        _swapFloor(
            fromToken,
            destToken,
            amount,
            distribution,
            flags
        );
    }

    function _swapFloor(
        IERC20 fromToken,
        IERC20 destToken,
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
        IERC20 destToken,
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
        (returnAmount, , distribution) = getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            0
        );
    }

    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        return oneSplitView.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            destTokenEthPriceTimesGasPrice
        );
    }

    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 flags  // See constants in IOneSplit.sol
    ) public payable returns(uint256 returnAmount) {
        if (fromToken == destToken) {
            return amount;
        }

        function(IERC20,IERC20,uint256,uint256)[DEXES_COUNT] memory reserves = [
            _swapOnUniswap,
            _swapOnNowhere,
            _swapOnBancor,
            _swapOnOasis,
            _swapOnCurveCompound,
            _swapOnCurveUSDT,
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
            _swapOnCurvePAX,
            _swapOnCurveRenBTC,
            _swapOnCurveTBTC,
            _swapOnDforceSwap,
            _swapOnShell,
            _swapOnMStableMUSD,
            _swapOnCurveSBTC,
            _swapOnBalancer1,
            _swapOnBalancer2,
            _swapOnBalancer3,
            _swapOnKyber1,
            _swapOnKyber2,
            _swapOnKyber3,
            _swapOnKyber4
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

        if (parts == 0) {
            if (fromToken.isETH()) {
                msg.sender.transfer(msg.value);
                return msg.value;
            }
            return amount;
        }

        fromToken.universalTransferFrom(msg.sender, address(this), amount);
        uint256 remainingAmount = fromToken.universalBalanceOf(address(this));

        for (uint i = 0; i < distribution.length; i++) {
            if (distribution[i] == 0) {
                continue;
            }

            uint256 swapAmount = amount.mul(distribution[i]).div(parts);
            if (i == lastNonZeroIndex) {
                swapAmount = remainingAmount;
            }
            remainingAmount -= swapAmount;
            reserves[i](fromToken, destToken, swapAmount, flags);
        }

        returnAmount = destToken.universalBalanceOf(address(this));
        require(returnAmount >= minReturn, "OneSplit: Return amount was not enough");
        destToken.universalTransfer(msg.sender, returnAmount);
        fromToken.universalTransfer(msg.sender, fromToken.universalBalanceOf(address(this)));
    }

    // Swap helpers

    function _swapOnCurveCompound(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        int128 i = (fromToken == dai ? 1 : 0) + (fromToken == usdc ? 2 : 0);
        int128 j = (destToken == dai ? 1 : 0) + (destToken == usdc ? 2 : 0);
        if (i == 0 || j == 0) {
            return;
        }

        fromToken.universalApprove(address(curveCompound), amount);
        curveCompound.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurveUSDT(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        int128 i = (fromToken == dai ? 1 : 0) +
            (fromToken == usdc ? 2 : 0) +
            (fromToken == usdt ? 3 : 0);
        int128 j = (destToken == dai ? 1 : 0) +
            (destToken == usdc ? 2 : 0) +
            (destToken == usdt ? 3 : 0);
        if (i == 0 || j == 0) {
            return;
        }

        fromToken.universalApprove(address(curveUSDT), amount);
        curveUSDT.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurveY(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        int128 i = (fromToken == dai ? 1 : 0) +
            (fromToken == usdc ? 2 : 0) +
            (fromToken == usdt ? 3 : 0) +
            (fromToken == tusd ? 4 : 0);
        int128 j = (destToken == dai ? 1 : 0) +
            (destToken == usdc ? 2 : 0) +
            (destToken == usdt ? 3 : 0) +
            (destToken == tusd ? 4 : 0);
        if (i == 0 || j == 0) {
            return;
        }

        fromToken.universalApprove(address(curveY), amount);
        curveY.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurveBinance(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        int128 i = (fromToken == dai ? 1 : 0) +
            (fromToken == usdc ? 2 : 0) +
            (fromToken == usdt ? 3 : 0) +
            (fromToken == busd ? 4 : 0);
        int128 j = (destToken == dai ? 1 : 0) +
            (destToken == usdc ? 2 : 0) +
            (destToken == usdt ? 3 : 0) +
            (destToken == busd ? 4 : 0);
        if (i == 0 || j == 0) {
            return;
        }

        fromToken.universalApprove(address(curveBinance), amount);
        curveBinance.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurveSynthetix(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        int128 i = (fromToken == dai ? 1 : 0) +
            (fromToken == usdc ? 2 : 0) +
            (fromToken == usdt ? 3 : 0) +
            (fromToken == susd ? 4 : 0);
        int128 j = (destToken == dai ? 1 : 0) +
            (destToken == usdc ? 2 : 0) +
            (destToken == usdt ? 3 : 0) +
            (destToken == susd ? 4 : 0);
        if (i == 0 || j == 0) {
            return;
        }

        fromToken.universalApprove(address(curveSynthetix), amount);
        curveSynthetix.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurvePAX(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        int128 i = (fromToken == dai ? 1 : 0) +
            (fromToken == usdc ? 2 : 0) +
            (fromToken == usdt ? 3 : 0) +
            (fromToken == pax ? 4 : 0);
        int128 j = (destToken == dai ? 1 : 0) +
            (destToken == usdc ? 2 : 0) +
            (destToken == usdt ? 3 : 0) +
            (destToken == pax ? 4 : 0);
        if (i == 0 || j == 0) {
            return;
        }

        fromToken.universalApprove(address(curvePAX), amount);
        curvePAX.exchange_underlying(i - 1, j - 1, amount, 0);
    }

    function _swapOnShell(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        fromToken.universalApprove(address(shell), amount);
        shell.swapByOrigin(
            address(fromToken),
            address(destToken),
            amount,
            0,
            now + 50
        );
    }

    function _swapOnMStableMUSD(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        fromToken.universalApprove(address(musd), amount);
        musd.swap(
            fromToken,
            destToken,
            amount,
            address(this)
        );
    }

    function _swapOnCurveRenBTC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        int128 i = (fromToken == renbtc ? 1 : 0) +
            (fromToken == wbtc ? 2 : 0);
        int128 j = (destToken == renbtc ? 1 : 0) +
            (destToken == wbtc ? 2 : 0);
        if (i == 0 || j == 0) {
            return;
        }

        fromToken.universalApprove(address(curveRenBTC), amount);
        curveRenBTC.exchange(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurveTBTC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        int128 i = (fromToken == tbtc ? 1 : 0) +
            (fromToken == wbtc ? 2 : 0) +
            (fromToken == hbtc ? 3 : 0);
        int128 j = (destToken == tbtc ? 1 : 0) +
            (destToken == wbtc ? 2 : 0) +
            (destToken == hbtc ? 3 : 0);
        if (i == 0 || j == 0) {
            return;
        }

        fromToken.universalApprove(address(curveTBTC), amount);
        curveTBTC.exchange(i - 1, j - 1, amount, 0);
    }

    function _swapOnCurveSBTC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        int128 i = (fromToken == renbtc ? 1 : 0) +
            (fromToken == wbtc ? 2 : 0) +
            (fromToken == sbtc ? 3 : 0);
        int128 j = (destToken == renbtc ? 1 : 0) +
            (destToken == wbtc ? 2 : 0) +
            (destToken == sbtc ? 3 : 0);
        if (i == 0 || j == 0) {
            return;
        }

        fromToken.universalApprove(address(curveSBTC), amount);
        curveSBTC.exchange(i - 1, j - 1, amount, 0);
    }

    function _swapOnDforceSwap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        fromToken.universalApprove(address(dforceSwap), amount);
        dforceSwap.swap(fromToken, destToken, amount);
    }

    function _swapOnUniswap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        uint256 returnAmount = amount;

        if (!fromToken.isETH()) {
            IUniswapExchange fromExchange = uniswapFactory.getExchange(fromToken);
            if (fromExchange != IUniswapExchange(0)) {
                fromToken.universalApprove(address(fromExchange), returnAmount);
                returnAmount = fromExchange.tokenToEthSwapInput(returnAmount, 1, now);
            }
        }

        if (!destToken.isETH()) {
            IUniswapExchange toExchange = uniswapFactory.getExchange(destToken);
            if (toExchange != IUniswapExchange(0)) {
                returnAmount = toExchange.ethToTokenSwapInput.value(returnAmount)(1, now);
            }
        }
    }

    function _swapOnUniswapCompound(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        if (!fromToken.isETH()) {
            ICompoundToken fromCompound = _getCompoundToken(fromToken);
            fromToken.universalApprove(address(fromCompound), amount);
            fromCompound.mint(amount);
            _swapOnUniswap(IERC20(fromCompound), destToken, IERC20(fromCompound).universalBalanceOf(address(this)), flags);
            return;
        }

        if (!destToken.isETH()) {
            ICompoundToken toCompound = _getCompoundToken(destToken);
            _swapOnUniswap(fromToken, IERC20(toCompound), amount, flags);
            toCompound.redeem(IERC20(toCompound).universalBalanceOf(address(this)));
            destToken.universalBalanceOf(address(this));
            return;
        }
    }

    function _swapOnUniswapChai(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        if (fromToken == dai) {
            fromToken.universalApprove(address(chai), amount);
            chai.join(address(this), amount);
            _swapOnUniswap(IERC20(chai), destToken, IERC20(chai).universalBalanceOf(address(this)), flags);
            return;
        }

        if (destToken == dai) {
            _swapOnUniswap(fromToken, IERC20(chai), amount, flags);
            chai.exit(address(this), chai.balanceOf(address(this)));
            return;
        }
    }

    function _swapOnUniswapAave(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        if (!fromToken.isETH()) {
            IAaveToken fromAave = _getAaveToken(fromToken);
            fromToken.universalApprove(aave.core(), amount);
            aave.deposit(fromToken, amount, 1101);
            _swapOnUniswap(IERC20(fromAave), destToken, IERC20(fromAave).universalBalanceOf(address(this)), flags);
            return;
        }

        if (!destToken.isETH()) {
            IAaveToken toAave = _getAaveToken(destToken);
            _swapOnUniswap(fromToken, IERC20(toAave), amount, flags);
            toAave.redeem(toAave.balanceOf(address(this)));
            return;
        }
    }

    function _swapOnMooniswap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        IMooniswap mooniswap = mooniswapRegistry.target();
        fromToken.universalApprove(address(mooniswap), amount);
        mooniswap.swap.value(fromToken.isETH() ? amount : 0)(
            fromToken,
            destToken,
            amount,
            0
        );
    }

    function _swapOnNowhere(
        IERC20 /*fromToken*/,
        IERC20 /*destToken*/,
        uint256 /*amount*/,
        uint256 /*flags*/
    ) internal {
        revert("This source was deprecated");
    }

    function _swapOnKyber1(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnKyber(
            fromToken,
            destToken,
            amount,
            flags,
            0xff4b796265722046707200000000000000000000000000000000000000000000
        );
    }

    function _swapOnKyber2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnKyber(
            fromToken,
            destToken,
            amount,
            flags,
            0xffabcd0000000000000000000000000000000000000000000000000000000000
        );
    }

    function _swapOnKyber3(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnKyber(
            fromToken,
            destToken,
            amount,
            flags,
            0xff4f6e65426974205175616e7400000000000000000000000000000000000000
        );
    }

    function _swapOnKyber4(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnKyber(
            fromToken,
            destToken,
            amount,
            flags,
            _kyberReserveIdByTokens(fromToken, destToken)
        );
    }

    function _swapOnKyber(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags,
        bytes32 reserveId
    ) internal {
        uint256 returnAmount = amount;
        uint256 bps = flags.check(1 << 255) ? 10 : 0;

        bytes32[] memory reserveIds = new bytes32[](1);
        reserveIds[0] = reserveId;

        if (!fromToken.isETH()) {
            bytes memory fromHint = kyberHintHandler.buildTokenToEthHint(
                fromToken,
                IKyberHintHandler.TradeType.MaskIn,
                reserveIds,
                new uint256[](0)
            );

            fromToken.universalApprove(address(kyberNetworkProxy), amount);
            returnAmount = kyberNetworkProxy.tradeWithHintAndFee(
                fromToken,
                returnAmount,
                ETH_ADDRESS,
                address(this),
                uint256(-1),
                0,
                0x4D37f28D2db99e8d35A6C725a5f1749A085850a3,
                bps,
                fromHint
            );
        }

        if (!destToken.isETH()) {
            bytes memory destHint = kyberHintHandler.buildEthToTokenHint(
                destToken,
                IKyberHintHandler.TradeType.MaskIn,
                reserveIds,
                new uint256[](0)
            );

            returnAmount = kyberNetworkProxy.tradeWithHintAndFee.value(returnAmount)(
                ETH_ADDRESS,
                returnAmount,
                destToken,
                address(this),
                uint256(-1),
                0,
                0x4D37f28D2db99e8d35A6C725a5f1749A085850a3,
                bps,
                destHint
            );
        }
    }

    function _swapOnBancor(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        IBancorNetwork bancorNetwork = IBancorNetwork(bancorContractRegistry.addressOf("BancorNetwork"));
        address[] memory path = bancorNetworkPathFinder.generatePath(
            fromToken.isETH() ? bancorEtherToken : fromToken,
            destToken.isETH() ? bancorEtherToken : destToken
        );
        fromToken.universalApprove(address(bancorNetwork), amount);
        bancorNetwork.convert.value(fromToken.isETH() ? amount : 0)(path, amount, 1);
    }

    function _swapOnOasis(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        if (fromToken.isETH()) {
            weth.deposit.value(amount)();
        }

        IERC20 approveToken = fromToken.isETH() ? weth : fromToken;
        approveToken.universalApprove(address(oasisExchange), amount);
        oasisExchange.sellAllAmount(
            fromToken.isETH() ? weth : fromToken,
            amount,
            destToken.isETH() ? weth : destToken,
            1
        );

        if (destToken.isETH()) {
            weth.withdraw(weth.balanceOf(address(this)));
        }
    }

    function _swapOnUniswapV2Internal(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal returns(uint256 returnAmount) {
        if (fromToken.isETH()) {
            weth.deposit.value(amount)();
        }

        IERC20 fromTokenReal = fromToken.isETH() ? weth : fromToken;
        IERC20 toTokenReal = destToken.isETH() ? weth : destToken;
        IUniswapV2Exchange exchange = uniswapV2.getPair(fromTokenReal, toTokenReal);
        returnAmount = exchange.getReturn(fromTokenReal, toTokenReal, amount);

        fromTokenReal.universalTransfer(address(exchange), amount);
        if (uint256(address(fromTokenReal)) < uint256(address(toTokenReal))) {
            exchange.swap(0, returnAmount, address(this), "");
        } else {
            exchange.swap(returnAmount, 0, address(this), "");
        }

        if (destToken.isETH()) {
            weth.withdraw(weth.balanceOf(address(this)));
        }
    }

    function _swapOnUniswapV2OverMid(
        IERC20 fromToken,
        IERC20 midToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnUniswapV2Internal(
            midToken,
            destToken,
            _swapOnUniswapV2Internal(
                fromToken,
                midToken,
                amount,
                flags
            ),
            flags
        );
    }

    function _swapOnUniswapV2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnUniswapV2Internal(
            fromToken,
            destToken,
            amount,
            flags
        );
    }

    function _swapOnUniswapV2ETH(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnUniswapV2OverMid(
            fromToken,
            weth,
            destToken,
            amount,
            flags
        );
    }

    function _swapOnUniswapV2DAI(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnUniswapV2OverMid(
            fromToken,
            dai,
            destToken,
            amount,
            flags
        );
    }

    function _swapOnUniswapV2USDC(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnUniswapV2OverMid(
            fromToken,
            usdc,
            destToken,
            amount,
            flags
        );
    }

    function _swapOnBalancerX(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/,
        uint256 poolIndex
    ) internal {
        address[] memory pools = balancerRegistry.getBestPoolsWithLimit(
            address(fromToken.isETH() ? weth : fromToken),
            address(destToken.isETH() ? weth : destToken),
            poolIndex + 1
        );

        if (fromToken.isETH()) {
            weth.deposit.value(amount)();
        }

        (fromToken.isETH() ? weth : fromToken).universalApprove(pools[poolIndex], amount);
        IBalancerPool(pools[poolIndex]).swapExactAmountIn(
            fromToken.isETH() ? weth : fromToken,
            amount,
            destToken.isETH() ? weth : destToken,
            0,
            uint256(-1)
        );

        if (destToken.isETH()) {
            weth.withdraw(weth.balanceOf(address(this)));
        }
    }

    function _swapOnBalancer1(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnBalancerX(fromToken, destToken, amount, flags, 0);
    }

    function _swapOnBalancer2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnBalancerX(fromToken, destToken, amount, flags, 1);
    }

    function _swapOnBalancer3(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnBalancerX(fromToken, destToken, amount, flags, 2);
    }
}
