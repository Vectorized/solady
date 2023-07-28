// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockERC1271Malicious {
    function isValidSignature(bytes32, bytes calldata) external pure returns (bytes4) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            return(0, 32)
        }
    }
}
