// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ZKsyncSingleUseETHVault} from "./ZKsyncSingleUseETHVault.sol";

/// @notice Library for force safe transferring ETH in ZKsync.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
library ZKsyncSafeTransferLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev A single use ETH vault has been created for `to`, with `amount`.
    event SingleUseETHVaultCreated(address indexed to, uint256 amount, address vault);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Suggested gas stipend for contract receiving ETH to perform a few
    /// storage reads and writes, but low enough to prevent griefing.
    uint256 internal constant GAS_STIPEND_NO_GRIEF = 1000000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ETH OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// If force transfer is used, returns the vault. Else returns `address(0)`.
    function forceSafeTransferETH(address to, uint256 amount, uint256 gasStipend)
        internal
        returns (address vault)
    {
        uint256 success;
        /// @solidity memory-safe-assembly
        assembly {
            if lt(selfbalance(), amount) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
            success := call(gasStipend, to, amount, 0x00, 0x00, 0x00, 0x00)
        }
        if (success == uint256(0)) {
            vault = address(new ZKsyncSingleUseETHVault{value: amount}(to));
            emit SingleUseETHVaultCreated(to, amount, vault);
        }
    }

    /// @dev Force sends all the ETH in the current contract to `to`, with a `gasStipend`.
    /// If force transfer is used, returns the vault. Else returns `address(0)`.
    function forceSafeTransferAllETH(address to, uint256 gasStipend)
        internal
        returns (address vault)
    {
        vault = forceSafeTransferETH(to, address(this).balance, gasStipend);
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with `GAS_STIPEND_NO_GRIEF`.
    /// If force transfer is used, returns the vault. Else returns `address(0)`.
    function forceSafeTransferETH(address to, uint256 amount) internal returns (address vault) {
        vault = forceSafeTransferETH(to, amount, GAS_STIPEND_NO_GRIEF);
    }

    /// @dev Force sends all the ETH in the current contract to `to`, with `GAS_STIPEND_NO_GRIEF`.
    /// If force transfer is used, returns the vault. Else returns `address(0)`.
    function forceSafeTransferAllETH(address to) internal returns (address vault) {
        vault = forceSafeTransferETH(to, address(this).balance, GAS_STIPEND_NO_GRIEF);
    }
}
