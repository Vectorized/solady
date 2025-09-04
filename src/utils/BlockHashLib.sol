// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev Ethereum block header fields relevant to historical MPT proofs.
struct ShortHeader {
    bytes32 parentHash;
    bytes32 stateRoot;
    bytes32 transactionsRoot;
    bytes32 receiptsRoot;
    bytes32[8] logsBloom;
}

/// @notice Library for accessing block hashes way beyond the 256-block limit.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/BlockHashLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Blockhash.sol)
library BlockHashLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Invalid block hash.
    error InvalidBlockHeader();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Address of the EIP-2935 history storage contract.
    /// See: https://eips.ethereum.org/EIPS/eip-2935
    address internal constant HISTORY_STORAGE_ADDRESS = 0x0000F90827F1C53a10cb7A02335B175320002935;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OPERATIONS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Retrieves the block hash for any historical block within the supported range.
    /// The function gracefully handles future blocks and blocks beyond the history window by returning zero,
    /// consistent with the EVM's native `BLOCKHASH` behavior.
    function blockHash(uint256 blockNumber) internal view returns (bytes32 result) {
        unchecked {
            // If `blockNumber + 256` overflows:
            // - Typical chain height (`block.number > 255`) -> `staticcall` -> 0.
            // - Very early chain (`block.number <= 255`) -> `blockhash` -> 0.
            if (block.number <= blockNumber + 256) return blockhash(blockNumber);
        }
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, blockNumber)
            mstore(0x00, 0)
            pop(staticcall(gas(), HISTORY_STORAGE_ADDRESS, 0x20, 0x20, 0x00, 0x20))
            result := mload(0x00)
        }
    }

    /// @dev Returns whether the hash of a provided RLP-encoded block `header` equals the block hash at `blockNumber`.
    function verifyBlockHash(bytes calldata header, uint256 blockNumber)
        internal
        view
        returns (bytes32 result)
    {
        result = blockHash(blockNumber);
        /// @solidity memory-safe-assembly
        assembly {
            calldatacopy(mload(0x40), header.offset, header.length)
            if iszero(eq(result, keccak256(mload(0x40), header.length))) {
                mstore(0x00, 0x464db2f8) // InvalidBlockHeader()
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Retrieves the most relevant fields for MPT proofs from an RLP-encoded block `header`.
    /// Leading fields are always present and have fixed offsets and lengths.
    /// This function allows efficient extraction of these fields from calldata without full RLP decoding.
    /// For the specification of field order and lengths, please refer to prefix. 6 of the Ethereum Yellow Paper:
    /// (https://ethereum.github.io/yellowpaper/paper.pdf)
    /// and the Ethereum Wiki (https://epf.wiki/#/wiki/EL/RLP).
    function toShortHeader(bytes calldata header)
        internal
        pure
        returns (ShortHeader memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let o := add(header.offset, sub(byte(0, calldataload(header.offset)), 0xF6))
            mstore(result, calldataload(add(1, o))) // parentHash
            mstore(add(0x20, result), calldataload(add(88, o))) // stateRoot
            mstore(add(0x40, result), calldataload(add(121, o))) // transactionsRoot
            mstore(add(0x60, result), calldataload(add(154, o))) // receiptsRoot
            mstore(add(0x80, result), m) // logsBloom
            calldatacopy(m, add(189, o), 0x100)
            mstore(0x40, add(0x100, m)) // Allocate the memory.
        }
    }
}
