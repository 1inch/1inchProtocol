pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IAaveToken.sol";


contract IAaveRegistry {
    function tokenByAToken(IAaveToken aToken) external view returns(IERC20);
    function aTokenByToken(IERC20 token) external view returns(IAaveToken);
}
