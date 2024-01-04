// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Initializable mixin for the upgradeable contracts.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Initializable.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/proxy/utils/Initializable.sol)
abstract contract Initializable {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The contract is already initialized.
    error InvalidInitialization();

    /// @dev The contract is not initializing.
    error NotInitializing();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Triggered when the contract has been initialized.
    event Initialized(uint64 version);

    /// @dev `keccak256(bytes("Initialized(uint64)"))`.
    bytes32 private constant _INTIALIZED_EVENT_SIGNATURE =
        0xc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The initializable slot is given by:
    /// `bytes32(~uint256(uint32(bytes4(keccak256("_INITIALIZABLE_SLOT")))))`.
    ///
    /// Bits Layout:
    /// - [0]     `initializing`
    /// - [1..64] `initializedVersion`
    bytes32 private constant _INITIALIZABLE_SLOT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffbf601132;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OPERATIONS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Guards an initializer function so that it can be invoked at most once.
    ///
    /// You can guard a function with `onlyInitializing` such that it can be called
    /// through a function guarded with `initializer`.
    ///
    /// This is similar to `reinitializer(1)`, except that in the context of a constructor,
    /// an `initializer` guarded function can be invoked multiple times.
    /// This can be useful during testing and is not expected to be used in production.
    ///
    /// Emits an {Initialized} event.
    modifier initializer() {
        uint256 i;
        /// @solidity memory-safe-assembly
        assembly {
            let s := _INITIALIZABLE_SLOT
            i := sload(s)
            // If `!(initializing && initializedVersion == 0)`.
            if i {
                // If `!(codesize == 0 && initializedVersion == 1)`.
                if iszero(lt(codesize(), eq(shr(1, i), 1))) {
                    mstore(0x00, 0xf92ee8a9) // `InvalidInitialization()`.
                    revert(0x1c, 0x04)
                }
            }
            // Set `initializing` to 1, `initializedVersion` to 1.
            sstore(s, 3)
        }
        _;
        /// @solidity memory-safe-assembly
        assembly {
            // If `initializing`.
            if iszero(and(i, 1)) {
                // Set `initializing` to 0, `initializedVersion` to 1.
                sstore(_INITIALIZABLE_SLOT, 2)
                // Emit the {Initialized} event.
                mstore(0x20, 1)
                log1(0x20, 0x20, _INTIALIZED_EVENT_SIGNATURE)
            }
        }
    }

    /// @dev Guards an reinitialzer function so that it can be invoked at most once.
    ///
    /// You can guard a function with `onlyInitializing` such that it can be called
    /// through a function guarded with `reinitializer`.
    ///
    /// Emits an {Initialized} event.
    modifier reinitializer(uint64 version) {
        /// @solidity memory-safe-assembly
        assembly {
            version := and(version, 0xffffffffffffffff) // Clean upper bits.
            let s := _INITIALIZABLE_SLOT
            let i := sload(s)
            // If `initializing || initializedVersion >= version`.
            if iszero(lt(and(i, 1), lt(shr(1, i), version))) {
                mstore(0x00, 0xf92ee8a9) // `InvalidInitialization()`.
                revert(0x1c, 0x04)
            }
            // Set `initializing` to 1, `initializedVersion` to `version`.
            sstore(s, or(1, shl(1, version)))
        }
        _;
        /// @solidity memory-safe-assembly
        assembly {
            // Set `initializing` to 0, `initializedVersion` to `version`.
            sstore(_INITIALIZABLE_SLOT, shl(1, version))
            // Emit the {Initialized} event.
            mstore(0x20, version)
            log1(0x20, 0x20, _INTIALIZED_EVENT_SIGNATURE)
        }
    }

    /// @dev Guards a function such that it can only be called in the scope
    /// of a function guarded with `initializer` or `reinitializer`.
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /// @dev Reverts if the contract is not initializing.
    function _checkInitializing() internal view virtual {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(and(1, sload(_INITIALIZABLE_SLOT))) {
                mstore(0x00, 0xd7e6bcf8) // `NotInitializing()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Locks any future initializations by setting the initialized version to `2**64 - 1`.
    ///
    /// Calling this in the constructor will prevent the contract from being initialized
    /// or reinitialized. It is recommended to use this to lock implementation contracts
    /// that are designed to be called through proxies.
    ///
    /// Emits an {Initialized} event the first time it is successfully called.
    function _disableInitializers() internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            let s := _INITIALIZABLE_SLOT
            let i := sload(s)
            if and(i, 1) {
                mstore(0x00, 0xf92ee8a9) // `InvalidInitialization()`.
                revert(0x1c, 0x04)
            }
            let uint64max := shr(192, s) // Computed to save bytecode.
            if iszero(eq(shr(1, i), uint64max)) {
                // Set `initializing` to 0, `initializedVersion` to `2**64 - 1`.
                sstore(s, shl(1, uint64max))
                // Emit the {Initialized} event.
                mstore(0x20, uint64max)
                log1(0x20, 0x20, _INTIALIZED_EVENT_SIGNATURE)
            }
        }
    }

    /// @dev Returns the highest version that has been initialized.
    function _getInitializedVersion() internal view returns (uint64 version) {
        /// @solidity memory-safe-assembly
        assembly {
            version := shr(1, sload(_INITIALIZABLE_SLOT))
        }
    }

    /// @dev Returns whether the contract is currently initializing.
    function _isInitializing() internal view returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := and(1, sload(_INITIALIZABLE_SLOT))
        }
    }
}
