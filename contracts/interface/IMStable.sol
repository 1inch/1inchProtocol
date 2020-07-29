pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract IMStable is IERC20 {
    function getSwapOutput(
        IERC20 _input,
        IERC20 _output,
        uint256 _quantity
    )
        external
        view
        returns (bool, string memory, uint256 output);

    function swap(
        IERC20 _input,
        IERC20 _output,
        uint256 _quantity,
        address _recipient
    )
        external
        returns (uint256 output);

    function redeem(
        IERC20 _basset,
        uint256 _bassetQuantity
    )
        external
        returns (uint256 massetRedeemed);
}

interface IMassetValidationHelper {
    /**
     * @dev Returns a valid bAsset to redeem
     * @param _mAsset Masset addr
     * @return valid bool
     * @return string message
     * @return address of bAsset to redeem
     */
    function suggestRedeemAsset(
        IERC20 _mAsset
    )
        external
        view
        returns (
            bool valid,
            string memory err,
            address token
        );

    /**
     * @dev Returns a valid bAsset with which to mint
     * @param _mAsset Masset addr
     * @return valid bool
     * @return string message
     * @return address of bAsset to mint
     */
    function suggestMintAsset(
        IERC20 _mAsset
    )
        external
        view
        returns (
            bool valid,
            string memory err,
            address token
        );

    /**
     * @dev Determines if a given Redemption is valid
     * @param _mAsset Address of the given mAsset (e.g. mUSD)
     * @param _mAssetQuantity Amount of mAsset to redeem (in mUSD units)
     * @param _outputBasset Desired output bAsset
     * @return valid
     * @return validity reason
     * @return output in bAsset units
     * @return bAssetQuantityArg - required input argument to the 'redeem' call
     */
    function getRedeemValidity(
        IERC20 _mAsset,
        uint256 _mAssetQuantity,
        IERC20 _outputBasset
    )
        external
        view
        returns (
            bool valid,
            string memory,
            uint256 output,
            uint256 bassetQuantityArg
        );
}
