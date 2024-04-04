// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {LibPRNG} from "../src/utils/LibPRNG.sol";
import {LibSort} from "../src/utils/LibSort.sol";
import {FixedPointMathLib} from "../src/utils/FixedPointMathLib.sol";

contract LibPRNGTest is SoladyTest {
    using LibPRNG for *;

    LibPRNG.LazyShuffler internal _lazyShuffler0;
    LibPRNG.LazyShuffler internal _lazyShuffler1;

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

    function testPRNGShuffleBytesGas() public pure {
        unchecked {
            bytes memory a = new bytes(10000);
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
                for (;;) {
                    prng.shuffle(a);
                    bytes32 hashAfterShuffle = keccak256(abi.encode(a));
                    LibSort.sort(a);
                    bytes32 hashAfterSort = keccak256(abi.encode(a));
                    assertTrue(hashBefore == hashAfterSort);
                    if (hashBefore != hashAfterShuffle) break;
                }
            }
            // Checking that we won't crash.
            for (uint256 n = 0; n < 2; ++n) {
                uint256[] memory a = new uint256[](n);
                prng.shuffle(a);
            }
        }
    }

    function testPRNGShuffleBytes() public {
        unchecked {
            LibPRNG.PRNG memory prng;
            for (uint256 s = 1; s < 9; ++s) {
                uint256 n = 1 << s; // 2, 4, 8, 16, ...
                bytes memory a = new bytes(n);
                for (uint256 i; i < n; ++i) {
                    a[i] = bytes1(uint8(i & 0xff));
                }
                bytes32 hashBefore = keccak256(abi.encode(a));
                uint256 checksumBefore = _bytesOrderAgnosticChecksum(a);
                for (uint256 i; i < 30; ++i) {
                    prng.shuffle(a);
                    assertEq(_bytesOrderAgnosticChecksum(a), checksumBefore);
                    bytes32 hashAfterShuffle = keccak256(abi.encode(a));
                    if (hashBefore != hashAfterShuffle) break;
                }
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

    function _bytesOrderAgnosticChecksum(bytes memory a) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            for { let n := mload(a) } n { n := sub(n, 1) } {
                result := add(result, and(mload(add(a, n)), 0xff))
            }
        }
    }

    // This is for demonstrating that the gas savings
    // over the `keccak256` approach isn't that much.
    // The multiplier and the increment are chosen for good enough
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

    function testStandardNormalWad() public {
        LibPRNG.PRNG memory prng;
        unchecked {
            uint256 n = 1000;
            int256 oldM;
            int256 newM;
            int256 oldS;
            int256 newS;
            for (uint256 i; i != n;) {
                uint256 gasBefore = gasleft();
                int256 x = prng.standardNormalWad();
                uint256 gasUsed = gasBefore - gasleft();
                if (++i == 1) {
                    oldM = (newM = x);
                } else {
                    newM = oldM + (x - oldM) / int256(i);
                    newS = oldS + (x - oldM) * (x - newM);
                    oldM = newM;
                    oldS = newS;
                }
                emit LogInt("standardNormalWad", x);
                emit LogUint("gasUsed", gasUsed);
            }
            int256 wad = int256(FixedPointMathLib.WAD);
            emit LogInt("mean", newM);
            int256 sd = int256(FixedPointMathLib.sqrt(uint256(newS / int256(n - 1))));
            assertLt(FixedPointMathLib.abs(newM), uint256(wad / 8));
            emit LogInt("standard deviation", sd);
            assertLt(FixedPointMathLib.abs(sd - wad), uint256(wad / 8));
        }
    }

    function testExponentialWad() public {
        LibPRNG.PRNG memory prng;
        unchecked {
            uint256 n = 1000;
            int256 oldM;
            int256 newM;
            int256 oldS;
            int256 newS;
            for (uint256 i; i != n;) {
                uint256 gasBefore = gasleft();
                int256 x = int256(prng.exponentialWad());
                uint256 gasUsed = gasBefore - gasleft();
                if (++i == 1) {
                    oldM = (newM = x);
                } else {
                    newM = oldM + (x - oldM) / int256(i);
                    newS = oldS + (x - oldM) * (x - newM);
                    oldM = newM;
                    oldS = newS;
                }
                emit LogInt("exponentialWad", x);
                emit LogUint("gasUsed", gasUsed);
            }
            int256 wad = int256(FixedPointMathLib.WAD);
            emit LogInt("mean", newM);
            int256 sd = int256(FixedPointMathLib.sqrt(uint256(newS / int256(n - 1))));
            assertLt(FixedPointMathLib.abs(newM - wad), uint256(wad / 8));
            emit LogInt("standard deviation", sd);
            assertLt(FixedPointMathLib.abs(sd - wad), uint256(wad / 8));
        }
    }

    function testLazyShufflerProducesShuffledRange(uint256 n) public {
        n = _bound(n, 1, _random() % 8 == 0 ? 50 : 10);
        if (_random() % 8 == 0) {
            _brutalizeMemory();
        }
        _lazyShuffler0.initialize(n);
        assertEq(_lazyShuffler0.length(), n);
        assertEq(_lazyShuffler0.numShuffled(), 0);
        if (_random() % 8 == 0) {
            _lazyShuffler0.restart();
        }
        assertEq(_lazyShuffler0.initialized(), true);
        assertEq(_lazyShuffler1.initialized(), false);
        assertEq(_lazyShuffler0.finished(), false);
        uint256[] memory outputs = new uint256[](n);
        unchecked {
            for (uint256 i; i != n; ++i) {
                assertEq(_lazyShuffler0.finished(), false);
                outputs[i] = _lazyShuffler0.next(_random());
            }
            if (n > 32) {
                bool anyShuffled;
                for (uint256 i; i != n && !anyShuffled; ++i) {
                    anyShuffled = outputs[i] != i;
                }
                assertTrue(anyShuffled); // Super unlikely to fail.
            }
            LibSort.sort(outputs);
            for (uint256 i; i != n; ++i) {
                assertEq(outputs[i], i);
            }
            assertEq(_lazyShuffler0.finished(), true);
        }
        assertEq(_lazyShuffler0.finished(), true);
    }

    function testLazyShufflerProducesShuffledRange2() public {
        unchecked {
            _lazyShuffler0.initialize(uint32(17));
            int256 m = 16;
            // This infinite loop must eventually break.
            for (bool done; !done;) {
                int256[] memory sums = new int256[](17);
                for (int256 t; t != m; ++t) {
                    for (uint256 i; i != 17; ++i) {
                        sums[i] += int256(uint256(_lazyShuffler0.next(_random())));
                    }
                    _lazyShuffler0.restart();
                }
                int256 expectedAvgSum = 8 * m;
                done = true;
                uint256 thres = uint256(expectedAvgSum / 8);
                for (uint256 i; i != 17; ++i) {
                    if (FixedPointMathLib.abs(sums[i] - expectedAvgSum) >= thres) {
                        done = false;
                        m *= 2;
                        break;
                    }
                }
            }
        }
    }

    function testLazyShufflerProducesShuffledRangeWithGrow(uint256 n, uint256 nGrow) public {
        n = _bound(n, 1, 32);
        nGrow = n + _bound(nGrow, 0, 32);
        _lazyShuffler0.initialize(n);
        uint256[] memory outputs = new uint256[](nGrow);
        unchecked {
            uint256 i;
            while (i != n) {
                outputs[i] = _lazyShuffler0.next(_random());
                ++i;
                if (_random() % 8 == 0) break;
            }
            _lazyShuffler0.grow(nGrow);
            while (i != nGrow) {
                outputs[i] = _lazyShuffler0.next(_random());
                ++i;
            }
            LibSort.sort(outputs);
            for (i = 0; i != nGrow; ++i) {
                assertEq(outputs[i], i);
            }
            assertEq(_lazyShuffler0.finished(), true);
        }
        assertEq(_lazyShuffler0.finished(), true);
    }

    function testLazyShufflerNoStorageCollisions() public {
        _lazyShuffler0.initialize(16);
        _lazyShuffler1.initialize(32);
        uint256[] memory outputs0 = new uint256[](16);
        uint256[] memory outputs1 = new uint256[](32);
        unchecked {
            for (uint256 i; i != 16; ++i) {
                outputs0[i] = _lazyShuffler0.next(_random());
            }
            for (uint256 i; i != 32; ++i) {
                assertEq(_lazyShuffler1.finished(), false);
                outputs1[i] = _lazyShuffler1.next(_random());
            }
            assertEq(_lazyShuffler0.finished(), true);
            assertEq(_lazyShuffler1.finished(), true);
            LibSort.sort(outputs0);
            LibSort.sort(outputs1);
            for (uint256 i; i != 16; ++i) {
                assertEq(outputs0[i], i);
            }
            for (uint256 i; i != 32; ++i) {
                assertEq(outputs1[i], i);
            }
        }
    }

    function testLazyShufflerGet() public {
        _lazyShuffler0.initialize(16);
        _lazyShuffler1.initialize(32);
        uint256[] memory outputs0 = new uint256[](16);
        uint256[] memory outputs1 = new uint256[](32);
        unchecked {
            for (uint256 i; i != 16; ++i) {
                assertEq(_lazyShuffler0.get(i), i);
            }
            for (uint256 i; i != 16; ++i) {
                outputs0[i] = _lazyShuffler0.next(_random());
            }
            for (uint256 i; i != 32; ++i) {
                assertEq(_lazyShuffler1.get(i), i);
            }
            for (uint256 i; i != 32; ++i) {
                assertEq(_lazyShuffler1.finished(), false);
                outputs1[i] = _lazyShuffler1.next(_random());
            }
            for (uint256 i; i != 16; ++i) {
                assertEq(_lazyShuffler0.get(i), outputs0[i]);
            }
            for (uint256 i; i != 32; ++i) {
                assertEq(_lazyShuffler1.get(i), outputs1[i]);
            }
        }
    }

    function testLazyShufflerGetOutOfBoundsReverts(uint256 n, uint256 i) public {
        n = _bound(n, 1, 2 ** 32 - 2);
        _lazyShuffler0.initialize(n);
        i = _bound(i, 1, 2 ** 32 + 1);
        if (i < n) {
            assertEq(this.lazyShuffler0Get(i), i);
        } else {
            vm.expectRevert(LibPRNG.LazyShufflerGetOutOfBounds.selector);
            this.lazyShuffler0Get(i);
        }
    }

    function testLazyShufflerRestart() public {
        uint256[] memory outputs0 = new uint256[](32);
        uint256[] memory outputs1 = new uint256[](32);
        _lazyShuffler0.initialize(32);
        assertEq(_lazyShuffler0.numShuffled(), 0);
        assertEq(_lazyShuffler0.length(), 32);
        for (uint256 i; i != 32; ++i) {
            assertEq(_lazyShuffler0.numShuffled(), i);
            outputs0[i] = _lazyShuffler0.next(_random());
        }
        assertEq(_lazyShuffler0.numShuffled(), 32);
        _lazyShuffler0.restart();
        assertEq(_lazyShuffler0.numShuffled(), 0);
        assertEq(_lazyShuffler0.length(), 32);
        for (uint256 i; i != 32; ++i) {
            outputs1[i] = _lazyShuffler0.next(_random());
        }
        assertTrue(keccak256(abi.encode(outputs0)) != keccak256(abi.encode(outputs1)));
        LibSort.sort(outputs0);
        LibSort.sort(outputs1);
        for (uint256 i; i != 32; ++i) {
            assertEq(outputs0[i], i);
            assertEq(outputs1[i], i);
        }
    }

    function testLazyShufflerRevertsOnInitWithInvalidLength(uint256 n) public {
        n = _bound(n, 0, 2 ** 32 + 1);
        if (n == 0 || n >= 2 ** 32 - 1) {
            vm.expectRevert(LibPRNG.InvalidInitialLazyShufflerLength.selector);
        }
        this.lazyShufflerInitialize(n);
    }

    function testLazyShufflerRevertsOnGrowWithInvalidLength(uint256 n, uint256 nGrow) public {
        n = _bound(n, 1, 2 ** 32 - 2);
        this.lazyShufflerInitialize(n);
        nGrow = _bound(n, 0, 2 ** 32 - 2);
        if (nGrow < n) {
            vm.expectRevert(LibPRNG.InvalidNewLazyShufflerLength.selector);
        }
        this.lazyShufflerGrow(n);
    }

    function testLazyShufflerRevertsOnDoubleInit() public {
        this.lazyShufflerInitialize(1);
        vm.expectRevert(LibPRNG.LazyShufflerAlreadyInitialized.selector);
        this.lazyShufflerInitialize(2);
    }

    function testLazyShufflerRevertsOnZeroLengthNext() public {
        vm.expectRevert(LibPRNG.LazyShuffleFinished.selector);
        lazyShufflerNext(_random());
    }

    function testLazyShufflerRevertsOnFinshedNext(uint256 n) public {
        n = _bound(n, 1, 3);
        _lazyShuffler0.initialize(n);
        unchecked {
            for (uint256 i; i != n; ++i) {
                lazyShufflerNext(_random());
            }
        }
        vm.expectRevert(LibPRNG.LazyShuffleFinished.selector);
        lazyShufflerNext(_random());
    }

    function lazyShufflerInitialize(uint256 n) public {
        _lazyShuffler0.initialize(n);
    }

    function lazyShufflerGrow(uint256 n) public {
        _lazyShuffler0.grow(n);
    }

    function lazyShufflerNext(uint256 randomness) public returns (uint256) {
        return _lazyShuffler0.next(randomness);
    }

    function lazyShuffler0Get(uint256 i) public view returns (uint256) {
        return _lazyShuffler0.get(i);
    }

    function lazyShuffler1Get(uint256 i) public view returns (uint256) {
        return _lazyShuffler1.get(i);
    }
}
