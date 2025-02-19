// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for handling Abstract Global Wallets.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ext/zksync/LibAGW.sol)
library LibAGW {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       AGW OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns if `target` may be an AGW.
    function maybeAGW(address target) internal view returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x87cf8b78) // `agwMessageTypeHash()`.
            let t := staticcall(gas(), target, 0x1c, 0x04, 0x00, 0x20)
            result := and(iszero(iszero(shr(128, mload(0x00)))), t)
        }
    }
}
