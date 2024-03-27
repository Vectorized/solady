// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/SoladyTest.sol";
import {SSHUFFLE} from "../src/utils/SSHUFFLE.sol";
import {LibString} from "../src/utils/LibString.sol";
import {LibPRNG} from "../src/utils/LibPRNG.sol";

contract SSHUFFLETest is SoladyTest {
    using SSHUFFLE for SSHUFFLE.State;
    using LibPRNG for LibPRNG.PRNG;
    using LibString for uint256;

    SSHUFFLE.State state;

    function testConstantInvariants() public {
        // The constants have to be hard-coded for use in assembly ¯\_(ツ)_/¯.
        assertEq(SSHUFFLE.MAX, (1 << SSHUFFLE.BITS) - 1, "MAX");
        assertEq(SSHUFFLE.E2E_SHIFT, 256 - SSHUFFLE.BITS, "E2E_SHIFT");
        assertEq(SSHUFFLE.LEFT_MASK, SSHUFFLE.MAX << SSHUFFLE.E2E_SHIFT, "LEFT_MASK");
    }

    function testInit(bytes memory key, uint32 size) public {
        state.init(key, size);

        assertEq(state.shuffled, 0, "zero shuffled at init");
        assertEq(state.size, size, "total");
        assertEq(state.array, uint192(bytes24(keccak256(key))), "array slot");
    }

    function testGetSet(bytes memory key, uint32 middle, uint32[9] memory vals) public {
        vm.assume(middle >= 4 && middle <= type(uint32).max - 4);
        for (uint256 i = 0; i < vals.length; ++i) {
            vm.assume(vals[i] != type(uint32).max);
        }

        uint32[9] memory indices;
        indices[0] = middle - 4;
        for (uint256 i = 1; i < indices.length; ++i) {
            indices[i] = indices[i - 1] + 1;
        }

        state.init(key, 0);

        for (uint256 i = 0; i < vals.length; ++i) {
            string memory iStr = uint256(indices[i]).toString();
            assertEq(
                state.get(indices[i]), indices[i], string.concat("default value == index ", iStr)
            );
        }

        for (uint256 i = 0; i < vals.length; ++i) {
            state.set(indices[i], vals[i]);

            for (uint256 j = 0; j < vals.length; ++j) {
                string memory iStr = uint256(indices[i]).toString();
                string memory jStr = uint256(indices[j]).toString();
                assertEq(
                    state.get(indices[j]),
                    j <= i ? vals[j] : indices[j],
                    string.concat("after setting up to index ", iStr, ", value of index ", jStr)
                );
            }
        }

        for (uint256 i = 0; i < vals.length; ++i) {
            state.set(indices[i], indices[i]);

            for (uint256 j = 0; j < vals.length; ++j) {
                string memory iStr = uint256(indices[i]).toString();
                string memory jStr = uint256(indices[j]).toString();
                assertEq(
                    state.get(indices[j]),
                    j <= i ? indices[j] : vals[j],
                    string.concat(
                        "after resetting (to default) up to index ", iStr, ", value of index ", jStr
                    )
                );
            }
        }
    }

    struct ShuffleTest {
        uint256 seed;
        uint8 size;
    }

    function testShuffle(ShuffleTest[16] memory tests) public {
        bool anyInPlace;
        bool anyShuffled;

        for (uint256 i = 0; i < tests.length; ++i) {
            (bool p, bool s) = _testShuffle(abi.encode(i), tests[i]);
            anyInPlace = anyInPlace || p;
            anyShuffled = anyShuffled || s;
        }

        assertTrue(anyInPlace, "no values left in place; might be Satollo's algorithm");
        assertTrue(anyShuffled, "all values left in place; no shuffling");
    }

    event Permutation(uint32[]);

    function _testShuffle(bytes memory key, ShuffleTest memory t)
        internal
        returns (bool anyInPlace, bool anyShuffled)
    {
        state.init(key, t.size);

        LibPRNG.PRNG memory rng;
        rng.seed(t.seed);

        uint32[] memory permuted = new uint32[](t.size);
        bool[] memory seen = new bool[](t.size);

        for (uint32 i = 0; i < t.size; ++i) {
            uint32 val = state.next(rng);
            assertLt(val, t.size, "value outside range");
            permuted[i] = val;

            anyInPlace = anyInPlace || val == i;
            anyShuffled = anyShuffled || val != i;

            // Given that all values are `< t.size` and `seen.length == t.size`, this proves that we have a permutation.
            assertFalse(seen[val], "duplicate value");
            seen[val] = true;
        }
        // In lieu of a logging function for uint32[].
        emit Permutation(permuted);

        // vm.expectRevert(SSHUFFLE.Finished.selector);
        // state.next(0);

        for (uint32 i = 0; i < t.size; ++i) {
            assertEq(
                state.get(i),
                permuted[i],
                string.concat("storage != returned value for index ", uint256(i).toString())
            );
        }
    }

    uint32[] private _nativeArray;

    function testLazyArrayGas(bytes memory key, uint8 size) public {
        vm.assume(size > 10);

        uint256 nativeGas = gasleft();
        _nativeArray = new uint32[](size);
        nativeGas -= gasleft();

        uint256 lazyGas = gasleft();
        state.init(key, size);
        lazyGas -= gasleft();

        assertLt(lazyGas, nativeGas, "gas for lazy array vs native");
    }
}
