// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC1967Proxy} from "./ERC1967Proxy.sol";
import {UpgradeableBeacon} from "./UpgradeableBeacon.sol";
import {ERC1967BeaconProxy} from "./ERC1967BeaconProxy.sol";

/// @notice A factory for deploying minimal ERC1967 proxies on ZKsync.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ext/zksync/ERC1967Factory.sol)
///
/// @dev This factory can be used in one of the following ways:
/// 1. Deploying a fresh copy with each contract.
///    Easier to test. In ZKsync VM, factory dependency bytecode is not included in the
///    factory bytecode, so you do not need to worry too much about bytecode size limits.
/// 2. Loading it from a storage variable which is set to the canonical address.
///    See: ERC1967FactoryConstants.ADDRESS.
///
/// This factory is crafted to be compatible with both ZKsync VM and regular EVM.
/// This is so that when ZKsync achieves full EVM equivalence,
/// this factory can still be used via the fresh copy per contract way.
contract ERC1967Factory {
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

    /// @dev No initialization code hash exists for the instance hash.
    error NoInitCodeHashFound();

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

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The hash of the proxy.
    bytes32 public proxyHash;

    /// @dev The hash of the upgradeable beacon.
    bytes32 public beaconHash;

    /// @dev The hash of the beacon proxy.
    bytes32 public beaconProxyHash;

    /// @dev Whether to use the CREATE2 address prediction workflow for ZKsync VM.
    bool internal _useZKsyncCreate2Prediction;

    /// @dev Maps the instance hash to the initialization code hash.
    mapping(bytes32 => bytes32) internal _initCodeHashes;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CONSTRUCTOR                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    constructor() payable {
        bytes32 proxySalt = keccak256(abi.encode(address(this), bytes32("proxySalt")));
        address proxyAddress = address(new ERC1967Proxy{salt: proxySalt}());

        proxyHash = _extcodehash(proxyAddress);
        beaconHash = _extcodehash(address(new UpgradeableBeacon()));
        beaconProxyHash = _extcodehash(address(new ERC1967BeaconProxy()));

        if (_predictDeterministicAddressZKsync(proxyHash, proxySalt) == proxyAddress) {
            _useZKsyncCreate2Prediction = true;
        } else {
            _initCodeHashes[proxyHash] = keccak256(type(ERC1967Proxy).creationCode);
            _initCodeHashes[beaconHash] = keccak256(type(UpgradeableBeacon).creationCode);
            _initCodeHashes[beaconProxyHash] = keccak256(type(ERC1967BeaconProxy).creationCode);
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ADMIN FUNCTIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the admin of the `instance`.
    /// Returns `address(0)` if `instance` is a beacon proxy.
    /// Works for both proxies and beacons.
    function adminOf(address instance) public view returns (address admin) {
        /// @solidity memory-safe-assembly
        assembly {
            admin := mul(sload(instance), gt(instance, 0xff))
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
        }
        emit AdminChanged(instance, admin);
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
        }
        emit Upgraded(instance, implementation);
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
        return _deploy(0, uint160(implementation), uint160(admin), "", false, data);
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
        return _deploy(0, uint160(implementation), uint160(admin), salt, true, data);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     BEACON DEPLOYMENT                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys a beacon with `implementation` and `admin`, and returns its address.
    function deployBeacon(address implementation, address admin) public returns (address) {
        return _deploy(1, uint160(implementation), uint160(admin), "", false, _emptyData());
    }

    /// @dev Deploys a beacon with `implementation` and `admin`, with `salt`,
    /// and returns its deterministic address.
    function deployBeaconDeterministic(address implementation, address admin, bytes32 salt)
        public
        payable
        returns (address)
    {
        return _deploy(1, uint160(implementation), uint160(admin), salt, true, _emptyData());
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
        return _deploy(2, uint160(beacon), 0, "", false, data);
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
        return _deploy(2, uint160(beacon), 0, salt, true, data);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       PUBLIC HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the address of the instance deployed with `salt`.
    /// `instanceHash` is one of `proxyHash`, `beaconProxyHash`, `beaconHash`.
    function predictDeterministicAddress(bytes32 instanceHash, bytes32 salt)
        public
        view
        returns (address)
    {
        if (_useZKsyncCreate2Prediction) {
            return _predictDeterministicAddressZKsync(instanceHash, salt);
        }
        return _predictDeterministicAddressRegularEVM(instanceHash, salt);
    }

    /// @dev Returns the implementation of `instance`.
    /// If `instance` is not deployed, returns `address(0)`.
    function implementationOf(address instance) public view returns (address result) {
        bytes32 h = _extcodehash(instance);
        if (h == proxyHash || h == beaconProxyHash) {
            /// @solidity memory-safe-assembly
            assembly {
                let s := staticcall(gas(), instance, 0x00, 0x01, 0x00, 0x20)
                if iszero(and(gt(returndatasize(), 0x1f), s)) { revert(0x00, 0x00) }
                result := mload(0x00)
            }
        } else if (h == beaconHash) {
            /// @solidity memory-safe-assembly
            assembly {
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

    /// @dev Validates the salt and returns it.
    function _validateSalt(bytes32 salt) internal view returns (bytes32) {
        /// @solidity memory-safe-assembly
        assembly {
            // If the salt does not start with the zero address or the caller.
            if iszero(or(iszero(shr(96, salt)), eq(caller(), shr(96, salt)))) {
                mstore(0x00, 0x2f634836) // `SaltDoesNotStartWithCaller()`.
                revert(0x1c, 0x04)
            }
        }
        return salt;
    }

    /// @dev Performs the deployment optionality to deploy deterministically with a `salt`.
    function _deploy(
        uint256 codeType,
        uint256 target,
        uint256 admin,
        bytes32 salt,
        bool useSalt,
        bytes calldata data
    ) internal returns (address instance) {
        if (codeType == 0) {
            instance = address(
                useSalt ? new ERC1967Proxy{salt: _validateSalt(salt)}() : new ERC1967Proxy()
            );
            /// @solidity memory-safe-assembly
            assembly {
                sstore(instance, admin)
            }
            emit ProxyDeployed(instance, address(uint160(target)), address(uint160(admin)));
        } else if (codeType == 1) {
            instance = address(
                useSalt
                    ? new UpgradeableBeacon{salt: _validateSalt(salt)}()
                    : new UpgradeableBeacon()
            );
            /// @solidity memory-safe-assembly
            assembly {
                sstore(instance, admin)
            }
            emit BeaconDeployed(instance, address(uint160(target)), address(uint160(admin)));
        } else {
            instance = address(
                useSalt
                    ? new ERC1967BeaconProxy{salt: _validateSalt(salt)}()
                    : new ERC1967BeaconProxy()
            );
            emit BeaconProxyDeployed(instance, address(uint160(target)));
        }
        /// @solidity memory-safe-assembly
        assembly {
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
        }
    }

    /// @dev Returns the `extcodehash` of `instance`.
    function _extcodehash(address instance) internal view returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := extcodehash(instance)
        }
    }

    /// @dev Helper function to return an empty bytes calldata.
    function _emptyData() internal pure returns (bytes calldata data) {
        /// @solidity memory-safe-assembly
        assembly {
            data.length := 0
        }
    }

    /// @dev Returns the predicted `CREATE2` address on ZKsync VM.
    function _predictDeterministicAddressZKsync(bytes32 instanceHash, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        bytes32 prefix = keccak256("zksyncCreate2");
        bytes32 emptyStringHash = keccak256("");
        /// @solidity memory-safe-assembly
        assembly {
            // The following is `keccak256(abi.encode(...))`.
            let m := mload(0x40)
            mstore(m, prefix)
            mstore(add(m, 0x20), address())
            mstore(add(m, 0x40), salt)
            mstore(add(m, 0x60), instanceHash)
            mstore(add(m, 0x80), emptyStringHash)
            predicted := keccak256(m, 0xa0)
        }
    }

    /// @dev Returns the predicted `CREATE2` address on regular EVM.
    function _predictDeterministicAddressRegularEVM(bytes32 instanceHash, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        bytes32 initCodeHash = _initCodeHashes[instanceHash];
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(initCodeHash) {
                mstore(0x00, 0xa3a58d1c) // `NoInitCodeHashFound()`.
                revert(0x1c, 0x04)
            }
            // The following is `keccak256(abi.encodePacked(...))`.
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, initCodeHash)
            mstore(0x01, shl(96, address()))
            mstore(0x15, salt)
            predicted := keccak256(0x00, 0x55)
            mstore(0x35, 0) // Restore the overwritten part of the free memory pointer.
        }
    }
}
