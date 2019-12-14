pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IUniswapExchange {

    function getEthToTokenInputPrice(uint256 ethSold)
        external view returns(uint256 tokensBought);

    function getTokenToEthInputPrice(uint256 tokensSold)
        external view returns (uint256 ethBought);

    function ethToTokenSwapInput(uint256 minTokens, uint256 deadline)
        external payable returns (uint256 tokensBought);

    function tokenToEthSwapInput(uint256 tokensSold, uint256 minEth, uint256 deadline)
        external returns (uint256 ethBought);

    function tokenToTokenSwapInput(uint256 tokensSold, uint256 minTokensBought, uint256 minEthBought, uint256 deadline, address tokenAddr)
        external returns (uint256 tokensBought);

}
