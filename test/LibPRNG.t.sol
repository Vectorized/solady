// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/TestPlus.sol";
import {LibPRNG} from "../src/utils/LibPRNG.sol";

contract LibPRNGTest is TestPlus {
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
            uint256 randomness;
            for (uint256 i; i < 256; i++) {
                randomness = LibPRNG.next(randomness);
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
        assembly {
            let a := 0xd6aad120322a96acae4ccfaf5fcd4bbfda3f2f3001db6837c0981639faa68d8d
            state := add(mul(state, a), 83)
            randomness := xor(state, shr(128, state))
        }
    }
}
