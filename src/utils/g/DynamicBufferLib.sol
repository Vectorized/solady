// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// This file is auto-generated.

/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
/*                          STRUCTS                           */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

/// @dev Type to represent a dynamic buffer in memory.
/// You can directly assign to `data`, and the `p` function will
/// take care of the memory allocation.
struct DynamicBuffer {
    bytes data;
}

using DynamicBufferLib for DynamicBuffer global;

/// @notice Library for buffers with automatic capacity resizing.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/g/DynamicBufferLib.sol)
/// @author Modified from cozyco (https://github.com/samkingco/cozyco/blob/main/contracts/utils/DynamicBuffer.sol)
library DynamicBufferLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OPERATIONS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Some of these functions returns the same buffer for function chaining.
    // `e.g. `buffer.p("1").p("2")`.

    /// @dev Shorthand for `buffer.data.length`.
    function length(DynamicBuffer memory buffer) internal pure returns (uint256) {
        return buffer.data.length;
    }

    /// @dev Reserves at least `minimum` amount of contiguous memory.
    function reserve(DynamicBuffer memory buffer, uint256 minimum)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = buffer;
        uint256 n = buffer.data.length;
        if (minimum > n) {
            uint256 i = 0x40;
            do {} while ((i <<= 1) < minimum);
            bytes memory data;
            /// @solidity memory-safe-assembly
            assembly {
                data := 0x01
                mstore(data, sub(i, n))
            }
            result = p(result, data);
        }
    }

    /// @dev Clears the buffer without deallocating the memory.
    function clear(DynamicBuffer memory buffer)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(mload(buffer), 0)
        }
        result = buffer;
    }

    /// @dev Returns a string pointing to the underlying bytes data.
    /// Note: The string WILL change if the buffer is updated.
    function s(DynamicBuffer memory buffer) internal pure returns (string memory) {
        return string(buffer.data);
    }

    /// @dev Appends `data` to `buffer`.
    function p(DynamicBuffer memory buffer, bytes memory data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = buffer;
        if (data.length == uint256(0)) return result;
        /// @solidity memory-safe-assembly
        assembly {
            let w := not(0x1f)
            let bufData := mload(buffer)
            let bufDataLen := mload(bufData)
            let newBufDataLen := add(mload(data), bufDataLen)
            // Some random prime number to multiply `cap`, so that
            // we know that the `cap` is for a dynamic buffer.
            // Selected to be larger than any memory pointer realistically.
            let prime := 1621250193422201
            let cap := mload(add(bufData, w)) // `mload(sub(bufData, 0x20))`.
            // Extract `cap`, initializing it to zero if it is not a multiple of `prime`.
            cap := mul(div(cap, prime), iszero(mod(cap, prime)))

            // Expand / Reallocate memory if required.
            // Note that we need to allocate an extra word for the length, and
            // and another extra word as a safety word (giving a total of 0x40 bytes).
            // Without the safety word, the backwards copying can cause a buffer overflow.
            for {} iszero(lt(newBufDataLen, cap)) {} {
                // Approximately more than double the capacity to ensure more than enough space.
                let newCap := and(add(cap, add(or(cap, newBufDataLen), 0x20)), w)
                // If the memory is contiguous, we can simply expand it.
                if iszero(or(xor(mload(0x40), add(bufData, add(0x40, cap))), eq(bufData, 0x60))) {
                    // Store `cap * prime` in the word before the length.
                    mstore(add(bufData, w), mul(prime, newCap))
                    mstore(0x40, add(bufData, add(0x40, newCap))) // Expand the memory allocation.
                    break
                }
                // Set the `newBufData` to point to the word after `cap`.
                let newBufData := add(mload(0x40), 0x20)
                mstore(0x40, add(newBufData, add(0x40, newCap))) // Reallocate the memory.
                mstore(buffer, newBufData) // Store the `newBufData`.
                // Copy `bufData` one word at a time, backwards.
                for { let o := and(add(bufDataLen, 0x20), w) } 1 {} {
                    mstore(add(newBufData, o), mload(add(bufData, o)))
                    o := add(o, w) // `sub(o, 0x20)`.
                    if iszero(o) { break }
                }
                // Store `cap * prime` in the word before the length.
                mstore(add(newBufData, w), mul(prime, newCap))
                bufData := newBufData // Assign `newBufData` to `bufData`.
                break
            }
            // If it's a reserve operation, set the variables to skip the appending.
            if eq(data, 0x01) {
                mstore(data, 0x00)
                newBufDataLen := bufDataLen
            }
            // Copy `data` one word at a time, backwards.
            for { let o := and(add(mload(data), 0x20), w) } 1 {} {
                mstore(add(add(bufData, bufDataLen), o), mload(add(data, o)))
                o := add(o, w) // `sub(o, 0x20)`.
                if iszero(o) { break }
            }
            mstore(add(add(bufData, 0x20), newBufDataLen), 0) // Zeroize the word after the buffer.
            mstore(bufData, newBufDataLen) // Store the length.
        }
    }

    /// @dev Appends `data0`, `data1` to `buffer`.
    function p(DynamicBuffer memory buffer, bytes memory data0, bytes memory data1)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(p(buffer, data0), data1);
    }

    /// @dev Appends `data0` .. `data2` to `buffer`.
    function p(
        DynamicBuffer memory buffer,
        bytes memory data0,
        bytes memory data1,
        bytes memory data2
    ) internal pure returns (DynamicBuffer memory result) {
        _deallocate(result);
        result = p(p(p(buffer, data0), data1), data2);
    }

    /// @dev Appends `data0` .. `data3` to `buffer`.
    function p(
        DynamicBuffer memory buffer,
        bytes memory data0,
        bytes memory data1,
        bytes memory data2,
        bytes memory data3
    ) internal pure returns (DynamicBuffer memory result) {
        _deallocate(result);
        result = p(p(p(p(buffer, data0), data1), data2), data3);
    }

    /// @dev Appends `data0` .. `data4` to `buffer`.
    function p(
        DynamicBuffer memory buffer,
        bytes memory data0,
        bytes memory data1,
        bytes memory data2,
        bytes memory data3,
        bytes memory data4
    ) internal pure returns (DynamicBuffer memory result) {
        _deallocate(result);
        result = p(p(p(p(p(buffer, data0), data1), data2), data3), data4);
    }

    /// @dev Appends `data0` .. `data5` to `buffer`.
    function p(
        DynamicBuffer memory buffer,
        bytes memory data0,
        bytes memory data1,
        bytes memory data2,
        bytes memory data3,
        bytes memory data4,
        bytes memory data5
    ) internal pure returns (DynamicBuffer memory result) {
        _deallocate(result);
        result = p(p(p(p(p(p(buffer, data0), data1), data2), data3), data4), data5);
    }

    /// @dev Appends `data0` .. `data6` to `buffer`.
    function p(
        DynamicBuffer memory buffer,
        bytes memory data0,
        bytes memory data1,
        bytes memory data2,
        bytes memory data3,
        bytes memory data4,
        bytes memory data5,
        bytes memory data6
    ) internal pure returns (DynamicBuffer memory result) {
        _deallocate(result);
        result = p(p(p(p(p(p(p(buffer, data0), data1), data2), data3), data4), data5), data6);
    }

    /// @dev Appends `abi.encodePacked(bool(data))` to buffer.
    function pBool(DynamicBuffer memory buffer, bool data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        uint256 casted;
        /// @solidity memory-safe-assembly
        assembly {
            casted := iszero(iszero(data))
        }
        result = p(buffer, _single(casted, 1));
    }

    /// @dev Appends `abi.encodePacked(address(data))` to buffer.
    function pAddress(DynamicBuffer memory buffer, address data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(uint256(uint160(data)), 20));
    }

    /// @dev Appends `abi.encodePacked(uint8(data))` to buffer.
    function pUint8(DynamicBuffer memory buffer, uint8 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 1));
    }

    /// @dev Appends `abi.encodePacked(uint16(data))` to buffer.
    function pUint16(DynamicBuffer memory buffer, uint16 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 2));
    }

    /// @dev Appends `abi.encodePacked(uint24(data))` to buffer.
    function pUint24(DynamicBuffer memory buffer, uint24 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 3));
    }

    /// @dev Appends `abi.encodePacked(uint32(data))` to buffer.
    function pUint32(DynamicBuffer memory buffer, uint32 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 4));
    }

    /// @dev Appends `abi.encodePacked(uint40(data))` to buffer.
    function pUint40(DynamicBuffer memory buffer, uint40 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 5));
    }

    /// @dev Appends `abi.encodePacked(uint48(data))` to buffer.
    function pUint48(DynamicBuffer memory buffer, uint48 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 6));
    }

    /// @dev Appends `abi.encodePacked(uint56(data))` to buffer.
    function pUint56(DynamicBuffer memory buffer, uint56 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 7));
    }

    /// @dev Appends `abi.encodePacked(uint64(data))` to buffer.
    function pUint64(DynamicBuffer memory buffer, uint64 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 8));
    }

    /// @dev Appends `abi.encodePacked(uint72(data))` to buffer.
    function pUint72(DynamicBuffer memory buffer, uint72 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 9));
    }

    /// @dev Appends `abi.encodePacked(uint80(data))` to buffer.
    function pUint80(DynamicBuffer memory buffer, uint80 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 10));
    }

    /// @dev Appends `abi.encodePacked(uint88(data))` to buffer.
    function pUint88(DynamicBuffer memory buffer, uint88 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 11));
    }

    /// @dev Appends `abi.encodePacked(uint96(data))` to buffer.
    function pUint96(DynamicBuffer memory buffer, uint96 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 12));
    }

    /// @dev Appends `abi.encodePacked(uint104(data))` to buffer.
    function pUint104(DynamicBuffer memory buffer, uint104 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 13));
    }

    /// @dev Appends `abi.encodePacked(uint112(data))` to buffer.
    function pUint112(DynamicBuffer memory buffer, uint112 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 14));
    }

    /// @dev Appends `abi.encodePacked(uint120(data))` to buffer.
    function pUint120(DynamicBuffer memory buffer, uint120 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 15));
    }

    /// @dev Appends `abi.encodePacked(uint128(data))` to buffer.
    function pUint128(DynamicBuffer memory buffer, uint128 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 16));
    }

    /// @dev Appends `abi.encodePacked(uint136(data))` to buffer.
    function pUint136(DynamicBuffer memory buffer, uint136 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 17));
    }

    /// @dev Appends `abi.encodePacked(uint144(data))` to buffer.
    function pUint144(DynamicBuffer memory buffer, uint144 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 18));
    }

    /// @dev Appends `abi.encodePacked(uint152(data))` to buffer.
    function pUint152(DynamicBuffer memory buffer, uint152 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 19));
    }

    /// @dev Appends `abi.encodePacked(uint160(data))` to buffer.
    function pUint160(DynamicBuffer memory buffer, uint160 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 20));
    }

    /// @dev Appends `abi.encodePacked(uint168(data))` to buffer.
    function pUint168(DynamicBuffer memory buffer, uint168 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 21));
    }

    /// @dev Appends `abi.encodePacked(uint176(data))` to buffer.
    function pUint176(DynamicBuffer memory buffer, uint176 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 22));
    }

    /// @dev Appends `abi.encodePacked(uint184(data))` to buffer.
    function pUint184(DynamicBuffer memory buffer, uint184 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 23));
    }

    /// @dev Appends `abi.encodePacked(uint192(data))` to buffer.
    function pUint192(DynamicBuffer memory buffer, uint192 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 24));
    }

    /// @dev Appends `abi.encodePacked(uint200(data))` to buffer.
    function pUint200(DynamicBuffer memory buffer, uint200 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 25));
    }

    /// @dev Appends `abi.encodePacked(uint208(data))` to buffer.
    function pUint208(DynamicBuffer memory buffer, uint208 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 26));
    }

    /// @dev Appends `abi.encodePacked(uint216(data))` to buffer.
    function pUint216(DynamicBuffer memory buffer, uint216 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 27));
    }

    /// @dev Appends `abi.encodePacked(uint224(data))` to buffer.
    function pUint224(DynamicBuffer memory buffer, uint224 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 28));
    }

    /// @dev Appends `abi.encodePacked(uint232(data))` to buffer.
    function pUint232(DynamicBuffer memory buffer, uint232 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 29));
    }

    /// @dev Appends `abi.encodePacked(uint240(data))` to buffer.
    function pUint240(DynamicBuffer memory buffer, uint240 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 30));
    }

    /// @dev Appends `abi.encodePacked(uint248(data))` to buffer.
    function pUint248(DynamicBuffer memory buffer, uint248 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 31));
    }

    /// @dev Appends `abi.encodePacked(uint256(data))` to buffer.
    function pUint256(DynamicBuffer memory buffer, uint256 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 32));
    }

    /// @dev Appends `abi.encodePacked(bytes1(data))` to buffer.
    function pBytes1(DynamicBuffer memory buffer, bytes1 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 1));
    }

    /// @dev Appends `abi.encodePacked(bytes2(data))` to buffer.
    function pBytes2(DynamicBuffer memory buffer, bytes2 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 2));
    }

    /// @dev Appends `abi.encodePacked(bytes3(data))` to buffer.
    function pBytes3(DynamicBuffer memory buffer, bytes3 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 3));
    }

    /// @dev Appends `abi.encodePacked(bytes4(data))` to buffer.
    function pBytes4(DynamicBuffer memory buffer, bytes4 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 4));
    }

    /// @dev Appends `abi.encodePacked(bytes5(data))` to buffer.
    function pBytes5(DynamicBuffer memory buffer, bytes5 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 5));
    }

    /// @dev Appends `abi.encodePacked(bytes6(data))` to buffer.
    function pBytes6(DynamicBuffer memory buffer, bytes6 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 6));
    }

    /// @dev Appends `abi.encodePacked(bytes7(data))` to buffer.
    function pBytes7(DynamicBuffer memory buffer, bytes7 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 7));
    }

    /// @dev Appends `abi.encodePacked(bytes8(data))` to buffer.
    function pBytes8(DynamicBuffer memory buffer, bytes8 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 8));
    }

    /// @dev Appends `abi.encodePacked(bytes9(data))` to buffer.
    function pBytes9(DynamicBuffer memory buffer, bytes9 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 9));
    }

    /// @dev Appends `abi.encodePacked(bytes10(data))` to buffer.
    function pBytes10(DynamicBuffer memory buffer, bytes10 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 10));
    }

    /// @dev Appends `abi.encodePacked(bytes11(data))` to buffer.
    function pBytes11(DynamicBuffer memory buffer, bytes11 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 11));
    }

    /// @dev Appends `abi.encodePacked(bytes12(data))` to buffer.
    function pBytes12(DynamicBuffer memory buffer, bytes12 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 12));
    }

    /// @dev Appends `abi.encodePacked(bytes13(data))` to buffer.
    function pBytes13(DynamicBuffer memory buffer, bytes13 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 13));
    }

    /// @dev Appends `abi.encodePacked(bytes14(data))` to buffer.
    function pBytes14(DynamicBuffer memory buffer, bytes14 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 14));
    }

    /// @dev Appends `abi.encodePacked(bytes15(data))` to buffer.
    function pBytes15(DynamicBuffer memory buffer, bytes15 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 15));
    }

    /// @dev Appends `abi.encodePacked(bytes16(data))` to buffer.
    function pBytes16(DynamicBuffer memory buffer, bytes16 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 16));
    }

    /// @dev Appends `abi.encodePacked(bytes17(data))` to buffer.
    function pBytes17(DynamicBuffer memory buffer, bytes17 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 17));
    }

    /// @dev Appends `abi.encodePacked(bytes18(data))` to buffer.
    function pBytes18(DynamicBuffer memory buffer, bytes18 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 18));
    }

    /// @dev Appends `abi.encodePacked(bytes19(data))` to buffer.
    function pBytes19(DynamicBuffer memory buffer, bytes19 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 19));
    }

    /// @dev Appends `abi.encodePacked(bytes20(data))` to buffer.
    function pBytes20(DynamicBuffer memory buffer, bytes20 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 20));
    }

    /// @dev Appends `abi.encodePacked(bytes21(data))` to buffer.
    function pBytes21(DynamicBuffer memory buffer, bytes21 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 21));
    }

    /// @dev Appends `abi.encodePacked(bytes22(data))` to buffer.
    function pBytes22(DynamicBuffer memory buffer, bytes22 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 22));
    }

    /// @dev Appends `abi.encodePacked(bytes23(data))` to buffer.
    function pBytes23(DynamicBuffer memory buffer, bytes23 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 23));
    }

    /// @dev Appends `abi.encodePacked(bytes24(data))` to buffer.
    function pBytes24(DynamicBuffer memory buffer, bytes24 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 24));
    }

    /// @dev Appends `abi.encodePacked(bytes25(data))` to buffer.
    function pBytes25(DynamicBuffer memory buffer, bytes25 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 25));
    }

    /// @dev Appends `abi.encodePacked(bytes26(data))` to buffer.
    function pBytes26(DynamicBuffer memory buffer, bytes26 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 26));
    }

    /// @dev Appends `abi.encodePacked(bytes27(data))` to buffer.
    function pBytes27(DynamicBuffer memory buffer, bytes27 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 27));
    }

    /// @dev Appends `abi.encodePacked(bytes28(data))` to buffer.
    function pBytes28(DynamicBuffer memory buffer, bytes28 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 28));
    }

    /// @dev Appends `abi.encodePacked(bytes29(data))` to buffer.
    function pBytes29(DynamicBuffer memory buffer, bytes29 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 29));
    }

    /// @dev Appends `abi.encodePacked(bytes30(data))` to buffer.
    function pBytes30(DynamicBuffer memory buffer, bytes30 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 30));
    }

    /// @dev Appends `abi.encodePacked(bytes31(data))` to buffer.
    function pBytes31(DynamicBuffer memory buffer, bytes31 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 31));
    }

    /// @dev Appends `abi.encodePacked(bytes32(data))` to buffer.
    function pBytes32(DynamicBuffer memory buffer, bytes32 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 32));
    }

    /// @dev Shorthand for returning a new buffer.
    function p() internal pure returns (DynamicBuffer memory result) {}

    /// @dev Shorthand for `p(p(), data)`.
    function p(bytes memory data) internal pure returns (DynamicBuffer memory result) {
        p(result, data);
    }

    /// @dev Shorthand for `p(p(), data0, data1)`.
    function p(bytes memory data0, bytes memory data1)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        p(p(result, data0), data1);
    }

    /// @dev Shorthand for `p(p(), data0, .., data2)`.
    function p(bytes memory data0, bytes memory data1, bytes memory data2)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        p(p(p(result, data0), data1), data2);
    }

    /// @dev Shorthand for `p(p(), data0, .., data3)`.
    function p(bytes memory data0, bytes memory data1, bytes memory data2, bytes memory data3)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        p(p(p(p(result, data0), data1), data2), data3);
    }

    /// @dev Shorthand for `p(p(), data0, .., data4)`.
    function p(
        bytes memory data0,
        bytes memory data1,
        bytes memory data2,
        bytes memory data3,
        bytes memory data4
    ) internal pure returns (DynamicBuffer memory result) {
        p(p(p(p(p(result, data0), data1), data2), data3), data4);
    }

    /// @dev Shorthand for `p(p(), data0, .., data5)`.
    function p(
        bytes memory data0,
        bytes memory data1,
        bytes memory data2,
        bytes memory data3,
        bytes memory data4,
        bytes memory data5
    ) internal pure returns (DynamicBuffer memory result) {
        p(p(p(p(p(p(result, data0), data1), data2), data3), data4), data5);
    }

    /// @dev Shorthand for `p(p(), data0, .., data6)`.
    function p(
        bytes memory data0,
        bytes memory data1,
        bytes memory data2,
        bytes memory data3,
        bytes memory data4,
        bytes memory data5,
        bytes memory data6
    ) internal pure returns (DynamicBuffer memory result) {
        p(p(p(p(p(p(p(result, data0), data1), data2), data3), data4), data5), data6);
    }

    /// @dev Shorthand for `pBool(p(), data)`.
    function pBool(bool data) internal pure returns (DynamicBuffer memory result) {
        pBool(result, data);
    }

    /// @dev Shorthand for `pAddress(p(), data)`.
    function pAddress(address data) internal pure returns (DynamicBuffer memory result) {
        pAddress(result, data);
    }

    /// @dev Shorthand for `pUint8(p(), data)`.
    function pUint8(uint8 data) internal pure returns (DynamicBuffer memory result) {
        pUint8(result, data);
    }

    /// @dev Shorthand for `pUint16(p(), data)`.
    function pUint16(uint16 data) internal pure returns (DynamicBuffer memory result) {
        pUint16(result, data);
    }

    /// @dev Shorthand for `pUint24(p(), data)`.
    function pUint24(uint24 data) internal pure returns (DynamicBuffer memory result) {
        pUint24(result, data);
    }

    /// @dev Shorthand for `pUint32(p(), data)`.
    function pUint32(uint32 data) internal pure returns (DynamicBuffer memory result) {
        pUint32(result, data);
    }

    /// @dev Shorthand for `pUint40(p(), data)`.
    function pUint40(uint40 data) internal pure returns (DynamicBuffer memory result) {
        pUint40(result, data);
    }

    /// @dev Shorthand for `pUint48(p(), data)`.
    function pUint48(uint48 data) internal pure returns (DynamicBuffer memory result) {
        pUint48(result, data);
    }

    /// @dev Shorthand for `pUint56(p(), data)`.
    function pUint56(uint56 data) internal pure returns (DynamicBuffer memory result) {
        pUint56(result, data);
    }

    /// @dev Shorthand for `pUint64(p(), data)`.
    function pUint64(uint64 data) internal pure returns (DynamicBuffer memory result) {
        pUint64(result, data);
    }

    /// @dev Shorthand for `pUint72(p(), data)`.
    function pUint72(uint72 data) internal pure returns (DynamicBuffer memory result) {
        pUint72(result, data);
    }

    /// @dev Shorthand for `pUint80(p(), data)`.
    function pUint80(uint80 data) internal pure returns (DynamicBuffer memory result) {
        pUint80(result, data);
    }

    /// @dev Shorthand for `pUint88(p(), data)`.
    function pUint88(uint88 data) internal pure returns (DynamicBuffer memory result) {
        pUint88(result, data);
    }

    /// @dev Shorthand for `pUint96(p(), data)`.
    function pUint96(uint96 data) internal pure returns (DynamicBuffer memory result) {
        pUint96(result, data);
    }

    /// @dev Shorthand for `pUint104(p(), data)`.
    function pUint104(uint104 data) internal pure returns (DynamicBuffer memory result) {
        pUint104(result, data);
    }

    /// @dev Shorthand for `pUint112(p(), data)`.
    function pUint112(uint112 data) internal pure returns (DynamicBuffer memory result) {
        pUint112(result, data);
    }

    /// @dev Shorthand for `pUint120(p(), data)`.
    function pUint120(uint120 data) internal pure returns (DynamicBuffer memory result) {
        pUint120(result, data);
    }

    /// @dev Shorthand for `pUint128(p(), data)`.
    function pUint128(uint128 data) internal pure returns (DynamicBuffer memory result) {
        pUint128(result, data);
    }

    /// @dev Shorthand for `pUint136(p(), data)`.
    function pUint136(uint136 data) internal pure returns (DynamicBuffer memory result) {
        pUint136(result, data);
    }

    /// @dev Shorthand for `pUint144(p(), data)`.
    function pUint144(uint144 data) internal pure returns (DynamicBuffer memory result) {
        pUint144(result, data);
    }

    /// @dev Shorthand for `pUint152(p(), data)`.
    function pUint152(uint152 data) internal pure returns (DynamicBuffer memory result) {
        pUint152(result, data);
    }

    /// @dev Shorthand for `pUint160(p(), data)`.
    function pUint160(uint160 data) internal pure returns (DynamicBuffer memory result) {
        pUint160(result, data);
    }

    /// @dev Shorthand for `pUint168(p(), data)`.
    function pUint168(uint168 data) internal pure returns (DynamicBuffer memory result) {
        pUint168(result, data);
    }

    /// @dev Shorthand for `pUint176(p(), data)`.
    function pUint176(uint176 data) internal pure returns (DynamicBuffer memory result) {
        pUint176(result, data);
    }

    /// @dev Shorthand for `pUint184(p(), data)`.
    function pUint184(uint184 data) internal pure returns (DynamicBuffer memory result) {
        pUint184(result, data);
    }

    /// @dev Shorthand for `pUint192(p(), data)`.
    function pUint192(uint192 data) internal pure returns (DynamicBuffer memory result) {
        pUint192(result, data);
    }

    /// @dev Shorthand for `pUint200(p(), data)`.
    function pUint200(uint200 data) internal pure returns (DynamicBuffer memory result) {
        pUint200(result, data);
    }

    /// @dev Shorthand for `pUint208(p(), data)`.
    function pUint208(uint208 data) internal pure returns (DynamicBuffer memory result) {
        pUint208(result, data);
    }

    /// @dev Shorthand for `pUint216(p(), data)`.
    function pUint216(uint216 data) internal pure returns (DynamicBuffer memory result) {
        pUint216(result, data);
    }

    /// @dev Shorthand for `pUint224(p(), data)`.
    function pUint224(uint224 data) internal pure returns (DynamicBuffer memory result) {
        pUint224(result, data);
    }

    /// @dev Shorthand for `pUint232(p(), data)`.
    function pUint232(uint232 data) internal pure returns (DynamicBuffer memory result) {
        pUint232(result, data);
    }

    /// @dev Shorthand for `pUint240(p(), data)`.
    function pUint240(uint240 data) internal pure returns (DynamicBuffer memory result) {
        pUint240(result, data);
    }

    /// @dev Shorthand for `pUint248(p(), data)`.
    function pUint248(uint248 data) internal pure returns (DynamicBuffer memory result) {
        pUint248(result, data);
    }

    /// @dev Shorthand for `pUint256(p(), data)`.
    function pUint256(uint256 data) internal pure returns (DynamicBuffer memory result) {
        pUint256(result, data);
    }

    /// @dev Shorthand for `pBytes1(p(), data)`.
    function pBytes1(bytes1 data) internal pure returns (DynamicBuffer memory result) {
        pBytes1(result, data);
    }

    /// @dev Shorthand for `pBytes2(p(), data)`.
    function pBytes2(bytes2 data) internal pure returns (DynamicBuffer memory result) {
        pBytes2(result, data);
    }

    /// @dev Shorthand for `pBytes3(p(), data)`.
    function pBytes3(bytes3 data) internal pure returns (DynamicBuffer memory result) {
        pBytes3(result, data);
    }

    /// @dev Shorthand for `pBytes4(p(), data)`.
    function pBytes4(bytes4 data) internal pure returns (DynamicBuffer memory result) {
        pBytes4(result, data);
    }

    /// @dev Shorthand for `pBytes5(p(), data)`.
    function pBytes5(bytes5 data) internal pure returns (DynamicBuffer memory result) {
        pBytes5(result, data);
    }

    /// @dev Shorthand for `pBytes6(p(), data)`.
    function pBytes6(bytes6 data) internal pure returns (DynamicBuffer memory result) {
        pBytes6(result, data);
    }

    /// @dev Shorthand for `pBytes7(p(), data)`.
    function pBytes7(bytes7 data) internal pure returns (DynamicBuffer memory result) {
        pBytes7(result, data);
    }

    /// @dev Shorthand for `pBytes8(p(), data)`.
    function pBytes8(bytes8 data) internal pure returns (DynamicBuffer memory result) {
        pBytes8(result, data);
    }

    /// @dev Shorthand for `pBytes9(p(), data)`.
    function pBytes9(bytes9 data) internal pure returns (DynamicBuffer memory result) {
        pBytes9(result, data);
    }

    /// @dev Shorthand for `pBytes10(p(), data)`.
    function pBytes10(bytes10 data) internal pure returns (DynamicBuffer memory result) {
        pBytes10(result, data);
    }

    /// @dev Shorthand for `pBytes11(p(), data)`.
    function pBytes11(bytes11 data) internal pure returns (DynamicBuffer memory result) {
        pBytes11(result, data);
    }

    /// @dev Shorthand for `pBytes12(p(), data)`.
    function pBytes12(bytes12 data) internal pure returns (DynamicBuffer memory result) {
        pBytes12(result, data);
    }

    /// @dev Shorthand for `pBytes13(p(), data)`.
    function pBytes13(bytes13 data) internal pure returns (DynamicBuffer memory result) {
        pBytes13(result, data);
    }

    /// @dev Shorthand for `pBytes14(p(), data)`.
    function pBytes14(bytes14 data) internal pure returns (DynamicBuffer memory result) {
        pBytes14(result, data);
    }

    /// @dev Shorthand for `pBytes15(p(), data)`.
    function pBytes15(bytes15 data) internal pure returns (DynamicBuffer memory result) {
        pBytes15(result, data);
    }

    /// @dev Shorthand for `pBytes16(p(), data)`.
    function pBytes16(bytes16 data) internal pure returns (DynamicBuffer memory result) {
        pBytes16(result, data);
    }

    /// @dev Shorthand for `pBytes17(p(), data)`.
    function pBytes17(bytes17 data) internal pure returns (DynamicBuffer memory result) {
        pBytes17(result, data);
    }

    /// @dev Shorthand for `pBytes18(p(), data)`.
    function pBytes18(bytes18 data) internal pure returns (DynamicBuffer memory result) {
        pBytes18(result, data);
    }

    /// @dev Shorthand for `pBytes19(p(), data)`.
    function pBytes19(bytes19 data) internal pure returns (DynamicBuffer memory result) {
        pBytes19(result, data);
    }

    /// @dev Shorthand for `pBytes20(p(), data)`.
    function pBytes20(bytes20 data) internal pure returns (DynamicBuffer memory result) {
        pBytes20(result, data);
    }

    /// @dev Shorthand for `pBytes21(p(), data)`.
    function pBytes21(bytes21 data) internal pure returns (DynamicBuffer memory result) {
        pBytes21(result, data);
    }

    /// @dev Shorthand for `pBytes22(p(), data)`.
    function pBytes22(bytes22 data) internal pure returns (DynamicBuffer memory result) {
        pBytes22(result, data);
    }

    /// @dev Shorthand for `pBytes23(p(), data)`.
    function pBytes23(bytes23 data) internal pure returns (DynamicBuffer memory result) {
        pBytes23(result, data);
    }

    /// @dev Shorthand for `pBytes24(p(), data)`.
    function pBytes24(bytes24 data) internal pure returns (DynamicBuffer memory result) {
        pBytes24(result, data);
    }

    /// @dev Shorthand for `pBytes25(p(), data)`.
    function pBytes25(bytes25 data) internal pure returns (DynamicBuffer memory result) {
        pBytes25(result, data);
    }

    /// @dev Shorthand for `pBytes26(p(), data)`.
    function pBytes26(bytes26 data) internal pure returns (DynamicBuffer memory result) {
        pBytes26(result, data);
    }

    /// @dev Shorthand for `pBytes27(p(), data)`.
    function pBytes27(bytes27 data) internal pure returns (DynamicBuffer memory result) {
        pBytes27(result, data);
    }

    /// @dev Shorthand for `pBytes28(p(), data)`.
    function pBytes28(bytes28 data) internal pure returns (DynamicBuffer memory result) {
        pBytes28(result, data);
    }

    /// @dev Shorthand for `pBytes29(p(), data)`.
    function pBytes29(bytes29 data) internal pure returns (DynamicBuffer memory result) {
        pBytes29(result, data);
    }

    /// @dev Shorthand for `pBytes30(p(), data)`.
    function pBytes30(bytes30 data) internal pure returns (DynamicBuffer memory result) {
        pBytes30(result, data);
    }

    /// @dev Shorthand for `pBytes31(p(), data)`.
    function pBytes31(bytes31 data) internal pure returns (DynamicBuffer memory result) {
        pBytes31(result, data);
    }

    /// @dev Shorthand for `pBytes32(p(), data)`.
    function pBytes32(bytes32 data) internal pure returns (DynamicBuffer memory result) {
        pBytes32(result, data);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Helper for deallocating a automatically allocated `buffer` pointer.
    function _deallocate(DynamicBuffer memory result) private pure {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x40, result) // Deallocate, as we have already allocated.
        }
    }

    /// @dev Returns a temporary bytes string of length `n` for `data`.
    function _single(uint256 data, uint256 n) private pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := 0x00
            mstore(n, data)
            mstore(result, n)
        }
    }

    /// @dev Returns a temporary bytes string of length `n` for `data`.
    function _single(bytes32 data, uint256 n) private pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := 0x00
            mstore(0x20, data)
            mstore(result, n)
        }
    }
}
