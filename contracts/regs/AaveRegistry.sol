pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "../interface/IAaveToken.sol";


interface IAaveRegistry {
    function getUnderlyingToken(IAaveToken aaveToken) external returns(IERC20);
}


contract AaveRegistry is IAaveRegistry {
    IERC20 constant public NOT_AAVE_TOKEN = IERC20(-1);
    IERC20 constant public NOT_FOUND_TOKEN = IERC20(0);

    IAaveLendingPool constant public aave = IAaveLendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);
    mapping(address => address) public cache;

    function getWrapping(IERC20 token) external returns(IAaveToken) {
        IAaveToken aaveToken = aave.core().getReserveATokenAddress(token);
        if (aaveToken == IAaveToken(0)) {
            return aaveToken(-1);
        }
        return aaveToken;
    }

    function getUnderlying(IAaveToken aaveToken) external returns(IERC20) {
        if (aaveToken == IAaveToken(0x3a3A65aAb0dd2A17E3F1947bA16138cd37d08c04)) { // ETH
            return IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
        }
        if (aaveToken == IAaveToken(0xfC1E690f61EFd961294b3e1Ce3313fBD8aa4f85d)) { // DAI
            return IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        }
        if (aaveToken == IAaveToken(0x9bA00D6856a4eDF4665BcA2C2309936572473B7E)) { // USDC
            return IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        }
        if (aaveToken == IAaveToken(0x625aE63000f46200499120B906716420bd059240)) { // SUSD
            return IERC20(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
        }
        if (aaveToken == IAaveToken(0x6Ee0f7BB50a54AB5253dA0667B0Dc2ee526C30a8)) { // BUSD
            return IERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53);
        }
        if (aaveToken == IAaveToken(0x4DA9b813057D04BAef4e5800E36083717b4a0341)) { // TUSD
            return IERC20(0x0000000000085d4780B73119b644AE5ecd22b376);
        }
        if (aaveToken == IAaveToken(0x71fc860F7D3A592A4a98740e39dB31d25db65ae8)) { // USDT
            return IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        }
        if (aaveToken == IAaveToken(0xE1BA0FB44CCb0D11b80F92f4f8Ed94CA3fF51D00)) { // BAT
            return IERC20(0x0D8775F648430679A709E98d2b0Cb6250d2887EF);
        }
        if (aaveToken == IAaveToken(0x9D91BE44C06d373a8a226E1f3b146956083803eB)) { // KNC
            return IERC20(0xdd974D5C2e2928deA5F71b9825b8b646686BD200);
        }
        if (aaveToken == IAaveToken(0x7D2D3688Df45Ce7C552E19c27e007673da9204B8)) { // LEND
            return IERC20(0x80fB784B7eD66730e8b1DBd9820aFD29931aab03);
        }
        if (aaveToken == IAaveToken(0xA64BD6C70Cb9051F6A9ba1F163Fdc07E0DfB5F84)) { // LINK
            return IERC20(0x514910771AF9Ca656af840dff83E8264EcF986CA);
        }
        if (aaveToken == IAaveToken(0x6FCE4A401B6B80ACe52baAefE4421Bd188e76F6f)) { // MANA
            return IERC20(0x0F5D2fB29fb7d3CFeE444a200298f468908cC942);
        }
        if (aaveToken == IAaveToken(0x7deB5e830be29F91E298ba5FF1356BB7f8146998)) { // MKR
            return IERC20(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
        }
        if (aaveToken == IAaveToken(0x71010A9D003445aC60C4e6A7017c1E89A477B438)) { // REP
            return IERC20(0x1985365e9f78359a9B6AD760e32412f4a445E862);
        }
        if (aaveToken == IAaveToken(0x328C4c80BC7aCa0834Db37e6600A6c49E12Da4DE)) { // SNX
            return IERC20(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F);
        }
        if (aaveToken == IAaveToken(0xFC4B8ED459e00e5400be803A9BB3954234FD50e3)) { // WBTC
            return IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
        }
        if (aaveToken == IAaveToken(0x6Fb0855c404E09c47C3fBCA25f08d4E41f9F062f)) { // ZRX
            return IERC20(0xE41d2489571d322189246DaFA5ebDe1F4699F498);
        }

        // Check cache
        IERC20 token = IERC20(cache[address(aaveToken)]);
        if (token == NOT_AAVE_TOKEN) {
            return NOT_FOUND_TOKEN;
        }
        else if (token != NOT_FOUND_TOKEN) {
            return token;
        }

        // Check dynamically and update cache
        (bool done, bytes memory data) = address(token).staticcall.gas(5000)(
            abi.encodeWithSelector(ERC20Detailed(0).name.selector)
        );
        if (done && data.length > 0) {
            if (data[0] == "A" &&
                data[1] == "a" &&
                data[2] == "v" &&
                data[3] == "e" &&
                data[4] == " ")
            {
                (bool done2, bytes memory data2) = address(aaveToken).staticcall(
                    abi.encodeWithSelector(aaveToken.underlyingAssetAddress.selector)
                );
                if (done2 && data2.length > 0) {
                    IERC20 token2 = abi.decode(data2, (IERC20));
                    cache[address(aaveToken)] = address(token2);
                    return token2;
                }
            }
        }

        cache[address(aaveToken)] = address(NOT_FOUND_TOKEN);
        return NOT_FOUND_TOKEN;
    }
}
