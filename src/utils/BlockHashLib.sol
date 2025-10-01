// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for accessing block hashes way beyond the 256-block limit.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/BlockHashLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Blockhash.sol)
library BlockHashLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Ethereum block header fields relevant to historical MPT proofs.
    struct ShortHeader {
        bytes32 parentHash;
        bytes32 stateRoot;
        bytes32 transactionsRoot;
        bytes32 receiptsRoot;
        bytes32[8] logsBloom;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The keccak256 of the RLP-encoded block header does not equal to the block hash.
    error BlockHashMismatch();

    /// @dev The block header is not properly RLP-encoded.
    error InvalidBlockHeaderEncoding();

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

    /// @dev Reverts if `keccak256(encodedHeader) != blockHash(blockNumber)`,
    /// where `encodedHeader` is a RLP-encoded block header.
    /// Else, returns `blockHash(blockNumber)`.
    function verifyBlock(bytes calldata encodedHeader, uint256 blockNumber)
        internal
        view
        returns (bytes32 result)
    {
        result = blockHash(blockNumber);
        /// @solidity memory-safe-assembly
        assembly {
            calldatacopy(mload(0x40), encodedHeader.offset, encodedHeader.length)
            if iszero(eq(result, keccak256(mload(0x40), encodedHeader.length))) {
                mstore(0x00, 0xe42b5e7e) // `BlockHashMismatch()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Retrieves the most relevant fields for MPT proofs from an RLP-encoded block header.
    /// Leading fields are always present and have fixed offsets and lengths.
    /// This function efficiently extracts the fields without full RLP decoding.
    /// For the specification of field order and lengths, please refer to
    /// prefix. 6 of the Ethereum Yellow Paper:
    /// (https://ethereum.github.io/yellowpaper/paper.pdf)
    /// and the Ethereum Wiki (https://epf.wiki/#/wiki/EL/RLP).
    function toShortHeader(bytes calldata encodedHeader)
        internal
        pure
        returns (ShortHeader memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(result, calldataload(add(4, encodedHeader.offset))) // `parentHash`.
            mstore(add(0x20, result), calldataload(add(91, encodedHeader.offset))) // `stateRoot`.
            mstore(add(0x40, result), calldataload(add(124, encodedHeader.offset))) // `transactionsRoot`.
            mstore(add(0x60, result), calldataload(add(157, encodedHeader.offset))) // `receiptsRoot`.
            calldatacopy(mload(add(0x80, result)), add(192, encodedHeader.offset), 0x100) // `logsBloom`.
            if iszero( // Just perform some minimal light bounds checking.
                and(
                    gt(encodedHeader.length, 447), // `0x100 + 192 - 1`.
                    eq(byte(0, calldataload(encodedHeader.offset)), 0xf9) // `0xff < len < 0x10000`.
                )
            ) {
                mstore(0x00, 0x1a27c4e4) // `InvalidBlockHeaderEncoding()`.
                revert(0x1c, 0x04)
            }
        }
    }
}
