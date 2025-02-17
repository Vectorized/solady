// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for EIP7702 operations.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/accounts/LibEIP7702.sol)
library LibEIP7702 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The proxy query has failed.
    error ProxyQueryFailed();

    /// @dev Failed to change the proxy admin.
    error ChangeProxyAdminFailed();

    /// @dev Failed to upgrade the proxy.
    error UpgradeProxyFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ERC-1967 storage slot for the implementation in the proxy.
    /// `uint256(keccak256("eip1967.proxy.implementation")) - 1`.
    bytes32 internal constant ERC1967_IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    AUTHORITY OPERATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the delegation of the account.
    /// If the account is not an EIP7702 authority, the `delegation` will be `address(0)`.
    function delegation(address account) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            extcodecopy(account, 0x00, 0x00, 0x20)
            // Note: checking that it starts with hex"ef01" is the most general and futureproof.
            // 7702 bytecode is `abi.encodePacked(hex"ef01", uint8(version), address(delegation))`.
            result := mul(shr(96, mload(0x03)), eq(0xef01, shr(240, mload(0x00))))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PROXY OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the implementation of the proxy.
    /// Assumes that the proxy is a proper EIP7702Proxy, if it exists.
    function proxyImplementation(address proxy) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Although `implementation()` is supported, we'll use a less common
            // function selector to avoid accidental collision with other delegations.
            mstore(0x00, 0x7dae87cb) // `eip7702ProxyImplementation()`.
            let t := staticcall(gas(), proxy, 0x1c, 0x04, 0x00, 0x20)
            if iszero(and(gt(returndatasize(), 0x1f), t)) {
                mstore(0x00, 0x26ec9b6a) // `ProxyQueryFailed()`.
                revert(0x1c, 0x04)
            }
            result := mload(0x00)
        }
    }

    /// @dev Returns the admin of the proxy.
    /// Assumes that the proxy is a proper EIP7702Proxy, if it exists.
    function proxyAdmin(address proxy) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0xf851a440) // `admin()`.
            let t := staticcall(gas(), proxy, 0x1c, 0x04, 0x00, 0x20)
            if iszero(and(gt(returndatasize(), 0x1f), t)) {
                mstore(0x00, 0x26ec9b6a) // `ProxyQueryFailed()`.
                revert(0x1c, 0x04)
            }
            result := mload(0x00)
        }
    }

    /// @dev Changes the admin on the proxy. The caller must be the admin.
    /// Assumes that the proxy is a proper EIP7702Proxy, if it exists.
    function changeProxyAdmin(address proxy, address newAdmin) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x8f283970) // `changeAdmin(address)`.
            mstore(0x20, shr(96, shl(96, newAdmin)))
            if iszero(and(eq(mload(0x00), 1), call(gas(), proxy, 0, 0x1c, 0x24, 0x00, 0x20))) {
                mstore(0x00, 0xc502e37e) // `ChangeProxyAdminFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Changes the implementation on the proxy. The caller must be the admin.
    /// Assumes that the proxy is a proper EIP7702Proxy, if it exists.
    function upgradeProxy(address proxy, address newImplementation) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x0900f010) // `upgrade(address)`.
            mstore(0x20, shr(96, shl(96, newImplementation)))
            if iszero(and(eq(mload(0x00), 1), call(gas(), proxy, 0, 0x1c, 0x24, 0x00, 0x20))) {
                mstore(0x00, 0xc6edd882) // `UpgradeProxyFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                PROXY DELEGATION OPERATIONS                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Upgrades the implementation.
    /// The new implementation will NOT be active until the next UserOp or transaction.
    /// To "auto-upgrade" to the latest implementation on the proxy, pass in `address(0)` to reset
    /// the implementation slot. This causes the proxy to use the latest default implementation,
    /// which may be optionally reinitialized via `requestProxyDelegationInitialization()`.
    /// This function is intended to be used on the authority of an EIP7702Proxy delegation.
    /// The most intended usage pattern is to wrap this in an access-gated admin function.
    function upgradeProxyDelegation(address newImplementation) internal {
        /// @solidity memory-safe-assembly
        assembly {
            sstore(ERC1967_IMPLEMENTATION_SLOT, shr(96, shl(96, newImplementation)))
        }
    }

    /// @dev Requests the implementation to be initialized to the latest implementation on the proxy.
    /// This function is intended to be used on the authority of an EIP7702Proxy delegation.
    /// The most intended usage pattern is to place it at the end of an `execute` function.
    function requestProxyDelegationInitialization() internal {
        /// @solidity memory-safe-assembly
        assembly {
            let implSlot := ERC1967_IMPLEMENTATION_SLOT
            if iszero(sload(implSlot)) { sstore(implSlot, implSlot) }
        }
    }
}
