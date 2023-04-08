// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Modern and gas efficient ERC1155 implementation.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/tokens/ERC1155.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    event TransferSingle(
        address indexed operator, address indexed from, address indexed to, uint256 id, uint256 amount
    );

    event TransferBatch(
        address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The `ownerSlotSeed` of a given owner is given by.
    /// ```
    ///     let ownerSlotSeed := or(_ERC1155_MASTER_SLOT_SEED, shl(96, owner))
    /// ```
    ///
    /// The balance slot of `owner` is given by.
    /// ```
    ///     mstore(0x20, ownerSlotSeed)
    ///     mstore(0x00, id)
    ///     let balanceSlot := keccak256(0x00, 0x40)
    /// ```
    ///
    /// The operator approval slot of `owner` is given by.
    /// ```
    ///     mstore(0x20, ownerSlotSeed)
    ///     mstore(0x00, operator)
    ///     let operatorApprovalSlot := keccak256(0x0c, 0x34)
    /// ```
    uint256 private constant _ERC1155_MASTER_SLOT_SEED = 0x9a31110384e0b0c9;


    function setApprovalForAll(address operator, bool isApproved) public virtual {
        _sstore(_operatorApprovalSlot(_ownerSlotSeed(msg.sender), operator), _toUint(isApproved));
        emit ApprovalForAll(msg.sender, operator, isApproved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool result) {
        assembly {
            mstore(0x20, or(_ERC1155_MASTER_SLOT_SEED, shl(96, owner)))
            mstore(0x00, operator)
            result := sload(keccak256(0x0c, 0x34))
        }
    }

    function _setApprovalForAll(address by, address operator, bool isApproved) internal virtual {
        _sstore(_operatorApprovalSlot(_ownerSlotSeed(by), operator), _toUint(isApproved));
        emit ApprovalForAll(by, operator, isApproved);
    }

    function _toBool(uint256 x) private pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := x
        }
    }

    function _toUint(bool x) private pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := x
        }
    }

    function _sload(uint256 storageSlot) private view returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(storageSlot)
        }
    }

    function _sstore(uint256 storageSlot, uint256 value) private {
        /// @solidity memory-safe-assembly
        assembly {
            sstore(storageSlot, value)
        }
    }

    function _balanceSlot(uint256 ownerSlotSeed, uint256 id) private pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, ownerSlotSeed)
            mstore(0x00, id)
            result := keccak256(0x00, 0x40)
        }
    }

    function _operatorApprovalSlot(uint256 ownerSlotSeed, address operator) private pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, ownerSlotSeed)
            mstore(0x00, operator)
            result := keccak256(0x0c, 0x34)
        }
    }

    function _ownerSlotSeed(address owner) private pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := or(_ERC1155_MASTER_SLOT_SEED, shl(96, owner))
        }
    }

    function _checkOnERC1155BatchReceivedCalldata(
        address by,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) private returns (bool) {
        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the calldata.
            let m := mload(0x40)
            let onERC1155BatchReceivedSelector := 0xbc197c81
            mstore(m, onERC1155BatchReceivedSelector)
            mstore(add(m, 0x20), shr(96, shl(96, by)))
            mstore(add(m, 0x40), shr(96, shl(96, from)))

            mstore(add(m, 0x60), 0xa0)
            let n := add(0x20, shl(5, ids.length))
            let o := add(m, 0xc0)
            calldatacopy(o, sub(ids.offset, 0x20), n)

            let s := add(0xa0, n)
            mstore(add(m, 0x80), s)
            o := add(o, n)
            n := add(0x20, shl(5, values.length))
            calldatacopy(o, sub(values.offset, 0x20), n)

            mstore(add(m, 0xa0), add(s, n))
            o := add(o, n)
            n := add(0x20, data.length)
            calldatacopy(o, sub(data.offset, 0x20), n)
            
            n := add(o, n)
            // Revert if the call reverts.
            if iszero(call(gas(), to, 0, add(m, 0x1c), n, m, 0x20)) {
                if returndatasize() {
                    // Bubble up the revert if the delegatecall reverts.
                    returndatacopy(0x00, 0x00, returndatasize())
                    revert(0x00, returndatasize())
                }
                mstore(m, 0)
            }
            // Load the returndata and compare it.
            if iszero(eq(mload(m), shl(224, onERC1155BatchReceivedSelector))) {
                revert(0x1c, 0x04)
            }
        }
        return true;
    }


    function _checkOnERC1155BatchReceived(
        address by,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) private returns (bool) {
        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the calldata.
            let m := mload(0x40)
            let onERC1155BatchReceivedSelector := 0xbc197c81
            mstore(m, onERC1155BatchReceivedSelector)
            mstore(add(m, 0x20), shr(96, shl(96, by)))
            mstore(add(m, 0x40), shr(96, shl(96, from)))
            
            mstore(add(m, 0x60), 0xa0)
            let n := add(0x20, shl(5, mload(ids)))
            let o := add(m, 0xc0)
            pop(staticcall(gas(), 4, ids, n, o, n))
            
            let s := add(0xa0, returndatasize())
            mstore(add(m, 0x80), s)
            o := add(o, returndatasize())
            n := add(0x20, shl(5, mload(values)))
            pop(staticcall(gas(), 4, values, n, o, n))
            
            mstore(add(m, 0xa0), add(s, returndatasize()))
            o := add(o, returndatasize())
            n := add(0x20, mload(data))
            pop(staticcall(gas(), 4, data, n, o, n))

            n := add(o, returndatasize())
            // Revert if the call reverts.
            if iszero(call(gas(), to, 0, add(m, 0x1c), n, m, 0x20)) {
                if returndatasize() {
                    // Bubble up the revert if the delegatecall reverts.
                    returndatacopy(0x00, 0x00, returndatasize())
                    revert(0x00, returndatasize())
                }
                mstore(m, 0)
            }
            // Load the returndata and compare it.
            if iszero(eq(mload(m), shl(224, onERC1155BatchReceivedSelector))) {
                revert(0x1c, 0x04)
            }
        }
        return true;
    }

}
