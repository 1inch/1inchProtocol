pragma solidity ^0.5.0;

interface IBFactory {
    function isBPool(address b) external view returns (bool);
}
