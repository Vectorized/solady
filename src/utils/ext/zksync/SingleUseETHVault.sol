// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice A single-use vault that allows a designated caller to withdraw all ETH in it.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ext/zksync/SingleUseETHVault.sol)
contract SingleUseETHVault {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unable to withdraw all.
    error WithdrawAllFailed();

    /// @dev Not authorized.
    error Unauthorized();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        WITHDRAW ALL                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    fallback() external payable virtual {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x40, 0) // Optimization trick to remove free memory pointer initialization.
            let owner := sload(0)
            // Initialization.
            if iszero(owner) {
                sstore(0, calldataload(0x00)) // Store the owner.
                return(0x00, 0x00) // Early return.
            }
            // Authorization check.
            if iszero(eq(caller(), owner)) {
                mstore(0x00, 0x82b42900) // `Unauthorized()`.
                revert(0x1c, 0x04)
            }
            let to := calldataload(0x00)
            // If the calldata is less than 32 bytes, zero-left-pad it to 32 bytes.
            // Then use the rightmost 20 bytes of the word as the `to` address.
            // This allows for the calldata to be `abi.encode(to)` or `abi.encodePacked(to)`.
            to := shr(mul(lt(calldatasize(), 0x20), shl(3, sub(0x20, calldatasize()))), to)
            // If `to` is `address(0)`, set it to `msg.sender`.
            to := xor(mul(xor(to, caller()), iszero(to)), to)
            // Transfers the whole balance to `to`.
            if iszero(call(gas(), to, selfbalance(), 0x00, 0x00, 0x00, 0x00)) {
                mstore(0x00, 0x651aee10) // `WithdrawAllFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }
}
