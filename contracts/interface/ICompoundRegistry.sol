pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ICompound.sol";


contract ICompoundRegistry {
    function tokenByCToken(ICompoundToken cToken) external view returns(IERC20);
    function cTokenByToken(IERC20 token) external view returns(ICompoundToken);
}
