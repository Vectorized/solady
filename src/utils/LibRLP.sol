// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for RLP encoding and CREATE address computation.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibRLP.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibRLP.sol)
library LibRLP {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev A pointer to a RLP item list in memory.
    struct List {
        // Do NOT modify the `_data` directly.
        uint256 _data;
    }

    /// @dev A pointer to a decoded RLP item in memory.
    /// It is a lightweight view (offset, length, and type) into the RLP encoded
    /// data being decoded. The fields are packed into a single word for efficiency.
    /// Items returned by `decodeList` reference memory in the original RLP encoded data.
    /// Mutating the original RLP encoded data may invalidate the items.
    struct Item {
        // Do NOT modify the `_data` directly.
        uint256 _data;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The RLP item is malformed and cannot be decoded.
    error RLPDecodingFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                 CREATE ADDRESS PREDICTION                  */
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
    /// This is equivalent to:
    /// `address(uint160(uint256(keccak256(LibRLP.p(deployer).p(nonce).encode()))))`.
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

    // Note:
    // - addresses are treated like byte strings of length 20, agnostic of leading zero bytes.
    // - uint256s are converted to byte strings, stripped of leading zero bytes, and encoded.
    // - bools are converted to uint256s (`b ? 1 : 0`), then encoded with the uint256.
    // - For bytes1 to bytes32, you must manually convert them to bytes memory
    //   with `abi.encodePacked(x)` before encoding.

    /// @dev Returns a new empty list.
    function p() internal pure returns (List memory result) {}

    /// @dev Returns a new list with `x` as the only element. Equivalent to `LibRLP.p().p(x)`.
    function p(uint256 x) internal pure returns (List memory result) {
        p(result, x);
    }

    /// @dev Returns a new list with `x` as the only element. Equivalent to `LibRLP.p().p(x)`.
    function p(address x) internal pure returns (List memory result) {
        p(result, x);
    }

    /// @dev Returns a new list with `x` as the only element. Equivalent to `LibRLP.p().p(x)`.
    function p(bool x) internal pure returns (List memory result) {
        p(result, x);
    }

    /// @dev Returns a new list with `x` as the only element. Equivalent to `LibRLP.p().p(x)`.
    function p(bytes memory x) internal pure returns (List memory result) {
        p(result, x);
    }

    /// @dev Returns a new list with `x` as the only element. Equivalent to `LibRLP.p().p(x)`.
    function p(List memory x) internal pure returns (List memory result) {
        p(result, x);
    }

    /// @dev Appends `x` to `list`. Returns `list` for function chaining.
    function p(List memory list, uint256 x) internal pure returns (List memory result) {
        result._data = x << 48;
        _updateTail(list, result);
        /// @solidity memory-safe-assembly
        assembly {
            // If `x` is too big, we cannot pack it inline with the node.
            // We'll have to allocate a new slot for `x` and store the pointer to it in the node.
            if shr(208, x) {
                let m := mload(0x40)
                mstore(m, x)
                mstore(0x40, add(m, 0x20))
                mstore(result, shl(40, or(1, shl(8, m))))
            }
        }
        result = list;
    }

    /// @dev Appends `x` to `list`. Returns `list` for function chaining.
    function p(List memory list, address x) internal pure returns (List memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(result, shl(40, or(4, shl(8, x))))
        }
        _updateTail(list, result);
        result = list;
    }

    /// @dev Appends `x` to `list`. Returns `list` for function chaining.
    function p(List memory list, bool x) internal pure returns (List memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(result, shl(48, iszero(iszero(x))))
        }
        _updateTail(list, result);
        result = list;
    }

    /// @dev Appends `x` to `list`. Returns `list` for function chaining.
    function p(List memory list, bytes memory x) internal pure returns (List memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(result, shl(40, or(2, shl(8, x))))
        }
        _updateTail(list, result);
        result = list;
    }

    /// @dev Appends `x` to `list`. Returns `list` for function chaining.
    function p(List memory list, List memory x) internal pure returns (List memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(result, shl(40, or(3, shl(8, x))))
        }
        _updateTail(list, result);
        result = list;
    }

    /// @dev Returns the RLP encoding of `list`.
    function encode(List memory list) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            function encodeUint(x_, o_) -> _o {
                _o := add(o_, 1)
                if iszero(gt(x_, 0x7f)) {
                    mstore8(o_, or(shl(7, iszero(x_)), x_)) // Copy `x_`.
                    leave
                }
                let r_ := shl(7, lt(0xffffffffffffffffffffffffffffffff, x_))
                r_ := or(r_, shl(6, lt(0xffffffffffffffff, shr(r_, x_))))
                r_ := or(r_, shl(5, lt(0xffffffff, shr(r_, x_))))
                r_ := or(r_, shl(4, lt(0xffff, shr(r_, x_))))
                r_ := or(shr(3, r_), lt(0xff, shr(r_, x_)))
                mstore8(o_, add(r_, 0x81)) // Store the prefix.
                mstore(0x00, x_)
                mstore(_o, mload(xor(31, r_))) // Copy `x_`.
                _o := add(add(1, r_), _o)
            }
            function encodeAddress(x_, o_) -> _o {
                _o := add(o_, 0x15)
                mstore(o_, shl(88, x_))
                mstore8(o_, 0x94)
            }
            function encodeBytes(x_, o_, c_) -> _o {
                _o := add(o_, 1)
                let n_ := mload(x_)
                if iszero(gt(n_, 55)) {
                    let f_ := mload(add(0x20, x_))
                    if iszero(and(eq(1, n_), lt(byte(0, f_), 0x80))) {
                        mstore8(o_, add(n_, c_)) // Store the prefix.
                        mstore(add(0x21, o_), mload(add(0x40, x_)))
                        mstore(_o, f_)
                        _o := add(n_, _o)
                        leave
                    }
                    mstore(o_, f_) // Copy `x_`.
                    leave
                }
                returndatacopy(returndatasize(), returndatasize(), shr(32, n_))
                let r_ := add(1, add(lt(0xff, n_), add(lt(0xffff, n_), lt(0xffffff, n_))))
                mstore(o_, shl(248, add(r_, add(c_, 55)))) // Store the prefix.
                // Copy `x`.
                let i_ := add(r_, _o)
                _o := add(i_, n_)
                for { let d_ := sub(add(0x20, x_), i_) } 1 {} {
                    mstore(i_, mload(add(d_, i_)))
                    i_ := add(i_, 0x20)
                    if iszero(lt(i_, _o)) { break }
                }
                mstore(o_, or(mload(o_), shl(sub(248, shl(3, r_)), n_))) // Store the prefix.
            }
            function encodeList(l_, o_) -> _o {
                if iszero(mload(l_)) {
                    mstore8(o_, 0xc0)
                    _o := add(o_, 1)
                    leave
                }
                let j_ := add(o_, 0x20)
                for { let h_ := l_ } 1 {} {
                    h_ := and(mload(h_), 0xffffffffff)
                    if iszero(h_) { break }
                    let t_ := byte(26, mload(h_))
                    if iszero(gt(t_, 1)) {
                        if iszero(t_) {
                            j_ := encodeUint(shr(48, mload(h_)), j_)
                            continue
                        }
                        j_ := encodeUint(mload(shr(48, mload(h_))), j_)
                        continue
                    }
                    if eq(t_, 2) {
                        j_ := encodeBytes(shr(48, mload(h_)), j_, 0x80)
                        continue
                    }
                    if eq(t_, 3) {
                        j_ := encodeList(shr(48, mload(h_)), j_)
                        continue
                    }
                    j_ := encodeAddress(shr(48, mload(h_)), j_)
                }
                let n_ := sub(j_, add(o_, 0x20))
                if iszero(gt(n_, 55)) {
                    mstore8(o_, add(n_, 0xc0)) // Store the prefix.
                    mstore(add(0x01, o_), mload(add(0x20, o_)))
                    mstore(add(0x21, o_), mload(add(0x40, o_)))
                    _o := add(n_, add(0x01, o_))
                    leave
                }
                mstore(o_, n_)
                _o := encodeBytes(o_, o_, 0xc0)
            }
            result := mload(0x40)
            let begin := add(result, 0x20)
            let end := encodeList(list, begin)
            mstore(result, sub(end, begin)) // Store the length of `result`.
            mstore(end, 0) // Zeroize the slot after `result`.
            mstore(0x40, add(end, 0x20)) // Allocate memory for `result`.
        }
    }

    /// @dev Returns the RLP encoding of `x`.
    function encode(uint256 x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            for {} 1 {} {
                result := mload(0x40)
                if iszero(gt(x, 0x7f)) {
                    mstore(result, 1) // Store the length of `result`.
                    mstore(add(result, 0x20), shl(248, or(shl(7, iszero(x)), x))) // Copy `x`.
                    mstore(0x40, add(result, 0x40)) // Allocate memory for `result`.
                    break
                }
                let r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
                r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
                r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
                r := or(r, shl(4, lt(0xffff, shr(r, x))))
                r := add(2, or(shr(3, r), lt(0xff, shr(r, x))))
                mstore(add(r, result), x) // Copy `x`.
                mstore(add(result, 1), add(r, 0x7f)) // Store the prefix.
                mstore(result, r) // Store the length of `result`.
                mstore(add(r, add(result, 0x20)), 0) // Zeroize the slot after `result`.
                mstore(0x40, add(result, 0x60)) // Allocate memory for `result`.
                break
            }
        }
    }

    /// @dev Returns the RLP encoding of `x`.
    function encode(address x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 0x15)
            let o := add(0x20, result)
            mstore(o, shl(88, x))
            mstore8(o, 0x94)
            mstore(0x40, add(0x20, o))
        }
    }

    /// @dev Returns the RLP encoding of `x`.
    function encode(bool x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, 1)
            mstore(add(0x20, result), shl(add(0xf8, mul(7, iszero(x))), 0x01))
            mstore(0x40, add(0x40, result))
        }
    }

    /// @dev Returns the RLP encoding of `x`.
    function encode(bytes memory x) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := x

            for {} iszero(and(eq(1, mload(x)), lt(byte(0, mload(add(x, 0x20))), 0x80))) {} {
                result := mload(0x40)
                let n := mload(x) // Length of `x`.
                if iszero(gt(n, 55)) {
                    mstore(0x40, add(result, 0x60))
                    mstore(add(0x41, result), mload(add(0x40, x)))
                    mstore(add(0x21, result), mload(add(0x20, x)))
                    mstore(add(1, result), add(n, 0x80)) // Store the prefix.
                    mstore(result, add(1, n)) // Store the length of `result`.
                    mstore(add(add(result, 0x21), n), 0) // Zeroize the slot after `result`.
                    break
                }
                returndatacopy(returndatasize(), returndatasize(), shr(32, n))
                let r := add(2, add(lt(0xff, n), add(lt(0xffff, n), lt(0xffffff, n))))
                // Copy `x`.
                let i := add(r, add(0x20, result))
                let end := add(i, n)
                for { let d := sub(add(0x20, x), i) } 1 {} {
                    mstore(i, mload(add(d, i)))
                    i := add(i, 0x20)
                    if iszero(lt(i, end)) { break }
                }
                mstore(add(r, result), n) // Store the prefix.
                mstore(add(1, result), add(r, 0xb6)) // Store the prefix.
                mstore(result, add(r, n)) // Store the length of `result`.
                mstore(end, 0) // Zeroize the slot after `result`.
                mstore(0x40, add(end, 0x20)) // Allocate memory.
                break
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  RLP DECODING OPERATIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Note:
    // - The decoding takes a permissive approach, accepting non-canonical encodings
    //   (e.g. scalar values with leading zero bytes). This prioritizes compatibility
    //   over strict adherence to the Yellow Paper's canonicalization rules.
    // - Single bytes in the `[0x00, 0x7f]` range that are improperly wrapped with a
    //   length prefix are still rejected as invalid.
    // - The top-level decoders do NOT require that the item spans the entire input;
    //   trailing bytes after a valid item are ignored.
    // - `Item`s returned by `decodeList` are views into the original RLP encoded data.
    //   Mutating the original encoded data may invalidate them.

    /// @dev Decodes the RLP encoded `encoded` into a bytes string.
    /// Reverts if `encoded` is not a single RLP data item.
    function decodeBytes(bytes memory encoded) internal pure returns (bytes memory) {
        return decodeBytes(_toItem(encoded));
    }

    /// @dev Decodes the RLP encoded `encoded` into a uint256 scalar.
    /// Reverts if `encoded` is not a single RLP data item of at most 32 bytes.
    function decodeUint256(bytes memory encoded) internal pure returns (uint256) {
        return decodeUint256(_toItem(encoded));
    }

    /// @dev Decodes the RLP encoded `encoded` into an address.
    /// Reverts if `encoded` is not a single RLP data item of 1 or 21 bytes.
    function decodeAddress(bytes memory encoded) internal pure returns (address) {
        return decodeAddress(_toItem(encoded));
    }

    /// @dev Decodes the RLP encoded `encoded` into a bytes32.
    /// Reverts if `encoded` is not a single RLP data item of at most 32 bytes.
    function decodeBytes32(bytes memory encoded) internal pure returns (bytes32) {
        return decodeBytes32(_toItem(encoded));
    }

    /// @dev Decodes the RLP encoded `encoded` into an array of RLP items.
    /// Reverts if `encoded` is not a single RLP list.
    /// The returned items are views into `encoded`. See: {Item}.
    function decodeList(bytes memory encoded) internal pure returns (Item[] memory) {
        return decodeList(_toItem(encoded));
    }

    /// @dev Decodes the RLP `item` into a bytes string.
    /// Reverts if `item` is not a single RLP data item.
    function decodeBytes(Item memory item) internal pure returns (bytes memory result) {
        (uint256 ptr, uint256 end) = _unpack(item);
        (uint256 payloadPtr, uint256 payloadLen, uint256 itemIsList) = _decodeLength(ptr, end);
        if (itemIsList != 0) revert RLPDecodingFailed();
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(result, payloadLen) // Store the length.
            let o := add(result, 0x20)
            // Copy the payload. May read some bytes past the payload, which are zeroized below.
            for { let i := 0 } lt(i, payloadLen) { i := add(i, 0x20) } {
                mstore(add(o, i), mload(add(payloadPtr, i)))
            }
            mstore(add(o, payloadLen), 0) // Zeroize the slot after the string.
            mstore(0x40, add(o, and(add(payloadLen, 0x1f), not(0x1f)))) // Allocate memory.
        }
    }

    /// @dev Decodes the RLP `item` into a uint256 scalar.
    /// Reverts if `item` is not a single RLP data item of at most 32 bytes.
    function decodeUint256(Item memory item) internal pure returns (uint256 result) {
        (uint256 ptr, uint256 end) = _unpack(item);
        (uint256 payloadPtr, uint256 payloadLen, uint256 itemIsList) = _decodeLength(ptr, end);
        if (itemIsList != 0) revert RLPDecodingFailed();
        if (payloadLen > 32) revert RLPDecodingFailed();
        result = _toUint(payloadPtr, payloadLen);
    }

    /// @dev Decodes the RLP `item` into an address.
    /// Reverts if `item` is not a single RLP data item of 1 or 21 bytes.
    function decodeAddress(Item memory item) internal pure returns (address result) {
        (uint256 ptr, uint256 end) = _unpack(item);
        (uint256 payloadPtr, uint256 payloadLen, uint256 itemIsList) = _decodeLength(ptr, end);
        uint256 itemLen;
        unchecked {
            itemLen = payloadPtr + payloadLen - ptr;
        }
        if (itemIsList != 0) revert RLPDecodingFailed();
        if (itemLen != 1) if (itemLen != 21) revert RLPDecodingFailed();
        result = address(uint160(_toUint(payloadPtr, payloadLen)));
    }

    /// @dev Decodes the RLP `item` into a bytes32.
    /// Reverts if `item` is not a single RLP data item of at most 32 bytes.
    function decodeBytes32(Item memory item) internal pure returns (bytes32) {
        return bytes32(decodeUint256(item));
    }

    /// @dev Decodes the RLP `item` into an array of RLP items.
    /// Reverts if `item` is not a single RLP list.
    /// The returned items are views into the original encoded data. See: {Item}.
    function decodeList(Item memory item) internal pure returns (Item[] memory result) {
        (uint256 ptr, uint256 end) = _unpack(item);
        (uint256 payloadPtr, uint256 payloadLen, uint256 itemIsList) = _decodeLength(ptr, end);
        if (itemIsList == 0) revert RLPDecodingFailed();
        uint256 listEnd;
        unchecked {
            listEnd = payloadPtr + payloadLen;
        }
        uint256 structsStart;
        /// @solidity memory-safe-assembly
        assembly {
            structsStart := mload(0x40)
        }
        // Write the packed `_data` of each child `Item` into the unallocated space,
        // and count the number of children. The children tile the list payload exactly.
        uint256 n;
        for (uint256 q = payloadPtr; q < listEnd;) {
            (uint256 pp, uint256 pl,) = _decodeLength(q, listEnd);
            /// @solidity memory-safe-assembly
            assembly {
                mstore(add(structsStart, shl(5, n)), or(q, shl(64, listEnd)))
            }
            unchecked {
                q = pp + pl;
                ++n;
            }
        }
        // Build the array header, followed by pointers to each `Item` struct.
        /// @solidity memory-safe-assembly
        assembly {
            let header := add(structsStart, shl(5, n))
            result := header
            mstore(header, n) // Store the length of the array.
            let ptrs := add(header, 0x20)
            for { let i := 0 } lt(i, n) { i := add(i, 1) } {
                mstore(add(ptrs, shl(5, i)), add(structsStart, shl(5, i)))
            }
            mstore(0x40, add(ptrs, shl(5, n))) // Allocate memory.
        }
    }

    /// @dev Returns the next sibling of `item` within its enclosing list.
    /// Returns an empty item if `item` is empty or is the last item in its list.
    /// Useful for iterating without allocating an array. See: {decodeList}, {isEmpty}.
    function next(Item memory item) internal pure returns (Item memory result) {
        (uint256 ptr, uint256 end) = _unpack(item);
        if (ptr == 0) return result;
        (uint256 payloadPtr, uint256 payloadLen,) = _decodeLength(ptr, end);
        unchecked {
            uint256 np = payloadPtr + payloadLen;
            if (np < end) result._data = np | (end << 64);
        }
    }

    /// @dev Returns whether `item` is a list.
    /// Returns false if `item` is empty.
    function isList(Item memory item) internal pure returns (bool result) {
        (uint256 ptr, uint256 end) = _unpack(item);
        if (ptr == 0) return false;
        (,, uint256 itemIsList) = _decodeLength(ptr, end);
        result = itemIsList != 0;
    }

    /// @dev Returns whether `item` is empty (i.e. a null item).
    /// This is the case for items returned by `next` after the last item in a list.
    function isEmpty(Item memory item) internal pure returns (bool result) {
        result = item._data == 0;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns an `Item` viewing the entirety of the RLP encoded `encoded`.
    /// The item packs the start pointer of the encoded data in the low 64 bits,
    /// and the end pointer (exclusive) in the next 64 bits.
    function _toItem(bytes memory encoded) private pure returns (Item memory item) {
        /// @solidity memory-safe-assembly
        assembly {
            let s := add(encoded, 0x20)
            item := mload(0x40)
            mstore(item, or(s, shl(64, add(s, mload(encoded)))))
            mstore(0x40, add(item, 0x20))
        }
    }

    /// @dev Unpacks the start pointer `p` and end pointer `e` from `item`.
    function _unpack(Item memory item) private pure returns (uint256 ptr, uint256 end) {
        uint256 data = item._data;
        ptr = uint64(data);
        end = uint64(data >> 64);
    }

    /// @dev Returns the big-endian integer of the `payloadLen` bytes at `payloadPtr`.
    /// Assumes `payloadLen <= 32`.
    function _toUint(uint256 payloadPtr, uint256 payloadLen) private pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            if payloadLen { result := shr(shl(3, sub(32, payloadLen)), mload(payloadPtr)) }
        }
    }

    /// @dev Decodes the length and type of the RLP item starting at pointer `p`,
    /// bounded by the end pointer `e` (exclusive).
    /// Returns the pointer to the payload, the length of the payload,
    /// and whether the item is a list (`itemIsList` is 1 for a list, 0 otherwise).
    /// Reverts if the item is malformed or extends beyond `e`.
    function _decodeLength(uint256 ptr, uint256 end)
        private
        pure
        returns (uint256 payloadPtr, uint256 payloadLen, uint256 itemIsList)
    {
        uint256 failed;
        /// @solidity memory-safe-assembly
        assembly {
            for {} 1 {} {
                if iszero(lt(ptr, end)) {
                    failed := 1
                    break
                }
                let b := byte(0, mload(ptr))
                payloadPtr := add(ptr, 1)
                // Case: single byte in `[0x00, 0x7f]`.
                if lt(b, 0x80) {
                    payloadPtr := ptr
                    payloadLen := 1
                    break
                }
                // Case: short string (0-55 bytes).
                if lt(b, 0xb8) {
                    payloadLen := sub(b, 0x80)
                    // A single byte below `0x80` must not be wrapped with a prefix.
                    if eq(payloadLen, 1) { failed := lt(byte(0, mload(payloadPtr)), 0x80) }
                    break
                }
                // Case: long string (>55 bytes).
                if lt(b, 0xc0) {
                    let l := sub(b, 0xb7) // Length of the length, in `[1, 8]`.
                    let chunk := mload(payloadPtr)
                    payloadLen := shr(sub(256, shl(3, l)), chunk)
                    payloadPtr := add(payloadPtr, l)
                    // The length must not have a leading zero byte, and must be > 55.
                    failed := or(iszero(byte(0, chunk)), iszero(gt(payloadLen, 55)))
                    break
                }
                itemIsList := 1
                // Case: short list.
                if lt(b, 0xf8) {
                    payloadLen := sub(b, 0xc0)
                    break
                }
                // Case: long list.
                let ll := sub(b, 0xf7) // Length of the length, in `[1, 8]`.
                let c := mload(payloadPtr)
                payloadLen := shr(sub(256, shl(3, ll)), c)
                payloadPtr := add(payloadPtr, ll)
                // The length must not have a leading zero byte, and must be > 55.
                failed := or(iszero(byte(0, c)), iszero(gt(payloadLen, 55)))
                break
            }
            // The item must not extend beyond `e`.
            if gt(add(payloadPtr, payloadLen), end) { failed := 1 }
        }
        if (failed != 0) revert RLPDecodingFailed();
    }

    /// @dev Updates the tail in `list`.
    function _updateTail(List memory list, List memory result) private pure {
        /// @solidity memory-safe-assembly
        assembly {
            let v := or(shr(mload(list), result), mload(list))
            let tail := shr(40, v)
            mstore(list, xor(shl(40, xor(tail, result)), v)) // Update the tail.
            mstore(tail, or(mload(tail), result)) // Make the previous tail point to `result`.
        }
    }
}
