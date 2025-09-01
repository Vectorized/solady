// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

    /// @dev Table of leading block header fields (indices 0-6), each entry is 20 bits: [12 bits: field length][8 bits: starting position]
    ///   0: parentHash          - starts = 1,   length 32 bytes
    ///   1: ommersHash        - starts = 34,  length 32 bytes (Now constant `Keccak256(RLP())`)
    ///   2: beneficiary          - starts = 67,  length 20 bytes
    ///   3: stateRoot            - starts = 88,  length 32 bytes
    ///   4: transactionsRoot  - starts = 121, length 32 bytes
    ///   5: receiptsRoot        - starts = 154, length 32 bytes
    ///   6: logsBloom           - starts = 189, length 256 bytes
    uint256 internal constant LEADING_FIELDS_POS_TABLE = 0x100bd0209a0207902058014430202202001;

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
    function verifyBlockHeader(bytes calldata header, uint256 blockNumber)
        internal
        view
        returns (bytes32 result)
    {
        result = blockHash(blockNumber);
        /// @solidity memory-safe-assembly
        assembly {
            calldatacopy(mload(0x40), header.offset, header.length)
            if xor(result, keccak256(mload(0x40), header.length)) {
                mstore(0x00, 0x464db2f8) // InvalidBlockHeader()
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Retrieves the position of a leading field (field indices 0-6) from an RLP-encoded block header.
    /// Leading fields are always present and have fixed sizes and lengths.
    /// This function allows efficient extraction of these fields from calldata without full RLP decoding.
    /// For the specification of field order and sizes, please refer to p. 6 of the Ethereum Yellow Paper:
    /// (https://ethereum.github.io/yellowpaper/paper.pdf)
    function leadingPos(bytes calldata header, uint256 field)
        internal
        pure
        returns (uint256 start, uint256 length)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let prefix := sub(byte(0, calldataload(header.offset)), 0xF6) // List prefix
            let pos :=
                mul(and(0xFFFFF, shr(mul(0x14, field), LEADING_FIELDS_POS_TABLE)), lt(field, 0x7))
            start := add(and(0xFF, pos), prefix)
            length := shr(0x8, pos)
        }
    }
}
