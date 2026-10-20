// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./utils/forge-std/Test.sol";
import {LibBytes} from "../src/utils/LibBytes.sol";
import {EfficientHashLib} from "../src/utils/EfficientHashLib.sol";

/// @dev Tests for LibBytes edge cases:
/// - `split` when the delimiter is longer than the subject,
/// - `dynamicStructInCalldata` with a malformed struct offset.
contract LibBytesEdgeCasesTest is Test {
    /// ------------------------------------------------------------------
    /// `split` with delimiter longer than subject.
    /// Previously, `indicesOf` returned a null pointer on this path, and
    /// `split` read the array length from the scratch space at 0x00,
    /// which is not guaranteed to be zero.
    /// ------------------------------------------------------------------
    /// Clean-scratch sanity: the null path works when scratch is zero.
    function testSplitNullPathCleanScratch() public pure {
        bytes[] memory p = LibBytes.split("ab", "xyz");
        require(p.length == 1, "length");
        require(bytes(p[0]).length == 2, "element length");
    }

    /// Scratch dirtied by a prior call to another library function.
    /// Before the fix: corrupted result or OOG. After the fix: correct result.
    function testSplitNullPathAfterHash() public {
        bytes32 h = EfficientHashLib.hash(uint256(1));
        h; // silence unused
        bytes[] memory p = LibBytes.split("ab", "xyz");
        assertEq(p.length, 1, "array length must be 1");
        assertEq(bytes(p[0]), "ab", "element must equal subject");
    }

    /// Two consecutive null-path splits: the first split itself leaves
    /// scratch dirty for the second. Before the fix: OOG revert.
    function testSplitNullPathTwoConsecutive() public pure {
        bytes[] memory a = LibBytes.split("ab", "xyz");
        require(a.length == 1, "first split length");
        require(bytes(a[0]).length == 2, "first split element");
        bytes[] memory b = LibBytes.split("cd", "wxyz");
        require(b.length == 1, "second split length");
        require(bytes(b[0]).length == 2, "second split element");
    }

    /// ------------------------------------------------------------------
    /// `dynamicStructInCalldata` with a malformed struct offset.
    /// Previously, a struct offset `s > a.length` was not rejected, and
    /// `result.length = a.length - s` wrapped around to a huge value.
    /// ------------------------------------------------------------------

    Harness harness;

    function setUp() public {
        harness = new Harness();
    }

    /// Malformed struct offset: a = 64 bytes, first word = 65 (> a.length).
    /// Before the fix: no revert from LibBytes, returned slice had
    /// length 2**256 - 1. After the fix: reverts with an empty reason
    /// (the assembly `revert(l, 0x00)` bounds check).
    function testDynamicStructInCalldataMalformedOffset() public {
        bytes memory payload = abi.encode(uint256(65), uint256(0)); // 64 bytes, s = 65
        (bool ok, bytes memory reason) =
            address(harness).call(abi.encodeWithSelector(Harness.f.selector, payload));
        assertFalse(ok, "must revert on out-of-bounds struct offset");
        assertEq(reason, bytes(""), "revert must come from LibBytes bounds check");
    }

    /// Valid input sanity: must NOT revert.
    function testDynamicStructInCalldataValid() public view {
        bytes memory payload = abi.encode(uint256(0x20), uint256(123));
        harness.f(payload);
    }
}

contract Harness {
    /// Re-encodes the returned slice so the wrapped length is actually consumed.
    function f(bytes calldata a) external pure returns (bytes calldata) {
        bytes calldata s = LibBytes.dynamicStructInCalldata(a, 0);
        // Touch the slice: reading its length forces use of the wrapped value.
        require(
            s.length < 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, "wrapped"
        );
        return s;
    }
}
