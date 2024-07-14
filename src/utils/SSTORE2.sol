// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SSTORE2.sol)
/// @author Saw-mon-and-Natalie (https://github.com/Saw-mon-and-Natalie)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
/// @author Modified from SSTORE3 (https://github.com/Philogy/sstore3)
library SSTORE2 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The proxy initialization code.
    uint256 private constant _CREATE3_PROXY_INITCODE = 0x67363d3d37363d34f03d5260086018f3;

    /// @dev Hash of the `_CREATE3_PROXY_INITCODE`.
    /// Equivalent to `keccak256(abi.encodePacked(hex"67363d3d37363d34f03d5260086018f3"))`.
    bytes32 internal constant CREATE3_PROXY_INITCODE_HASH =
        0x21c35dbe1b344a2488cf3321d6ce542f8e9f305544ff09e4993a62319a497c1f;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CUSTOM ERRORS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unable to deploy the storage contract.
    error DeploymentFailed();

    /// @dev The storage contract address is invalid.
    error InvalidPointer();

    /// @dev Attempt to read outside of the storage contract's bytecode bounds.
    error ReadOutOfBounds();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         WRITE LOGIC                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Writes `data` into the bytecode of a storage contract and returns its address.
    function write(bytes memory data) internal returns (address pointer) {
        /// @solidity memory-safe-assembly
        assembly {
            let originalDataLength := mload(data)
            let n := add(originalDataLength, 1) // Bytecode length. +1 as we prefix a STOP opcode.
            /**
             * ----------------------------------------------------------------+
             * Opcode      | Mnemonic        | Stack     | Memory              |
             * ----------------------------------------------------------------|
             * 61 n        | PUSH2 n         | n         |                     |
             * 80          | DUP1            | n n       |                     |
             * 60 0xa      | PUSH1 0xa       | 0xa n n   |                     |
             * 3D          | RETURNDATASIZE  | 0 0xa n n |                     |
             * 39          | CODECOPY        | n         | [0..n): code        |
             * 3D          | RETURNDATASIZE  | 0 n       | [0..n): code        |
             * F3          | RETURN          |           | [0..n): code        |
             * 00          | STOP            |           |                     |
             * ----------------------------------------------------------------+
             * @dev Prefix the bytecode with a STOP opcode to ensure it cannot be called.
             * Also PUSH2 is used since max contract size cap is 24,576 bytes which is less than 2 ** 16.
             */
            mstore(
                // Do a out-of-gas revert if `n` is more than 2 bytes.
                // The actual EVM limit may be smaller and may change over time.
                add(data, gt(n, 0xffff)),
                // Left shift `n` by 64 so that it lines up with the 0000 after PUSH2.
                or(0xfd61000080600a3d393df300, shl(0x40, n))
            )
            // Deploy a new contract with the generated creation code.
            pointer := create(0, add(data, 0x15), add(n, 0xa))
            if iszero(pointer) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(data, originalDataLength) // Restore the length of `data`.
        }
    }

    /// @dev Writes `data` into the bytecode of a storage contract and returns its address.
    /// This uses the "CREATE3" workflow, which means that `pointer` is agnostic to `data,
    /// and only depends on `salt`.
    function writeDeterministic(bytes memory data, bytes32 salt)
        internal
        returns (address pointer)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let originalDataLength := mload(data)
            let n := add(originalDataLength, 1) // Bytecode length. +1 as we prefix a STOP opcode.

            mstore(0x00, _CREATE3_PROXY_INITCODE) // Store the `_PROXY_INITCODE`.
            let proxy := create2(0, 0x10, 0x10, salt)
            if iszero(proxy) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x14, proxy) // Store the proxy's address.
            // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x01).
            // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex).
            mstore(0x00, 0xd694)
            mstore8(0x34, 0x01) // Nonce of the proxy contract (1).
            pointer := keccak256(0x1e, 0x17)

            mstore(
                // Do a out-of-gas revert if `n` is more than 2 bytes.
                // The actual EVM limit may be smaller and may change over time.
                add(data, gt(n, 0xffff)),
                // Left shift `n` by 64 so that it lines up with the 0000 after PUSH2.
                or(0xfd61000080600a3d393df300, shl(0x40, n))
            )
            if iszero(
                mul( // The arguments of `mul` are evaluated last to first.
                    extcodesize(pointer),
                    call(gas(), proxy, 0, add(data, 0x15), add(n, 0xa), codesize(), 0x00)
                )
            ) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(data, originalDataLength) // Restore the length of `data`.
        }
    }

    /// @dev Returns the deterministic address for `salt`.
    /// This uses the "CREATE3" formula.
    function predictDeterministicAddress(bytes32 salt) internal view returns (address pointer) {
        pointer = predictDeterministicAddress(salt, address(this));
    }

    /// @dev Returns the deterministic address for `salt` with `deployer`.
    /// This uses the "CREATE3" formula.
    function predictDeterministicAddress(bytes32 salt, address deployer)
        internal
        pure
        returns (address pointer)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x00, deployer) // Store `deployer`.
            mstore8(0x0b, 0xff) // Store the prefix.
            mstore(0x20, salt) // Store the salt.
            mstore(0x40, CREATE3_PROXY_INITCODE_HASH) // Store the bytecode hash.

            mstore(0x14, keccak256(0x0b, 0x55)) // Store the proxy's address.
            mstore(0x40, m) // Restore the free memory pointer.
            // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x01).
            // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex).
            mstore(0x00, 0xd694)
            mstore8(0x34, 0x01) // Nonce of the proxy contract (1).
            pointer := keccak256(0x1e, 0x17)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         READ LOGIC                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns all the `data` from the bytecode of the storage contract at `pointer`.
    function read(address pointer) internal view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            let pointerCodesize := extcodesize(pointer)
            if iszero(pointerCodesize) {
                mstore(0x00, 0x11052bb4) // `InvalidPointer()`.
                revert(0x1c, 0x04)
            }
            let l := sub(pointerCodesize, 1) // Data length. -1 to skip the STOP opcode.
            // Get the pointer to the free memory and allocate
            // enough 32-byte words for the data and the length of the data,
            // then copy the code to the allocated memory.
            data := mload(0x40)
            mstore(0x40, add(data, add(l, 0x40)))
            mstore(data, l)
            mstore(add(add(data, 0x20), l), 0) // Zeroize the last slot.
            extcodecopy(pointer, add(data, 0x20), 1, l)
        }
    }

    /// @dev Returns the `data` from the bytecode of the storage contract at `pointer`,
    /// from the byte at `start`, to the end of the data stored.
    function read(address pointer, uint256 start) internal view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            let pointerCodesize := extcodesize(pointer)
            if iszero(pointerCodesize) {
                mstore(0x00, 0x11052bb4) // `InvalidPointer()`.
                revert(0x1c, 0x04)
            }
            // If `!(data.length + 1 > start)`, revert.
            // This also handles the case where `start + 1` overflows.
            if iszero(gt(pointerCodesize, start)) {
                mstore(0x00, 0x84eb0dd1) // `ReadOutOfBounds()`.
                revert(0x1c, 0x04)
            }
            let l := sub(pointerCodesize, add(start, 1)) // Data length. -1 to skip the STOP opcode.
            // Get the pointer to the free memory and allocate
            // enough 32-byte words for the data and the length of the data,
            // then copy the code to the allocated memory.
            data := mload(0x40)
            mstore(0x40, add(data, add(l, 0x40)))
            mstore(data, l)
            mstore(add(add(data, 0x20), l), 0) // Zeroize the last slot.
            extcodecopy(pointer, add(data, 0x20), add(start, 1), l)
        }
    }

    /// @dev Returns the `data` from the bytecode of the storage contract at `pointer`,
    /// from the byte at `start`, to the byte at `end` (exclusive) of the data stored.
    function read(address pointer, uint256 start, uint256 end)
        internal
        view
        returns (bytes memory data)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let pointerCodesize := extcodesize(pointer)
            if iszero(pointerCodesize) {
                mstore(0x00, 0x11052bb4) // `InvalidPointer()`.
                revert(0x1c, 0x04)
            }
            // If `!(data.length + 1 > end && start <= end)`, revert.
            // This also handles the cases where
            // `end + 1` or `start + 1` overflows.
            if iszero(gt(gt(pointerCodesize, end), gt(start, end))) {
                mstore(0x00, 0x84eb0dd1) // `ReadOutOfBounds()`.
                revert(0x1c, 0x04)
            }
            let l := sub(end, start) // Data length.
            // Get the pointer to the free memory and allocate
            // enough 32-byte words for the data and the length of the data,
            // then copy the code to the allocated memory.
            data := mload(0x40)
            mstore(0x40, add(data, add(l, 0x40)))
            mstore(data, l)
            mstore(add(add(data, 0x20), l), 0) // Zeroize the last slot.
            extcodecopy(pointer, add(data, 0x20), add(start, 1), l)
        }
    }
}
