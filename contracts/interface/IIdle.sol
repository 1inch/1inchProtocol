pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract IIdleToken is IERC20 {
    function tokenPrice() external view returns (uint256);
    /**
     * Used to get the underlying token address (eg DAI address)
     *
     * @return : underlying token address
     */
    function token() external view returns (address);
    /**
     * Used to mint IdleTokens, given an underlying amount (eg. DAI).
     * This method triggers a rebalance of the pools if needed
     * NOTE: User should 'approve' _amount of tokens before calling mintIdleToken
     * NOTE 2: this method can be paused
     *
     * @param _amount : amount of underlying token to be lended
     * @param _clientProtocolAmounts : client side calculated amounts to put on each lending protocol
     * @return mintedTokens : amount of IdleTokens minted
     */
    function mintIdleToken(uint256 _amount, uint256[] calldata _clientProtocolAmounts) external returns (uint256 mintedTokens);
    /**
     * @param _amount : amount of underlying token to be lended
     * @return : address[] array with all token addresses used,
     *                          eg [cTokenAddress, iTokenAddress]
     * @return : uint256[] array with all amounts for each protocol in order,
     *                   eg [amountCompound, amountFulcrum]
     */
    function getParamsForMintIdleToken(uint256 _amount) external returns (address[] memory, uint256[] memory);
    /**
     * Here we calc the pool share one can withdraw given the amount of IdleToken they want to burn
     * This method triggers a rebalance of the pools if needed
     * NOTE: If the contract is paused or iToken price has decreased one can still redeem but no rebalance happens.
     * NOTE 2: If iToken price has decresed one should not redeem (but can do it) otherwise he would capitalize the loss.
     *         Ideally one should wait until the black swan event is terminated
     *
     * @param _amount : amount of IdleTokens to be burned
     * @param _clientProtocolAmounts : client side calculated amounts to put on each lending protocol
     * @return redeemedTokens : amount of underlying tokens redeemed
     */
    function redeemIdleToken(uint256 _amount, bool _skipRebalance, uint256[] calldata _clientProtocolAmounts)
      external returns (uint256 redeemedTokens);
    /**
     * @param _amount : amount of IdleTokens to be burned
     * @param _skipRebalance : whether to skip the rebalance process or not
     * @return : address[] array with all token addresses used,
     *                          eg [cTokenAddress, iTokenAddress]
     * @return : uint256[] array with all amounts for each protocol in order,
     *                   eg [amountCompound, amountFulcrum]
     */
    function getParamsForRedeemIdleToken(uint256 _amount, bool _skipRebalance)
      external returns (address[] memory, uint256[] memory);
}
