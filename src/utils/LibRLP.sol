// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for computing contract addresses from their deployer and nonce.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibRLP.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibRLP.sol)
library LibRLP {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev A pointer to a RLP item node.
    struct Item {
        // Do NOT modify the `_data` directly.
        // Bits Layout:
        /// - [0..1]     item type (0: uint inlined, 1: uint pointer, 2: bytes, 3: list)
        /// - [2..255]   uint inlined value or pointer to uint / bytes / children array.
        uint256 _data;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  RLP ENCODING OPERATIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns `x` as an item.
    function toItem(uint256 x) internal pure returns (Item memory result) {
        // TODO
    }

    /// @dev Returns `x` as an item.
    function toItem(bytes memory x) internal pure returns (Item memory result) {
        // TODO
    }

    /// @dev Returns an item representing a list of `n` items.
    /// All items are initialized to 0.
    function list(uint256 n) internal pure returns (Item memory result) {
        // TODO.
    }

    /// @dev Converts `item` into a bytes string and sets its value to `x`.
    function set(Item memory item, uint256 x) internal pure returns (Item memory result) {
        // TODO
    }

    /// @dev Converts `item` into a bytes string and sets its value to `x`.
    function set(Item memory item, bytes memory x) internal pure returns (Item memory result) {
        // TODO
    }

    /// @dev Converts `item` into a list and sets the `i`th element to `x`.
    /// `item` will be automatically resized, with new items defaulting to 0.
    function set(Item memory item, uint256 i, uint256 x)
        internal
        pure
        returns (Item memory result)
    {
        // TODO
    }

    /// @dev Converts `item` into a list and sets the `i`th element to `x`.
    /// `item` will be automatically resized, with new items defaulting to 0.
    function set(Item memory item, uint256 i, bytes memory x)
        internal
        pure
        returns (Item memory result)
    {
        // TODO
    }

    /// @dev Converts `item` into a list and sets the `i`th element to `x`.
    /// `item` will be automatically resized, with new items defaulting to 0.
    function set(Item memory item, uint256 i, Item memory x)
        internal
        pure
        returns (Item memory result)
    {
        // TODO
    }

    /// @dev Returns the RLP encoding of `item`.
    function encode(Item memory item) internal pure returns (bytes memory result) {
        // TODO
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                ADDRESS PREDICTION OPERATION                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the address where a contract will be stored if deployed via
    /// `deployer` with `nonce` using the `CREATE` opcode.
    /// For the specification of the Recursive Length Prefix (RLP)
    /// encoding scheme, please refer to p. 19 of the Ethereum Yellow Paper
    /// (https://ethereum.github.io/yellowpaper/paper.pdf)
    /// and the Ethereum Wiki (https://eth.wiki/fundamentals/rlp).
    ///
    /// Based on the EIP-161 (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-161.md)
    /// specification, all contract accounts on the Ethereum mainnet are initiated with
    /// `nonce = 1`. Thus, the first contract address created by another contract
    /// is calculated with a non-zero nonce.
    ///
    /// The theoretical allowed limit, based on EIP-2681
    /// (https://eips.ethereum.org/EIPS/eip-2681), for an account nonce is 2**64-2.
    ///
    /// Caution! This function will NOT check that the nonce is within the theoretical range.
    /// This is for performance, as exceeding the range is extremely impractical.
    /// It is the user's responsibility to ensure that the nonce is valid
    /// (e.g. no dirty bits after packing / unpacking).
    ///
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function computeAddress(address deployer, uint256 nonce)
        internal
        pure
        returns (address deployed)
    {
        /// @solidity memory-safe-assembly
        assembly {
            for {} 1 {} {
                // The integer zero is treated as an empty byte string,
                // and as a result it only has a length prefix, 0x80,
                // computed via `0x80 + 0`.

                // A one-byte integer in the [0x00, 0x7f] range uses its
                // own value as a length prefix,
                // there is no additional `0x80 + length` prefix that precedes it.
                if iszero(gt(nonce, 0x7f)) {
                    mstore(0x00, deployer)
                    // Using `mstore8` instead of `or` naturally cleans
                    // any dirty upper bits of `deployer`.
                    mstore8(0x0b, 0x94)
                    mstore8(0x0a, 0xd6)
                    // `shl` 7 is equivalent to multiplying by 0x80.
                    mstore8(0x20, or(shl(7, iszero(nonce)), nonce))
                    deployed := keccak256(0x0a, 0x17)
                    break
                }
                let i := 8
                // Just use a loop to generalize all the way with minimal bytecode size.
                for {} shr(i, nonce) { i := add(i, 8) } {}
                // `shr` 3 is equivalent to dividing by 8.
                i := shr(3, i)
                // Store in descending slot sequence to overlap the values correctly.
                mstore(i, nonce)
                mstore(0x00, shl(8, deployer))
                mstore8(0x1f, add(0x80, i))
                mstore8(0x0a, 0x94)
                mstore8(0x09, add(0xd6, i))
                deployed := keccak256(0x09, add(0x17, i))
                break
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Helper for deallocating a automatically allocated `item` pointer.
    function _deallocate(Item memory result) private pure {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x40, result) // Deallocate, as we have already allocated.
        }
    }
}
