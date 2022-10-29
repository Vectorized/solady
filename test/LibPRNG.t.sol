// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/TestPlus.sol";
import {LibPRNG} from "../src/utils/LibPRNG.sol";
import {LibSort} from "../src/utils/LibSort.sol";

contract LibPRNGTest is TestPlus {
    using LibPRNG for *;

    function testPRNGNext() public {
        unchecked {
            // Super unlikely to fail.
            for (uint256 i; i < 32; ++i) {
                LibPRNG.PRNG memory prng;
                prng.seed(i);
                uint256 r0 = prng.next();
                uint256 r1 = prng.next();
                uint256 r2 = prng.next();
                assertTrue(r0 != r1);
                assertTrue(r1 != r2);
                prng.seed(i * 2);
                uint256 r3 = prng.next();
                assertTrue(r2 != r3);
            }
        }
    }

    function testPRNGUniform() public {
        unchecked {
            LibPRNG.PRNG memory prng;
            for (uint256 i = 1; i < 32; ++i) {
                for (uint256 j; j < 32; ++j) {
                    assertTrue(prng.uniform(i) < i);
                }
            }
            for (uint256 i; i < 32; ++i) {
                assertTrue(prng.uniform(0) == 0);
            }
            // Super unlikely to fail.
            uint256 previous;
            for (uint256 i = 128; i < 256; ++i) {
                uint256 n = 1 << i;
                for (uint256 j; j < 8; ++j) {
                    uint256 r = prng.uniform(n);
                    assertTrue(r < n);
                    assertTrue(r != previous);
                    previous = r;
                }
            }
        }
    }

    function testPRNGShuffleGas() public pure {
        unchecked {
            uint256[] memory a = new uint256[](10000);
            LibPRNG.PRNG memory prng;
            prng.shuffle(a);
        }
    }

    function testPRNGShuffle() public {
        unchecked {
            LibPRNG.PRNG memory prng;
            for (uint256 s = 1; s < 9; ++s) {
                uint256 n = 1 << s; // 2, 4, 8, 16, ...
                uint256[] memory a = new uint256[](n);
                for (uint256 i; i < n; ++i) {
                    a[i] = i;
                }
                bytes32 hashBefore = keccak256(abi.encode(a));
                uint256 numDifferent;
                for (uint256 i; i < 30; ++i) {
                    prng.shuffle(a);
                    bytes32 hashAfterShuffle = keccak256(abi.encode(a));
                    if (hashBefore != hashAfterShuffle) {
                        numDifferent++;
                    }
                    LibSort.sort(a);
                    bytes32 hashAfterSort = keccak256(abi.encode(a));
                    assertTrue(hashBefore == hashAfterSort);
                }
                assertTrue(numDifferent > 1);
            }
            // Checking that we won't crash.
            for (uint256 n = 0; n < 2; ++n) {
                uint256[] memory a = new uint256[](n);
                prng.shuffle(a);
            }
        }
    }

    function testLCGGas() public {
        unchecked {
            uint256 randomness;
            for (uint256 i; i < 256; i++) {
                randomness = _stepLCG(randomness);
            }
            assertTrue(randomness != 0);
        }
    }

    function testPRNGGas() public {
        unchecked {
            LibPRNG.PRNG memory prng;
            uint256 randomness;
            for (uint256 i; i < 256; i++) {
                randomness = prng.next();
            }
            assertTrue(randomness != 0);
        }
    }

    // This is for demonstrating that the gas savings
    // over the `keccak256` approach isn't that much.
    // The multiplier and the increment are choosen for good enough
    // statistical test results.
    //
    // See: https://github.com/stevenang/randomness_testsuite
    // See: https://www.pcg-random.org/posts/does-it-beat-the-minimal-standard.html
    //
    // The xorshift is required because the raw 128 lower bits
    // of the LCG alone will not pass the tests.
    function _stepLCG(uint256 state) private pure returns (uint256 randomness) {
        /// @solidity memory-safe-assembly
        assembly {
            let a := 0xd6aad120322a96acae4ccfaf5fcd4bbfda3f2f3001db6837c0981639faa68d8d
            state := add(mul(state, a), 83)
            randomness := xor(state, shr(128, state))
        }
    }
}
