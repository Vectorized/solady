// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Efficient bytemap library for mapping integers to bytes.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibBytemap.sol)
library LibBytemap {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev A bytemap in storage.
    struct Bytemap {
        mapping(uint256 => uint256) map;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OPERATIONS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the uint8 value of the byte at `index` in `bytemap`.
    function get(Bytemap storage bytemap, uint256 index) internal view returns (uint8 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, bytemap.slot)
            mstore(0x00, shr(5, index))
            result := byte(and(index, 0x1f), sload(keccak256(0x00, 0x20)))
        }
    }

    /// @dev Updates the uint8 value of the byte at `index` in `bytemap`.
    function set(Bytemap storage bytemap, uint256 index, uint8 value) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, bytemap.slot)
            mstore(0x00, shr(5, index))
            let storageSlot := keccak256(0x00, 0x20)
            // Store the value into the 0x00 slot.
            mstore(0x00, sload(storageSlot))
            // And abuse `mstore8` to directly set the byte.
            mstore8(and(index, 0x1f), value)
            sstore(storageSlot, mload(0x00))
        }
    }
}
