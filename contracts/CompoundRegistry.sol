pragma solidity ^0.5.0;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/ICompoundRegistry.sol";
import "./UniversalERC20.sol";


contract CompoundRegistry is Ownable, ICompoundRegistry {
    using UniversalERC20 for IERC20;

    ICompoundToken internal constant cETH = ICompoundToken(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);
    IERC20 internal constant ETH = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    mapping(address => address) private _tokenByCToken;
    mapping(address => address) private _cTokenByToken;

    function tokenByCToken(ICompoundToken cToken) external view returns(IERC20) {
        if (cToken == cETH) {
            return ETH;
        }
        return IERC20(_tokenByCToken[address(cToken)]);
    }

    function cTokenByToken(IERC20 token) external view returns(ICompoundToken) {
        if (token.isETH()) {
            return cETH;
        }
        return ICompoundToken(_cTokenByToken[address(token)]);
    }

    function addCToken(ICompoundToken cToken) public onlyOwner {
        IERC20 token = IERC20(cToken.underlying());
        _tokenByCToken[address(cToken)] = address(token);
        _cTokenByToken[address(token)] = address(cToken);
    }

    function addCTokens(ICompoundToken[] calldata cTokens) external onlyOwner {
        for (uint i = 0; i < cTokens.length; i++) {
            addCToken(cTokens[i]);
        }
    }
}
