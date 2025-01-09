// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ZKsyncERC1967Proxy} from "./ZKsyncERC1967Proxy.sol";
import {ZKsyncUpgradeableBeacon} from "./ZKsyncUpgradeableBeacon.sol";
import {ZKsyncERC1967BeaconProxy} from "./ZKsyncERC1967BeaconProxy.sol";

/// @notice A factory for deploying minimal ERC1967 proxies on ZKsync.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ext/zksync/ZKsyncERC1967Factory.sol)
contract ZKsyncERC1967Factory {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The caller is not authorized to call the function.
    error Unauthorized();

    /// @dev The proxy deployment failed.
    error DeploymentFailed();

    /// @dev The upgrade failed.
    error UpgradeFailed();

    /// @dev The salt does not start with the caller.
    error SaltDoesNotStartWithCaller();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The admin of a `instance` has been changed. Applies to both proxies and beacons.
    event AdminChanged(address indexed instance, address indexed admin);

    /// @dev The implementation for `instance` has been upgraded. Applies to both proxies and beacons.
    event Upgraded(address indexed instance, address indexed implementation);

    /// @dev A proxy has been deployed.
    event ProxyDeployed(
        address indexed proxy, address indexed implementation, address indexed admin
    );

    /// @dev A beacon has been deployed.
    event BeaconDeployed(
        address indexed beacon, address indexed implementation, address indexed admin
    );

    /// @dev A beacon proxy has been deployed.
    event BeaconProxyDeployed(address indexed beaconProxy, address indexed beacon);

    /// @dev `keccak256(bytes("AdminChanged(address,address)"))`.
    uint256 internal constant _ADMIN_CHANGED_EVENT_SIGNATURE =
        0x7e644d79422f17c01e4894b5f4f588d331ebfa28653d42ae832dc59e38c9798f;

    /// @dev `keccak256(bytes("Upgraded(address,address)"))`.
    uint256 internal constant _UPGRADED_EVENT_SIGNATURE =
        0x5d611f318680d00598bb735d61bacf0c514c6b50e1e5ad30040a4df2b12791c7;

    /// @dev `keccak256(bytes("ProxyDeployed(address,address,address)"))`.
    uint256 internal constant _PROXY_DEPLOYED_EVENT_SIGNATURE =
        0x9e0862c4ebff2150fbbfd3f8547483f55bdec0c34fd977d3fccaa55d6c4ce784;

    /// @dev `keccak256(bytes("BeaconDeployed(address,address,address)"))`.
    uint256 internal constant _BEACON_DEPLOYED_EVENT_SIGNATURE =
        0xf53ff7c8fa39204521b1e348ab2a7ad0397471eefade072522e79552bf633726;

    /// @dev `keccak256(bytes("BeaconProxyDeployed(address,address)"))`.
    uint256 internal constant _BEACON_PROXY_DEPLOYED_EVENT_SIGNATURE =
        0xfa8e336138457120a1572efbe25f72698abd5cca1c9be0bce42ad406ff350a2b;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The hash of the proxy.
    bytes32 public constant PROXY_HASH =
        0x01000041235eb6c6e003c5e0191695f009ed2590e899a662cb693bf85e8fb022;

    /// @dev The hash of the upgradeable beacon.
    bytes32 public constant BEACON_HASH =
        0x0100001901442d36d6e35ba0454223ed52727c75cb12e9646ea46ee78a24ae62;

    /// @dev The hash of the beacon proxy.
    bytes32 public constant BEACON_PROXY_HASH =
        0x0100004dd6ba616b61acec35fbf9874af5fbc2691cfba34f6f47877ac601955a;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ADMIN FUNCTIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the admin of the `instance`.
    /// Returns `address(0)` if `instance` is a beacon proxy.
    /// Works for both proxies and beacons.
    function adminOf(address instance) public view returns (address admin) {
        /// @solidity memory-safe-assembly
        assembly {
            admin := sload(instance)
        }
    }

    /// @dev Sets the admin of the `instance`.
    /// The caller of this function must be the admin of `instance`.
    /// Works for both proxies and beacons.
    function changeAdmin(address instance, address admin) public {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(eq(sload(instance), caller())) {
                mstore(0x00, 0x82b42900) // `Unauthorized()`.
                revert(0x1c, 0x04)
            }
            sstore(instance, admin)
            // Emit the {AdminChanged} event.
            log3(0x00, 0x00, _ADMIN_CHANGED_EVENT_SIGNATURE, instance, admin)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     UPGRADE FUNCTIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Upgrades `instance` to point to `implementation`.
    /// The caller of this function must be the admin of `instance`.
    /// Works for both proxies and beacons.
    function upgrade(address instance, address implementation) public payable {
        upgradeAndCall(instance, implementation, _emptyData());
    }

    /// @dev Upgrades `instance` to point to `implementation`.
    /// Then, calls it with abi encoded `data`.
    /// The caller of this function must be the admin of `instance`.
    /// Works for both proxies and beacons.
    function upgradeAndCall(address instance, address implementation, bytes calldata data)
        public
        payable
    {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(eq(sload(instance), caller())) {
                mstore(0x00, 0x82b42900) // `Unauthorized()`.
                revert(0x1c, 0x04)
            }
            let m := mload(0x40)
            mstore(m, implementation)
            calldatacopy(add(m, 0x20), data.offset, data.length)
            if iszero(call(gas(), instance, callvalue(), m, add(0x20, data.length), 0x00, 0x00)) {
                if iszero(returndatasize()) {
                    mstore(0x00, 0x55299b49) // `UpgradeFailed()`.
                    revert(0x1c, 0x04)
                }
                returndatacopy(0x00, 0x00, returndatasize())
                revert(0x00, returndatasize())
            }
            // Emit the {Upgraded} event.
            log3(0x00, 0x00, _UPGRADED_EVENT_SIGNATURE, instance, implementation)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PROXY DEPLOYMENT                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys a proxy for `implementation`, with `admin`, and returns its address.
    /// The value passed into this function will be forwarded to the proxu.
    function deployProxy(address implementation, address admin) public payable returns (address) {
        return deployProxyAndCall(implementation, admin, _emptyData());
    }

    /// @dev Deploys a proxy for `implementation`, with `admin`, and returns its address.
    /// The value passed into this function will be forwarded to the proxu.
    /// Then, calls the proxy with abi encoded `data`.
    function deployProxyAndCall(address implementation, address admin, bytes calldata data)
        public
        payable
        returns (address)
    {
        return _deploy(0, uint160(implementation), uint160(admin), "", 0, data);
    }

    /// @dev Deploys a proxy for `implementation`, with `admin`, `salt`,
    /// and returns its deterministic address.
    /// The value passed into this function will be forwarded to the proxy.
    function deployProxyDeterministic(address implementation, address admin, bytes32 salt)
        public
        payable
        returns (address)
    {
        return deployProxyDeterministicAndCall(implementation, admin, salt, _emptyData());
    }

    /// @dev Deploys a proxy for `implementation`, with `admin`, `salt`,
    /// and returns its deterministic address.
    /// The value passed into this function will be forwarded to the proxy.
    /// Then, calls the proxy with abi encoded `data`.
    function deployProxyDeterministicAndCall(
        address implementation,
        address admin,
        bytes32 salt,
        bytes calldata data
    ) public payable returns (address) {
        return _deploy(0, uint160(implementation), uint160(admin), salt, 1, data);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     BEACON DEPLOYMENT                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys a beacon with `implementation` and `admin`, and returns its address.
    function deployBeacon(address implementation, address admin) public returns (address) {
        return _deploy(1, uint160(implementation), uint160(admin), "", 0, _emptyData());
    }

    /// @dev Deploys a beacon with `implementation` and `admin`, with `salt`,
    /// and returns its deterministic address.
    function deployBeaconDeterministic(address implementation, address admin, bytes32 salt)
        public
        payable
        returns (address)
    {
        return _deploy(1, uint160(implementation), uint160(admin), salt, 1, _emptyData());
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  BEACON PROXY DEPLOYMENT                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys a beacon proxy referring to `beacon`, and returns its address.
    /// The value passed into this function will be forwarded to the beacon proxy.
    function deployBeaconProxy(address beacon) public payable returns (address) {
        return deployBeaconProxyAndCall(beacon, _emptyData());
    }

    /// @dev Deploys a beacon proxy referring to `beacon`, and returns its address.
    /// The value passed into this function will be forwarded to the beacon proxy.
    /// Then, calls the beacon proxy with abi encoded `data`.
    function deployBeaconProxyAndCall(address beacon, bytes calldata data)
        public
        payable
        returns (address)
    {
        return _deploy(2, uint160(beacon), 0, "", 0, data);
    }

    /// @dev Deploys a beacon proxy referring to `beacon`, with `salt`,
    /// and returns its deterministic address.
    /// The value passed into this function will be forwarded to the beacon proxy.
    function deployBeaconProxyDeterministic(address beacon, bytes32 salt)
        public
        payable
        returns (address)
    {
        return deployBeaconProxyDeterministicAndCall(beacon, salt, _emptyData());
    }

    /// @dev Deploys a beacon proxy referring to `beacon`, with `salt`,
    /// and returns its deterministic address.
    /// The value passed into this function will be forwarded to the beacon proxy.
    /// Then, calls the beacon proxy with abi encoded `data`.
    function deployBeaconProxyDeterministicAndCall(
        address beacon,
        bytes32 salt,
        bytes calldata data
    ) public payable returns (address) {
        return _deploy(2, uint160(beacon), 0, salt, 1, data);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       PUBLIC HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the address of the instance deployed with `salt`.
    /// `instanceHash` is one of `PROXY_HASH`, `BEACON_PROXY_HASH`, `BEACON_HASH`.
    function predictDeterministicAddress(bytes32 instanceHash, bytes32 salt)
        public
        view
        returns (address)
    {
        bytes32 h = keccak256(
            abi.encode(
                keccak256("zksyncCreate2"),
                bytes32(uint256(uint160(address(this)))),
                salt,
                instanceHash,
                keccak256("")
            )
        );
        return address(uint160(uint256(h)));
    }

    /// @dev Returns the implementation of `instance`.
    /// If `instance` is not deployed, returns `address(0)`.
    function implementationOf(address instance) public view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            let h := extcodehash(instance)
            if or(eq(h, PROXY_HASH), eq(h, BEACON_PROXY_HASH)) {
                let s := staticcall(gas(), instance, 0x00, 0x01, 0x00, 0x20)
                if iszero(and(gt(returndatasize(), 0x1f), s)) { revert(0x00, 0x00) }
                result := mload(0x00)
            }
            if eq(h, BEACON_HASH) {
                mstore(0x00, 0x5c60da1b) // `implementation()`.
                let s := staticcall(gas(), instance, 0x1c, 0x04, 0x00, 0x20)
                if iszero(and(gt(returndatasize(), 0x1f), s)) { revert(0x00, 0x00) }
                result := mload(0x00)
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      INTERNAL HELPERS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Performs the deployment optionality to deploy deterministically with a `salt`.
    function _deploy(
        uint256 codeType,
        uint256 target,
        uint256 admin,
        bytes32 salt,
        uint256 useSalt,
        bytes calldata data
    ) internal returns (address instance) {
        bytes memory c;
        if (codeType == 0) c = type(ZKsyncERC1967Proxy).creationCode;
        else if (codeType == 1) c = type(ZKsyncUpgradeableBeacon).creationCode;
        else c = type(ZKsyncERC1967BeaconProxy).creationCode;
        /// @solidity memory-safe-assembly
        assembly {
            switch useSalt
            case 0 { instance := create(0, add(c, 0x20), mload(c)) }
            default {
                // If the salt does not start with the zero address or the caller.
                if iszero(or(iszero(shr(96, salt)), eq(caller(), shr(96, salt)))) {
                    mstore(0x00, 0x2f634836) // `SaltDoesNotStartWithCaller()`.
                    revert(0x1c, 0x04)
                }
                instance := create2(0, add(c, 0x20), mload(c), salt)
            }
            // Revert if the creation fails.
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }

            // Make the initialization call.
            let m := mload(0x40)
            mstore(m, target)
            calldatacopy(add(m, 0x20), data.offset, data.length)
            if iszero(call(gas(), instance, callvalue(), m, add(0x20, data.length), 0x00, 0x00)) {
                // Revert with the `DeploymentFailed` selector if there is no error returndata.
                if iszero(returndatasize()) {
                    mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                    revert(0x1c, 0x04)
                }
                // Otherwise, bubble up the returned error.
                returndatacopy(0x00, 0x00, returndatasize())
                revert(0x00, returndatasize())
            }

            switch codeType
            case 0 {
                sstore(instance, admin)
                // Emit the {ProxyDeployed} event.
                log4(0x00, 0x00, _PROXY_DEPLOYED_EVENT_SIGNATURE, instance, target, admin)
            }
            case 1 {
                sstore(instance, admin)
                // Emit the {BeaconDeployed} event.
                log4(0x00, 0x00, _BEACON_DEPLOYED_EVENT_SIGNATURE, instance, target, admin)
            }
            default {
                // Emit the {BeaconProxyDeployed} event.
                log3(0x00, 0x00, _BEACON_PROXY_DEPLOYED_EVENT_SIGNATURE, instance, target)
            }
        }
    }

    /// @dev Helper function to return an empty bytes calldata.
    function _emptyData() internal pure returns (bytes calldata data) {
        /// @solidity memory-safe-assembly
        assembly {
            data.length := 0
        }
    }
}
