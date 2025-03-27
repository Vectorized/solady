// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Library for EIP7702 operations.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/accounts/LibEIP7702.sol)
library LibEIP7702 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Failed to deploy the EIP7702Proxy.
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

    /// @dev The creation code for the EIP7702Proxy.
    /// This is generated from `EIP7702Proxy.sol` with exact compilation settings.
    bytes internal constant EIP7702_PROXY_CREATION_CODE =
        hex"60c060408190523060805261031138819003908190833981016040819052610026916100a3565b6001600160a01b039182167f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc81905591167fb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103819055811515110260a0526100d4565b80516001600160a01b038116811461009e575f5ffd5b919050565b5f5f604083850312156100b4575f5ffd5b6100bd83610088565b91506100cb60208401610088565b90509250929050565b60805160a05161021e6100f35f395f602601525f6005015261021e5ff3fe3d6040527f00000000000000000000000000000000000000000000000000000000000000007f00000000000000000000000000000000000000000000000000000000000000007f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc308318610119576001361161007e5780543652602036f35b5f3560e01c80635c60da1b0361009f5760205f5f36305afa1561009f573d5ff35b7fb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d610380548263f851a440036100d557805f5260205ff35b8033036101125760103560601c83638f283970036100f95780835560015f5260205ff35b83630900f010036101105780855560015f5260205ff35b505b5050505f3dfd5b805436600103610154578060601b61014657826101435760205f5f36875afa61013e57fe5b60205ff35b50815b8060601b60601c5f5260205ff35b365f5f378060601b6101cb57826101c8576020365f36875afa5f5f365f36515af416610182573d5f5f3e3d5ffd5b7f94e11c6e41e7fb92cb8bb65e13fdfbd4eba8b831292a1a220f7915c78c7c078f805c156101bf57365183546001600160a01b0319161783555f815d5b503d5f5f3e3d5ff35b50815b5f36365f845af46101de573d5f5f3e3d5ffd5b50503d5f5f3e3d5ff3fea2646970667358221220ad810cb1d8296ebd4649785ecb093c978531e8ae483468cdb56d4856d522f99464736f6c634300081c0033";

    /// @dev The keccak256 of runtime code for `EIP7702Proxy.sol` with exact compilation settings,
    /// with immutables zeroized and without the CBOR metadata.
    bytes32 internal constant EIP7702_PROXY_MINIMAL_CODE_HASH =
        0x7386c2810632fa8ea702ec3b7b0ad8fe514f063d42915830c6dd30abd543082e;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               AUTHORITY AND PROXY OPERATIONS               */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the delegation of the account.
    /// If the account is not an EIP7702 authority, returns `address(0)`.
    function delegationOf(address account) internal view returns (address result) {
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
    function delegationAndImplementationOf(address account)
        internal
        view
        returns (address delegation, address implementation)
    {
        delegation = delegationOf(account);
        if (isEIP7702Proxy(delegation)) {
            /// @solidity memory-safe-assembly
            assembly {
                mstore(0x00, 0)
                if iszero(staticcall(gas(), account, 0x00, 0x01, 0x00, 0x20)) { revert(0x00, 0x00) }
                implementation := mload(0x00)
            }
        }
    }

    /// @dev Returns the implementation of `target`.
    /// If `target` is neither an EIP7702Proxy nor an EOA delegated to an EIP7702Proxy, returns `address(0)`.
    function implementationOf(address target) internal view returns (address result) {
        if (!isEIP7702Proxy(target)) if (!isEIP7702Proxy(delegationOf(target))) return address(0);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0)
            if iszero(staticcall(gas(), target, 0x00, 0x01, 0x00, 0x20)) { revert(0x00, 0x00) }
            result := mload(0x00)
        }
    }

    /// @dev Returns if `target` is an valid EIP7702Proxy based on a bytecode hash check.
    function isEIP7702Proxy(address target) internal view returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            // Copy the runtime bytecode without the CBOR metadata.
            extcodecopy(target, m, 0x00, 0x1e8)
            // Zeroize the immutables.
            mstore(add(m, 0x05), 0)
            mstore(add(m, 0x26), 0)
            result := eq(keccak256(m, 0x1e8), EIP7702_PROXY_MINIMAL_CODE_HASH)
        }
    }

    /// @dev Returns the initialization code for the EIP7702Proxy.
    function proxyInitCode(address initialImplementation, address initialAdmin)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            EIP7702_PROXY_CREATION_CODE,
            uint256(uint160(initialImplementation)),
            uint256(uint160(initialAdmin))
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
    /*                      UUPS OPERATIONS                       */
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
