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

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         WRITE LOGIC                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Writes `data` into the bytecode of a storage contract and returns its address.
    function write(bytes memory data) internal returns (address pointer) {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(data) // Let `l` be `n + 1`. +1 as we prefix a STOP opcode.
            /**
             * ---------------------------------------------------+
             * Opcode | Mnemonic       | Stack     | Memory       |
             * ---------------------------------------------------|
             * 61 l   | PUSH2 l        | l         |              |
             * 80     | DUP1           | l l       |              |
             * 60 0xa | PUSH1 0xa      | 0xa l l   |              |
             * 3D     | RETURNDATASIZE | 0 0xa l l |              |
             * 39     | CODECOPY       | l         | [0..l): code |
             * 3D     | RETURNDATASIZE | 0 l       | [0..l): code |
             * F3     | RETURN         |           | [0..l): code |
             * 00     | STOP           |           |              |
             * ---------------------------------------------------+
             * @dev Prefix the bytecode with a STOP opcode to ensure it cannot be called.
             * Also PUSH2 is used since max contract size cap is 24,576 bytes which is less than 2 ** 16.
             */
            // Do a out-of-gas revert if `n + 1` is more than 2 bytes.
            mstore(add(data, gt(n, 0xfffe)), add(0xfe61000180600a3d393df300, shl(0x40, n)))
            // Deploy a new contract with the generated creation code.
            pointer := create(0, add(data, 0x15), add(n, 0xb))
            if iszero(pointer) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(data, n) // Restore the length of `data`.
        }
    }

    /// @dev Writes `data` into the bytecode of a storage contract with `salt`
    /// and returns its normal CREATE2 deterministic address.
    function writeCounterfactual(bytes memory data, bytes32 salt)
        internal
        returns (address pointer)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(data)
            // Do a out-of-gas revert if `n + 1` is more than 2 bytes.
            mstore(add(data, gt(n, 0xfffe)), add(0xfe61000180600a3d393df300, shl(0x40, n)))
            // Deploy a new contract with the generated creation code.
            pointer := create2(0, add(data, 0x15), add(n, 0xb), salt)
            if iszero(pointer) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(data, n) // Restore the length of `data`.
        }
    }

    /// @dev Writes `data` into the bytecode of a storage contract and returns its address.
    /// This uses the so-called "CREATE3" workflow,
    /// which means that `pointer` is agnostic to `data, and only depends on `salt`.
    function writeDeterministic(bytes memory data, bytes32 salt)
        internal
        returns (address pointer)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(data)
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

            // Do a out-of-gas revert if `n + 1` is more than 2 bytes.
            mstore(add(data, gt(n, 0xfffe)), add(0xfe61000180600a3d393df300, shl(0x40, n)))
            if iszero(
                mul( // The arguments of `mul` are evaluated last to first.
                    extcodesize(pointer),
                    call(gas(), proxy, 0, add(data, 0x15), add(n, 0xb), codesize(), 0x00)
                )
            ) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(data, n) // Restore the length of `data`.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    ADDRESS CALCULATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the initialization code hash of the storage contract for `data`.
    /// Used for mining vanity addresses with create2crunch.
    function initCodeHash(bytes memory data) internal pure returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(data)
            // Do a out-of-gas revert if `n + 1` is more than 2 bytes.
            returndatacopy(returndatasize(), returndatasize(), gt(n, 0xfffe))
            mstore(data, add(0x61000180600a3d393df300, shl(0x40, n)))
            hash := keccak256(add(data, 0x15), add(n, 0xb))
            mstore(data, n) // Restore the length of `data`.
        }
    }

    /// @dev Equivalent to `predictCounterfactualAddress(data, salt, address(this))`
    function predictCounterfactualAddress(bytes memory data, bytes32 salt)
        internal
        view
        returns (address pointer)
    {
        pointer = predictCounterfactualAddress(data, salt, address(this));
    }

    /// @dev Returns the CREATE2 address of the storage contract for `data`
    /// deployed with `salt` by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictCounterfactualAddress(bytes memory data, bytes32 salt, address deployer)
        internal
        pure
        returns (address predicted)
    {
        bytes32 hash = initCodeHash(data);
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and store the bytecode hash.
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, hash)
            mstore(0x01, shl(96, deployer))
            mstore(0x15, salt)
            predicted := keccak256(0x00, 0x55)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x35, 0)
        }
    }

    /// @dev Equivalent to `predictDeterministicAddress(salt, address(this))`.
    function predictDeterministicAddress(bytes32 salt) internal view returns (address pointer) {
        pointer = predictDeterministicAddress(salt, address(this));
    }

    /// @dev Returns the "CREATE3" deterministic address for `salt` with `deployer`.
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

    /// @dev Equivalent to `read(pointer, 0, 2 ** 256 - 1)`.
    function read(address pointer) internal view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            data := mload(0x40)
            let n := and(sub(extcodesize(pointer), 0x01), 0xffffffffff)
            extcodecopy(pointer, add(data, 0x1f), 0x00, add(n, 0x21))
            mstore(data, n) // Store the length.
            mstore(0x40, add(n, add(data, 0x40))) // Allocate memory.
        }
    }

    /// @dev Equivalent to `read(pointer, start, 2 ** 256 - 1)`.
    function read(address pointer, uint256 start) internal view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            data := mload(0x40)
            let n := and(sub(extcodesize(pointer), 0x01), 0xffffffffff)
            extcodecopy(pointer, add(data, 0x1f), start, add(n, 0x21))
            mstore(data, mul(sub(n, start), lt(start, n))) // Store the length.
            mstore(0x40, add(data, add(0x40, mload(data)))) // Allocate memory.
        }
    }

    /// @dev Returns a slice of the data on `pointer` from `start` to `end`.
    /// `start` and `end` will be clamped to the range `[0, args.length]`.
    /// The `pointer` MUST be deployed via the SSTORE2 write functions.
    /// Otherwise, the behavior is undefined.
    /// Out-of-gas reverts if `pointer` does not have any code.
    function read(address pointer, uint256 start, uint256 end)
        internal
        view
        returns (bytes memory data)
    {
        /// @solidity memory-safe-assembly
        assembly {
            data := mload(0x40)
            if iszero(lt(end, 0xffff)) { end := 0xffff }
            let d := mul(sub(end, start), lt(start, end))
            extcodecopy(pointer, add(data, 0x1f), start, add(d, 0x01))
            if iszero(and(0xff, mload(add(data, d)))) {
                let n := sub(extcodesize(pointer), 0x01)
                returndatacopy(returndatasize(), returndatasize(), shr(64, n))
                d := mul(gt(n, start), sub(d, mul(gt(end, n), sub(end, n))))
            }
            mstore(data, d) // Store the length.
            mstore(add(add(data, 0x20), d), 0) // Zeroize the slot after the bytes.
            mstore(0x40, add(add(data, 0x40), d)) // Allocate memory.
        }
    }
}
