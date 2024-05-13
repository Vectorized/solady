// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for buffers with automatic capacity resizing.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/DynamicBuffer.sol)
/// @author Modified from cozyco (https://github.com/samkingco/cozyco/blob/main/contracts/utils/DynamicBuffer.sol)
library DynamicBufferLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Type to represent a dynamic buffer in memory.
    /// You can directly assign to `data`, and the `p` function will
    /// take care of the memory allocation.
    struct DynamicBuffer {
        bytes data;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OPERATIONS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

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
    /// Returns the same buffer, so that it can be used for function chaining.
    function p(DynamicBuffer memory buffer, bytes memory data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = buffer;
        if (data.length == 0) return result;
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
    /// Returns the same buffer, so that it can be used for function chaining.
    function p(DynamicBuffer memory buffer, bytes memory data0, bytes memory data1)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(p(buffer, data0), data1);
    }

    /// @dev Appends `data0` .. `data2` to `buffer`.
    /// Returns the same buffer, so that it can be used for function chaining.
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
    /// Returns the same buffer, so that it can be used for function chaining.
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
    /// Returns the same buffer, so that it can be used for function chaining.
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
    /// Returns the same buffer, so that it can be used for function chaining.
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
    /// Returns the same buffer, so that it can be used for function chaining.
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
    /// Returns the same buffer, so that it can be used for function chaining.
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
    /// Returns the same buffer, so that it can be used for function chaining.
    function pAddress(DynamicBuffer memory buffer, address data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(uint256(uint160(data)), 20));
    }

    /// @dev Appends `abi.encodePacked(uint8(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint8(DynamicBuffer memory buffer, uint8 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 1));
    }

    /// @dev Appends `abi.encodePacked(uint16(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint16(DynamicBuffer memory buffer, uint16 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 2));
    }

    /// @dev Appends `abi.encodePacked(uint24(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint24(DynamicBuffer memory buffer, uint24 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 3));
    }

    /// @dev Appends `abi.encodePacked(uint32(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint32(DynamicBuffer memory buffer, uint32 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 4));
    }

    /// @dev Appends `abi.encodePacked(uint40(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint40(DynamicBuffer memory buffer, uint40 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 5));
    }

    /// @dev Appends `abi.encodePacked(uint48(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint48(DynamicBuffer memory buffer, uint48 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 6));
    }

    /// @dev Appends `abi.encodePacked(uint56(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint56(DynamicBuffer memory buffer, uint56 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 7));
    }

    /// @dev Appends `abi.encodePacked(uint64(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint64(DynamicBuffer memory buffer, uint64 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 8));
    }

    /// @dev Appends `abi.encodePacked(uint72(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint72(DynamicBuffer memory buffer, uint72 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 9));
    }

    /// @dev Appends `abi.encodePacked(uint80(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint80(DynamicBuffer memory buffer, uint80 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 10));
    }

    /// @dev Appends `abi.encodePacked(uint88(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint88(DynamicBuffer memory buffer, uint88 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 11));
    }

    /// @dev Appends `abi.encodePacked(uint96(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint96(DynamicBuffer memory buffer, uint96 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 12));
    }

    /// @dev Appends `abi.encodePacked(uint104(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint104(DynamicBuffer memory buffer, uint104 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 13));
    }

    /// @dev Appends `abi.encodePacked(uint112(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint112(DynamicBuffer memory buffer, uint112 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 14));
    }

    /// @dev Appends `abi.encodePacked(uint120(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint120(DynamicBuffer memory buffer, uint120 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 15));
    }

    /// @dev Appends `abi.encodePacked(uint128(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint128(DynamicBuffer memory buffer, uint128 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 16));
    }

    /// @dev Appends `abi.encodePacked(uint136(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint136(DynamicBuffer memory buffer, uint136 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 17));
    }

    /// @dev Appends `abi.encodePacked(uint144(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint144(DynamicBuffer memory buffer, uint144 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 18));
    }

    /// @dev Appends `abi.encodePacked(uint152(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint152(DynamicBuffer memory buffer, uint152 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 19));
    }

    /// @dev Appends `abi.encodePacked(uint160(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint160(DynamicBuffer memory buffer, uint160 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 20));
    }

    /// @dev Appends `abi.encodePacked(uint168(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint168(DynamicBuffer memory buffer, uint168 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 21));
    }

    /// @dev Appends `abi.encodePacked(uint176(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint176(DynamicBuffer memory buffer, uint176 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 22));
    }

    /// @dev Appends `abi.encodePacked(uint184(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint184(DynamicBuffer memory buffer, uint184 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 23));
    }

    /// @dev Appends `abi.encodePacked(uint192(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint192(DynamicBuffer memory buffer, uint192 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 24));
    }

    /// @dev Appends `abi.encodePacked(uint200(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint200(DynamicBuffer memory buffer, uint200 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 25));
    }

    /// @dev Appends `abi.encodePacked(uint208(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint208(DynamicBuffer memory buffer, uint208 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 26));
    }

    /// @dev Appends `abi.encodePacked(uint216(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint216(DynamicBuffer memory buffer, uint216 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 27));
    }

    /// @dev Appends `abi.encodePacked(uint224(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint224(DynamicBuffer memory buffer, uint224 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 28));
    }

    /// @dev Appends `abi.encodePacked(uint232(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint232(DynamicBuffer memory buffer, uint232 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 29));
    }

    /// @dev Appends `abi.encodePacked(uint240(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint240(DynamicBuffer memory buffer, uint240 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 30));
    }

    /// @dev Appends `abi.encodePacked(uint248(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint248(DynamicBuffer memory buffer, uint248 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 31));
    }

    /// @dev Appends `abi.encodePacked(uint256(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pUint256(DynamicBuffer memory buffer, uint256 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(data, 32));
    }

    /// @dev Appends `abi.encodePacked(bytes1(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes1(DynamicBuffer memory buffer, bytes1 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 1));
    }

    /// @dev Appends `abi.encodePacked(bytes2(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes2(DynamicBuffer memory buffer, bytes2 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 2));
    }

    /// @dev Appends `abi.encodePacked(bytes3(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes3(DynamicBuffer memory buffer, bytes3 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 3));
    }

    /// @dev Appends `abi.encodePacked(bytes4(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes4(DynamicBuffer memory buffer, bytes4 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 4));
    }

    /// @dev Appends `abi.encodePacked(bytes5(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes5(DynamicBuffer memory buffer, bytes5 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 5));
    }

    /// @dev Appends `abi.encodePacked(bytes6(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes6(DynamicBuffer memory buffer, bytes6 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 6));
    }

    /// @dev Appends `abi.encodePacked(bytes7(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes7(DynamicBuffer memory buffer, bytes7 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 7));
    }

    /// @dev Appends `abi.encodePacked(bytes8(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes8(DynamicBuffer memory buffer, bytes8 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 8));
    }

    /// @dev Appends `abi.encodePacked(bytes9(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes9(DynamicBuffer memory buffer, bytes9 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 9));
    }

    /// @dev Appends `abi.encodePacked(bytes10(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes10(DynamicBuffer memory buffer, bytes10 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 10));
    }

    /// @dev Appends `abi.encodePacked(bytes11(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes11(DynamicBuffer memory buffer, bytes11 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 11));
    }

    /// @dev Appends `abi.encodePacked(bytes12(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes12(DynamicBuffer memory buffer, bytes12 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 12));
    }

    /// @dev Appends `abi.encodePacked(bytes13(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes13(DynamicBuffer memory buffer, bytes13 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 13));
    }

    /// @dev Appends `abi.encodePacked(bytes14(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes14(DynamicBuffer memory buffer, bytes14 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 14));
    }

    /// @dev Appends `abi.encodePacked(bytes15(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes15(DynamicBuffer memory buffer, bytes15 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 15));
    }

    /// @dev Appends `abi.encodePacked(bytes16(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes16(DynamicBuffer memory buffer, bytes16 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 16));
    }

    /// @dev Appends `abi.encodePacked(bytes17(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes17(DynamicBuffer memory buffer, bytes17 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 17));
    }

    /// @dev Appends `abi.encodePacked(bytes18(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes18(DynamicBuffer memory buffer, bytes18 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 18));
    }

    /// @dev Appends `abi.encodePacked(bytes19(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes19(DynamicBuffer memory buffer, bytes19 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 19));
    }

    /// @dev Appends `abi.encodePacked(bytes20(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes20(DynamicBuffer memory buffer, bytes20 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 20));
    }

    /// @dev Appends `abi.encodePacked(bytes21(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes21(DynamicBuffer memory buffer, bytes21 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 21));
    }

    /// @dev Appends `abi.encodePacked(bytes22(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes22(DynamicBuffer memory buffer, bytes22 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 22));
    }

    /// @dev Appends `abi.encodePacked(bytes23(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes23(DynamicBuffer memory buffer, bytes23 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 23));
    }

    /// @dev Appends `abi.encodePacked(bytes24(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes24(DynamicBuffer memory buffer, bytes24 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 24));
    }

    /// @dev Appends `abi.encodePacked(bytes25(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes25(DynamicBuffer memory buffer, bytes25 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 25));
    }

    /// @dev Appends `abi.encodePacked(bytes26(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes26(DynamicBuffer memory buffer, bytes26 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 26));
    }

    /// @dev Appends `abi.encodePacked(bytes27(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes27(DynamicBuffer memory buffer, bytes27 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 27));
    }

    /// @dev Appends `abi.encodePacked(bytes28(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes28(DynamicBuffer memory buffer, bytes28 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 28));
    }

    /// @dev Appends `abi.encodePacked(bytes29(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes29(DynamicBuffer memory buffer, bytes29 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 29));
    }

    /// @dev Appends `abi.encodePacked(bytes30(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes30(DynamicBuffer memory buffer, bytes30 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 30));
    }

    /// @dev Appends `abi.encodePacked(bytes31(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes31(DynamicBuffer memory buffer, bytes31 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 31));
    }

    /// @dev Appends `abi.encodePacked(bytes32(data))` to buffer.
    /// Returns the same buffer, so that it can be used for function chaining.
    function pBytes32(DynamicBuffer memory buffer, bytes32 data)
        internal
        pure
        returns (DynamicBuffer memory result)
    {
        _deallocate(result);
        result = p(buffer, _single(bytes32(data), 32));
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
