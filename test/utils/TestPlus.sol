// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";

contract TestPlus is Test {
    /// @dev Fills the memory with junk, for more robust testing of inline assembly
    /// which reads/write to the memory.
    modifier brutalizeMemory() {
        // To prevent a solidity 0.8.13 bug.
        // See: https://blog.soliditylang.org/2022/06/15/inline-assembly-memory-side-effects-bug
        // Basically, we need to access a solidity variable from the assembly to
        // tell the compiler that this assembly block is not in isolation.
        {
            uint256 zero;
            /// @solidity memory-safe-assembly
            assembly {
                let offset := mload(0x40) // Start the offset at the free memory pointer.
                calldatacopy(offset, zero, calldatasize())

                // Fill the 64 bytes of scratch space with garbage.
                mstore(zero, caller())
                mstore(0x20, keccak256(offset, calldatasize()))
                mstore(zero, keccak256(zero, 0x40))

                let r0 := mload(zero)
                let r1 := mload(0x20)

                let cSize := add(codesize(), iszero(codesize()))
                if iszero(lt(cSize, 32)) { cSize := sub(cSize, and(mload(0x02), 31)) }
                let start := mod(mload(0x10), cSize)
                let size := mul(sub(cSize, start), gt(cSize, start))
                let times := div(0x7ffff, cSize)
                if iszero(lt(times, 128)) { times := 128 }

                // Occasionally offset the offset by a psuedorandom large amount.
                // Can't be too large, or we will easily get out-of-gas errors.
                offset := add(offset, mul(iszero(and(r1, 0xf)), and(r0, 0xfffff)))

                // Fill the free memory with garbage.
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
            }
        }

        _;

        _checkMemory();
    }

    /// @dev Returns a psuedorandom random number from [0 .. 2**256 - 1] (inclusive).
    /// For usage in fuzz tests, please ensure that the function has an unnamed uint256 argument.
    /// e.g. `testSomething(uint256) public`.
    function _random() internal returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // This is the keccak256 of a very long string I randomly mashed on my keyboard.
            let sSlot := 0xd715531fe383f818c5f158c342925dcf01b954d24678ada4d07c36af0f20e1ee
            let sValue := sload(sSlot)

            mstore(0x20, sValue)
            r := keccak256(0x20, 0x40)

            // If the storage is uninitialized, initialize it to the keccak256 of the calldata.
            if iszero(sValue) {
                sValue := sSlot
                let m := mload(0x40)
                calldatacopy(m, 0, calldatasize())
                r := keccak256(m, calldatasize())
            }
            sstore(sSlot, add(r, 1))

            // Do some biased sampling for more robust tests.
            for {} 1 {} {
                let d := byte(0, r)
                // With a 1/256 chance, randomly set `r` to any of 0,1,2.
                if iszero(d) {
                    r := and(r, 3)
                    break
                }
                // With a 1/2 chance, set `r` to near a random power of 2.
                if iszero(and(2, d)) {
                    // Set `t` either `not(0)` or `xor(sValue, r)`.
                    let t := xor(not(0), mul(iszero(and(4, d)), not(xor(sValue, r))))
                    // Set `r` to `t` shifted left or right by a random multiple of 8.
                    switch and(8, d)
                    case 0 {
                        if iszero(and(16, d)) { t := 1 }
                        r := add(shl(shl(3, and(byte(3, r), 31)), t), sub(and(r, 7), 3))
                    }
                    default {
                        if iszero(and(16, d)) { t := shl(255, 1) }
                        r := add(shr(shl(3, and(byte(3, r), 31)), t), sub(and(r, 7), 3))
                    }
                    // With a 1/2 chance, negate `r`.
                    if iszero(and(32, d)) { r := not(r) }
                    break
                }
                // Otherwise, just set `r` to `xor(sValue, r)`.
                r := xor(sValue, r)
                break
            }
        }
    }

    /// @dev Returns a random signer and its private key.
    function _randomSigner() internal returns (address signer, uint256 privateKey) {
        uint256 privateKeyMax = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140;
        privateKey = _bound(_random(), 1, privateKeyMax);
        signer = vm.addr(privateKey);
    }

    /// @dev Rounds up the free memory pointer the the next word boundary.
    /// Sometimes, some Solidity operations causes the free memory pointer to be misaligned.
    function _roundUpFreeMemoryPointer() internal pure {
        // To prevent a solidity 0.8.13 bug.
        // See: https://blog.soliditylang.org/2022/06/15/inline-assembly-memory-side-effects-bug
        // Basically, we need to access a solidity variable from the assembly to
        // tell the compiler that this assembly block is not in isolation.
        uint256 twoWords = 0x40;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(twoWords, and(add(mload(twoWords), 31), not(31)))
        }
    }

    /// @dev Misaligns the free memory pointer.
    function _misalignFreeMemoryPointer() internal pure {
        uint256 twoWords = 0x40;
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(twoWords)
            m := add(m, mul(and(keccak256(0x00, twoWords), 31), iszero(and(m, 31))))
            mstore(twoWords, add(m, iszero(and(m, 31))))
        }
    }

    /// @dev Check if the free memory pointer and the zero slot are not contaminated.
    /// Useful for cases where these slots are used for temporary storage.
    function _checkMemory() internal pure {
        bool zeroSlotIsNotZero;
        bool freeMemoryPointerOverflowed;
        /// @solidity memory-safe-assembly
        assembly {
            // Test at a lower, but reasonable limit for more safety room.
            if gt(mload(0x40), 0xffffffff) { freeMemoryPointerOverflowed := 1 }
            // Check the value of the zero slot.
            zeroSlotIsNotZero := mload(0x60)
        }
        if (freeMemoryPointerOverflowed) revert("Free memory pointer overflowed!");
        if (zeroSlotIsNotZero) revert("Zero slot is not zero!");
    }

    /// @dev Check if `s`:
    /// - Has sufficient memory allocated.
    /// - Is aligned to a word boundary
    /// - Is zero right padded (cuz some frontends like Etherscan has issues
    ///   with decoding non-zero-right-padded strings)
    function _checkMemory(bytes memory s) internal pure {
        bool notZeroRightPadded;
        bool fmpNotWordAligned;
        bool insufficientMalloc;
        /// @solidity memory-safe-assembly
        assembly {
            let length := mload(s)
            let lastWord := mload(add(add(s, 0x20), and(length, not(31))))
            let remainder := and(length, 31)
            if remainder { if shl(mul(8, remainder), lastWord) { notZeroRightPadded := 1 } }
            // Check if the free memory pointer is a multiple of 32.
            fmpNotWordAligned := and(mload(0x40), 31)
            // Write some garbage to the free memory.
            mstore(mload(0x40), keccak256(0x00, 0x60))
            // Check if the memory allocated is sufficient.
            if length { if gt(add(add(s, 0x20), length), mload(0x40)) { insufficientMalloc := 1 } }
        }
        if (notZeroRightPadded) revert("Not zero right padded!");
        if (fmpNotWordAligned) revert("Free memory pointer `0x40` not 32-byte word aligned!");
        if (insufficientMalloc) revert("Insufficient memory allocation!");
        _checkMemory();
    }

    /// @dev For checking the memory allocation for string `s`.
    function _checkMemory(string memory s) internal pure {
        _checkMemory(bytes(s));
    }

    /// @dev Adapted from:
    /// https://github.com/foundry-rs/forge-std/blob/ff4bf7db008d096ea5a657f2c20516182252a3ed/src/StdUtils.sol#L10
    /// Differentially fuzzed tested against the original implementation.
    function _bound(uint256 x, uint256 min, uint256 max)
        internal
        pure
        virtual
        returns (uint256 result)
    {
        require(min <= max, "_bound(uint256,uint256,uint256): Max is less than min.");

        /// @solidity memory-safe-assembly
        assembly {
            for {} 1 {} {
                // If `x` is between `min` and `max`, return `x` directly.
                // This is to ensure that dictionary values
                // do not get shifted if the min is nonzero.
                // More info: https://github.com/foundry-rs/forge-std/issues/188
                if iszero(or(lt(x, min), gt(x, max))) {
                    result := x
                    break
                }

                let size := add(sub(max, min), 1)
                if and(iszero(gt(x, 3)), gt(size, x)) {
                    result := add(min, x)
                    break
                }

                let w := not(0)
                if and(iszero(lt(x, sub(0, 4))), gt(size, sub(w, x))) {
                    result := sub(max, sub(w, x))
                    break
                }

                // Otherwise, wrap x into the range [min, max],
                // i.e. the range is inclusive.
                if iszero(lt(x, max)) {
                    let d := sub(x, max)
                    let r := mod(d, size)
                    if iszero(r) {
                        result := max
                        break
                    }
                    result := add(add(min, r), w)
                    break
                }
                let d := sub(min, x)
                let r := mod(d, size)
                if iszero(r) {
                    result := min
                    break
                }
                result := add(sub(max, r), 1)
                break
            }
        }
    }

    /// @dev This function will make forge's gas output display the approximate codesize of
    /// the test contract as the amount of gas burnt. Useful for quick guess checking if
    /// certain optimizations actually compiles to similar bytecode.
    function test__codesize() external view {
        /// @solidity memory-safe-assembly
        assembly {
            // If the caller is the contract itself (i.e. recursive call), burn all the gas.
            if eq(caller(), address()) { invalid() }
            mstore(0x00, 0xf09ff470) // Store the function selector of `test__codesize()`.
            pop(staticcall(codesize(), address(), 0x1c, 0x04, 0x00, 0x00))
        }
    }
}
