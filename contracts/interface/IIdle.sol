pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract IIdle is IERC20 {
    function token()
        external view returns (IERC20);

    function tokenPrice()
        external view returns (uint256);

    function mintIdleToken(uint256 _amount, uint256[] calldata _clientProtocolAmounts)
        external returns (uint256 mintedTokens);

    function redeemIdleToken(uint256 _amount, bool _skipRebalance, uint256[] calldata _clientProtocolAmounts)
        external returns (uint256 redeemedTokens);
}
