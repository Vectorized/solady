// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Factory for deploying and managing ERC1967 proxy contracts.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ERC1967Factory.sol)
/// @author jtriley-eth (https://github.com/jtriley-eth/minimum-viable-proxy)
contract ERC1967Factory {
    /// @dev The caller is not authorized to call the function.
    error Unauthorized();

    /// @dev The proxy deployment failed.
    error DeploymentFailed();

    /// @dev The upgrade failed.
    error UpgradeFailed();

    /// @dev `bytes4(keccak256(bytes("UpgradeFailed()")))`.
    uint256 private constant _UPGRADE_FAILED_ERROR_SELECTOR = 0x55299b49;

    /// @dev The admin of a proxy contract has been set.
    event AdminSet(address indexed proxy, address indexed admin);

    /// @dev The implementation for a proxy has been upgraded.
    event ProxyUpgraded(address indexed proxy, address indexed implementation);

    /// @dev Proxy admin registry.
    mapping(address proxy => address admin) public adminOf;

    /// @dev Sets the admin of the proxy if authorized.
    function setAdminFor(address proxy, address admin) external {
        if (adminOf[proxy] != msg.sender) revert Unauthorized();
        adminOf[proxy] = admin;
        emit AdminSet(proxy, admin);
    }

    /// @dev Upgrades the proxy if authorized.
    function upgradeProxyFor(address proxy, address implementation) external {
        if (adminOf[proxy] != msg.sender) revert Unauthorized();

        assembly {
            mstore(0x00, implementation)
            if iszero(call(gas(), proxy, 0x00, 0x00, 0x20, 0x00, 0x00)) {
                mstore(0x00, _UPGRADE_FAILED_ERROR_SELECTOR)
                revert(0x1c, 0x04)
            }
        }

        emit ProxyUpgraded(proxy, implementation);
    }

    /// @dev Deploys a proxy contract, sets the implementation, and sets the admin.
    function deployProxy(address implementation, address admin) external returns (address proxy) {
        assembly {
            /**
             * -------------------------------------------------------------------------------------|
             * CREATION (48 bytes)                                                                  |
             * -------------------------------------------------------------------------------------|
             * Opcode      | Mnemonic       | Stack               | Memory                          |
             * -------------------------------------------------------------------------------------|
             * 60 initsize | PUSH1 initsize | is                  |                                 |
             * 80          | DUP1           | is is               |                                 |
             * 38          | CODESIZE       | cs is is            |                                 |
             * 03          | SUB            | rs is               |                                 |
             * 90          | SWAP1          | is rs               |                                 |
             * 3d          | RETURNDATASIZE | 0 is rs             |                                 |
             * 39          | CODECOPY       |                     | [0..runsize): runtime code      |
             * 60 runsize  | PUSH1 runsize  | rs                  | [0..runsize): runtime code      |
             * 80          | DUP1           | rs rs               | [0..runsize): runtime code      |
             * 51          | MLOAD          | arg rs              | [0..runsize): runtime code      |
             * 7f slot     | PUSH32 SLOT    | s arg rs            | [0..runsize): runtime code      |
             * 55          | SSTORE         | rs                  | [0..runsize): runtime code      |
             * 3d          | RETURNDATASIZE | 0 rs                | [0..runsize): runtime code      |
             * f3          | RETURN         |                     | [0..runsize): runtime code      |
             * -------------------------------------------------------------------------------------|
             * RUNTIME (122 bytes)                                                                  |
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
             * 3d          | RETURNDATASIZE | 0                   |                                 |
             * 35          | CALLDATALOAD   | impl                |                                 |
             * 7f slot     | PUSH32 slot    | slot impl           |                                 |
             * 55          | SSTORE         |                     |                                 |
             * 00          | STOP           |                     |                                 |
             * -------------------------------------------------------------------------------------+
             */

            // get the free memory pointer,
            // set it to the end of the memory allocation.
            let memPtr := mload(0x40)
            mstore(0x40, add(memPtr, mallocSize))

            // store the bytecode in chunks starting at the free memory pointer.
            mstore(memPtr, chunk0)
            mstore(add(memPtr, 0x20), chunk1)
            mstore(add(memPtr, 0x40), chunk2)
            mstore(add(memPtr, 0x60), chunk3)
            mstore(add(memPtr, 0x80), chunk4)
            mstore(add(memPtr, 0xa0), chunk5)

            // write implementation address to the end of the bytecode.
            // this is treated as a constructor argument in the proxy initcode.
            mstore(add(memPtr, codeSize), implementation)

            // write the factory address to the bytecode.
            // we mask to avoid overwriting bytes.
            let factoryCodePtr := add(memPtr, factoryOffset)
            mstore(factoryCodePtr, or(address(), mload(factoryCodePtr)))

            // create the proxy.
            proxy := create(0x00, memPtr, mallocSize)
        }

        if (proxy == address(0)) revert DeploymentFailed();
        adminOf[proxy] = admin;
        emit AdminSet(proxy, admin);
    }
}

// pointers
uint256 constant mallocSize = 0xcd;
uint256 constant codeSize = 0xad;
uint256 constant factoryOffset = 0x25;

// bytecode chunks
uint256 constant chunk0 = 0x6030803803903d39607d80517f360894a13ba1a3210667c828492db98dca3e20;
uint256 constant chunk1 = 0x76cc3735a920a3ca505d382bbc553df373000000000000000000000000000000;
uint256 constant chunk2 = 0x00000000003314605557363d3d373d3d3d363d7f360894a13ba1a3210667c828;
uint256 constant chunk3 = 0x492db98dca3e2076cc3735a920a3ca505d382bbc545af43d82803e6051573d90;
uint256 constant chunk4 = 0xfd5b3d90f35b3d357f360894a13ba1a3210667c828492db98dca3e2076cc3735;
uint256 constant chunk5 = 0xa920a3ca505d382bbc5500000000000000000000000000000000000000000000;
