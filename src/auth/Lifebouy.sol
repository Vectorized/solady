// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Lifebouy {
    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();
    /// @dev The ERC20 `transfer` has failed.
    error ERC20TransferFailed();
    /// @dev The ERC721 `transfer` has failed.
    error ERC721TransferFailed();
    /// @dev `rescueLocked` was set to true.
    error LockedRescue();
    /// @dev Not owner or deployer.
    error NotAllowed();

    /*
     * Intentionally a high value to avoid collisions: _OWNER_SLOT + 1.
     * Packed slot is as follow:
     * [0x0]        => rescueLocked
     * [0x1...0x14] => deployer
    **/
    bytes32 internal constant _PACKED_SLOT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff74873928;

    /// @dev `keccak256(bytes("RescueLocked()"))`.
    bytes32 private constant _RESCUE_LOCKED_EVENT_SIGNATURE =
        0xc15d3aeb27824b3a0f3b82805aec015b721bd99f8e6146ea5a0e572f38a6f823;

    event RescueLocked();

    constructor() payable {
        assembly {
            let depl := caller()

            if gt(selfbalance(), returndatasize()) {
                if iszero(
                    call(
                        gas(),
                        caller(),
                        selfbalance(),
                        returndatasize(),
                        returndatasize(),
                        returndatasize(),
                        returndatasize()
                    )
                ) {
                    if iszero(
                        call(gas(), origin(), selfbalance(), codesize(), 0x00, codesize(), 0x00)
                    ) {
                        mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                        revert(0x1c, 0x04)
                    }

                    depl := origin()
                }
            }

            sstore(_PACKED_SLOT, shl(0x01, depl))
        }
    }

    function deployer() external view returns (address addr) {
        assembly {
            addr := shr(0x01, sload(_PACKED_SLOT))
        }
    }

    function rescueLocked() external view returns (bool locked) {
        assembly {
            locked := and(0x01, sload(_PACKED_SLOT))
        }
    }

    function lockRescue() external {
        _requireCanRescue();

        assembly {
            sstore(_PACKED_SLOT, or(sload(_PACKED_SLOT), 0x01))
            log1(0x00, 0x00, _RESCUE_LOCKED_EVENT_SIGNATURE)
        }
    }

    function rescueETH(address to, uint256 amount) external {
        _requireCanRescue();

        assembly {
            if iszero(call(gas(), to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    function rescueERC20(address erc20, address to, uint256 amount) external {
        _requireCanRescue();

        assembly {
            // Store the `to` and `amount` argument.
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            // `transfer(address,uint256)`.
            mstore(0x00, 0xa9059cbb000000000000000000000000)
            // Perform the transfer, reverting upon failure.
            if iszero(
                // The arguments of `and` are evaluated from right to left.
                and(
                    // Returned 1 or nothing.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), erc20, 0x00, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0xf27f64e4) // `ERC20TransferFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    function rescueERC721(address erc721, address to, uint256 id) external {
        _requireCanRescue();

        assembly {
            mstore(0x14, address()) // Store the `from` argument.
            mstore(0x34, to) // Store the `to` argument.
            mstore(0x54, id) // Store the `tokenId` argument.
            // `safeTransferFrom(address from, address to, uint256 tokenId)`.
            mstore(0x00, 0x42842e0e000000000000000000000000)
            // Perform the safe transfer from, reverting upon failure.

            if iszero(call(gas(), erc721, 0x00, 0x10, 0x64, codesize(), 0x00)) {
                mstore(0x00, 0xdff14c1e) // `ERC721TransferFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    function _requireCanRescue() internal view {
        assembly {
            mstore(returndatasize(), sload(_PACKED_SLOT))

            if gt(and(0x01, mload(returndatasize())), returndatasize()) {
                mstore(returndatasize(), 0x350c1e72) // `LockedRescue()`.
                revert(0x1c, 0x04)
            }

            // Checking if is deployer.
            if iszero(eq(caller(), shr(0x01, mload(returndatasize())))) {
                // If not, checking if is Ownable and caller is owner.
                mstore(returndatasize(), 0x8da5cb5b) // `owner()` selector.
                if iszero(
                    and(
                        eq(mload(0x0), caller()),
                        // calling owner().
                        staticcall(gas(), address(), 0x1c, 0x04, returndatasize(), 0x20)
                    )
                ) {
                    mstore(0x00, 0x3d693ada) // `NotAllowed()`.
                    revert(0x1c, 0x04)
                }
            }
        }
    }
}
