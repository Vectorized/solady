// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for efficient querying of the delegate registry on ZKsync.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ext/zksync/delegatexyz/DelegateCheckerLib.sol)
library DelegateCheckerLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The canonical delegate registry V2 on ZKsync.
    /// There's no V1 on ZKsync.
    /// See: https://sepolia.abscan.org/address/0x0000000059A24EB229eED07Ac44229DB56C5d797
    address internal constant DELEGATE_REGISTRY_V2 = 0x0000000059A24EB229eED07Ac44229DB56C5d797;

    /// @dev The storage slot to store an override address for the `DELEGATE_REGISTRY_V2`.
    /// If the address is non-zero, it will be used instead.
    /// This is so that you can avoid using `vm.etch` in ZKsync Foundry,
    /// and instead use `vm.store` instead.
    bytes32 internal constant DELEGATE_REGISTRY_V2_OVERRIDE_SLOT =
        0x04ecb0522ab37ca0b278a89c6884dfdbcde83c177150fc939ab02e069068bdef;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                DELEGATE CHECKING OPERATIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Note:
    // - `to` is the delegate. Typically called the "hot wallet".
    // - `from` is the grantor of the delegate rights. Typically called the "cold vault".

    /// @dev Returns if `to` is a delegate of `from`.
    /// ```
    ///     v2.checkDelegateForAll(to, from, "")
    /// ```
    function checkDelegateForAll(address to, address from) internal view returns (bool isValid) {
        address v2 = _delegateRegistryV2();
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            // `0x60` is already 0.
            mstore(0x40, from)
            mstore(0x2c, shl(96, to))
            mstore(0x0c, 0xe839bd53000000000000000000000000) // `checkDelegateForAll(address,address,bytes32)`.
            isValid := eq(mload(staticcall(gas(), v2, 0x1c, 0x64, 0x01, 0x20)), 1)
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Returns if `to` is a delegate of `from`.
    /// ```
    ///     v2.checkDelegateForAll(to, from, rights)
    /// ```
    function checkDelegateForAll(address to, address from, bytes32 rights)
        internal
        view
        returns (bool isValid)
    {
        address v2 = _delegateRegistryV2();
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(0x60, rights)
            mstore(0x40, from)
            mstore(0x2c, shl(96, to))
            mstore(0x0c, 0xe839bd53000000000000000000000000) // `checkDelegateForAll(address,address,bytes32)`.
            isValid := eq(mload(staticcall(gas(), v2, 0x1c, 0x64, 0x01, 0x20)), 1)
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero pointer.
        }
    }

    /// @dev Returns if `to` is a delegate of `from` for the specified `contract_`.
    /// ```
    ///     v2.checkDelegateForContract(to, from, contract_, "")
    /// ```
    /// Returns true if `checkDelegateForAll(to, from)` returns true.
    function checkDelegateForContract(address to, address from, address contract_)
        internal
        view
        returns (bool isValid)
    {
        address v2 = _delegateRegistryV2();
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(add(0x80, m), 0)
            mstore(add(0x60, m), contract_)
            mstore(add(0x4c, m), shl(96, from))
            mstore(add(0x2c, m), shl(96, to))
            // `checkDelegateForContract(address,address,address,bytes32)`.
            mstore(add(0x0c, m), 0x8988eea9000000000000000000000000)
            isValid := staticcall(gas(), v2, add(m, 0x1c), 0x84, m, 0x20)
            isValid := and(eq(mload(m), 1), isValid)
        }
    }

    /// @dev Returns if `to` is a delegate of `from` for the specified `contract_`.
    /// ```
    ///     v2.checkDelegateForContract(to, from, contract_, rights)
    /// ```
    /// Returns true if `checkDelegateForAll(to, from, rights)` returns true.
    function checkDelegateForContract(address to, address from, address contract_, bytes32 rights)
        internal
        view
        returns (bool isValid)
    {
        address v2 = _delegateRegistryV2();
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(add(0x80, m), rights)
            mstore(add(0x60, m), contract_)
            mstore(add(0x4c, m), shl(96, from))
            mstore(add(0x2c, m), shl(96, to))
            // `checkDelegateForContract(address,address,address,bytes32)`.
            mstore(add(0x0c, m), 0x8988eea9000000000000000000000000)
            isValid := staticcall(gas(), v2, add(m, 0x1c), 0x84, m, 0x20)
            isValid := and(eq(mload(m), 1), isValid)
        }
    }

    /// @dev Returns if `to` is a delegate of `from` for the specified `contract_` and token `id`.
    /// ```
    ///     v2.checkDelegateForERC721(to, from, contract_, id, "")
    /// ```
    /// Returns true if `checkDelegateForContract(to, from, contract_)` returns true.
    function checkDelegateForERC721(address to, address from, address contract_, uint256 id)
        internal
        view
        returns (bool isValid)
    {
        address v2 = _delegateRegistryV2();
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(add(0xa0, m), 0)
            mstore(add(0x80, m), id)
            mstore(add(0x60, m), contract_)
            mstore(add(0x4c, m), shl(96, from))
            mstore(add(0x2c, m), shl(96, to))
            // `checkDelegateForERC721(address,address,address,uint256,bytes32)`.
            mstore(add(0x0c, m), 0xb9f36874000000000000000000000000)
            isValid := staticcall(gas(), v2, add(m, 0x1c), 0xa4, m, 0x20)
            isValid := and(eq(mload(m), 1), isValid)
        }
    }

    /// @dev Returns if `to` is a delegate of `from` for the specified `contract_` and token `id`.
    /// ```
    ///     v2.checkDelegateForERC721(to, from, contract_, id, rights)
    /// ```
    /// Returns true if `checkDelegateForContract(to, from, contract_, rights)` returns true.
    function checkDelegateForERC721(
        address to,
        address from,
        address contract_,
        uint256 id,
        bytes32 rights
    ) internal view returns (bool isValid) {
        address v2 = _delegateRegistryV2();
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(add(0xa0, m), rights)
            mstore(add(0x80, m), id)
            mstore(add(0x60, m), contract_)
            mstore(add(0x4c, m), shl(96, from))
            mstore(add(0x2c, m), shl(96, to))
            // `checkDelegateForERC721(address,address,address,uint256,bytes32)`.
            mstore(add(0x0c, m), 0xb9f36874000000000000000000000000)
            isValid := staticcall(gas(), v2, add(m, 0x1c), 0xa4, m, 0x20)
            isValid := and(eq(mload(m), 1), isValid)
        }
    }

    /// @dev Returns the amount of an ERC20 token for `contract_`
    /// that `to` is granted rights to act on the behalf of `from`.
    /// ```
    ///     v2.checkDelegateForERC20(to, from, contract_, "")
    /// ```
    /// Returns `type(uint256).max` if `checkDelegateForContract(to, from, contract_)` returns true.
    function checkDelegateForERC20(address to, address from, address contract_)
        internal
        view
        returns (uint256 amount)
    {
        address v2 = _delegateRegistryV2();
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let o := add(0x80, m)
            mstore(o, 0)
            mstore(add(0x60, m), contract_)
            mstore(add(0x4c, m), shl(96, from))
            mstore(add(0x2c, m), shl(96, to))
            // `checkDelegateForERC20(address,address,address,bytes32)`.
            mstore(add(0x0c, m), 0xba63c817000000000000000000000000)
            amount := staticcall(gas(), v2, add(m, 0x1c), 0x84, o, 0x20)
            amount := mul(mload(o), amount)
        }
    }

    /// @dev Returns the amount of an ERC20 token for `contract_`
    /// that `to` is granted rights to act on the behalf of `from`.
    /// ```
    ///     v2.checkDelegateForERC20(to, from, contract_, rights)
    /// ```
    /// Returns `type(uint256).max` if `checkDelegateForContract(to, from, contract_, rights)` returns true.
    function checkDelegateForERC20(address to, address from, address contract_, bytes32 rights)
        internal
        view
        returns (uint256 amount)
    {
        address v2 = _delegateRegistryV2();
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(0x00, 0)
            mstore(add(0x80, m), rights)
            mstore(add(0x60, m), contract_)
            mstore(add(0x4c, m), shl(96, from))
            mstore(add(0x2c, m), shl(96, to))
            // `checkDelegateForERC20(address,address,address,bytes32)`.
            mstore(add(0x0c, m), 0xba63c817000000000000000000000000)
            amount := staticcall(gas(), v2, add(m, 0x1c), 0x84, 0x00, 0x20)
            amount := mul(mload(0x00), amount)
        }
    }

    /// @dev Returns the amount of an ERC1155 token `id` for `contract_`
    /// that `to` is granted rights to act on the behalf of `from`.
    /// ```
    ///     v2.checkDelegateForERC1155(to, from, contract_, id, "")
    /// ```
    /// Returns `type(uint256).max` if `checkDelegateForContract(to, from, contract_)` returns true.
    function checkDelegateForERC1155(address to, address from, address contract_, uint256 id)
        internal
        view
        returns (uint256 amount)
    {
        address v2 = _delegateRegistryV2();
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let o := add(0xa0, m)
            mstore(o, 0)
            mstore(add(0x80, m), id)
            mstore(add(0x60, m), contract_)
            mstore(add(0x4c, m), shl(96, from))
            mstore(add(0x2c, m), shl(96, to))
            // `checkDelegateForERC1155(address,address,address,uint256,bytes32)`.
            mstore(add(0x0c, m), 0xb8705875000000000000000000000000)
            amount := staticcall(gas(), v2, add(m, 0x1c), 0xa4, o, 0x20)
            amount := mul(mload(o), amount)
        }
    }

    /// @dev Returns the amount of an ERC1155 token `id` for `contract_`
    /// that `to` is granted rights to act on the behalf of `from`.
    /// ```
    ///     v2.checkDelegateForERC1155(to, from, contract_, id, rights)
    /// ```
    /// Returns `type(uint256).max` if `checkDelegateForContract(to, from, contract_, rights)` returns true.
    function checkDelegateForERC1155(
        address to,
        address from,
        address contract_,
        uint256 id,
        bytes32 rights
    ) internal view returns (uint256 amount) {
        address v2 = _delegateRegistryV2();
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(0x00, 0)
            mstore(add(0xa0, m), rights)
            mstore(add(0x80, m), id)
            mstore(add(0x60, m), contract_)
            mstore(add(0x4c, m), shl(96, from))
            mstore(add(0x2c, m), shl(96, to))
            // `checkDelegateForERC1155(address,address,address,uint256,bytes32)`.
            mstore(add(0x0c, m), 0xb8705875000000000000000000000000)
            amount := staticcall(gas(), v2, add(m, 0x1c), 0xa4, 0x00, 0x20)
            amount := mul(mload(0x00), amount)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the address of the delegate registry V2.
    function _delegateRegistryV2() private view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Don't worry about it, storage read is cheap on ZKsync VM.
            result := shr(96, shl(96, sload(DELEGATE_REGISTRY_V2_OVERRIDE_SLOT)))
            result := or(mul(DELEGATE_REGISTRY_V2, iszero(result)), result)
        }
    }
}
