// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Deploy to deterministic addresses without an initcode factor.
/// @author Solady (https://github.com/vectorized/solmady/blob/main/src/utils/CREATE3.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/CREATE3.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/create3/blob/master/contracts/Create3.sol)
library CREATE3 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CUSTOM ERRORS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error DeploymentFailed();

    error InitializationFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      BYTECODE CONSTANTS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * -------------------------------------------------------------------+
     * Opcode      | Opcode + Args    | Stack        | Memory             |
     * -------------------------------------------------------------------|
     * 36          | CALLDATASIZE     | cds          |                    |
     * 3d          | RETURNDATASIZE   | 0 cds        |                    |
     * 3d          | RETURNDATASIZE   | 0 0          |                    |
     * 37          | CALLDATACOPY     |              | [0..cds): calldata |
     * 36          | CALLDATASIZE     | cds          | [0..cds): calldata |
     * 3d          | RETURNDATASIZE   | 0 cds        | [0..cds): calldata |
     * 34          | CALLVALUE        | value 0 cds  | [0..cds): calldata |
     * f0          | CREATE           | newContract  | [0..cds): calldata |
     * -------------------------------------------------------------------|
     * Opcode      | Opcode + Args    | Stack        | Memory             |
     * -------------------------------------------------------------------|
     * 67 bytecode | PUSH8 bytecode   | bytecode     |                    |
     * 3d          | RETURNDATASIZE   | 0 bytecode   |                    |
     * 52          | MSTORE           |              | [0..8): bytecode   |
     * 60 0x08     | PUSH1 0x08       | 0x08         | [0..8): bytecode   |
     * 60 0x18     | PUSH1 0x18       | 0x18 0x08    | [0..8): bytecode   |
     * f3          | RETURN           |              | [0..8): bytecode   |
     * -------------------------------------------------------------------+
     */

    uint256 internal constant PROXY_BYTECODE = 0x67_36_3d_3d_37_36_3d_34_f0_3d_52_60_08_60_18_f3;

    bytes32 internal constant PROXY_BYTECODE_HASH = 0x21c35dbe1b344a2488cf3321d6ce542f8e9f305544ff09e4993a62319a497c1f;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      CREATE3 OPERATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function deploy(
        bytes32 salt,
        bytes memory creationCode,
        uint256 value
    ) internal returns (address deployed) {
        assembly {
            // Store the `PROXY_BYTECODE` into scratch space.
            mstore(0x00, PROXY_BYTECODE)
            // Deploy a new contract with our pre-made bytecode via CREATE2.
            let proxy := create2(0, 0x10, 0x10, salt)

            // If the result of `create2` is the zero address, revert.
            if iszero(proxy) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Store the proxy's address.
            mstore(0x14, proxy)
            // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x01).
            // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex).
            mstore(0x00, 0xd694)
            // Nonce of the proxy contract (1).
            mstore8(0x34, 0x01)

            deployed := keccak256(0x1e, 0x17)

            // If the `call` fails, revert.
            if iszero(
                call(
                    gas(), // Gas remaining.
                    proxy, // Proxy's address.
                    value, // Ether value.
                    add(creationCode, 0x20), // Start of `creationCode`.
                    mload(creationCode), // Length of `creationCode`.
                    0x00, // Offset of output.
                    0x00 // Length of output.
                )
            ) {
                // Store the function selector of `InitializationFailed()`.
                mstore(0x00, 0x19b991a8)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // If the code size of `deployed` is zero, revert.
            if iszero(extcodesize(deployed)) {
                // Store the function selector of `InitializationFailed()`.
                mstore(0x00, 0x19b991a8)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    function getDeployed(bytes32 salt) internal view returns (address deployed) {
        assembly {
            // Cache the free memory pointer.
            let m := mload(0x40)
            // Store `address(this)`.
            mstore(0x00, address())
            // Store the prefix.
            mstore8(0x0b, 0xff)
            // Store the salt.
            mstore(0x20, salt)
            // Store the bytecode hash.
            mstore(0x40, PROXY_BYTECODE_HASH)

            // Store the proxy's address.
            mstore(0x14, keccak256(0x0b, 0x55))
            // Restore the free memory pointer.
            mstore(0x40, m)
            // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x01).
            // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex).
            mstore(0x00, 0xd694)
            // Nonce of the proxy contract (1).
            mstore8(0x34, 0x01)

            deployed := keccak256(0x1e, 0x17)
        }
    }
}
