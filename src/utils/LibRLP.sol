// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for computing contract addresses from their deployer and nonce.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibRLP.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibRLP.sol)
library LibRLP {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The bytes string is too big to be RLP encoded.
    error BytesStringTooBig();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev A pointer to a RLP item list.
    struct List {
        // Do NOT modify the `_data` directly.
        // Bits layout for each element:
        // - [0..253]     uint inlined value or pointer to uint / bytes / children array.
        // - [254..255]   item type (0: uint inlined, 1: uint pointer, 2: bytes, 3: list).
        uint256 _data;
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
    /*                  RLP ENCODING OPERATIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Appends `x` to `l`.
    function p(List memory l, uint256 x) internal pure returns (List memory result) {
        _deallocate(result);
        bytes32 ptr = _grow(l);
        /// @solidity memory-safe-assembly
        assembly {
            for {} 1 {} {
                if iszero(shr(254, x)) {
                    mstore(ptr, x)
                    break
                }
                let m := mload(0x40)
                mstore(m, x)
                mstore(ptr, or(shl(254, 1), m))
                mstore(0x40, add(m, 0x20))
                break
            }
            result := l
        }
    }

    /// @dev Appends `x` to `l`.
    function p(List memory l, bytes memory x) internal pure returns (List memory result) {
        // TODO
    }

    /// @dev Appends `x` to `l`.
    function p(List memory l, List memory x) internal pure returns (List memory result) {
        // TODO
    }

    /// @dev Returns the RLP encoding of `l`.
    function encode(List memory l) internal pure returns (bytes memory result) {
        // TODO
    }

    /// @dev Returns the RLP encoding of `x`.
    function encode(uint256 x) internal pure returns (bytes memory result) {
        // TODO
    }

    /// @dev Returns the RLP encoding of `x`.
    function encode(bytes memory x) internal pure returns (bytes memory result) {
        // TODO
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Extends the list by 1 slot and returns the newly allocated slot.
    function _grow(List memory l) private pure returns (bytes32 ptr) {
        /// @solidity memory-safe-assembly
        assembly {
            for { let v := mload(l) } 1 {} {
                let n := and(v, 0xffffffff) // Length of `l`.
                if iszero(eq(shr(224, shl(192, v)), n)) {
                    mstore(l, add(v, 1))
                    ptr := add(shr(64, v), shl(5, n))
                    break
                }
                ptr := mload(0x40)
                if iszero(n) {
                    mstore(l, or(shl(64, ptr), or(shl(32, 0x10), 1)))
                    mstore(0x40, add(ptr, 0x200)) // Allocate 16 slots.
                    break
                }
                let end := add(ptr, shl(5, n))
                mstore(l, or(shl(64, ptr), or(shl(33, n), add(1, n))))
                mstore(0x40, add(ptr, shl(6, n))) // Allocate memory.
                let d := sub(shr(64, v), ptr)
                for {} 1 {} {
                    mstore(ptr, mload(add(ptr, d)))
                    ptr := add(ptr, 0x20)
                    if eq(ptr, end) { break }
                }
                break
            }
        }
    }

    /// @dev Helper for deallocating a automatically allocated `list` pointer.
    function _deallocate(List memory result) private pure {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x40, result) // Deallocate, as we have already allocated.
        }
    }
}
