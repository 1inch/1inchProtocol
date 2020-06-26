pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IMooniswapRegistry {
    function target() external view returns(IMooniswap);
}


interface IMooniswap {
    function getReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    )
        external
        view
        returns(uint256 returnAmount);

    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 minReturn
    )
        external
        payable
        returns(uint256 returnAmount);
}
