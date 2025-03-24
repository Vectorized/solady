// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Library for EIP7702 operations.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/accounts/LibEIP7702.sol)
library LibEIP7702 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Failed to deploy the EIP7702 proxy.
    error DeploymentFailed();

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

    /// @dev The transient storage slot for requesting the proxy to initialize the implementation.
    /// `uint256(keccak256("eip7702.proxy.delegation.initialization.request")) - 1`.
    /// While we would love to use a smaller constant, this slot is used in both the proxy
    /// and the delegation, so we shall just use bytes32 in case we want to standardize this.
    bytes32 internal constant EIP7702_PROXY_DELEGATION_INITIALIZATION_REQUEST_SLOT =
        0x94e11c6e41e7fb92cb8bb65e13fdfbd4eba8b831292a1a220f7915c78c7c078f;

    /// @dev The runtime bytecode for the EIP7702Proxy, with immutables zeroized.
    /// See: https://gist.github.com/Vectorized/0a83937618a55b389e38a230da6d9531
    bytes internal constant EIP7702_PROXY_BYTECODE =
        hex"3d6040527f00000000000000000000000000000000000000000000000000000000000000007f00000000000000000000000000000000000000000000000000000000000000007f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc30831861011f573661007b5780543652602036f35b5f3560e01c80637dae87cb1481635c60da1b1417156100a55760205f5f36305afa156100a5573d5ff35b7fb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d610380548263f851a440036100db57805f5260205ff35b8033036101185760103560601c83638f283970036100ff5780835560015f5260205ff35b83630900f010036101165780855560015f5260205ff35b505b5050505f3dfd5b80543660010361015a578060601b61014c57826101495760205f5f36875afa61014457fe5b60205ff35b50815b8060601b60601c5f5260205ff35b365f5f378060601b6101d157826101ce576020365f36875afa5f5f365f36515af416610188573d5f5f3e3d5ffd5b7f94e11c6e41e7fb92cb8bb65e13fdfbd4eba8b831292a1a220f7915c78c7c078f805c156101c557365183546001600160a01b0319161783555f815d5b503d5f5f3e3d5ff35b50815b5f36365f845af46101e4573d5f5f3e3d5ffd5b50503d5f5f3e3d5ff3fea264697066735822122083f79db79e1d888dce9d6a6e069750bacafdfad774becb8ebfa8e7719225031464736f6c634300081c0033";

    /// @dev The creation code for the EIP7702Proxy.
    bytes internal constant EIP7702_PROXY_CREATION_CODE = abi.encodePacked(
        hex"60c060408190523060805261031738819003908190833981016040819052610026916100a3565b6001600160a01b039182167f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc81905591167fb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103819055811515110260a0526100d4565b80516001600160a01b038116811461009e575f5ffd5b919050565b5f5f604083850312156100b4575f5ffd5b6100bd83610088565b91506100cb60208401610088565b90509250929050565b60805160a0516102246100f35f395f602601525f600501526102245ff3fe",
        EIP7702_PROXY_BYTECODE
    );

    /// @dev The keccak256 of deployed code for the EIP7702Proxy, with immutables zeroized.
    bytes32 internal constant EIP7702_PROXY_CODE_HASH = keccak256(EIP7702_PROXY_BYTECODE);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    AUTHORITY OPERATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the delegation of the account.
    /// If the account is not an EIP7702 authority, returns `address(0)`.
    function delegation(address account) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            extcodecopy(account, 0x00, 0x00, 0x20)
            // Note: Checking that it starts with hex"ef01" is the most general and futureproof.
            // 7702 bytecode is `abi.encodePacked(hex"ef01", uint8(version), address(delegation))`.
            result := mul(shr(96, mload(0x03)), eq(0xef01, shr(240, mload(0x00))))
        }
    }

    /// @dev Returns the delegation and the implementation of the account.
    /// If the account delegation is not a valid EIP7702Proxy, returns `address(0)`.
    function delegationAndImplementation(address account)
        internal
        view
        returns (address accountDelegation, address implementation)
    {
        accountDelegation = delegation(account);
        bytes32 codeHash = EIP7702_PROXY_CODE_HASH;
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            extcodecopy(accountDelegation, m, 0x00, 0x224) // The expected runtime bytecode is 548 bytes.
            // Zeroize the immutables.
            mstore(add(m, 0x05), 0)
            mstore(add(m, 0x26), 0)
            if eq(keccak256(m, 0x224), codeHash) {
                mstore(0x00, 0)
                if staticcall(gas(), account, 0x00, 0x01, 0x00, 0x20) {
                    implementation := mload(0x00)
                }
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PROXY OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the initialization code for the EIP7702Proxy.
    function proxyInitCode(address initialImplementation, address initialAdmin)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            EIP7702_PROXY_CREATION_CODE, abi.encode(initialImplementation, initialAdmin)
        );
    }

    /// @dev Deploys an EIP7702Proxy.
    function deployProxy(address initialImplementation, address initialAdmin)
        internal
        returns (address instance)
    {
        bytes memory initCode = proxyInitCode(initialImplementation, initialAdmin);
        /// @solidity memory-safe-assembly
        assembly {
            instance := create(0, add(initCode, 0x20), mload(initCode))
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Deploys an EIP7702Proxy to a deterministic address with `salt`.
    function deployProxyDeterministic(
        address initialImplementation,
        address initialAdmin,
        bytes32 salt
    ) internal returns (address instance) {
        bytes memory initCode = proxyInitCode(initialImplementation, initialAdmin);
        /// @solidity memory-safe-assembly
        assembly {
            instance := create2(0, add(initCode, 0x20), mload(initCode), salt)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

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
            mstore(0x20, newAdmin) // The implementation will clean the upper 96 bits.
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
            mstore(0x20, newImplementation) // The implementation will clean the upper 96 bits.
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
            let s := ERC1967_IMPLEMENTATION_SLOT
            // Preserve the upper 96 bits when updating in case they are used for some stuff.
            mstore(0x00, sload(s))
            mstore(0x0c, shl(96, newImplementation))
            sstore(s, mload(0x00))
        }
    }

    /// @dev Requests the implementation to be initialized to the latest implementation on the proxy.
    /// This function is intended to be used on the authority of an EIP7702Proxy delegation.
    /// The most intended usage pattern is to place it at the end of an `execute` function.
    function requestProxyDelegationInitialization() internal {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(shl(96, sload(ERC1967_IMPLEMENTATION_SLOT))) {
                // Use a dedicated transient storage slot for better Swiss-cheese-model safety.
                tstore(EIP7702_PROXY_DELEGATION_INITIALIZATION_REQUEST_SLOT, address())
            }
        }
    }
}
