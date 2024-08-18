// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract Brutalizer {
    /// @dev Multiplier for a mulmod Lehmer psuedorandom number generator.
    /// Prime, and a primitive root of `_LPRNG_MODULO`.
    uint256 private constant _LPRNG_MULTIPLIER = 0x100000000000000000000000000000051;

    /// @dev Modulo for a mulmod Lehmer psuedorandom number generator. (prime)
    uint256 private constant _LPRNG_MODULO =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff43;

    /// @dev Fills the memory with junk, for more robust testing of inline assembly
    /// which reads/write to the memory.
    function _brutalizeMemory() internal view {
        // To prevent a solidity 0.8.13 bug.
        // See: https://blog.soliditylang.org/2022/06/15/inline-assembly-memory-side-effects-bug
        // Basically, we need to access a solidity variable from the assembly to
        // tell the compiler that this assembly block is not in isolation.
        uint256 zero;
        /// @solidity memory-safe-assembly
        assembly {
            let offset := mload(0x40) // Start the offset at the free memory pointer.
            calldatacopy(offset, zero, calldatasize())

            // Fill the 64 bytes of scratch space with garbage.
            mstore(zero, add(caller(), gas()))
            mstore(0x20, keccak256(offset, calldatasize()))
            mstore(zero, keccak256(zero, 0x40))

            let r0 := mload(zero)
            let r1 := mload(0x20)

            let cSize := add(codesize(), iszero(codesize()))
            if iszero(lt(cSize, 32)) { cSize := sub(cSize, and(mload(0x02), 0x1f)) }
            let start := mod(mload(0x10), cSize)
            let size := mul(sub(cSize, start), gt(cSize, start))
            let times := div(0x7ffff, cSize)
            if iszero(lt(times, 128)) { times := 128 }

            // Occasionally offset the offset by a pseudorandom large amount.
            // Can't be too large, or we will easily get out-of-gas errors.
            offset := add(offset, mul(iszero(and(r1, 0xf)), and(r0, 0xfffff)))

            // Fill the free memory with garbage.
            // prettier-ignore
            for { let w := not(0) } 1 {} {
                mstore(offset, r0)
                mstore(add(offset, 0x20), r1)
                offset := add(offset, 0x40)
                // We use codecopy instead of the identity precompile
                // to avoid polluting the `forge test -vvvv` output with tons of junk.
                codecopy(offset, start, size)
                codecopy(add(offset, size), 0, start)
                offset := add(offset, cSize)
                times := add(times, w) // `sub(times, 1)`.
                if iszero(times) { break }
            }
            // With a 1/32 chance, set the scratch space to zero.
            if iszero(and(31, keccak256(zero, 0x3e))) {
                mstore(0x20, zero)
                mstore(zero, zero)
            }
        }
    }

    /// @dev Fills the scratch space with junk, for more robust testing of inline assembly
    /// which reads/write to the memory.
    function _brutalizeScratchSpace() internal view {
        // To prevent a solidity 0.8.13 bug.
        // See: https://blog.soliditylang.org/2022/06/15/inline-assembly-memory-side-effects-bug
        // Basically, we need to access a solidity variable from the assembly to
        // tell the compiler that this assembly block is not in isolation.
        uint256 zero;
        /// @solidity memory-safe-assembly
        assembly {
            let offset := mload(0x40) // Start the offset at the free memory pointer.
            calldatacopy(offset, zero, calldatasize())

            // Fill the 64 bytes of scratch space with garbage.
            mstore(zero, add(caller(), gas()))
            mstore(0x20, keccak256(offset, calldatasize()))
            mstore(zero, keccak256(zero, 0x40))
            // With a 1/32 chance, set the scratch space to zero.
            if iszero(and(31, keccak256(zero, 0x3e))) {
                mstore(0x20, zero)
                mstore(zero, zero)
            }
        }
    }

    /// @dev Fills the lower memory with junk, for more robust testing of inline assembly
    /// which reads/write to the memory.
    /// For efficiency, this only fills a small portion of the free memory.
    function _brutalizeLowerMemory() internal view {
        // To prevent a solidity 0.8.13 bug.
        // See: https://blog.soliditylang.org/2022/06/15/inline-assembly-memory-side-effects-bug
        // Basically, we need to access a solidity variable from the assembly to
        // tell the compiler that this assembly block is not in isolation.
        uint256 zero;
        /// @solidity memory-safe-assembly
        assembly {
            let offset := mload(0x40) // Start the offset at the free memory pointer.
            calldatacopy(offset, zero, calldatasize())

            // Fill the 64 bytes of scratch space with garbage.
            mstore(zero, add(caller(), gas()))
            mstore(0x20, keccak256(offset, calldatasize()))
            mstore(zero, keccak256(zero, 0x40))

            for { let r := keccak256(0x10, 0x20) } 1 {} {
                if iszero(and(7, r)) {
                    let x := keccak256(zero, 0x40)
                    mstore(offset, x)
                    mstore(add(0x20, offset), x)
                    mstore(add(0x40, offset), x)
                    mstore(add(0x60, offset), x)
                    mstore(add(0x80, offset), x)
                    mstore(add(0xa0, offset), x)
                    mstore(add(0xc0, offset), x)
                    mstore(add(0xe0, offset), x)
                    mstore(add(0x100, offset), x)
                    mstore(add(0x120, offset), x)
                    mstore(add(0x140, offset), x)
                    mstore(add(0x160, offset), x)
                    mstore(add(0x180, offset), x)
                    mstore(add(0x1a0, offset), x)
                    mstore(add(0x1c0, offset), x)
                    mstore(add(0x1e0, offset), x)
                    mstore(add(0x200, offset), x)
                    mstore(add(0x220, offset), x)
                    mstore(add(0x240, offset), x)
                    mstore(add(0x260, offset), x)
                    break
                }
                codecopy(offset, byte(0, r), codesize())
                break
            }
            // With a 1/32 chance, set the scratch space to zero.
            if iszero(and(31, keccak256(zero, 0x3e))) {
                mstore(0x20, zero)
                mstore(zero, zero)
            }
        }
    }

    /// @dev Fills the memory with junk, for more robust testing of inline assembly
    /// which reads/write to the memory.
    modifier brutalizeMemory() {
        _brutalizeMemory();
        _;
        _checkMemory();
    }

    /// @dev Fills the scratch space with junk, for more robust testing of inline assembly
    /// which reads/write to the memory.
    modifier brutalizeScratchSpace() {
        _brutalizeScratchSpace();
        _;
        _checkMemory();
    }

    /// @dev Fills the lower memory with junk, for more robust testing of inline assembly
    /// which reads/write to the memory.
    modifier brutalizeLowerMemory() {
        _brutalizeLowerMemory();
        _;
        _checkMemory();
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalized(address value) internal pure returns (address) {
        uint256 r = uint256(uint160(value));
        return address(uint160((__brutalizerRandomness(r) << 160) ^ r));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint8(uint8 value) internal pure returns (uint8) {
        return uint8((__brutalizerRandomness(value) << 8) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes1(bytes1 value) internal pure returns (bytes1) {
        return bytes1(__brutalizedBytesN(value, 8));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint16(uint16 value) internal pure returns (uint16) {
        return uint16((__brutalizerRandomness(value) << 16) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes2(bytes2 value) internal pure returns (bytes2) {
        return bytes2(__brutalizedBytesN(value, 16));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint24(uint24 value) internal pure returns (uint24) {
        return uint24((__brutalizerRandomness(value) << 24) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes3(bytes3 value) internal pure returns (bytes3) {
        return bytes3(__brutalizedBytesN(value, 24));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint32(uint32 value) internal pure returns (uint32) {
        return uint32((__brutalizerRandomness(value) << 32) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes4(bytes4 value) internal pure returns (bytes4) {
        return bytes4(__brutalizedBytesN(value, 32));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint40(uint40 value) internal pure returns (uint40) {
        return uint40((__brutalizerRandomness(value) << 40) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes5(bytes5 value) internal pure returns (bytes5) {
        return bytes5(__brutalizedBytesN(value, 40));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint48(uint48 value) internal pure returns (uint48) {
        return uint48((__brutalizerRandomness(value) << 48) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes6(bytes6 value) internal pure returns (bytes6) {
        return bytes6(__brutalizedBytesN(value, 48));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint56(uint56 value) internal pure returns (uint56) {
        return uint56((__brutalizerRandomness(value) << 56) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes7(bytes7 value) internal pure returns (bytes7) {
        return bytes7(__brutalizedBytesN(value, 56));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint64(uint64 value) internal pure returns (uint64) {
        return uint64((__brutalizerRandomness(value) << 64) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes8(bytes8 value) internal pure returns (bytes8) {
        return bytes8(__brutalizedBytesN(value, 64));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint72(uint72 value) internal pure returns (uint72) {
        return uint72((__brutalizerRandomness(value) << 72) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes9(bytes9 value) internal pure returns (bytes9) {
        return bytes9(__brutalizedBytesN(value, 72));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint80(uint80 value) internal pure returns (uint80) {
        return uint80((__brutalizerRandomness(value) << 80) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes10(bytes10 value) internal pure returns (bytes10) {
        return bytes10(__brutalizedBytesN(value, 80));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint88(uint88 value) internal pure returns (uint88) {
        return uint88((__brutalizerRandomness(value) << 88) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes11(bytes11 value) internal pure returns (bytes11) {
        return bytes11(__brutalizedBytesN(value, 88));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint96(uint96 value) internal pure returns (uint96) {
        return uint96((__brutalizerRandomness(value) << 96) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes12(bytes12 value) internal pure returns (bytes12) {
        return bytes12(__brutalizedBytesN(value, 96));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint104(uint104 value) internal pure returns (uint104) {
        return uint104((__brutalizerRandomness(value) << 104) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes13(bytes13 value) internal pure returns (bytes13) {
        return bytes13(__brutalizedBytesN(value, 104));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint112(uint112 value) internal pure returns (uint112) {
        return uint112((__brutalizerRandomness(value) << 112) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes14(bytes14 value) internal pure returns (bytes14) {
        return bytes14(__brutalizedBytesN(value, 112));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint120(uint120 value) internal pure returns (uint120) {
        return uint120((__brutalizerRandomness(value) << 120) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes15(bytes15 value) internal pure returns (bytes15) {
        return bytes15(__brutalizedBytesN(value, 120));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint128(uint128 value) internal pure returns (uint128) {
        return uint128((__brutalizerRandomness(value) << 128) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes16(bytes16 value) internal pure returns (bytes16) {
        return bytes16(__brutalizedBytesN(value, 128));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint136(uint136 value) internal pure returns (uint136) {
        return uint136((__brutalizerRandomness(value) << 136) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes17(bytes17 value) internal pure returns (bytes17) {
        return bytes17(__brutalizedBytesN(value, 136));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint144(uint144 value) internal pure returns (uint144) {
        return uint144((__brutalizerRandomness(value) << 144) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes18(bytes18 value) internal pure returns (bytes18) {
        return bytes18(__brutalizedBytesN(value, 144));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint152(uint152 value) internal pure returns (uint152) {
        return uint152((__brutalizerRandomness(value) << 152) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes19(bytes19 value) internal pure returns (bytes19) {
        return bytes19(__brutalizedBytesN(value, 152));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint160(uint160 value) internal pure returns (uint160) {
        return uint160((__brutalizerRandomness(value) << 160) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes20(bytes20 value) internal pure returns (bytes20) {
        return bytes20(__brutalizedBytesN(value, 160));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint168(uint168 value) internal pure returns (uint168) {
        return uint168((__brutalizerRandomness(value) << 168) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes21(bytes21 value) internal pure returns (bytes21) {
        return bytes21(__brutalizedBytesN(value, 168));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint176(uint176 value) internal pure returns (uint176) {
        return uint176((__brutalizerRandomness(value) << 176) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes22(bytes22 value) internal pure returns (bytes22) {
        return bytes22(__brutalizedBytesN(value, 176));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint184(uint184 value) internal pure returns (uint184) {
        return uint184((__brutalizerRandomness(value) << 184) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes23(bytes23 value) internal pure returns (bytes23) {
        return bytes23(__brutalizedBytesN(value, 184));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint192(uint192 value) internal pure returns (uint192) {
        return uint192((__brutalizerRandomness(value) << 192) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes24(bytes24 value) internal pure returns (bytes24) {
        return bytes24(__brutalizedBytesN(value, 192));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint200(uint200 value) internal pure returns (uint200) {
        return uint200((__brutalizerRandomness(value) << 200) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes25(bytes25 value) internal pure returns (bytes25) {
        return bytes25(__brutalizedBytesN(value, 200));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint208(uint208 value) internal pure returns (uint208) {
        return uint208((__brutalizerRandomness(value) << 208) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes26(bytes26 value) internal pure returns (bytes26) {
        return bytes26(__brutalizedBytesN(value, 208));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint216(uint216 value) internal pure returns (uint216) {
        return uint216((__brutalizerRandomness(value) << 216) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes27(bytes27 value) internal pure returns (bytes27) {
        return bytes27(__brutalizedBytesN(value, 216));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint224(uint224 value) internal pure returns (uint224) {
        return uint224((__brutalizerRandomness(value) << 224) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes28(bytes28 value) internal pure returns (bytes28) {
        return bytes28(__brutalizedBytesN(value, 224));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint232(uint232 value) internal pure returns (uint232) {
        return uint232((__brutalizerRandomness(value) << 232) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes29(bytes29 value) internal pure returns (bytes29) {
        return bytes29(__brutalizedBytesN(value, 232));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint240(uint240 value) internal pure returns (uint240) {
        return uint240((__brutalizerRandomness(value) << 240) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes30(bytes30 value) internal pure returns (bytes30) {
        return bytes30(__brutalizedBytesN(value, 240));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalizedUint248(uint248 value) internal pure returns (uint248) {
        return uint248((__brutalizerRandomness(value) << 248) ^ uint256(value));
    }

    /// @dev Returns the result with the lower bits dirtied.
    function _brutalizedBytes31(bytes31 value) internal pure returns (bytes31) {
        return bytes31(__brutalizedBytesN(value, 248));
    }

    /// @dev Returns the result with the upper bits dirtied.
    function _brutalized(bool value) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, xor(add(value, calldataload(0x00)), mload(0x10)))
            mstore(0x20, calldataload(0x04))
            let r := keccak256(0x00, 0x88)
            mstore(0x10, r)
            result := mul(iszero(iszero(value)), r)
            if iszero(and(1, shr(128, mulmod(r, _LPRNG_MULTIPLIER, _LPRNG_MODULO)))) {
                result := iszero(iszero(result))
            }
        }
    }

    /// @dev Returns a brutalizer randomness.
    function __brutalizedBytesN(bytes32 x, uint256 s) private pure returns (bytes32) {
        return bytes32(uint256((__brutalizerRandomness(uint256(x)) >> s) ^ uint256(x)));
    }

    /// @dev Returns a brutalizer randomness.
    function __brutalizerRandomness(uint256 seed) private pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mulmod(seed, _LPRNG_MULTIPLIER, _LPRNG_MODULO)
            mstore(0x00, xor(add(result, calldataload(0x00)), mload(0x10)))
            mstore(0x20, calldataload(0x04))
            result := keccak256(0x00, 0x88)
            mstore(0x10, result)
            result := mul(iszero(shr(251, result)), result)
        }
    }

    /// @dev Misaligns the free memory pointer.
    /// The free memory pointer has a 1/32 chance to be aligned.
    function _misalignFreeMemoryPointer() internal pure {
        uint256 twoWords = 0x40;
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(twoWords)
            m := add(m, mul(and(keccak256(0x00, twoWords), 0x1f), iszero(and(m, 0x1f))))
            mstore(twoWords, m)
        }
    }

    /// @dev Check if the free memory pointer and the zero slot are not contaminated.
    /// Useful for cases where these slots are used for temporary storage.
    function _checkMemory() internal pure {
        bool zeroSlotIsNotZero;
        bool freeMemoryPointerOverflowed;
        /// @solidity memory-safe-assembly
        assembly {
            // Write ones to the free memory, to make subsequent checks fail if
            // insufficient memory is allocated.
            mstore(mload(0x40), not(0))
            // Test at a lower, but reasonable limit for more safety room.
            if gt(mload(0x40), 0xffffffff) { freeMemoryPointerOverflowed := 1 }
            // Check the value of the zero slot.
            zeroSlotIsNotZero := mload(0x60)
        }
        if (freeMemoryPointerOverflowed) revert("`0x40` overflowed!");
        if (zeroSlotIsNotZero) revert("`0x60` is not zero!");
    }

    /// @dev Check if `s`:
    /// - Has sufficient memory allocated.
    /// - Is zero right padded (cuz some frontends like Etherscan has issues
    ///   with decoding non-zero-right-padded strings).
    function _checkMemory(bytes memory s) internal pure {
        bool notZeroRightPadded;
        bool insufficientMalloc;
        /// @solidity memory-safe-assembly
        assembly {
            // Write ones to the free memory, to make subsequent checks fail if
            // insufficient memory is allocated.
            mstore(mload(0x40), not(0))
            let length := mload(s)
            let lastWord := mload(add(add(s, 0x20), and(length, not(0x1f))))
            let remainder := and(length, 0x1f)
            if remainder { if shl(mul(8, remainder), lastWord) { notZeroRightPadded := 1 } }
            // Check if the memory allocated is sufficient.
            if length { if gt(add(add(s, 0x20), length), mload(0x40)) { insufficientMalloc := 1 } }
        }
        if (notZeroRightPadded) revert("Not zero right padded!");
        if (insufficientMalloc) revert("Insufficient memory allocation!");
        _checkMemory();
    }

    /// @dev For checking the memory allocation for string `s`.
    function _checkMemory(string memory s) internal pure {
        _checkMemory(bytes(s));
    }
}
