// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for efficient querying of the delegate registries.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ext/delegate/DelegateCheckerLib.sol)
library DelegateCheckerLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The canonical elegate registry V1.
    /// See: https://etherscan.io/address/0x00000000000076a84fef008cdabe6409d2fe638b
    address internal constant DELEGATE_REGISTRY_V1 = 0x00000000000076A84feF008CDAbe6409d2FE638B;

    /// @dev The canonical elegate registry V2.
    /// See: https://etherscan.io/address/0x00000000000000447e69651d841bD8D104Bed493
    address internal constant DELEGATE_REGISTRY_V2 = 0x00000000000000447e69651d841bD8D104Bed493;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                DELEGATE CHECKING OPERATIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Note:
    // - `to` is the delegate. Typically called the "hot wallet".
    // - `from` is the grantor of the delegate. Typically called the "cold vault".
    // - For token authorization checks (ERC721, ERC20, ERC1155),
    //   both factories fallback to `checkDelegateForContract` checks.
    //   For delegated quantity queries (ERC20, ERC1155), this returns
    //   the maximum uint256 amount if the fallback returns true.
    // - For contract authorization checks, both factories fallback to
    //   `checkDelegateForAll` checks.

    /// @dev Returns if `to` is a delegate of `from`.
    /// ```
    ///     v2.checkDelegateForAll(to, from, "") ||
    ///     v1.checkDelegateForAll(to, from)
    /// ```
    function checkDelegateForAll(address to, address from) internal view returns (bool isValid) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(0x00, 0xe839bd53) // `checkDelegateForAll(address,address,bytes32)`.
            mstore(0x20, shr(96, shl(96, to)))
            mstore(0x40, shr(96, shl(96, from)))
            // `0x60` is already 0.
            isValid :=
                and(eq(mload(0x00), 1), staticcall(gas(), DELEGATE_REGISTRY_V2, 0x1c, 0x64, 0x00, 0x20))
            if iszero(isValid) {
                mstore(0x00, 0x9c395bc2) // `checkDelegateForAll(address,address)`.
                isValid :=
                    and(
                        eq(mload(0x00), 1),
                        staticcall(gas(), DELEGATE_REGISTRY_V1, 0x1c, 0x44, 0x00, 0x20)
                    )
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
            mstore(0x00, 0xe839bd53) // `checkDelegateForAll(address,address,bytes32)`.
            mstore(0x20, shr(96, shl(96, to)))
            mstore(0x40, shr(96, shl(96, from)))
            mstore(0x60, rights)
            isValid :=
                and(eq(mload(0x00), 1), staticcall(gas(), DELEGATE_REGISTRY_V2, 0x1c, 0x64, 0x00, 0x20))
            if iszero(or(rights, isValid)) {
                mstore(0x00, 0x9c395bc2) // `checkDelegateForAll(address,address)`.
                isValid :=
                    and(
                        eq(mload(0x00), 1),
                        staticcall(gas(), DELEGATE_REGISTRY_V1, 0x1c, 0x44, 0x00, 0x20)
                    )
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
    function checkDelegateForContract(address to, address from, address contract_)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, 0x8988eea9) // `checkDelegateForContract(address,address,address,bytes32)`.
            let addressMask := shr(96, not(0))
            mstore(add(0x20, m), and(addressMask, to))
            mstore(add(0x40, m), and(addressMask, from))
            mstore(add(0x60, m), and(addressMask, contract_))
            mstore(add(0x80, m), 0)
            isValid :=
                and(
                    eq(mload(m), 1),
                    staticcall(gas(), DELEGATE_REGISTRY_V2, add(m, 0x1c), 0x84, m, 0x20)
                )
            if iszero(isValid) {
                mstore(m, 0x90c9a2d0) // `checkDelegateForContract(address,address,address)`.
                isValid :=
                    and(
                        eq(mload(m), 1),
                        staticcall(gas(), DELEGATE_REGISTRY_V1, add(m, 0x1c), 0x64, m, 0x20)
                    )
            }
        }
    }

    /// @dev Returns if `to` is a delegate of `from` for the specified `contract_`.
    /// ```
    ///     v2.checkDelegateForContract(to, from, contract_, rights) ||
    ///     (rights == "" && v1.checkDelegateForContract(to, from, contract_))
    /// ```
    function checkDelegateForContract(address to, address from, address contract_, bytes32 rights)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, 0x8988eea9) // `checkDelegateForContract(address,address,address,bytes32)`.
            let addressMask := shr(96, not(0))
            mstore(add(0x20, m), and(addressMask, to))
            mstore(add(0x40, m), and(addressMask, from))
            mstore(add(0x60, m), and(addressMask, contract_))
            mstore(add(0x80, m), rights)
            isValid :=
                and(
                    eq(mload(m), 1),
                    staticcall(gas(), DELEGATE_REGISTRY_V2, add(m, 0x1c), 0x84, m, 0x20)
                )
            if iszero(or(rights, isValid)) {
                mstore(m, 0x90c9a2d0) // `checkDelegateForContract(address,address,address)`.
                isValid :=
                    and(
                        eq(mload(m), 1),
                        staticcall(gas(), DELEGATE_REGISTRY_V1, add(m, 0x1c), 0x64, m, 0x20)
                    )
            }
        }
    }

    /// @dev Returns if `to` is a delegate of `from` for the specified `contract_` and token `id`.
    /// ```
    ///     v2.checkDelegateForERC721(to, from, contract_, id, "") ||
    ///     v1.checkDelegateForToken(to, from, contract_, id)
    /// ```
    function checkDelegateForERC721(address to, address from, address contract_, uint256 id)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, 0xb9f36874) // `checkDelegateForERC721(address,address,address,uint256,bytes32)`.
            let addressMask := shr(96, not(0))
            mstore(add(0x20, m), and(addressMask, to))
            mstore(add(0x40, m), and(addressMask, from))
            mstore(add(0x60, m), and(addressMask, contract_))
            mstore(add(0x80, m), id)
            mstore(add(0xa0, m), 0)
            isValid :=
                and(
                    eq(mload(m), 1),
                    staticcall(gas(), DELEGATE_REGISTRY_V2, add(m, 0x1c), 0xa4, m, 0x20)
                )
            if iszero(isValid) {
                mstore(m, 0xaba69cf8) // `checkDelegateForToken(address,address,address,uint256)`.
                isValid :=
                    and(
                        eq(mload(m), 1),
                        staticcall(gas(), DELEGATE_REGISTRY_V1, add(m, 0x1c), 0x84, m, 0x20)
                    )
            }
        }
    }

    /// @dev Returns if `to` is a delegate of `from` for the specified `contract_` and token `id`.
    /// ```
    ///     v2.checkDelegateForERC721(to, from, contract_, id, rights) ||
    ///     (rights == "" && v1.checkDelegateForToken(to, from, contract_, id))
    /// ```
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
            mstore(m, 0xb9f36874) // `checkDelegateForERC721(address,address,address,uint256,bytes32)`.
            let addressMask := shr(96, not(0))
            mstore(add(0x20, m), and(addressMask, to))
            mstore(add(0x40, m), and(addressMask, from))
            mstore(add(0x60, m), and(addressMask, contract_))
            mstore(add(0x80, m), id)
            mstore(add(0xa0, m), rights)
            isValid :=
                and(
                    eq(mload(m), 1),
                    staticcall(gas(), DELEGATE_REGISTRY_V2, add(m, 0x1c), 0xa4, m, 0x20)
                )
            if iszero(or(rights, isValid)) {
                mstore(m, 0xaba69cf8) // `checkDelegateForToken(address,address,address,uint256)`.
                isValid :=
                    and(
                        eq(mload(m), 1),
                        staticcall(gas(), DELEGATE_REGISTRY_V1, add(m, 0x1c), 0x84, m, 0x20)
                    )
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
    function checkDelegateForERC20(address to, address from, address contract_)
        internal
        view
        returns (uint256 amount)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, 0xba63c817) // `checkDelegateForERC20(address,address,address,bytes32)`.
            let addressMask := shr(96, not(0))
            mstore(add(0x20, m), and(addressMask, to))
            mstore(add(0x40, m), and(addressMask, from))
            mstore(add(0x60, m), and(addressMask, contract_))
            mstore(add(0x80, m), 0)
            amount :=
                mul(
                    mload(m),
                    and(
                        gt(returndatasize(), 0x1f),
                        staticcall(gas(), DELEGATE_REGISTRY_V2, add(m, 0x1c), 0x84, m, 0x20)
                    )
                )
            if not(amount) {
                mstore(m, 0x90c9a2d0) // `checkDelegateForContract(address,address,address)`.
                let t := staticcall(gas(), DELEGATE_REGISTRY_V1, add(m, 0x1c), 0x64, m, 0x20)
                amount := sub(0, and(eq(mload(m), 1), t))
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
    function checkDelegateForERC20(address to, address from, address contract_, bytes32 rights)
        internal
        view
        returns (uint256 amount)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, 0xba63c817) // `checkDelegateForERC20(address,address,address,bytes32)`.
            let addressMask := shr(96, not(0))
            mstore(add(0x20, m), and(addressMask, to))
            mstore(add(0x40, m), and(addressMask, from))
            mstore(add(0x60, m), and(addressMask, contract_))
            mstore(add(0x80, m), rights)
            amount :=
                mul(
                    mload(m),
                    and(
                        gt(returndatasize(), 0x1f),
                        staticcall(gas(), DELEGATE_REGISTRY_V2, add(m, 0x1c), 0x84, m, 0x20)
                    )
                )
            if iszero(or(rights, iszero(not(amount)))) {
                mstore(m, 0x90c9a2d0) // `checkDelegateForContract(address,address,address)`.
                let t := staticcall(gas(), DELEGATE_REGISTRY_V1, add(m, 0x1c), 0x64, m, 0x20)
                amount := sub(0, and(eq(mload(m), 1), t))
            }
        }
    }

    /// @dev Returns the amount of an ERC1155 token `id` for `contract_`
    /// that `to` is granted rights to act on the behalf of `from`.
    /// ```
    ///     max(
    ///         v2.checkDelegateForERC1155(to, from, contract_, id, rights),
    ///         v1.checkDelegateForContract(to, from, contract_, id) ? type(uint256).max : 0
    ///     )
    /// ```
    function checkDelegateForERC1155(address to, address from, address contract_, uint256 id)
        internal
        view
        returns (uint256 amount)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, 0xb8705875) // `checkDelegateForERC1155(address,address,address,uint256,bytes32)`.
            let addressMask := shr(96, not(0))
            mstore(add(0x20, m), and(addressMask, to))
            mstore(add(0x40, m), and(addressMask, from))
            mstore(add(0x60, m), and(addressMask, contract_))
            mstore(add(0x80, m), id)
            mstore(add(0xa0, m), 0)
            amount :=
                mul(
                    mload(m),
                    and(
                        gt(returndatasize(), 0x1f),
                        staticcall(gas(), DELEGATE_REGISTRY_V2, add(m, 0x1c), 0xa4, m, 0x20)
                    )
                )
            if not(amount) {
                mstore(m, 0x90c9a2d0) // `checkDelegateForContract(address,address,address)`.
                let t := staticcall(gas(), DELEGATE_REGISTRY_V1, add(m, 0x1c), 0x64, m, 0x20)
                amount := sub(0, and(eq(mload(m), 1), t))
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
            mstore(m, 0xb8705875) // `checkDelegateForERC1155(address,address,address,uint256,bytes32)`.
            let addressMask := shr(96, not(0))
            mstore(add(0x20, m), and(addressMask, to))
            mstore(add(0x40, m), and(addressMask, from))
            mstore(add(0x60, m), and(addressMask, contract_))
            mstore(add(0x80, m), id)
            mstore(add(0xa0, m), rights)
            amount :=
                mul(
                    mload(m),
                    and(
                        gt(returndatasize(), 0x1f),
                        staticcall(gas(), DELEGATE_REGISTRY_V2, add(m, 0x1c), 0xa4, m, 0x20)
                    )
                )
            if iszero(or(rights, iszero(not(amount)))) {
                mstore(m, 0x90c9a2d0) // `checkDelegateForContract(address,address,address)`.
                let t := staticcall(gas(), DELEGATE_REGISTRY_V1, add(m, 0x1c), 0x64, m, 0x20)
                amount := sub(0, and(eq(mload(m), 1), t))
            }
        }
    }
}
