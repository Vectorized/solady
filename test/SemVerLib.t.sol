// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {SemVerLib} from "../src/utils/SemVerLib.sol";

contract SemVerLibTest is SoladyTest {
    int256 internal constant _EQ = 0;
    int256 internal constant _LT = -1;
    int256 internal constant _GT = 1;

    function testCmp() public {
        assertEq(SemVerLib.cmp("a", "1"), _LT); // Forgiving: coalesces to `0.0.0`, `1.0.0`.
        assertEq(SemVerLib.cmp("a1", "1"), _LT); // Forgiving: coalesces to `0.0.0`, `1.0.0`.
        assertEq(SemVerLib.cmp("!", "1"), _LT); // Forgiving: coalesces to `0.0.0`, `1.0.0`.
        assertEq(SemVerLib.cmp("1", "1"), _EQ); // Forgiving: coalesces to `1.0.0`, `1.0.0`.
        assertEq(SemVerLib.cmp("1", "2"), _LT); // Forgiving: coalesces to `1.0.0`, `2.0.0`.
        assertEq(SemVerLib.cmp("2", "1"), _GT); // Forgiving: coalesces to `2.0.0`, `1.0.0`.
        assertEq(SemVerLib.cmp("1.0.0", "1.0.0"), _EQ); // Equal.
        assertEq(SemVerLib.cmp("1.0.0", "1.0.1"), _LT); // Patch compared.
        assertEq(SemVerLib.cmp("1.0.1", "1.0.0"), _GT); // Patch compared.
        assertEq(SemVerLib.cmp("1.2.3", "1.3.0"), _LT); // Minor compared.
        assertEq(SemVerLib.cmp("2.0.0", "1.9.999"), _GT); // Early exit at major.
        assertEq(SemVerLib.cmp("v1.2.3", "1.2.3"), _EQ); // Forgiving: skips v.
        assertEq(SemVerLib.cmp("v1.2.4", "1.2.3"), _GT); // Forgiving: skips v.
        assertEq(SemVerLib.cmp("v1.2.2", "1.2.3"), _LT); // Forgiving: skips v.
        assertEq(SemVerLib.cmp("1.2", "1.2.0"), _EQ); // Forgiving: implicit `.0` for patch.
        assertEq(SemVerLib.cmp("1.3", "1.2.0"), _GT); // Forgiving: implicit `.0` for patch.
        assertEq(SemVerLib.cmp("1.1", "1.2.0"), _LT); // Forgiving: implicit `.0` for patch.
        assertEq(SemVerLib.cmp("1.2.3", "1.2.3-alpha"), _GT); // Prerelease loses.
        assertEq(SemVerLib.cmp("1.2.3-alpha", "1.2.3"), _LT); // Prerelease loses.
        assertEq(SemVerLib.cmp("1.2.3-alpha", "1.2.3-alpha"), _EQ);
        assertEq(SemVerLib.cmp("1.2.3-alpha", "1.2.3-alpha.123"), _LT);
        assertEq(SemVerLib.cmp("1.2.3-alpha", "1.2.3-alpha.0"), _LT);
        assertEq(SemVerLib.cmp("1.2.3-alpha.123", "1.2.3-alpha"), _GT);
        // We should probably make some helper to auto test the `_GT` for every `_LT`.
    }
}
