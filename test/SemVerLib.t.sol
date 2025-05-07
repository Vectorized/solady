// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {SemVerLib} from "../src/utils/SemVerLib.sol";
import {LibString} from "../src/utils/LibString.sol";

contract SemVerLibTest is SoladyTest {
    function _checkEq(bytes32 a, bytes32 b) internal {
        assertEq(SemVerLib.cmp(a, b), 0);
        assertEq(SemVerLib.cmp(_addMeta(a), b), 0);
        assertEq(SemVerLib.cmp(a, _addMeta(b)), 0);
        assertEq(SemVerLib.cmp(_addMeta(a), _addMeta(b)), 0);
    }

    function _checkLt(bytes32 a, bytes32 b) internal {
        assertEq(SemVerLib.cmp(a, b), -1);
        assertEq(SemVerLib.cmp(_addMeta(a), b), -1);
        assertEq(SemVerLib.cmp(a, _addMeta(b)), -1);
        assertEq(SemVerLib.cmp(_addMeta(a), _addMeta(b)), -1);
        (a, b) = (b, a);
        assertEq(SemVerLib.cmp(a, b), 1);
        assertEq(SemVerLib.cmp(_addMeta(a), b), 1);
        assertEq(SemVerLib.cmp(a, _addMeta(b)), 1);
        assertEq(SemVerLib.cmp(_addMeta(a), _addMeta(b)), 1);
    }

    function _addMeta(bytes32 a) internal returns (bytes32) {
        bytes memory data = bytes(LibString.fromSmallString(a));
        if (data.length < 20) {
            data = abi.encodePacked(data, "+");
            if (_randomChance(2)) data = abi.encodePacked(data, "hehe");
            return LibString.toSmallString(string(data));
        } else {
            return a;
        }
    }

    function _s(uint256 x) internal pure returns (bytes memory) {
        return bytes(LibString.toString(x));
    }

    function _s(bytes memory x) internal pure returns (bytes32) {
        return LibString.toSmallString(string(x));
    }

    function testCmpMajorMinor(uint256 aMajor, uint256 bMajor, uint256 aMinor, uint256 bMinor)
        public
    {
        aMajor = _bound(aMajor, 0, 100000);
        bMajor = _bound(bMajor, 0, 100000);
        aMinor = _bound(aMinor, 0, 100000);
        bMinor = _bound(bMinor, 0, 100000);
        if (bMajor < aMajor) (aMajor, bMajor) = (bMajor, aMajor);
        if (aMajor < bMajor) {
            _checkLt(
                _s(abi.encodePacked(_s(aMajor), ".", _s(aMinor), ".0")),
                _s(abi.encodePacked(_s(bMajor), ".", _s(bMinor), ".0"))
            );
        }
        if (aMajor == bMajor && aMinor < bMinor) {
            _checkLt(
                _s(abi.encodePacked(_s(aMajor), ".", _s(aMinor), ".0")),
                _s(abi.encodePacked(_s(bMajor), ".", _s(bMinor), ".0"))
            );
        }
        if (aMajor == bMajor && aMinor == bMinor) {
            _checkLt(
                _s(abi.encodePacked(_s(aMajor), ".", _s(aMinor), ".0")),
                _s(abi.encodePacked(_s(bMajor), ".", _s(bMinor), ".0"))
            );
        }
    }

    function testCmpMajor(uint256 a, uint256 b) public {
        a = _bound(a, 0, 100000);
        b = _bound(b, 0, 100000);
        if (b < a) (a, b) = (b, a);
        if (a < b) {
            _checkLt(_s(abi.encodePacked(_s(a), ".0.0")), _s(abi.encodePacked(_s(b), ".0.0")));
        } else if (a == b) {
            _checkEq(_s(abi.encodePacked(_s(a), ".0.0")), _s(abi.encodePacked(_s(b), ".0.0")));
        }
    }

    function testCmpMinor(uint256 a, uint256 b) public {
        a = _bound(a, 0, 100000);
        b = _bound(b, 0, 100000);
        if (b < a) (a, b) = (b, a);
        if (a < b) {
            _checkLt(
                _s(abi.encodePacked("0.", _s(a), ".0.0")), _s(abi.encodePacked("0.", _s(b), ".0.0"))
            );
        } else if (a == b) {
            _checkEq(
                _s(abi.encodePacked("0.", _s(a), ".0.0")), _s(abi.encodePacked("0.", _s(b), ".0.0"))
            );
        }
    }

    function testCmpPatch(uint256 a, uint256 b) public {
        a = _bound(a, 0, 100000);
        b = _bound(b, 0, 100000);
        if (b < a) (a, b) = (b, a);
        if (a < b) {
            _checkLt(_s(abi.encodePacked("0.0.", _s(a))), _s(abi.encodePacked("0.0.", _s(b))));
        } else if (a == b) {
            _checkEq(_s(abi.encodePacked("0.0.", _s(a))), _s(abi.encodePacked("0.0.", _s(b))));
        }
    }

    function testCmp() public {
        // Compliant.
        _checkEq("1.0.0", "1.0.0");
        _checkLt("1.0.0", "1.0.1");
        _checkLt("1.0.0", "1.1.0");
        _checkLt("1.0.0", "1.1.1");
        _checkLt("1.0.0", "2.0.1");
        _checkLt("1.0.0", "2.1.0");
        _checkLt("1.0.0", "2.1.1");
        _checkLt("1.2.0", "2.1.1");
        _checkLt("1.2.999999", "2.1.1");
        _checkLt("1.9.999", "2.0.0");

        // Forgiving.
        _checkLt("a", "1");
        _checkLt("a1", "1");
        _checkLt("!", "1");
        _checkEq("1", "1");
        _checkLt("1", "2");
        _checkLt("1a", "2");
        _checkLt("1a", "2a");
        _checkLt("1", "2a");
        _checkLt("", "2a");
        _checkEq("", "");

        _checkEq("v1.2.3", "1.2.3");
        _checkLt("v1.2.2", "1.2.3");
        _checkLt("v1.2", "1.2.3");
        _checkEq("v1.2", "1.2.0");
        _checkEq("1.2.3", "v1.2.3");
        _checkLt("1.2.2", "v1.2.3");
        _checkLt("1.2", "v1.2.3");
        _checkEq("1.2", "v1.2.0");

        _checkEq("1.2", "1.2.0");
        _checkLt("1.2.3-alpha", "1.2.3");
        _checkLt("1.2-alpha", "1.2.3");
        _checkEq("1.2.3-alpha", "1.2.3-alpha");
        _checkLt("1.2.3-alpha", "1.2.3-alpha.123");
        _checkLt("1.2.3-alpha.123", "1.2.3-alpha.124");
        _checkLt("1.2.3-alpha.123.z", "1.2.3-alpha.124");
        _checkLt("1.2.3-alpha.123.", "1.2.3-alpha.124");
        _checkLt("1.2.3-alpha.124", "1.2.3-alpha.124a");
        _checkLt("1.2.3-alpha.124", "1.2.3-alpha.12a");
        _checkLt("1.2.3-thequickbrownfoxjumpsover", "1.2.3-thequickbrownfoxjumpsover1");
        _checkLt("1.2.3-thequickbrownfoxjumpsover", "1.2.3-thequickbrownfoxjumpsover0");
        _checkEq("1.2.3-thequickbrownfoxjumpsover0", "1.2.3-thequickbrownfoxjumpsover0");
        _checkLt("1.2.3-99999999999999999999999999", "1.2.3-thequickbrownfoxjumpsover0");
        _checkLt("1.2.3-99999999999999999999999999", "1.2.3-t");
        _checkLt("1.2.3-alpha", "1.2.3-alpha.0");
        _checkLt("1.2-alpha", "1.2.3-alpha");
    }
}
