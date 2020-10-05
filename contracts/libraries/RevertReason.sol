// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


library RevertReason {
    function parse(bytes memory data, string memory message) internal pure returns (string memory) {
        (, string memory reason) = abi.decode(abi.encodePacked(bytes28(0), data), (uint256, string));
        return string(abi.encodePacked(message, reason));
    }
}
