// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for efficient querying of the delegate registries.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ext/delegate/DelegateCheckerLib.sol)
library DelegateCheckerLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The canonical delegate registry V1.
    /// See: https://etherscan.io/address/0x00000000000076a84fef008cdabe6409d2fe638b
    address internal constant DELEGATE_REGISTRY_V1 = 0x00000000000076A84feF008CDAbe6409d2FE638B;

    /// @dev The canonical delegate registry V2.
    /// See: https://etherscan.io/address/0x00000000000000447e69651d841bD8D104Bed493
    address internal constant DELEGATE_REGISTRY_V2 = 0x00000000000000447e69651d841bD8D104Bed493;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                DELEGATE CHECKING OPERATIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Note:
    // - `to` is the delegate. Typically called the "hot wallet".
    // - `from` is the grantor of the delegate rights. Typically called the "cold vault".

    /// @dev Returns if `to` is a delegate of `from`.
    /// ```
    ///     v2.checkDelegateForAll(to, from, "") ||
    ///     v1.checkDelegateForAll(to, from)
    /// ```
    function checkDelegateForAll(address to, address from) internal view returns (bool isValid) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            // `0x60` is already 0.
            mstore(0x40, from)
            mstore(0x2c, shl(96, to))
            mstore(0x0c, 0xe839bd53000000000000000000000000) // `checkDelegateForAll(address,address,bytes32)`.
            isValid := eq(mload(staticcall(gas(), DELEGATE_REGISTRY_V2, 0x1c, 0x64, 0x01, 0x20)), 1)
            if iszero(isValid) {
                mstore(0x01, 0x9c395bc200) // `checkDelegateForAll(address,address)`.
                isValid :=
                    eq(mload(staticcall(gas(), DELEGATE_REGISTRY_V1, 0x1c, 0x44, 0x01, 0x20)), 1)
            }
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Returns if `to` is a delegate of `from`.
    /// ```
    ///     v2.checkDelegateForAll(to, from, rights) ||
    ///     (rights == "" && v1.checkDelegateForAll(to, from))
    /// ```
    function checkDelegateForAll(address to, address from, bytes32 rights)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(0x60, rights)
            mstore(0x40, from)
            mstore(0x2c, shl(96, to))
            mstore(0x0c, 0xe839bd53000000000000000000000000) // `checkDelegateForAll(address,address,bytes32)`.
            isValid := eq(mload(staticcall(gas(), DELEGATE_REGISTRY_V2, 0x1c, 0x64, 0x01, 0x20)), 1)
            if iszero(or(rights, isValid)) {
                mstore(0x01, 0x9c395bc200) // `checkDelegateForAll(address,address)`.
                isValid :=
                    eq(mload(staticcall(gas(), DELEGATE_REGISTRY_V1, 0x1c, 0x44, 0x01, 0x20)), 1)
            }
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero pointer.
        }
    }

    /// @dev Returns if `to` is a delegate of `from` for the specified `contract_`.
    /// ```
    ///     v2.checkDelegateForContract(to, from, contract_, "") ||
    ///     v1.checkDelegateForContract(to, from, contract_)
    /// ```
    /// Returns true if `checkDelegateForAll(to, from)` returns true.
    function checkDelegateForContract(address to, address from, address contract_)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(add(0x80, m), 0)
            mstore(add(0x60, m), contract_)
            mstore(add(0x4c, m), shl(96, from))
            mstore(add(0x2c, m), shl(96, to))
            // `checkDelegateForContract(address,address,address,bytes32)`.
            mstore(add(0x0c, m), 0x8988eea9000000000000000000000000)
            isValid := staticcall(gas(), DELEGATE_REGISTRY_V2, add(m, 0x1c), 0x84, m, 0x20)
            isValid := and(eq(mload(m), 1), isValid)
            if iszero(isValid) {
                mstore(m, 0x90c9a2d0) // `checkDelegateForContract(address,address,address)`.
                isValid := staticcall(gas(), DELEGATE_REGISTRY_V1, add(m, 0x1c), 0x64, m, 0x20)
                isValid := and(eq(mload(m), 1), isValid)
            }
        }
    }

    /// @dev Returns if `to` is a delegate of `from` for the specified `contract_`.
    /// ```
    ///     v2.checkDelegateForContract(to, from, contract_, rights) ||
    ///     (rights == "" && v1.checkDelegateForContract(to, from, contract_))
    /// ```
    /// Returns true if `checkDelegateForAll(to, from, rights)` returns true.
    function checkDelegateForContract(address to, address from, address contract_, bytes32 rights)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(add(0x80, m), rights)
            mstore(add(0x60, m), contract_)
            mstore(add(0x4c, m), shl(96, from))
            mstore(add(0x2c, m), shl(96, to))
            // `checkDelegateForContract(address,address,address,bytes32)`.
            mstore(add(0x0c, m), 0x8988eea9000000000000000000000000)
            isValid := staticcall(gas(), DELEGATE_REGISTRY_V2, add(m, 0x1c), 0x84, m, 0x20)
            isValid := and(eq(mload(m), 1), isValid)
            if iszero(or(rights, isValid)) {
                mstore(m, 0x90c9a2d0) // `checkDelegateForContract(address,address,address)`.
                isValid := staticcall(gas(), DELEGATE_REGISTRY_V1, add(m, 0x1c), 0x64, m, 0x20)
                isValid := and(eq(mload(m), 1), isValid)
            }
        }
    }

    /// @dev Returns if `to` is a delegate of `from` for the specified `contract_` and token `id`.
    /// ```
    ///     v2.checkDelegateForERC721(to, from, contract_, id, "") ||
    ///     v1.checkDelegateForToken(to, from, contract_, id)
    /// ```
    /// Returns true if `checkDelegateForContract(to, from, contract_)` returns true.
    function checkDelegateForERC721(address to, address from, address contract_, uint256 id)
        internal
        view
        returns (bool isValid)
    {
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
            isValid := staticcall(gas(), DELEGATE_REGISTRY_V2, add(m, 0x1c), 0xa4, m, 0x20)
            isValid := and(eq(mload(m), 1), isValid)
            if iszero(isValid) {
                mstore(m, 0xaba69cf8) // `checkDelegateForToken(address,address,address,uint256)`.
                isValid := staticcall(gas(), DELEGATE_REGISTRY_V1, add(m, 0x1c), 0x84, m, 0x20)
                isValid := and(eq(mload(m), 1), isValid)
            }
        }
    }

    /// @dev Returns if `to` is a delegate of `from` for the specified `contract_` and token `id`.
    /// ```
    ///     v2.checkDelegateForERC721(to, from, contract_, id, rights) ||
    ///     (rights == "" && v1.checkDelegateForToken(to, from, contract_, id))
    /// ```
    /// Returns true if `checkDelegateForContract(to, from, contract_, rights)` returns true.
    function checkDelegateForERC721(
        address to,
        address from,
        address contract_,
        uint256 id,
        bytes32 rights
    ) internal view returns (bool isValid) {
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
            isValid := staticcall(gas(), DELEGATE_REGISTRY_V2, add(m, 0x1c), 0xa4, m, 0x20)
            isValid := and(eq(mload(m), 1), isValid)
            if iszero(or(rights, isValid)) {
                mstore(m, 0xaba69cf8) // `checkDelegateForToken(address,address,address,uint256)`.
                isValid := staticcall(gas(), DELEGATE_REGISTRY_V1, add(m, 0x1c), 0x84, m, 0x20)
                isValid := and(eq(mload(m), 1), isValid)
            }
        }
    }

    /// @dev Returns the amount of an ERC20 token for `contract_`
    /// that `to` is granted rights to act on the behalf of `from`.
    /// ```
    ///     max(
    ///         v2.checkDelegateForERC20(to, from, contract_, ""),
    ///         v1.checkDelegateForContract(to, from, contract_) ? type(uint256).max : 0
    ///     )
    /// ```
    /// Returns `type(uint256).max` if `checkDelegateForContract(to, from, contract_)` returns true.
    function checkDelegateForERC20(address to, address from, address contract_)
        internal
        view
        returns (uint256 amount)
    {
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
            amount := staticcall(gas(), DELEGATE_REGISTRY_V2, add(m, 0x1c), 0x84, o, 0x20)
            amount := mul(mload(o), amount)
            if not(amount) {
                mstore(m, 0x90c9a2d0) // `checkDelegateForContract(address,address,address)`.
                let t := staticcall(gas(), DELEGATE_REGISTRY_V1, add(m, 0x1c), 0x64, m, 0x20)
                amount := or(sub(0, and(eq(mload(m), 1), t)), amount)
            }
        }
    }

    /// @dev Returns the amount of an ERC20 token for `contract_`
    /// that `to` is granted rights to act on the behalf of `from`.
    /// ```
    ///     max(
    ///         v2.checkDelegateForERC20(to, from, contract_, rights),
    ///         (rights == "" && v1.checkDelegateForContract(to, from, contract_)) ? type(uint256).max : 0
    ///     )
    /// ```
    /// Returns `type(uint256).max` if `checkDelegateForContract(to, from, contract_, rights)` returns true.
    function checkDelegateForERC20(address to, address from, address contract_, bytes32 rights)
        internal
        view
        returns (uint256 amount)
    {
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
            amount := staticcall(gas(), DELEGATE_REGISTRY_V2, add(m, 0x1c), 0x84, 0x00, 0x20)
            amount := mul(mload(0x00), amount)
            if iszero(or(rights, iszero(not(amount)))) {
                mstore(m, 0x90c9a2d0) // `checkDelegateForContract(address,address,address)`.
                let t := staticcall(gas(), DELEGATE_REGISTRY_V1, add(m, 0x1c), 0x64, m, 0x20)
                amount := or(sub(0, and(eq(mload(m), 1), t)), amount)
            }
        }
    }

    /// @dev Returns the amount of an ERC1155 token `id` for `contract_`
    /// that `to` is granted rights to act on the behalf of `from`.
    /// ```
    ///     max(
    ///         v2.checkDelegateForERC1155(to, from, contract_, id, ""),
    ///         v1.checkDelegateForContract(to, from, contract_, id) ? type(uint256).max : 0
    ///     )
    /// ```
    /// Returns `type(uint256).max` if `checkDelegateForContract(to, from, contract_)` returns true.
    function checkDelegateForERC1155(address to, address from, address contract_, uint256 id)
        internal
        view
        returns (uint256 amount)
    {
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
            amount := staticcall(gas(), DELEGATE_REGISTRY_V2, add(m, 0x1c), 0xa4, o, 0x20)
            amount := mul(mload(o), amount)
            if not(amount) {
                mstore(m, 0x90c9a2d0) // `checkDelegateForContract(address,address,address)`.
                let t := staticcall(gas(), DELEGATE_REGISTRY_V1, add(m, 0x1c), 0x64, m, 0x20)
                amount := or(sub(0, and(eq(mload(m), 1), t)), amount)
            }
        }
    }

    /// @dev Returns the amount of an ERC1155 token `id` for `contract_`
    /// that `to` is granted rights to act on the behalf of `from`.
    /// ```
    ///     max(
    ///         v2.checkDelegateForERC1155(to, from, contract_, id, rights),
    ///         (rights == "" && v1.checkDelegateForContract(to, from, contract_, id)) ? type(uint256).max : 0
    ///     )
    /// ```
    /// Returns `type(uint256).max` if `checkDelegateForContract(to, from, contract_, rights)` returns true.
    function checkDelegateForERC1155(
        address to,
        address from,
        address contract_,
        uint256 id,
        bytes32 rights
    ) internal view returns (uint256 amount) {
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
            amount := staticcall(gas(), DELEGATE_REGISTRY_V2, add(m, 0x1c), 0xa4, 0x00, 0x20)
            amount := mul(mload(0x00), amount)
            if iszero(or(rights, iszero(not(amount)))) {
                mstore(m, 0x90c9a2d0) // `checkDelegateForContract(address,address,address)`.
                let t := staticcall(gas(), DELEGATE_REGISTRY_V1, add(m, 0x1c), 0x64, m, 0x20)
                amount := or(sub(0, and(eq(mload(m), 1), t)), amount)
            }
        }
    }
}
