// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IAaveRegistry.sol";
import "./interfaces/ICompound.sol";
import "./libraries/UniERC20.sol";
import "./OneRouterConstants.sol";


contract PathsAdvisor is OneRouterConstants {
    using UniERC20 for IERC20;

    IAaveRegistry constant private _AAVE_REGISTRY = IAaveRegistry(0xEd8b133B7B88366E01Bb9E38305Ab11c26521494);
    ICompoundRegistry constant private _COMPOUND_REGISTRY = ICompoundRegistry(0xF451Dbd7Ba14BFa7B1B78A766D3Ed438F79EE1D1);

    function getPathsForTokens(IERC20 fromToken, IERC20 destToken) external view returns(IERC20[][] memory) {
        IERC20[4] memory midTokens = [_DAI, _USDC, _USDT, _WBTC];
        IERC20[][] memory paths = new IERC20[][](2 + midTokens.length);

        IERC20 aFromToken = _AAVE_REGISTRY.tokenByAToken(fromToken);
        IERC20 aDestToken = _AAVE_REGISTRY.tokenByAToken(destToken);
        if (aFromToken != IERC20(0)) {
            aFromToken = _COMPOUND_REGISTRY.tokenByCToken(fromToken);
        }
        if (aDestToken != IERC20(0)) {
            aDestToken = _COMPOUND_REGISTRY.tokenByCToken(destToken);
        }

        uint index = 0;
        paths[index] = new IERC20[](0);
        index++;

        if (!fromToken.isETH() && !aFromToken.isETH() && !destToken.isETH() && !aDestToken.isETH()) {
            paths[index] = new IERC20[](1);
            paths[index][0] = UniERC20.ETH_ADDRESS;
            index++;
        }

        for (uint i = 0; i < midTokens.length; i++) {
            if (fromToken != midTokens[i] && aFromToken != midTokens[i] && destToken != midTokens[i] && aDestToken != midTokens[i]) {
                paths[index] = new IERC20[](
                    1 +
                    ((aFromToken != IERC20(0)) ? 1 : 0) +
                    ((aDestToken != IERC20(0)) ? 1 : 0)
                );

                uint pos = 0;
                if (aFromToken != IERC20(0)) {
                    paths[index][pos++] = aFromToken;
                }
                paths[index][pos++] = midTokens[i];
                if (aDestToken != IERC20(0)) {
                    paths[index][pos] = aDestToken;
                }

                index++;
            }
        }

        IERC20[][] memory paths2 = new IERC20[][](index);
        for (uint i = 0; i < paths2.length; i++) {
            paths2[i] = paths[i];
        }
        return paths2;
    }
}
