// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Modern and gas efficient ERC1155 implementation.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/tokens/ERC1155.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC721 {
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
        _setApprovalForAll(by, operator, isApproved);
    }

    function _setApprovalForAll(address by, address operator, bool isApproved) internal virtual {
        _sstore(_operatorApprovalSlot(_ownerSlotSeed(by), operator), isApproved);
        emit ApprovalForAll(by, operator, isApproved);
    }

    // function _safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data)
    //     public
    //     virtual
    // {
    //     require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

    //     balanceOf[from][id] -= amount;
    //     balanceOf[to][id] += amount;

    //     emit TransferSingle(msg.sender, from, to, id, amount);

    //     require(
    //         to.code.length == 0
    //             ? to != address(0)
    //             : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data)
    //                 == ERC1155TokenReceiver.onERC1155Received.selector,
    //         "UNSAFE_RECIPIENT"
    //     );
    // }

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

}
