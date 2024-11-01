// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Reentrancy guard mixin (transient storage variant).
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ReentrancyGuardTransient.sol)
///
/// @dev Note: This implementation utilizes the `TSTORE` and `TLOAD` opcodes.
/// Please ensure that the chain you are deploying on supports them.
abstract contract ReentrancyGuardTransient {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unauthorized reentrant call.
    error Reentrancy();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Equivalent to: `uint32(bytes4(keccak256("Reentrancy()"))) | 1 << 71`.
    /// 9 bytes is large enough to avoid collisions in practice,
    /// but not too large to result in excessive bytecode bloat.
    uint256 private constant _REENTRANCY_GUARD_SLOT = 0x8000000000ab143c06;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      REENTRANCY GUARD                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Guards a function from reentrancy.
    modifier nonReentrant() virtual {
        if (_useTransientReentrancyGuardOnlyOnMainnet()) {
            uint256 s = _REENTRANCY_GUARD_SLOT;
            if (block.chainid == 1) {
                /// @solidity memory-safe-assembly
                assembly {
                    if tload(s) {
                        mstore(0x00, s) // `Reentrancy()`.
                        revert(0x1c, 0x04)
                    }
                    tstore(s, address())
                }
            } else {
                /// @solidity memory-safe-assembly
                assembly {
                    if eq(sload(s), address()) {
                        mstore(0x00, s) // `Reentrancy()`.
                        revert(0x1c, 0x04)
                    }
                    sstore(s, address())
                }
            }
        } else {
            /// @solidity memory-safe-assembly
            assembly {
                if tload(_REENTRANCY_GUARD_SLOT) {
                    mstore(0x00, 0xab143c06) // `Reentrancy()`.
                    revert(0x1c, 0x04)
                }
                tstore(_REENTRANCY_GUARD_SLOT, address())
            }
        }
        _;
        if (_useTransientReentrancyGuardOnlyOnMainnet()) {
            uint256 s = _REENTRANCY_GUARD_SLOT;
            if (block.chainid == 1) {
                /// @solidity memory-safe-assembly
                assembly {
                    tstore(s, 0)
                }
            } else {
                /// @solidity memory-safe-assembly
                assembly {
                    sstore(s, s)
                }
            }
        } else {
            /// @solidity memory-safe-assembly
            assembly {
                tstore(_REENTRANCY_GUARD_SLOT, 0)
            }
        }
    }

    /// @dev Guards a view function from read-only reentrancy.
    modifier nonReadReentrant() virtual {
        if (_useTransientReentrancyGuardOnlyOnMainnet()) {
            uint256 s = _REENTRANCY_GUARD_SLOT;
            if (block.chainid == 1) {
                /// @solidity memory-safe-assembly
                assembly {
                    if tload(s) {
                        mstore(0x00, s) // `Reentrancy()`.
                        revert(0x1c, 0x04)
                    }
                }
            } else {
                /// @solidity memory-safe-assembly
                assembly {
                    if eq(sload(s), address()) {
                        mstore(0x00, s) // `Reentrancy()`.
                        revert(0x1c, 0x04)
                    }
                }
            }
        } else {
            /// @solidity memory-safe-assembly
            assembly {
                if tload(_REENTRANCY_GUARD_SLOT) {
                    mstore(0x00, 0xab143c06) // `Reentrancy()`.
                    revert(0x1c, 0x04)
                }
            }
        }
        _;
    }

    /// @dev For widespread compatibility with L2s.
    /// Only Ethereum mainnet is expensive anyways.
    function _useTransientReentrancyGuardOnlyOnMainnet() internal view virtual returns (bool) {
        return true;
    }
}
