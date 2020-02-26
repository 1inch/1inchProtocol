pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ISmartTokenConverter.sol";


interface ISmartToken {
    function owner() external view returns (ISmartTokenConverter);
}
