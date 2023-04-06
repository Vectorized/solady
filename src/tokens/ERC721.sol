// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Basic flexible gas efficient ERC721 implementation.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/tokens/ERC721.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokenss/ERC721.sol)
abstract contract ERC721 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev An account can hold up to 4294967295 tokens.
    uint256 internal constant _MAX_ACCOUNT_BALANCE = 0xffffffff;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Only the token owner or an approved account can manage the token.
    error NotOwnerNorApproved();

    /// @dev The token does not exist.
    error TokenDoesNotExist();

    /// @dev The token already exists.
    error TokenAlreadyExists();

    /// @dev Cannot query the balance for the zero address.
    error BalanceQueryForZeroAddress();

    /// @dev Cannot mint or transfer to the zero address.
    error TransferToZeroAddress();

    /// @dev The token must be owned by `from`.
    error TransferFromIncorrectOwner();

    /// @dev The recipient's balance has overflowed.
    error AccountBalanceOverflow();

    /// @dev Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
    error TransferToNonERC721ReceiverImplementer();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Emitted when token `id` is transferred from `from` to `to`.
    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    /// @dev Emitted when `owner` enables `approved` to manage the `id` token.
    event Approval(address indexed owner, address indexed approved, uint256 indexed id);

    /// @dev Emitted when `owner` enables or disables `operator` to manage all of their tokens.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /// @dev `keccak256(bytes("Transfer(address,address,uint256)"))`.
    uint256 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    /// @dev `keccak256(bytes("Approval(address,address,uint256)"))`.
    uint256 private constant _APPROVAL_EVENT_SIGNATURE =
        0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925;

    /// @dev `keccak256(bytes("ApprovalForAll(address,address,bool)"))`.
    uint256 private constant _APPROVAL_FOR_ALL_EVENT_SIGNATURE =
        0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ownership data slot of `id` is given by.
    /// ```
    ///     mstore(0x20, _OWNERSHIP_DATA_SLOT_SEED)
    ///     mstore(0x00, id)
    ///     let ownershipDataSlot := keccak256(0x00, 0x40)
    /// ```
    /// Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `extraData`
    uint256 private constant _OWNERSHIP_DATA_SLOT_SEED = 0x1e498770;

    /// @dev The address data slot of `owner` is given by.
    /// ```
    ///     mstore(0x0c, _ADDRESS_DATA_SLOT_SEED)
    ///     mstore(0x00, owner)
    ///     let addressDataSlot := keccak256(0x0c, 0x20)
    /// ```
    /// Bits Layout:
    /// - [0..31]   `balance`
    /// - [32..225] `aux`
    uint256 private constant _ADDRESS_DATA_SLOT_SEED = 0xee1757ab;

    /// @dev The approved address slot of token `id` is given by.
    /// ```
    ///     mstore(0x20, _APPROVED_ADDRESS_SLOT_SEED)
    ///     mstore(0x00, id)
    ///     let approvedAddressSlot := keccak256(0x00, 0x40)
    /// ```
    uint256 private constant _APPROVED_ADDRESS_SLOT_SEED = 0x2f2069df;

    /// @dev The operator approval slot of `owner` is given by.
    /// ```
    ///     mstore(0x20, operator)
    ///     mstore(0x0c, _OPERATOR_APPROVAL_SLOT_SEED)
    ///     mstore(0x00, owner)
    ///     let operatorApprovalSlot := keccak256(0x0c, 0x34)
    /// ```
    uint256 private constant _OPERATOR_APPROVAL_SLOT_SEED = 0x7ee4befd;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC721 METADATA                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the token collection name.
    function name() public view virtual returns (string memory);

    /// @dev Returns the token collection symbol.
    function symbol() public view virtual returns (string memory);

    /// @dev Returns the Uniform Resource Identifier (URI) for token `id`.
    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           ERC721                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function ownerOf(uint256 id) public view virtual returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, _OWNERSHIP_DATA_SLOT_SEED)
            mstore(0x00, id)
            result := shr(96, shl(96, sload(keccak256(0x00, 0x40))))
            if iszero(result) {
                mstore(0x00, 0xceea21b6) // `TokenDoesNotExist()`.
                revert(0x1c, 0x04)
            }
        }
    }

    function balanceOf(address owner) public view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x0c, _ADDRESS_DATA_SLOT_SEED)
            mstore(0x00, owner)
            owner := shr(96, mload(0x0c))
            // Revert if the `owner` is the zero address.
            if iszero(owner) {
                mstore(0x00, 0x8f4eb604) // `BalanceQueryForZeroAddress()`.
                revert(0x1c, 0x04)
            }
            result := and(sload(keccak256(0x0c, 0x20)), _MAX_ACCOUNT_BALANCE)
        }
    }

    function getApproved(uint256 id) public view virtual returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, _APPROVED_ADDRESS_SLOT_SEED)
            mstore(0x00, id)
            result := shr(96, shl(96, sload(keccak256(0x00, 0x40))))
        }
    }

    function approve(address spender, uint256 id) public payable virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Clear the upper 96 bits.
            spender := shr(96, shl(96, spender))
            // Load the owner of the token.
            mstore(0x20, _OWNERSHIP_DATA_SLOT_SEED)
            mstore(0x00, id)
            let owner_ := shl(96, sload(keccak256(0x00, 0x40)))
            // Revert if the token does not exist.
            if iszero(owner_) {
                mstore(0x00, 0xceea21b6) // `TokenDoesNotExist()`.
                revert(0x1c, 0x04)
            }
            // Revert if the caller is not the owner, nor approved.
            if iszero(eq(shl(96, caller()), owner_)) {
                mstore(0x20, caller())
                mstore(0x0c, or(owner_, _OPERATOR_APPROVAL_SLOT_SEED))
                if iszero(sload(keccak256(0x0c, 0x34))) {
                    mstore(0x00, 0x4b6e7f18) // `NotOwnerNorApproved()`.
                    revert(0x1c, 0x04)
                }
            }
            // Update the `spender` for `id`.
            mstore(0x20, _APPROVED_ADDRESS_SLOT_SEED)
            mstore(0x00, id)
            sstore(keccak256(0x00, 0x40), spender)
            // Emit the {Approval} event.
            log4(0x00, 0x00, _APPROVAL_EVENT_SIGNATURE, caller(), spender, id)
        }
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        returns (bool result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, operator)
            mstore(0x0c, _OPERATOR_APPROVAL_SLOT_SEED)
            mstore(0x00, owner)
            result := sload(keccak256(0x0c, 0x34))
        }
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Clear the upper 96 bits.
            operator := shr(96, shl(96, operator))
            // Convert to 0 or 1.
            approved := iszero(iszero(approved))
            // Update the `approved` for (`msg.sender`, `operator`).
            mstore(0x20, operator)
            mstore(0x0c, _OPERATOR_APPROVAL_SLOT_SEED)
            mstore(0x00, caller())
            sstore(keccak256(0x0c, 0x34), approved)
            // Emit the {ApprovalForAll} event.
            mstore(0x00, approved)
            log3(0x00, 0x20, _APPROVAL_FOR_ALL_EVENT_SIGNATURE, caller(), operator)
        }
    }

    function transferFrom(address from, address to, uint256 id) public payable virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Clear the upper 96 bits.
            let from_ := shl(96, from)
            from := shr(96, from_)
            to := shr(96, shl(96, to))
            // Load the ownership data.
            mstore(0x20, _OWNERSHIP_DATA_SLOT_SEED)
            mstore(0x00, id)
            let ownershipSlot := keccak256(0x00, 0x40)
            let ownershipPacked := sload(ownershipSlot)
            let ownershipPacked_ := shl(96, ownershipPacked)
            // Revert if the token does not exist.
            if iszero(ownershipPacked_) {
                mstore(0x00, 0xceea21b6) // `TokenDoesNotExist()`.
                revert(0x1c, 0x04)
            }
            // Revert if `from` is not the owner.
            if iszero(eq(ownershipPacked_, from_)) {
                mstore(0x00, 0xa1148100) // `TransferFromIncorrectOwner()`.
                revert(0x1c, 0x04)
            }
            // Revert if `to` is the zero address.
            if iszero(to) {
                mstore(0x00, 0xea553b34) // `TransferToZeroAddress()`.
                revert(0x1c, 0x04)
            }
            // Load, check, and update the token approval.
            {
                mstore(0x20, _APPROVED_ADDRESS_SLOT_SEED)
                mstore(0x00, id)
                let approvedAddressSlot := keccak256(0x00, 0x40)
                let approvedAddress := sload(approvedAddressSlot)
                // Delete the approved address if any.
                if approvedAddress { sstore(approvedAddressSlot, 0) }
                // Revert if the caller is not the owner, nor approved.
                if iszero(or(eq(caller(), from), eq(caller(), approvedAddress))) {
                    mstore(0x20, caller())
                    mstore(0x0c, or(from_, _OPERATOR_APPROVAL_SLOT_SEED))
                    if iszero(sload(keccak256(0x0c, 0x34))) {
                        mstore(0x00, 0x4b6e7f18) // `NotOwnerNorApproved()`.
                        revert(0x1c, 0x04)
                    }
                }
            }
            // Update with the new owner.
            sstore(ownershipSlot, xor(ownershipPacked, xor(from, to)))
            // Decrement the balance of `from`.
            {
                mstore(0x0c, or(from_, _ADDRESS_DATA_SLOT_SEED))
                let fromBalanceSlot := keccak256(0x0c, 0x20)
                sstore(fromBalanceSlot, sub(sload(fromBalanceSlot), 1))
            }
            // Increment the balance of `to`.
            {
                mstore(0x00, to)
                let toBalanceSlot := keccak256(0x0c, 0x20)
                let toBalanceSlotPacked := add(sload(toBalanceSlot), 1)
                if iszero(and(toBalanceSlotPacked, _MAX_ACCOUNT_BALANCE)) {
                    mstore(0x00, 0x01336cea) // `AccountBalanceOverflow()`.
                    revert(0x1c, 0x04)
                }
                sstore(toBalanceSlot, toBalanceSlotPacked)
            }
            // Emit the {Transfer} event.
            log4(0x00, 0x00, _TRANSFER_EVENT_SIGNATURE, from, to, id)
        }
    }

    function safeTransferFrom(address from, address to, uint256 id) public payable virtual {
        safeTransferFrom(from, to, id, "");
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes memory _data)
        public
        payable
        virtual
    {
        transferFrom(from, to, id);
        if (to.code.length != 0) _checkOnERC721Received(from, to, id, _data, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            let s := shr(224, interfaceId)
            // ERC165: 0x01ffc9a7, ERC721: 0x80ac58cd, ERC721Metadata: 0x5b5e139f.
            result := or(or(eq(s, 0x01ffc9a7), eq(s, 0x80ac58cd)), eq(s, 0x5b5e139f))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                INTERNAL FUNCTIONS FOR USAGE                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _exists(uint256 id) internal view virtual returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, _OWNERSHIP_DATA_SLOT_SEED)
            mstore(0x00, id)
            result := iszero(iszero(shl(96, sload(keccak256(0x00, 0x40)))))
        }
    }

    function _ownerOf(uint256 id) internal view virtual returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, _OWNERSHIP_DATA_SLOT_SEED)
            mstore(0x00, id)
            result := shr(96, shl(96, sload(keccak256(0x00, 0x40))))
        }
    }

    function _isApprovedOrOwner(address spender, uint256 id)
        internal
        view
        virtual
        returns (bool result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            // Clear the upper 96 bits.
            let spender_ := shl(96, spender)
            // Load the ownership data.
            mstore(0x20, _OWNERSHIP_DATA_SLOT_SEED)
            mstore(0x00, id)
            let owner_ := shl(96, sload(keccak256(0x00, 0x40)))
            // Revert if the token does not exist.
            if iszero(owner_) {
                mstore(0x00, 0xceea21b6) // `TokenDoesNotExist()`.
                revert(0x1c, 0x04)
            }
            // Check if `spender` is the `owner`.
            if iszero(eq(spender_, owner_)) {
                mstore(0x20, spender)
                mstore(0x0c, or(owner_, _OPERATOR_APPROVAL_SLOT_SEED))
                // Check if `spender` is approved to
                if iszero(sload(keccak256(0x0c, 0x34))) {
                    mstore(0x20, _APPROVED_ADDRESS_SLOT_SEED)
                    mstore(0x00, id)
                    result := eq(spender_, shl(96, sload(keccak256(0x00, 0x40))))
                }
            }
        }
    }

    function _approve(address spender, uint256 id) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Clear the upper 96 bits.
            spender := shr(96, shl(96, spender))
            // Update the `spender` for `id`.
            mstore(0x20, _APPROVED_ADDRESS_SLOT_SEED)
            mstore(0x00, id)
            sstore(keccak256(0x00, 0x40), spender)
            // Load the owner of `id` for the event.
            mstore(0x20, _OWNERSHIP_DATA_SLOT_SEED)
            let owner := shr(96, shl(96, sload(keccak256(0x00, 0x40))))
            // Emit the {Approval} event.
            log4(0x00, 0x00, _APPROVAL_EVENT_SIGNATURE, owner, spender, id)
        }
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Clear the upper 96 bits.
            let owner_ := shl(96, owner)
            operator := shr(96, shl(96, operator))
            // Convert to 0 or 1.
            approved := iszero(iszero(approved))
            // Update the `approved` for (`msg.sender`, `operator`).
            mstore(0x20, operator)
            mstore(0x0c, or(owner_, _OPERATOR_APPROVAL_SLOT_SEED))
            sstore(keccak256(0x0c, 0x34), approved)
            // Emit the {ApprovalForAll} event.
            mstore(0x00, approved)
            log3(0x00, 0x20, _APPROVAL_FOR_ALL_EVENT_SIGNATURE, shr(96, owner_), operator)
        }
    }

    function _transfer(address from, address to, uint256 id) internal virtual {
        _transfer(from, to, id, address(0));
    }

    function _transfer(address from, address to, uint256 id, address spender) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Clear the upper 96 bits.
            let from_ := shl(96, from)
            from := shr(96, from_)
            to := shr(96, shl(96, to))
            spender := shr(96, shl(96, spender))
            // Load the ownership data.
            mstore(0x20, _OWNERSHIP_DATA_SLOT_SEED)
            mstore(0x00, id)
            let ownershipSlot := keccak256(0x00, 0x40)
            let ownershipPacked := sload(ownershipSlot)
            let ownershipPacked_ := shl(96, ownershipPacked)
            // Revert if the token does not exist.
            if iszero(ownershipPacked_) {
                mstore(0x00, 0xceea21b6) // `TokenDoesNotExist()`.
                revert(0x1c, 0x04)
            }
            // Revert if `from` is not the owner.
            if iszero(eq(ownershipPacked_, from_)) {
                mstore(0x00, 0xa1148100) // `TransferFromIncorrectOwner()`.
                revert(0x1c, 0x04)
            }
            // Revert if `to` is the zero address.
            if iszero(to) {
                mstore(0x00, 0xea553b34) // `TransferToZeroAddress()`.
                revert(0x1c, 0x04)
            }
            // Load, check, and update the token approval.
            {
                mstore(0x20, _APPROVED_ADDRESS_SLOT_SEED)
                mstore(0x00, id)
                let approvedAddressSlot := keccak256(0x00, 0x40)
                let approvedAddress := sload(approvedAddressSlot)
                // Delete the approved address if any.
                if approvedAddress { sstore(approvedAddressSlot, 0) }
                // If `spender` is not the zero address, do the approval check.
                if spender {
                    // Revert if the caller is not the owner, nor approved.
                    if iszero(or(eq(spender, from), eq(spender, approvedAddress))) {
                        mstore(0x20, spender)
                        mstore(0x0c, or(from_, _OPERATOR_APPROVAL_SLOT_SEED))
                        if iszero(sload(keccak256(0x0c, 0x34))) {
                            mstore(0x00, 0x4b6e7f18) // `NotOwnerNorApproved()`.
                            revert(0x1c, 0x04)
                        }
                    }
                }
            }
            // Update with the new owner.
            sstore(ownershipSlot, xor(ownershipPacked, xor(from, to)))
            // Decrement the balance of `from`.
            {
                mstore(0x0c, or(from_, _ADDRESS_DATA_SLOT_SEED))
                let fromBalanceSlot := keccak256(0x0c, 0x20)
                sstore(fromBalanceSlot, sub(sload(fromBalanceSlot), 1))
            }
            // Increment the balance of `to`.
            {
                mstore(0x00, to)
                let toBalanceSlot := keccak256(0x0c, 0x20)
                let toBalanceSlotPacked := add(sload(toBalanceSlot), 1)
                if iszero(and(toBalanceSlotPacked, _MAX_ACCOUNT_BALANCE)) {
                    mstore(0x00, 0x01336cea) // `AccountBalanceOverflow()`.
                    revert(0x1c, 0x04)
                }
                sstore(toBalanceSlot, toBalanceSlotPacked)
            }
            // Emit the {Transfer} event.
            log4(0x00, 0x00, _TRANSFER_EVENT_SIGNATURE, from, to, id)
        }
    }

    function _safeTransfer(address from, address to, uint256 id) internal virtual {
        _safeTransfer(from, to, id, "");
    }

    function _safeTransfer(address from, address to, uint256 id, bytes memory _data)
        internal
        virtual
    {
        _transfer(from, to, id, address(0));
        if (to.code.length != 0) _checkOnERC721Received(from, to, id, _data, msg.sender);
    }

    function _safeTransfer(address from, address to, uint256 id, address spender)
        internal
        virtual
    {
        _safeTransfer(from, to, id, "", spender);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 id,
        bytes memory _data,
        address spender
    ) internal virtual {
        _transfer(from, to, id, spender);
        if (to.code.length != 0) _checkOnERC721Received(from, to, id, _data, spender);
    }

    function _mint(address to, uint256 id) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Clear the upper 96 bits.
            to := shr(96, shl(96, to))
            // Revert if `to` is the zero address.
            if iszero(to) {
                mstore(0x00, 0xea553b34) // `TransferToZeroAddress()`.
                revert(0x1c, 0x04)
            }
            // Load the ownership data.
            mstore(0x20, _OWNERSHIP_DATA_SLOT_SEED)
            mstore(0x00, id)
            let ownershipSlot := keccak256(0x00, 0x40)
            let ownershipPacked := sload(ownershipSlot)
            // Revert if the token already exists.
            if shl(96, ownershipPacked) {
                mstore(0x00, 0xc991cbb1) // `TokenAlreadyExists()`.
                revert(0x1c, 0x04)
            }
            // Update with the owner.
            sstore(ownershipSlot, or(ownershipPacked, to))
            // Increment the balance of the owner.
            {
                mstore(0x0c, _ADDRESS_DATA_SLOT_SEED)
                mstore(0x00, to)
                let balanceSlot := keccak256(0x0c, 0x20)
                let balanceSlotPacked := add(sload(balanceSlot), 1)
                if iszero(and(balanceSlotPacked, _MAX_ACCOUNT_BALANCE)) {
                    mstore(0x00, 0x01336cea) // `AccountBalanceOverflow()`.
                    revert(0x1c, 0x04)
                }
                sstore(balanceSlot, balanceSlotPacked)
            }
            // Emit the {Transfer} event.
            log4(0x00, 0x00, _TRANSFER_EVENT_SIGNATURE, 0, to, id)
        }
    }

    function _safeMint(address to, uint256 id) internal virtual {
        _safeMint(to, id, "");
    }

    function _safeMint(address to, uint256 id, bytes memory _data) internal virtual {
        _mint(to, id);
        if (to.code.length != 0) _checkOnERC721Received(address(0), to, id, _data, msg.sender);
    }

    function _burn(uint256 id) internal virtual {
        _burn(id, address(0));
    }

    function _burn(uint256 id, address spender) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Clear the upper 96 bits.
            spender := shr(96, shl(96, spender))
            // Load the ownership data.
            mstore(0x20, _OWNERSHIP_DATA_SLOT_SEED)
            mstore(0x00, id)
            let ownershipSlot := keccak256(0x00, 0x40)
            let ownershipPacked := sload(ownershipSlot)
            let owner := shr(96, shl(96, ownershipPacked))
            // Revert if the token does not exist.
            if iszero(owner) {
                mstore(0x00, 0xceea21b6) // `TokenDoesNotExist()`.
                revert(0x1c, 0x04)
            }
            // Clear the owner.
            sstore(ownershipSlot, xor(ownershipPacked, owner))
            // Load, check, and update the token approval.
            {
                mstore(0x20, _APPROVED_ADDRESS_SLOT_SEED)
                mstore(0x00, id)
                let approvedAddressSlot := keccak256(0x00, 0x40)
                let approvedAddress := sload(approvedAddressSlot)
                // Delete the approved address if any.
                if approvedAddress { sstore(approvedAddressSlot, 0) }
                // If `spender` is not the zero address, do the approval check.
                if spender {
                    // Revert if the `spender` is not the owner, nor approved.
                    if iszero(or(eq(spender, owner), eq(spender, approvedAddress))) {
                        mstore(0x20, spender)
                        mstore(0x0c, _OPERATOR_APPROVAL_SLOT_SEED)
                        mstore(0x00, owner)
                        if iszero(sload(keccak256(0x0c, 0x34))) {
                            mstore(0x00, 0x4b6e7f18) // `NotOwnerNorApproved()`.
                            revert(0x1c, 0x04)
                        }
                    }
                }
            }
            // Decrement the balance of `owner`.
            {
                mstore(0x0c, _ADDRESS_DATA_SLOT_SEED)
                mstore(0x00, owner)
                let balanceSlot := keccak256(0x0c, 0x20)
                sstore(balanceSlot, sub(sload(balanceSlot), 1))
            }
            // Emit the {Transfer} event.
            log4(0x00, 0x00, _TRANSFER_EVENT_SIGNATURE, owner, 0, id)
        }
    }

    function _getAux(address owner) internal virtual returns (uint224 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x0c, _ADDRESS_DATA_SLOT_SEED)
            mstore(0x00, owner)
            result := shr(32, sload(keccak256(0x0c, 0x20)))
        }
    }

    function _setAux(address owner, uint224 value) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x0c, _ADDRESS_DATA_SLOT_SEED)
            mstore(0x00, owner)
            let addressDataSlot := keccak256(0x0c, 0x20)
            let packed := sload(addressDataSlot)
            sstore(addressDataSlot, xor(packed, shl(32, xor(value, shr(32, packed)))))
        }
    }

    function _getExtraData(uint256 id) internal virtual returns (uint96 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, _OWNERSHIP_DATA_SLOT_SEED)
            mstore(0x00, id)
            result := shr(160, sload(keccak256(0x00, 0x40)))
        }
    }

    function _setExtraData(uint256 id, uint96 value) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, _OWNERSHIP_DATA_SLOT_SEED)
            mstore(0x00, id)
            let ownershipDataSlot := keccak256(0x00, 0x40)
            let packed := sload(ownershipDataSlot)
            sstore(ownershipDataSlot, xor(packed, shl(160, xor(value, shr(160, packed)))))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 id,
        bytes memory _data,
        address spender
    ) private {
        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the calldata.
            let m := mload(0x40)
            mstore(m, 0x150b7a02)
            mstore(add(m, 0x20), shr(96, shl(96, spender)))
            mstore(add(m, 0x40), shr(96, shl(96, from)))
            mstore(add(m, 0x60), id)
            mstore(add(m, 0x80), 0x80)
            let n := mload(_data)
            let o := add(m, 0xa0)
            mstore(o, n)
            for { let i := 0 } lt(i, n) {} {
                i := add(i, 0x20)
                mstore(add(o, i), mload(add(_data, i)))
            }
            // Revert if the call reverts.
            if iszero(call(gas(), to, 0, add(m, 0x1c), add(n, 0xa4), m, 0x20)) {
                if iszero(returndatasize()) {
                    mstore(0x00, 0xd1a57ed6) // `TransferToNonERC721ReceiverImplementer()`.
                    revert(0x1c, 0x04)
                }
                // Bubble up the revert if the delegatecall reverts.
                returndatacopy(0x00, 0x00, returndatasize())
                revert(0x00, returndatasize())
            }
            // Load the returndata and compare it.
            if iszero(eq(mload(m), shl(224, 0x150b7a02))) {
                mstore(0x00, 0xd1a57ed6) // `TransferToNonERC721ReceiverImplementer()`.
                revert(0x1c, 0x04)
            }
        }
    }
}
