// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// This file is auto-generated.

/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
/*                          STRUCTS                           */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

/// @dev Generates a storage slot that can be invalidated.
struct Bump {
    uint256 _current;
}

/// @dev Pointer struct to a `uint256` in storage.
/// We have opted for a `uint256` as the inner type,
/// as it requires less casting to get / set specific bits.
struct Ref {
    uint256 value;
}

using LibStorage for Bump global;
using LibStorage for Ref global;

/// @notice Library for basic storage operations.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/g/LibStorage.sol)
library LibStorage {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The storage slot seed for calculating a bumped storage slot.
    /// `bytes4(keccak256("_BUMPED_STORAGE_REF_SLOT_SEED"))`.
    uint256 private constant _BUMPED_STORAGE_REF_SLOT_SEED = 0xd4203f8b;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OPERATIONS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the current storage slot pointed by the bump.
    /// Use inline-assembly to cast the result to a desired custom data type storage pointer.
    function slot(Bump storage b) internal view returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x1f, sload(b.slot))
            mstore(0x04, _BUMPED_STORAGE_REF_SLOT_SEED)
            mstore(0x00, b.slot)
            result := keccak256(0x00, 0x3f)
        }
    }

    /// @dev Makes the bump point to a whole new storage slot.
    function invalidate(Bump storage b) internal {
        unchecked {
            ++b._current;
        }
    }

    /// @dev Returns a bump at the storage slot.
    function bump(bytes32 sSlot) internal pure returns (Bump storage $) {
        /// @solidity memory-safe-assembly
        assembly {
            $.slot := sSlot
        }
    }

    /// @dev Returns a bump at the storage slot.
    function bump(uint256 sSlot) internal pure returns (Bump storage $) {
        /// @solidity memory-safe-assembly
        assembly {
            $.slot := sSlot
        }
    }

    /// @dev Returns a pointer to a `uint256` in storage.
    function ref(bytes32 sSlot) internal pure returns (Ref storage $) {
        /// @solidity memory-safe-assembly
        assembly {
            $.slot := sSlot
        }
    }

    /// @dev Returns a pointer to a `uint256` in storage.
    function ref(uint256 sSlot) internal pure returns (Ref storage $) {
        /// @solidity memory-safe-assembly
        assembly {
            $.slot := sSlot
        }
    }
}
