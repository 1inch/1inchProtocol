pragma solidity ^0.5.0;

contract IIdleToken is IERC20 {
  function getIdleTokenAddress(address) external view returns(address);
}
