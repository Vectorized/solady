// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice A vault to allow for forced ETH transfers.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ext/zksync/ZKsyncETHVault.sol)
///
/// Note: we may tentatively use this instead.
contract ZKsyncETHVault {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev `amount` of ETH has been deposited `to` by `by`.
    event Deposit(address indexed by, address indexed to, uint256 amount);

    /// @dev `amount` of ETH has been withdrawn `to` by `by`.
    event Withdraw(address indexed by, address indexed to, uint256 amount);

    /// @dev `keccak256(bytes("Deposit(address,address,uint256)"))`.
    uint256 private constant _DEPOSIT_EVENT_SIGNATURE =
        0x5548c837ab068cf56a2c2479df0882a4922fd203edb7517321831d95078c5f62;

    /// @dev `keccak256(bytes("Withdraw(address,address,uint256)"))`.
    uint256 private constant _WITHDRAW_EVENT_SIGNATURE =
        0x9b1bfa7fa9ee420a16e124f794c35ac9f90472acc99140eb2f6447c714cad8eb;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unable to withdraw all.
    error WithdrawFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                BALANCE / DEPOSIT / WITHDRAW                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    fallback() external payable virtual {
        /// @solidity memory-safe-assembly
        assembly {
            function min(x_, y_) -> _z {
                _z := xor(x_, mul(xor(x_, y_), lt(y_, x_)))
            }
            // Deposit workflow.
            if eq(calldataload(0x00), 1) {
                let to := shr(96, shl(96, calldataload(0x20)))
                sstore(to, add(sload(to), callvalue())) // Increment the accrued balance.
                // Emit the {Deposit} event.
                mstore(0x00, callvalue())
                log3(0x00, 0x20, _DEPOSIT_EVENT_SIGNATURE, caller(), to)
                stop() // End context.
            }
            // Balance of query workflow.
            if eq(calldataload(0x00), 2) {
                mstore(0x00, sload(shr(96, shl(96, calldataload(0x20)))))
                return(0x00, 0x20)
            }
            // Withdraw workflow.
            let accrued := sload(caller())
            // Allow for an optional amount stored in bytes `32..63` (inclusive) in the calldata.
            let amount := min(accrued, mul(calldataload(0x20), gt(calldatasize(), 0x3f)))
            sstore(caller(), sub(accrued, amount)) // Decrement and update the accrued balance.
            let to := calldataload(0x00)
            // If the calldata is less than 32 bytes, zero-left-pad it to 32 bytes.
            to := shr(mul(lt(calldatasize(), 0x20), shl(3, sub(0x20, calldatasize()))), to)
            // Clean the upper 96 bits, in case they are dirty.
            to := shr(96, shl(96, calldataload(0x20)))
            // If `to` is `address(to)`, set it to `msg.sender`.
            to := xor(mul(xor(to, caller()), iszero(to)), to)
            if iszero(call(gas(), to, amount, 0x00, 0x00, 0x00, 0x00)) {
                mstore(0x00, 0x651aee10) // `WithdrawAllFailed()`.
                revert(0x1c, 0x04)
            }
            // Emit the {Withdraw} event.
            mstore(0x00, amount)
            log3(0x00, 0x20, _WITHDRAW_EVENT_SIGNATURE, caller(), to)
        }
    }
}
