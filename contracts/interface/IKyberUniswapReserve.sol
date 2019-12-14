pragma solidity ^0.5.0;


interface IKyberUniswapReserve {
    function uniswapFactory() external view returns(address);
}
