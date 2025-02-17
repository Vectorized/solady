// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for EIP7702 operations.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/accounts/LibEIP7702.sol)
library LibEIP7702 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Failed to perform the proxy query.
    error ProxyQueryFailed();

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
    function proxyImplementation(address proxy) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(mul(returndatasize(), staticcall(gas(), proxy, 0x00, 0x00, 0x00, 0x20))) {
                mstore(0x00, 0x26ec9b6a) // `ProxyQueryFailed()`.
                revert(0x1c, 0x04)
            }
            result := mload(0x00)
        }
    }

    /// @dev Returns the admin of the proxy.
    function proxyAdmin(address proxy) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0xf851a440) // `admin()`.
            if iszero(mul(returndatasize(), staticcall(gas(), proxy, 0x1c, 0x04, 0x00, 0x20))) {
                mstore(0x00, 0x26ec9b6a) // `ProxyQueryFailed()`.
                revert(0x1c, 0x04)
            }
            result := mload(0x00)
        }
    }

    /// @dev Changes the admin on the proxy. The caller must be the admin.
    function changeProxyAdmin(address proxy, address newAdmin) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x8f283970) // `changeAdmin(address)`.
            mstore(0x20, shr(96, shl(96, newAdmin)))
            if iszero(and(eq(mload(0x00), 1), call(gas(), proxy, 0, 0x1c, 0x24, 0x00, 0x20))) {
                mstore(0x00, 0x26ec9b6a) // `ProxyQueryFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Changes the implementation on the proxy. The caller must be the admin.
    function upgradeProxy(address proxy, address newImplementation) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x0900f010) // `upgrade(address)`.
            mstore(0x20, shr(96, shl(96, newImplementation)))
            if iszero(and(eq(mload(0x00), 1), call(gas(), proxy, 0, 0x1c, 0x24, 0x00, 0x20))) {
                mstore(0x00, 0x26ec9b6a) // `ProxyQueryFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                PROXY DELEGATION OPERATIONS                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Upgrades the implementation to the latest implementation on the proxy.
    /// To be used by delegation implementations pointed to by an EIP7702Proxy.
    function upgradeToLatestProxyDelegation() internal {
        address proxy = delegation(address(this));
        if (proxy != address(0)) {
            upgradeProxyDelegation(proxyImplementation(proxy));
        }
    }

    /// @dev Upgrades the implementation.
    /// To be used by delegation implementations pointed to by an EIP7702Proxy.
    function upgradeProxyDelegation(address newImplementation) internal {
        /// @solidity memory-safe-assembly
        assembly {
            sstore(ERC1967_IMPLEMENTATION_SLOT, shr(96, shl(96, newImplementation)))
        }
    }

    /// @dev Requests the implementation to be initialized to the latest implementation on the proxy.
    /// To be used by delegation implementations pointed to by an EIP7702Proxy.
    function requestProxyDelegationInitialization() internal {
        /// @solidity memory-safe-assembly
        assembly {
            let implSlot := ERC1967_IMPLEMENTATION_SLOT
            if iszero(sload(implSlot)) { sstore(implSlot, implSlot) }
        }
    }
}
