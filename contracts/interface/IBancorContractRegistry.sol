pragma solidity ^0.5.0;


contract IBancorContractRegistry {

    function addressOf(bytes32 contractName)
        external view returns (address);
}