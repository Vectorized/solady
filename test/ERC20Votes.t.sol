// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {FixedPointMathLib} from "../src/utils/FixedPointMathLib.sol";

contract ERC20VotesTest is SoladyTest {
    function testSmallSqrtApprox(uint32 n) public {
        uint256 approx = _smallSqrtApprox(n);
        uint256 groundTruth = FixedPointMathLib.sqrt(n);
        assertGe(approx, groundTruth);
        assertLe(FixedPointMathLib.dist(approx, groundTruth), 3);
    }

    function _smallSqrtApprox(uint256 n) internal pure returns (uint256 m) {
        /// @solidity memory-safe-assembly
        assembly {
            m := shl(4, lt(0xffff, n))
            m := shl(shr(1, or(shl(3, lt(0xff, shr(m, n))), m)), 16)
            m := shr(1, add(m, div(n, m)))
            m := shr(1, add(m, div(n, m)))
            m := shr(1, add(m, div(n, m)))
            m := shr(1, add(m, div(n, m)))
            m := shr(1, add(m, div(n, m)))
            m := shr(1, add(m, div(n, m)))
        }
    }
}
