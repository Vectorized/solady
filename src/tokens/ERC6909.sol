// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Simple EIP-6909 implementation.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/tokens/ERC6909.sol)
///
/// @dev Note:
/// The ERC6909 standard allows minting and transferring to and from the zero address,
/// minting and transferring zero tokens, as well as self-approvals.
/// For performance, this implementation WILL NOT revert for such actions.
/// Please add any checks with overrides if desired.
abstract contract ERC6909 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Insufficient balance of the specified `owner` for the given `id`.
    error InsufficientBalance(address owner, uint256 id);

    /// @dev Insufficient permission for the specified `spender` for the given `id`.
    error InsufficientPermission(address spender, uint256 id);

    /// @dev The total supply has overflowed.
    error TotalSupplyOverflow();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Emitted when `amount` tokens is transferred from `from` to `to` for the given `id`.
    event Transfer(
        address indexed sender, address indexed receiver, uint256 indexed id, uint256 amount
    );

    /// @dev Emitted when `owner` enables or disables `operator` to manage all of their tokens.
    event OperatorSet(address indexed owner, address indexed spender, bool approved);

    /// @dev Emitted when `amount` tokens is approved by `owner` to be used by `spender` for the given `id`.
    event Approval(
        address indexed owner, address indexed spender, uint256 indexed id, uint256 amount
    );

    /// @dev `keccak256(bytes("Transfer(address,address,uint256,uint256)"))`.
    uint256 private constant _TRANSFER_EVENT_SIGNATURE =
        0x9ed053bb818ff08b8353cd46f78db1f0799f31c9e4458fdb425c10eccd2efc44;

    /// @dev `keccak256(bytes("OperatorSet(address,address,bool)"))`.
    uint256 private constant _OPERATOR_SET_EVENT_SIGNATURE =
        0xceb576d9f15e4e200fdb5096d64d5dfd667e16def20c1eefd14256d8e3faa267;

    /// @dev `keccak256(bytes("Approval(address,address,uint256,uint256)"))`.
    uint256 private constant _APPROVAL_EVENT_SIGNATURE =
        0xb3fd5071835887567a0671151121894ddccc2842f1d10bedad13e0d17cace9a7;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The total supply of `id` is given by.
    /// ```
    ///     mstore(0x0c ,_ERC6909_MASTER_SLOT_SEED)
    ///     mstore(0x00, id)
    ///     let totalSupplySlot := keccak256(0x00, 0x2c)
    /// ```
    ///
    /// The decimals of `id` is given by.
    /// ```
    ///     mstore(0x00, _ERC6909_MASTER_SLOT_SEED)
    ///     mstore(0x20, id)
    ///     let decimalsSlot := keccak256(0x14, 0x2c)
    /// ```
    ///
    /// The `ownerSlotSeed` of a given owner is given by.
    /// ```
    ///     let ownerSlotSeed := or(_ERC6909_MASTER_SLOT_SEED, shl(96, owner))
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
    ///
    /// The allowance slot of (`owner`, `spender`, `id`) is given by:
    /// ```
    ///     mstore(0x34, ownerSlotSeed)
    ///     mstore(0x14, spender)
    ///     mstore(0x00, id)
    ///     let allowanceSlot := keccak256(0x0c, 0x54)
    /// ```
    uint256 private constant _ERC6909_MASTER_SLOT_SEED = 0xedcaa89a82293940;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC6909 METADATA                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the token collection name.
    function name() public view virtual returns (string memory);

    /// @dev Returns the token collection symbol.
    function symbol() public view virtual returns (string memory);

    /// @dev Returns 18 decimal places by default.
    ///
    /// Note: If you want custom decimal place override this function with `_getDecimals`.
    function decimals(uint256 /*id*/ ) public view virtual returns (uint8) {
        return 18;
    }

    /// @dev Returns the Uniform Resource Identifier (URI) for token `id`.
    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          ERC6909                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the amount of tokens in existence.
    function totalSupply(uint256 id) public view virtual returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x0c, _ERC6909_MASTER_SLOT_SEED)
            mstore(0x00, id)
            let totalSupplySlot := keccak256(0x00, 0x2c)
            amount := sload(totalSupplySlot)
        }
    }

    /// @dev Returns the amount of given token`id` owned by `owner`.
    function balanceOf(address owner, uint256 id) public view virtual returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, _ERC6909_MASTER_SLOT_SEED)
            mstore(0x14, owner)
            mstore(0x00, id)
            amount := sload(keccak256(0x00, 0x40))
        }
    }

    /// @dev Returns the amount tokens that `spender` can spend on behalf of `owner` for the given `id`.
    function allowance(address owner, address spender, uint256 id)
        public
        view
        virtual
        returns (uint256 amount)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x34, _ERC6909_MASTER_SLOT_SEED)
            mstore(0x28, owner)
            mstore(0x14, spender)
            mstore(0x00, id)
            amount := sload(keccak256(0x00, 0x54))
            // Restore the part of the free-memory-pointer that was overwritten.
            mstore(0x34, 0x00)
        }
    }

    /// @dev Checks if a `spender` is approved by an `owner` as an operator.
    function isOperator(address owner, address spender) public view virtual returns (bool status) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, _ERC6909_MASTER_SLOT_SEED)
            mstore(0x14, owner)
            mstore(0x00, spender)
            status := sload(keccak256(0x0c, 0x34))
        }
    }

    /// @dev Transfer `amount` tokens from the caller to `to` for the given `id`.
    ///
    /// Requirements:
    /// - caller must at least have `amount`.
    ///
    /// Emits a {Transfer} event.
    function transfer(address to, uint256 id, uint256 amount) public virtual returns (bool) {
        _beforeTokenTransfer(msg.sender, to, id, amount);
        /// @solidity memory-safe-assembly
        assembly {
            /// Compute the balance slot and load its value.
            mstore(0x20, _ERC6909_MASTER_SLOT_SEED)
            mstore(0x14, caller())
            mstore(0x00, id)
            let fromBalanceSlot := keccak256(0x00, 0x40)
            let fromBalance := sload(fromBalanceSlot)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x34, mload(0x00))
                mstore(0x00, shl(96, 0xf6deaa04)) // `InsufficientBalance(address,uint256)`.
                revert(0x10, 0x44)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, sub(fromBalance, amount))
            // Compute the balance slot of `to`.
            mstore(0x14, to)
            mstore(0x00, id)
            let toBalanceSlot := keccak256(0x00, 0x40)
            // Add and store the updated balance of `to`.
            // Will not overflow because the sum of all user balances
            // cannot exceed the maximum uint256 value.
            sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))
            // Emit the {Transfer} event.
            mstore(0x00, amount)
            log4(0x00, 0x20, _TRANSFER_EVENT_SIGNATURE, caller(), shr(96, mload(0x20)), id)
        }
        _afterTokenTransfer(msg.sender, to, id, amount);
        return true;
    }

    /// @dev Transfers `amount` tokens from `from` to `to` for the given `id`.
    ///
    /// Note: Does not update the allowance if it is the maximum uint256 value.
    ///
    /// Requirements:
    /// - `from` must at least have `amount`.
    /// -  The caller must have at least `amount` of allowance to transfer the
    ///    tokens of `from` or approved as a operator.
    ///
    /// Emits a {Transfer} event.
    function transferFrom(address from, address to, uint256 id, uint256 amount)
        public
        virtual
        returns (bool)
    {
        _beforeTokenTransfer(from, to, id, amount);
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the operator slot and load its value.
            mstore(0x34, _ERC6909_MASTER_SLOT_SEED)
            mstore(0x28, from)
            mstore(0x14, caller())

            // check the caller is operator
            if iszero(sload(keccak256(0x20, 0x34))) {
                // Compute the allowance slot and load its value.
                mstore(0x00, id)
                let allowanceSlot := keccak256(0x00, 0x54)
                let allowance_ := sload(allowanceSlot)
                // If the allowance is not the maximum uint256 value.
                if add(allowance_, 1) {
                    // Revert if the amount to be transferred exceeds the allowance.
                    if gt(amount, allowance_) {
                        mstore(0x34, mload(0x00))
                        mstore(0x00, shl(96, 0x731555bd)) // `InsufficientPermission(address,uint256)`.
                        revert(0x10, 0x44)
                    }
                    // Subtract and store the updated allowance.
                    sstore(allowanceSlot, sub(allowance_, amount))
                }
            }
            // Compute the balance slot and load its value.
            mstore(0x14, id)
            let fromBalanceSlot := keccak256(0x14, 0x40)
            let fromBalance := sload(fromBalanceSlot)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x48, id)
                mstore(0x14, shl(96, 0xf6deaa04)) // `InsufficientBalance(address,uint256)`.
                revert(0x24, 0x44)
            }

            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, sub(fromBalance, amount))
            // Compute the balance slot of `to`.
            mstore(0x28, to)
            mstore(0x14, id)
            let toBalanceSlot := keccak256(0x14, 0x40)
            // Add and store the updated balance of `to`.
            // Will not overflow because the sum of all user balances
            // cannot exceed the maximum uint256 value.
            sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))
            // Emit the {Transfer} event.
            mstore(0x00, amount)
            // forgefmt: disable-next-line
            log4(0x00, 0x20, _TRANSFER_EVENT_SIGNATURE, shr(96, shl(96, from)), shr(96, mload(0x34)), id)
            /// Update the free memory pointer with the cached value.
            mstore(0x34, 0x00)
        }
        _afterTokenTransfer(from, to, id, amount);
        return true;
    }

    /// @dev Sets `amount` as the allowance of `spender` over the caller tokens for the given `id`.
    ///
    /// Emits a {Approval} event.
    function approve(address spender, uint256 id, uint256 amount) public virtual returns (bool) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the allowance slot and store the amount.
            mstore(0x34, _ERC6909_MASTER_SLOT_SEED)
            mstore(0x28, caller())
            mstore(0x14, spender)
            mstore(0x00, id)
            sstore(keccak256(0x00, 0x54), amount)

            // Emit the {Approval} event.
            mstore(0x00, amount)
            log4(0x00, 0x20, _APPROVAL_EVENT_SIGNATURE, caller(), shr(96, mload(0x20)), id)
            /// Update the free memory pointer with the cached value.
            mstore(0x34, 0x00)
        }
        return true;
    }

    ///  @dev Set or revoke operator status for `spender` for the caller based on the `approved`.
    ///
    /// Emits {OperatorSet} event.
    function setOperator(address spender, bool approved) public virtual returns (bool) {
        /// @solidity memory-safe-assembly
        assembly {
            // Convert `approved` to `0` or `1`.
            approved := iszero(iszero(approved))
            // Compute the operator slot and store the approved.
            mstore(0x20, _ERC6909_MASTER_SLOT_SEED)
            mstore(0x14, caller())
            mstore(0x00, spender)
            sstore(keccak256(0x0c, 0x34), approved)

            // Emit the {OperatorSet} event.
            mstore(0x20, approved)
            log3(0x20, 0x20, _OPERATOR_SET_EVENT_SIGNATURE, caller(), shr(96, mload(0x0c)))
        }
        return true;
    }

    /// @dev Returns true if this contract implements the interface defined by `interfaceId`.
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            let s := shr(224, interfaceId)
            // ERC165: 0x01ffc9a7, ERC6909: 0xb2e69f8a.
            result := or(eq(s, 0x01ffc9a7), eq(s, 0xb2e69f8a))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Mints `amount` tokens to `to`, increasing the total supply.
    ///
    /// Note: This function doesn't set given token `id` decimal.
    /// Emits a {Transfer} event.
    function _mint(address to, uint256 id, uint256 amount) internal virtual {
        _beforeTokenTransfer(address(0), to, id, amount);
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the total supply slot and load its value.
            mstore(0x0c, _ERC6909_MASTER_SLOT_SEED)
            mstore(0x00, id)
            let totalSupplySlot := keccak256(0x00, 0x2c)
            let totalSupplyBefore := sload(totalSupplySlot)
            let totalSupplyAfter := add(totalSupplyBefore, amount)

            // Revert if the total supply overflows.
            if lt(totalSupplyAfter, totalSupplyBefore) {
                mstore(0x00, 0xe5cfe957) // `TotalSupplyOverflow()`.
                revert(0x1c, 0x04)
            }

            // Store the updated total supply.
            sstore(totalSupplySlot, totalSupplyAfter)

            // Compute the balance slot and load its value.
            mstore(0x20, or(shl(96, to), _ERC6909_MASTER_SLOT_SEED))
            let toBalanceSlot := keccak256(0x00, 0x40)
            // Add and store the updated balance
            sstore(toBalanceSlot, add(sload(toBalanceSlot), amount))

            // Emit the {Transfer} event.
            mstore(0x00, amount)
            log4(0x00, 0x20, _TRANSFER_EVENT_SIGNATURE, 0, shr(96, mload(0x20)), id)
        }
        _afterTokenTransfer(address(0), to, id, amount);
    }

    /// @dev Burns `amount` token `id` from `from`, reducing the total supply.
    ///
    /// Emits a {Transfer} event.
    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        _beforeTokenTransfer(from, address(0), id, amount);
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the balance slot and load its value.
            mstore(0x20, _ERC6909_MASTER_SLOT_SEED)
            mstore(0x14, from)
            mstore(0x00, id)
            let fromBalanceSlot := keccak256(0x00, 0x40)
            let fromBalance := sload(fromBalanceSlot)

            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x34, mload(0x00))
                mstore(0x00, shl(96, 0xf6deaa04)) // `InsufficientBalance(address,uint256)`.
                revert(0x10, 0x44)
            }

            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, sub(fromBalance, amount))
            // Emit the {Transfer} event.
            mstore(0x00, amount)
            log4(0x00, 0x20, _TRANSFER_EVENT_SIGNATURE, shr(96, mload(0x20)), 0, id)
            // Compute totalSupply slot and load its value.
            mstore(0x14, id)
            let totalSupplySlot := keccak256(0x14, 0x2c)
            // Subtract and store the updated total supply.
            sstore(totalSupplySlot, sub(sload(totalSupplySlot), amount))
        }

        _afterTokenTransfer(from, address(0), id, amount);
    }

    /// @dev Set decimals place for the given `id`.
    function _setDecimals(uint256 id, uint8 decimal) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, _ERC6909_MASTER_SLOT_SEED)
            mstore(0x20, id)
            sstore(keccak256(0x14, 0x2c), and(0xff, decimal))
        }
    }

    /// @dev Return decimals place for the given `id` is
    ///      set by `_setDecimal` function.
    function _getDecimals(uint256 id) internal view virtual returns (uint8 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, _ERC6909_MASTER_SLOT_SEED)
            mstore(0x20, id)
            result := sload(keccak256(0x14, 0x2c))
        }
    }

    function _exists(uint256 id) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x0c, _ERC6909_MASTER_SLOT_SEED)
            mstore(0x00, id)
            result := iszero(iszero(keccak256(0x00, 0x2c)))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     HOOKS TO OVERRIDE                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Hook that is called before any transfer of tokens.
    /// This includes minting and burning.
    function _beforeTokenTransfer(address from, address to, uint256 id, uint256 amount)
        internal
        virtual
    {}

    /// @dev Hook that is called after any transfer of tokens.
    /// This includes minting and burning.
    function _afterTokenTransfer(address from, address to, uint256 id, uint256 amount)
        internal
        virtual
    {}
}
