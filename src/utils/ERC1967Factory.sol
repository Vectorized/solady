// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Factory for deploying and managing ERC1967 proxy contracts.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ERC1967Factory.sol)
/// @author jtriley-eth (https://github.com/jtriley-eth/minimum-viable-proxy)
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

    /// @dev `bytes4(keccak256(bytes("Unauthorized()")))`.
    uint256 internal constant _UNAUTHORIZED_ERROR_SELECTOR = 0x82b42900;

    /// @dev `bytes4(keccak256(bytes("DeploymentFailed()")))`.
    uint256 internal constant _DEPLOYMENT_FAILED_ERROR_SELECTOR = 0x30116425;

    /// @dev `bytes4(keccak256(bytes("UpgradeFailed()")))`.
    uint256 internal constant _UPGRADE_FAILED_ERROR_SELECTOR = 0x55299b49;

    /// @dev `bytes4(keccak256(bytes("SaltDoesNotStartWithCaller()")))`.
    uint256 internal constant _SALT_DOES_NOT_START_WITH_CALLER_ERROR_SELECTOR = 0x2f634836;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The admin of a proxy contract has been set.
    event AdminSet(address indexed proxy, address indexed admin);

    /// @dev The implementation for a proxy has been upgraded.
    event ProxyUpgraded(address indexed proxy, address indexed implementation);

    /// @dev A proxy has been deployed.
    event ProxyDeployed(
        address indexed proxy, address indexed implementation, address indexed admin
    );

    /// @dev `keccak256(bytes("AdminSet(address,address)"))`.
    uint256 internal constant _ADMIN_SET_EVENT_SIGNATURE =
        0xbf265e8326285a2747e33e54d5945f7111f2b5edb826eb8c08d4677779b3ff97;

    /// @dev `keccak256(bytes("ProxyUpgraded(address,address)"))`.
    uint256 internal constant _PROXY_UPGRADED_EVENT_SIGNATURE =
        0x3684250ce1e33b790ed973c23080f312db0adb21a6d98c61a5c9ff99e4babc17;

    /// @dev `keccak256(bytes("ProxyDeployed(address,address,address)"))`.
    uint256 internal constant _PROXY_DEPLOYED_EVENT_SIGNATURE =
        0x9e0862c4ebff2150fbbfd3f8547483f55bdec0c34fd977d3fccaa55d6c4ce784;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The admin slot for a `proxy` is given by:
    /// ```
    ///     mstore(0x0c, _ADMIN_SLOT_SEED)
    ///     mstore(0x00, proxy)
    ///     let adminSlot := keccak256(0x0c, 0x20)
    /// ```
    uint256 internal constant _ADMIN_SLOT_SEED = 0x98762005;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ADMIN FUNCTIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the admin of the proxy.
    function adminOf(address proxy) public view returns (address admin) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x0c, _ADMIN_SLOT_SEED)
            mstore(0x00, proxy)
            admin := sload(keccak256(0x0c, 0x20))
        }
    }

    /// @dev Sets the admin of the proxy.
    /// The caller of this function must be the admin of the proxy on this factory.
    function setAdmin(address proxy, address admin) public {
        /// @solidity memory-safe-assembly
        assembly {
            // Check if the caller is the admin of the proxy.
            mstore(0x0c, _ADMIN_SLOT_SEED)
            mstore(0x00, proxy)
            let adminSlot := keccak256(0x0c, 0x20)
            if iszero(eq(sload(adminSlot), caller())) {
                mstore(0x00, _UNAUTHORIZED_ERROR_SELECTOR)
                revert(0x1c, 0x04)
            }
            // Store the admin for the proxy.
            sstore(adminSlot, admin)
            // Emit the {AdminSet} event.
            log3(0, 0, _ADMIN_SET_EVENT_SIGNATURE, proxy, admin)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     UPGRADE FUNCTIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Upgrades the proxy to point to `implementation`.
    /// The caller of this function must be the admin of the proxy on this factory.
    function upgrade(address proxy, address implementation) public payable {
        upgradeAndCall(proxy, implementation, _emptyData());
    }

    /// @dev Upgrades the proxy to point to `implementation`.
    /// Then, calls the proxy with abi encoded `data`.
    /// The caller of this function must be the admin of the proxy on this factory.
    function upgradeAndCall(address proxy, address implementation, bytes calldata data)
        public
        payable
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Check if the caller is the admin of the proxy.
            mstore(0x0c, _ADMIN_SLOT_SEED)
            mstore(0x00, proxy)
            if iszero(eq(sload(keccak256(0x0c, 0x20)), caller())) {
                mstore(0x00, _UNAUTHORIZED_ERROR_SELECTOR)
                revert(0x1c, 0x04)
            }
            // Set up the calldata to upgrade the proxy.
            let m := mload(0x40)
            mstore(m, implementation)
            calldatacopy(add(m, 0x20), data.offset, data.length)
            // Try upgrading the proxy and revert upon failure.
            if iszero(call(gas(), proxy, callvalue(), m, add(0x20, data.length), 0x00, 0x00)) {
                // Revert with the `UpgradeFailed` selector if there is no error returndata.
                if iszero(returndatasize()) {
                    mstore(0x00, _UPGRADE_FAILED_ERROR_SELECTOR)
                    revert(0x1c, 0x04)
                }
                // Otherwise, bubble up the returned error.
                mstore(0x00, returndatasize())
                revert(0x00, returndatasize())
            }
            // Emit the {ProxyUpgraded} event.
            log3(0, 0, _PROXY_UPGRADED_EVENT_SIGNATURE, proxy, implementation)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      DEPLOY FUNCTIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys a proxy for `implementation`, with `admin`,
    /// and returns its address.
    /// The value passed into this function will be forwarded to the proxy.
    function deploy(address implementation, address admin) public payable returns (address proxy) {
        proxy = _deploy(implementation, admin, bytes32(0), false, _emptyData());
    }

    /// @dev Deploys a proxy for `implementation`, with `admin`,
    /// and returns its address.
    /// The value passed into this function will be forwarded to the proxy.
    /// Then, calls the proxy with abi encoded `data`.
    function deployAndCall(address implementation, address admin, bytes calldata data)
        public
        payable
        returns (address proxy)
    {
        proxy = _deploy(implementation, admin, bytes32(0), false, data);
    }

    /// @dev Deploys a proxy for `implementation`, with `admin`, `salt`,
    /// and returns its deterministic address.
    /// The value passed into this function will be forwarded to the proxy.
    function deployDeterministic(address implementation, address admin, bytes32 salt)
        public
        payable
        checkStartsWithCaller(salt)
        returns (address proxy)
    {
        proxy = _deploy(implementation, admin, salt, true, _emptyData());
    }

    /// @dev Deploys a proxy for `implementation`, with `admin`, `salt`,
    /// and returns its deterministic address.
    /// The value passed into this function will be forwarded to the proxy.
    /// Then, calls the proxy with abi encoded `data`.
    function deployDeterministic(
        address implementation,
        address admin,
        bytes32 salt,
        bytes calldata data
    ) public payable checkStartsWithCaller(salt) returns (address proxy) {
        proxy = _deploy(implementation, admin, salt, true, data);
    }

    /// @dev Deploys the proxy, with optionality to deploy deterministically with a `salt`.
    function _deploy(
        address implementation,
        address admin,
        bytes32 salt,
        bool useSalt,
        bytes calldata data
    ) internal returns (address proxy) {
        bytes memory m = _initCode();
        /// @solidity memory-safe-assembly
        assembly {
            // Create the proxy.
            switch useSalt
            case 0 { proxy := create(0, add(m, 0x16), 0xa7) }
            default { proxy := create2(0, add(m, 0x16), 0xa7, salt) }
            // Revert if the creation fails.
            if iszero(proxy) {
                mstore(0x00, _DEPLOYMENT_FAILED_ERROR_SELECTOR)
                revert(0x1c, 0x04)
            }

            // Set up the calldata to set the implementation of the proxy.
            mstore(m, implementation)
            calldatacopy(add(m, 0x20), data.offset, data.length)
            // Try setting the implementation the proxy and revert upon failure.
            if iszero(call(gas(), proxy, callvalue(), m, add(0x20, data.length), 0x00, 0x00)) {
                // Revert with the `UpgradeFailed` selector if there is no error returndata.
                if iszero(returndatasize()) {
                    mstore(0x00, _UPGRADE_FAILED_ERROR_SELECTOR)
                    revert(0x1c, 0x04)
                }
                // Otherwise, bubble up the returned error.
                mstore(0x00, returndatasize())
                revert(0x00, returndatasize())
            }

            // Store the admin for the proxy.
            mstore(0x0c, _ADMIN_SLOT_SEED)
            mstore(0x00, proxy)
            sstore(keccak256(0x0c, 0x20), admin)

            // Emit the {ProxyDeployed} event.
            log4(0, 0, _PROXY_DEPLOYED_EVENT_SIGNATURE, proxy, implementation, admin)
        }
    }

    /// @dev Returns the address of the proxy deployed with `salt`.
    function predictDeterministicAddress(bytes32 salt) internal pure returns (address predicted) {
        bytes32 hash = initCodeHash();
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and store the bytecode hash.
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, hash)
            mstore(0x01, shl(96, address()))
            mstore(0x15, salt)
            predicted := keccak256(0x00, 0x55)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x35, 0)
        }
    }

    /// @dev Returns the initialization code hash of the proxy.
    /// Used for mining vanity addresses with create2crunch.
    function initCodeHash() public view returns (bytes32 result) {
        bytes memory m = _initCode();
        /// @solidity memory-safe-assembly
        assembly {
            result := keccak256(add(m, 0x16), 0xa7)
        }
    }

    /// @dev Returns the initialization code of a proxy created via this factory.
    function _initCode() internal view returns (bytes memory m) {
        /// @solidity memory-safe-assembly
        assembly {
            /**
             * -------------------------------------------------------------------------------------+
             * CREATION (9 bytes)                                                                   |
             * -------------------------------------------------------------------------------------|
             * Opcode     | Mnemonic        | Stack               | Memory                          |
             * -------------------------------------------------------------------------------------|
             * 60 runSize | PUSH1 runSize   | r                   |                                 |
             * 3d         | RETURNDATASIZE  | 0 r                 |                                 |
             * 81         | DUP2            | r 0 r               |                                 |
             * 60 offset  | PUSH1 offset    | o r 0 r             |                                 |
             * 3d         | RETURNDATASIZE  | 0 o r 0 r           |                                 |
             * 39         | CODECOPY        | 0 r                 | [0..runSize): runtime code      |
             * f3         | RETURN          |                     | [0..runSize): runtime code      |
             * -------------------------------------------------------------------------------------|
             * RUNTIME (158 bytes)                                                                  |
             * -------------------------------------------------------------------------------------|
             * Opcode      | Mnemonic       | Stack               | Memory                          |
             * -------------------------------------------------------------------------------------|
             *                                                                                      |
             * ::: check if caller is factory ::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 73 factory  | PUSH20 factory | f                   |                                 |
             * 33          | CALLER         | c f                 |                                 |
             * 14          | EQ             | isf                 |                                 |
             * 60 55       | PUSH1 0x55     | isf_dst isf         |                                 |
             * 57          | JUMPI          |                     |                                 |
             *                                                                                      |
             * ::: copy calldata to memory :::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 36          | CALLDATASIZE   | cds                 |                                 |
             * 3d          | RETURNDATASIZE | 0 cds               |                                 |
             * 3d          | RETURNDATASIZE | 0 0 cds             |                                 |
             * 37          | CALLDATACOPY   |                     | [0..calldatasize): calldata     |
             *                                                                                      |
             * ::: cache zero for after delegatecall :::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d          | RETURNDATASIZE | 0                   | [0..calldatasize): calldata     |
             *                                                                                      |
             * ::: delegatecall to implementation ::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d          | RETURNDATASIZE | 0 0                 | [0..calldatasize): calldata     |
             * 3d          | RETURNDATASIZE | 0 0 0               | [0..calldatasize): calldata     |
             * 36          | CALLDATASIZE   | cds 0 0 0           | [0..calldatasize): calldata     |
             * 3d          | RETURNDATASIZE | 0 cds 0 0 0         | [0..calldatasize): calldata     |
             * 7f slot     | PUSH32 slot    | s 0 cds 0 0 0       | [0..calldatasize): calldata     |
             * 54          | SLOAD          | i cds 0 0 0         | [0..calldatasize): calldata     |
             * 5a          | GAS            | g i cds 0 0 0       | [0..calldatasize): calldata     |
             * f4          | DELEGATECALL   | success 0           | [0..calldatasize): calldata     |
             *                                                                                      |
             * ::: copy returndata to memory :::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d          | RETURNDATASIZE | rds success 0       | [0..calldatasize): calldata     |
             * 82          | DUP3           | 0 rds success 0     | [0..calldatasize): calldata     |
             * 80          | DUP1           | 0 0 rds success 0   | [0..calldatasize): calldata     |
             * 3e          | RETURNDATACOPY | success 0           | [0..returndatasize): returndata |
             *                                                                                      |
             * ::: revert if delegatecall failed :::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 60 0x51     | PUSH1 0x51     | succ_dest success 0 | [0..returndatasize): returndata |
             * 57          | JUMPI          | 0                   | [0..returndatasize): returndata |
             *                                                                                      |
             * ::: call failed, revert :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d          | RETURNDATASIZE | rds 0               | [0..returndatasize): returndata |
             * 90          | SWAP1          | 0 rds               | [0..returndatasize): returndata |
             * fd          | REVERT         |                     | [0..returndatasize): returndata |
             *                                                                                      |
             * ::: call succeeded, return ::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b          | JUMPDEST       | 0                   | [0..returndatasize): returndata |
             * 3d          | RETURNDATASIZE | rds 0               | [0..returndatasize): returndata |
             * 90          | SWAP1          | 0 rds               | [0..returndatasize): returndata |
             * f3          | RETURN         |                     | [0..returndatasize): returndata |
             *                                                                                      |
             * ::: set new implementation (caller is factory) ::::::::::::::::::::::::::::::::::::: |
             * 5b          | JUMPDEST       | 0                   |                                 |
             * 3d          | RETURNDATASIZE | 0                   |                                 |
             * 35          | CALLDATALOAD   | impl                |                                 |
             * 7f slot     | PUSH32 slot    | slot impl           |                                 |
             * 55          | SSTORE         |                     |                                 |
             *                                                                                      |
             * ::: no extra calldata, return :::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 60 0x20     | PUSH1 0x20     | w                   |                                 |
             * 80          | DUP1           | w w                 |                                 |
             * 36          | CALLDATASIZE   | cds w w             |                                 |
             * 11          | GT             | cds_gt_w w          |                                 |
             * 60 0x83     | PUSH1 0x83     | dest cds_gt_w w     |                                 |
             * 57          | JUMPI          | w                   |                                 |
             * 00          | STOP           | w                   |                                 |
             *                                                                                      |
             * ::: copy extra calldata to memory :::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b          | JUMPDEST       | w                   |                                 |
             * 36          | CALLDATASIZE   | cds w               |                                 |
             * 03          | SUB            | t                   |                                 |
             * 80          | DUP1           | t t                 |                                 |
             * 60 0x20     | PUSH1 0x20     | w t t               |                                 |
             * 3d          | RETURNDATASIZE | 0 w t t             |                                 |
             * 37          | CALLDATACOPY   | t                   | [0..t): extra calldata          |
             *                                                                                      |
             * ::: cache zero for after delegatecall :::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d          | RETURNDATASIZE | 0 t                 | [0..t): extra calldata          |
             *                                                                                      |
             * ::: delegatecall to implementation ::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d          | RETURNDATASIZE | 0 0 t               | [0..t): extra calldata          |
             * 3d          | RETURNDATASIZE | 0 0 0 t             | [0..t): extra calldata          |
             * 92          | SWAP3          | t 0 0 0             | [0..t): extra calldata          |
             * 3d          | RETURNDATASIZE | 0 t 0 0 0           | [0..t): extra calldata          |
             * 3d          | RETURNDATASIZE | 0 0 t 0 0 0         | [0..t): extra calldata          |
             * 35          | CALLDATALOAD   | i t 0 0 0           | [0..t): extra calldata          |
             * 5a          | GAS            | g i t 0 0 0         | [0..t): extra calldata          |
             * f4          | DELEGATECALL   | success 0           | [0..t): extra calldata          |
             *                                                                                      |
             * ::: copy returndata to memory :::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d          | RETURNDATASIZE | rds success 0       | [0..t): extra calldata          |
             * 82          | DUP3           | 0 rds success 0     | [0..t): extra calldata          |
             * 80          | DUP1           | 0 0 rds success 0   | [0..t): extra calldata          |
             * 3e          | RETURNDATACOPY | success 0           | [0..returndatasize): returndata |
             *                                                                                      |
             * ::: revert if delegatecall failed :::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 60 0x51     | PUSH1 0x51     | succ_dest success 0 | [0..returndatasize): returndata |
             * 57          | JUMPI          | 0                   | [0..returndatasize): returndata |
             *                                                                                      |
             * ::: call failed, revert :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d          | RETURNDATASIZE | rds 0               | [0..returndatasize): returndata |
             * 90          | SWAP1          | 0 rds               | [0..returndatasize): returndata |
             * fd          | REVERT         |                     | [0..returndatasize): returndata |
             * -------------------------------------------------------------------------------------+
             */
            m := mload(0x40)
            mstore(add(m, 0x8d), 0x82803e6051573d90fd) // 9
            mstore(add(m, 0x94), 0x5d382bbc556020803611608357005b36038060203d373d3d3d923d3d355af43d) // 32
            mstore(add(m, 0x74), 0x5b3d357f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca50) // 32
            mstore(add(m, 0x54), 0x3e2076cc3735a920a3ca505d382bbc545af43d82803e6051573d90fd5b3d90f3) // 32
            mstore(add(m, 0x34), 0x3314605557363d3d373d3d3d363d7f360894a13ba1a3210667c828492db98dca) // 32
            mstore(add(m, 0x14), address()) // 20
            mstore(m, 0x609e3d8160093d39f373) // 10
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          HELPERS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Reverts if `salt` does not start with either the zero address or the caller.
    modifier checkStartsWithCaller(bytes32 salt) {
        /// @solidity memory-safe-assembly
        assembly {
            // If the salt does not start with the zero address or the caller.
            if iszero(or(iszero(shr(96, salt)), eq(caller(), shr(96, salt)))) {
                mstore(0x00, _SALT_DOES_NOT_START_WITH_CALLER_ERROR_SELECTOR)
                revert(0x1c, 0x04)
            }
        }
        _;
    }

    /// @dev Helper function to return an empty bytes calldata.
    function _emptyData() internal pure returns (bytes calldata data) {
        /// @solidity memory-safe-assembly
        assembly {
            data.length := 0
        }
    }
}
