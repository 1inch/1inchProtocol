pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface iRebalancingSetToken {

    function currentSet() external view returns(IERC20);
}