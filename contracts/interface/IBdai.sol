pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract IBdai is IERC20 {
    function join(uint256) external;

    function exit(uint256) external;
}
