pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface ISmartTokenRegistry {
    function isSmartToken(IERC20 token) external view returns (bool);
}
