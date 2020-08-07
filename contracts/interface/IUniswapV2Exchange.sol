pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../UniversalERC20.sol";


interface IUniswapV2Exchange {
    function getReserves() external view returns(uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function sync() external;
}


library UniswapV2ExchangeLib {
    using SafeMath for uint256;
    using UniversalERC20 for IERC20;

    function getReturn(
        IUniswapV2Exchange exchange,
        IERC20 fromToken,
        IERC20 destToken,
        uint amountIn
    ) internal view returns (uint256 result, bool needSync) {
        uint256 reserveIn = fromToken.universalBalanceOf(address(exchange));
        uint256 reserveOut = destToken.universalBalanceOf(address(exchange));
        (uint112 reserve0, uint112 reserve1,) = exchange.getReserves();
        if (fromToken > destToken) {
            (reserve0, reserve1) = (reserve1, reserve0);
        }
        needSync = (reserve0 != reserveIn || reserve1 != reserveOut);

        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        result = (denominator == 0) ? 0 : numerator.div(denominator);
    }
}
