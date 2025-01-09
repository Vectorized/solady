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
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev For upgrades / initialization.
    uint256 private __owner;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CONSTRUCTOR                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    constructor(address owner) payable {
        __owner = uint256(uint160(owner));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        WITHDRAW ALL                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    fallback() external payable virtual {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(eq(caller(), sload(__owner.slot))) {
                mstore(0x00, 0x82b42900) // `Unauthorized()`.
                revert(0x1c, 0x04)
            }
            let to := calldataload(0x00)
            to := shr(mul(lt(calldatasize(), 0x20), shl(3, sub(0x20, calldatasize()))), to)
            to := xor(mul(xor(to, caller()), iszero(to)), to)
            if iszero(call(gas(), to, selfbalance(), 0x00, 0x00, 0x00, 0x00)) {
                mstore(0x00, 0x651aee10) // `WithdrawAllFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }
}
