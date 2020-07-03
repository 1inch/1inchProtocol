pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IBancorContractRegistry.sol";
import "./interface/IBancorConverterRegistry.sol";
import "./UniversalERC20.sol";


contract BancorFinder {
    using UniversalERC20 for IERC20;

    IERC20 constant internal ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IERC20 constant internal bnt = IERC20(0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C);
    IBancorContractRegistry constant internal bancorContractRegistry = IBancorContractRegistry(0x52Ae12ABe5D8BD778BD5397F99cA900624CfADD4);

    function buildBancorPath(
        IERC20 fromToken,
        IERC20 destToken
    )
        public
        view
        returns(address[] memory path)
    {
        if (fromToken == destToken) {
            return new address[](0);
        }

        if (fromToken.isETH()) {
            fromToken = ETH_ADDRESS;
        }
        if (destToken.isETH()) {
            destToken = ETH_ADDRESS;
        }

        if (fromToken == bnt || destToken == bnt) {
            path = new address[](3);
        } else {
            path = new address[](5);
        }

        address fromConverter;
        address toConverter;

        IBancorConverterRegistry bancorConverterRegistry = IBancorConverterRegistry(
            bancorContractRegistry.addressOf("BancorConverterRegistry")
        );

        if (fromToken != bnt) {
            (bool success, bytes memory data) = address(bancorConverterRegistry).staticcall.gas(100000)(abi.encodeWithSelector(
                bancorConverterRegistry.getConvertibleTokenSmartToken.selector,
                fromToken.isETH() ? ETH_ADDRESS : fromToken,
                0
            ));
            if (!success) {
                return new address[](0);
            }

            fromConverter = abi.decode(data, (address));
            if (fromConverter == address(0)) {
                return new address[](0);
            }
        }

        if (destToken != bnt) {
            (bool success, bytes memory data) = address(bancorConverterRegistry).staticcall.gas(100000)(abi.encodeWithSelector(
                bancorConverterRegistry.getConvertibleTokenSmartToken.selector,
                destToken.isETH() ? ETH_ADDRESS : destToken,
                0
            ));
            if (!success) {
                return new address[](0);
            }

            toConverter = abi.decode(data, (address));
            if (toConverter == address(0)) {
                return new address[](0);
            }
        }

        if (destToken == bnt) {
            path[0] = address(fromToken);
            path[1] = fromConverter;
            path[2] = address(bnt);
            return path;
        }

        if (fromToken == bnt) {
            path[0] = address(bnt);
            path[1] = toConverter;
            path[2] = address(destToken);
            return path;
        }

        path[0] = address(fromToken);
        path[1] = fromConverter;
        path[2] = address(bnt);
        path[3] = toConverter;
        path[4] = address(destToken);
        return path;
    }
}
