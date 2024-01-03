// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Initializable helper for the upgradeable contracts
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
    ///  let _INITIALIZABLE_SLOT := `bytes32(~uint256(uint32(bytes4(keccak256("_INITIALIZABLE_SLOT")))))`.
    ///
    /// The initialized version of current contract is :
    ///     initialized := shr(1, sload(_INITIALIZABLE_SLOT))
    ///
    /// The process of being initialized is :
    ///     initializing :=  and(sload(_INITIALIZABLE_SLOT), 1)
    bytes32 private constant _INITIALIZABLE_SLOT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffbf601132;

    modifier initializer() {
        uint256 i;
        assembly {
            i := sload(_INITIALIZABLE_SLOT)
            if iszero(or(iszero(i), lt(codesize(), eq(shr(1, i), 1)))) {
                mstore(0x00, 0xf92ee8a9)
                revert(0x1c, 0x04)
            }
            sstore(_INITIALIZABLE_SLOT, or(0x02, iszero(and(i, 1))))
        }
        _;
        assembly {
            if iszero(and(i, 1)) {
                sstore(_INITIALIZABLE_SLOT, xor(sload(_INITIALIZABLE_SLOT), 1))
                mstore(0x20, 0x01)
                log1(0x20, 0x20, _INTIALIZED_EVENT_SIGNATURE)
            }
        }
    }

    modifier reinitializer(uint64 version) {
        assembly {
            // clean upper bits
            version := and(version, 0xffffffffffffffff)
            let i := sload(_INITIALIZABLE_SLOT)

            if or(and(i, 1), iszero(lt(shr(1, i), version))) {
                mstore(0x00, 0xf92ee8a9)
                revert(0x1c, 0x04)
            }
            sstore(_INITIALIZABLE_SLOT, or(shl(1, version), 1))
        }

        _;
        assembly {
            sstore(_INITIALIZABLE_SLOT, shl(1, version))
            mstore(0x20, version)
            log1(0x20, 0x20, _INTIALIZED_EVENT_SIGNATURE)
        }
    }

    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    function _checkInitializing() internal view virtual {
        assembly {
            if iszero(and(1, sload(_INITIALIZABLE_SLOT))) {
                mstore(0x00, 0xd7e6bcf8)
                revert(0x1c, 0x04)
            }
        }
    }

    function _disableInitializers() internal virtual {
        assembly {
            let i := sload(_INITIALIZABLE_SLOT)
            if and(i, 1) {
                mstore(0x00, 0xf92ee8a9)
                revert(0x1c, 0x04)
            }
            if iszero(eq(shr(1, i), 0xffffffffffffffffff)) {
                sstore(_INITIALIZABLE_SLOT, 0x01fffffffffffffffe)
                mstore(0x20, 0xffffffffffffffffff)
                log1(0x20, 0x20, _INTIALIZED_EVENT_SIGNATURE)
            }
        }
    }

    function _getInitializedVersion() internal view returns (uint64 version) {
        assembly {
            version := shr(1, sload(_INITIALIZABLE_SLOT))
        }
    }

    function _isInitializing() internal view returns (bool result) {
        assembly {
            result := and(1, sload(_INITIALIZABLE_SLOT))
        }
    }
}
