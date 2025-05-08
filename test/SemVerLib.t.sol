// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {SemVerLib} from "../src/utils/SemVerLib.sol";
import {LibString} from "../src/utils/LibString.sol";

contract SemVerLibTest is SoladyTest {
    function _checkEq(bytes32 a, bytes32 b) public {
        assertEq(SemVerLib.cmp(a, b), 0);
        assertEq(SemVerLib.cmp(_addMeta(a), b), 0);
        assertEq(SemVerLib.cmp(a, _addMeta(b)), 0);
        assertEq(SemVerLib.cmp(_addMeta(a), _addMeta(b)), 0);
    }

    function _checkLt(bytes32 a, bytes32 b) public {
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
        if (data.length >= 20) return a;
        data = abi.encodePacked(data, "+");
        if (_randomChance(2)) {
            data = abi.encodePacked(
                data, _truncateBytes(abi.encodePacked(_random()), _randomUniform() % 5)
            );
        }
        return LibString.toSmallString(string(data));
    }

    function _s(uint256 x) internal pure returns (bytes memory) {
        return bytes(LibString.toString(x));
    }

    function _s(bytes memory x) internal pure returns (bytes32) {
        return LibString.toSmallString(string(x));
    }

    function _s(bytes32 x) internal pure returns (bytes memory) {
        return bytes(LibString.fromSmallString(x));
    }

    function _s(uint256[] memory x) internal pure returns (bytes32) {
        bytes memory buffer;
        for (uint256 i; i < x.length; ++i) {
            if (i != 0) {
                buffer = abi.encodePacked(buffer, ".", _s(x[i]));
            } else {
                buffer = abi.encodePacked(buffer, _s(x[i]));
            }
        }
        return _s(buffer);
    }

    function _maybePrependV(bytes32 x) internal returns (bytes32) {
        if (_randomChance(2)) return x;
        if (_randomChance(2)) return _s(abi.encodePacked("v", _s(x)));
        return _s(abi.encodePacked("V", _s(x)));
    }

    function testCmpMajorMinorPatch(bytes32) public {
        uint256 n = _bound(_randomUniform(), 0, 5);
        uint256[] memory a = new uint256[](n);
        uint256[] memory b = new uint256[](n);
        for (uint256 i; i < n; ++i) {
            a[i] = _bound(_random(), 0, 10000);
            b[i] = _bound(_random(), 0, 10000);
        }
        int256 expected = _cmpMajorMinorPatchOriginal(a, b);
        if (expected == 0) {
            _checkEq(_maybePrependV(_s(a)), _maybePrependV(_s(b)));
        } else if (expected == 1) {
            _checkLt(_maybePrependV(_s(b)), _maybePrependV(_s(a)));
        } else if (expected == -1) {
            _checkLt(_maybePrependV(_s(a)), _maybePrependV(_s(b)));
        } else {
            revert("Should never reach here.");
        }
    }

    function _cmpMajorMinorPatchOriginal(uint256[] memory a, uint256[] memory b)
        internal
        pure
        returns (int256)
    {
        require(a.length == b.length, "Input arrays must have same lengths.");
        for (uint256 i; i < a.length; ++i) {
            if (a[i] > b[i]) return 1;
            if (a[i] < b[i]) return -1;
        }
        return 0;
    }

    struct _CmpPreReleaseTemps {
        uint256 n;
        uint256[] a;
        uint256[] b;
        bool aIsNum;
        bool bIsNum;
        uint256 aNum;
        uint256 bNum;
        bytes aBuffer;
        bytes bBuffer;
        bytes aPreReleaseBuffer;
        bytes bPreReleaseBuffer;
        int256 lexoCmpResult;
    }

    function testCmpPreRelease(bytes32) public {
        _CmpPreReleaseTemps memory t;
        t.n = _bound(_randomUniform(), 1, 3);
        t.a = new uint256[](t.n);
        t.b = new uint256[](t.n);
        for (uint256 i; i < t.n; ++i) {
            t.a[i] = _bound(_random(), 0, 200);
            t.b[i] = t.a[i];
        }
        t.aBuffer = _s(_maybePrependV(_s(t.a)));
        t.bBuffer = _s(_maybePrependV(_s(t.b)));
        t.aIsNum = _randomChance(2);
        t.bIsNum = _randomChance(2);

        if (t.aIsNum) {
            t.aNum = _random() % (10 ** (32 - 1 - t.aBuffer.length));
            t.aBuffer = abi.encodePacked(t.aBuffer, "-", _s(t.aNum));
        } else {
            t.aNum = _random() % (10 ** (32 - 2 - t.aBuffer.length));
            t.aPreReleaseBuffer = abi.encodePacked(_s(t.aNum), "h");
            t.aBuffer = abi.encodePacked(t.aBuffer, "-", t.aPreReleaseBuffer);
        }

        if (t.bIsNum) {
            t.bNum = _random() % (10 ** (32 - 1 - t.bBuffer.length));
            t.bBuffer = abi.encodePacked(t.bBuffer, "-", _s(t.bNum));
        } else {
            t.bNum = _random() % (10 ** (32 - 2 - t.bBuffer.length));
            t.bPreReleaseBuffer = abi.encodePacked(_s(t.bNum), "h");
            t.bBuffer = abi.encodePacked(t.bBuffer, "-", t.bPreReleaseBuffer);
        }

        if (t.aIsNum && t.bIsNum) {
            if (t.aNum < t.bNum) {
                _checkLt(_s(t.aBuffer), _s(t.bBuffer));
            } else if (t.aNum > t.bNum) {
                _checkLt(_s(t.bBuffer), _s(t.aBuffer));
            } else {
                _checkEq(_s(t.aBuffer), _s(t.bBuffer));
            }
        } else if (t.aIsNum && !t.bIsNum) {
            _checkLt(_s(t.aBuffer), _s(t.bBuffer));
        } else if (!t.aIsNum && t.bIsNum) {
            _checkLt(_s(t.bBuffer), _s(t.aBuffer));
        } else if (!t.aIsNum && !t.bIsNum) {
            t.lexoCmpResult = _lexoCmp(t.aPreReleaseBuffer, t.bPreReleaseBuffer);
            if (t.lexoCmpResult == -1) {
                _checkLt(_s(t.aBuffer), _s(t.bBuffer));
            } else if (t.lexoCmpResult == 1) {
                _checkLt(_s(t.bBuffer), _s(t.aBuffer));
            } else {
                _checkEq(_s(t.aBuffer), _s(t.bBuffer));
            }
        }
    }

    function _lexoCmp(bytes memory a, bytes memory b) internal pure returns (int256) {
        unchecked {
            uint256 len = a.length < b.length ? a.length : b.length;
            for (uint256 i; i < len; ++i) {
                uint8 ac = uint8(a[i]);
                uint8 bc = uint8(b[i]);
                if (ac < bc) return -1;
                if (ac > bc) return 1;
            }
            if (a.length < b.length) return -1;
            if (a.length > b.length) return 1;
            return 0;
        }
    }

    function testCmpCompliant() public {
        this._checkEq("1.0.0", "1.0.0");
        this._checkLt("1.0.0", "1.0.1");
        this._checkLt("1.0.0", "1.1.0");
        this._checkLt("1.0.0", "1.1.1");
        this._checkLt("1.0.0", "2.0.1");
        this._checkLt("1.0.0", "2.1.0");
        this._checkLt("1.0.0", "2.1.1");
        this._checkLt("1.2.0", "2.1.1");
        this._checkLt("1.2.999999", "2.1.1");
        this._checkLt("1.9.999", "2.0.0");
    }

    function testCmpForgiving() public {
        this._checkLt("a", "1");
        this._checkLt("a1", "1");
        this._checkLt("!", "1");
        this._checkEq("1", "1");
        this._checkLt("1", "2");
        this._checkLt("1a", "2");
        this._checkLt("1a", "2a");
        this._checkLt("1", "2a");
        this._checkLt("", "2a");
        this._checkEq("", "");

        this._checkEq("v1.2.3", "1.2.3");
        this._checkLt("v1.2.2", "1.2.3");
        this._checkLt("v1.2", "1.2.3");
        this._checkEq("v1.2", "1.2.0");
        this._checkEq("1.2.3", "v1.2.3");
        this._checkLt("1.2.2", "v1.2.3");
        this._checkLt("1.2", "v1.2.3");
        this._checkEq("1.2", "v1.2.0");

        this._checkEq("1.2", "1.2.0");
        this._checkLt("1.2.3-alpha", "1.2.3");
        this._checkLt("1.2-alpha", "1.2.3");
        this._checkEq("1.2.3-alpha", "1.2.3-alpha");
        this._checkLt("1.2.3-alpha", "1.2.3-alpha.123");
        this._checkLt("1.2.3-alpha.123", "1.2.3-alpha.124");
        this._checkLt("1.2.3-alpha.123.z", "1.2.3-alpha.124");
        this._checkLt("1.2.3-alpha.123.", "1.2.3-alpha.124");
        this._checkLt("1.2.3-alpha.124", "1.2.3-alpha.124a");
        this._checkLt("1.2.3-alpha.124", "1.2.3-alpha.12a");
        this._checkLt("1.2.3-thequickbrownfoxjumpsover", "1.2.3-thequickbrownfoxjumpsover1");
        this._checkLt("1.2.3-thequickbrownfoxjumpsover", "1.2.3-thequickbrownfoxjumpsover0");
        this._checkEq("1.2.3-thequickbrownfoxjumpsover0", "1.2.3-thequickbrownfoxjumpsover0");
        this._checkLt("1.2.3-99999999999999999999999999", "1.2.3-thequickbrownfoxjumpsover0");
        this._checkLt("1.2.3-99999999999999999999999999", "1.2.3-t");
        this._checkLt("1.2.3-alpha", "1.2.3-alpha.0");
        this._checkLt("1.2-alpha", "1.2.3-alpha");

        this._checkLt("1.2.3-1", "1.2.3-a");
        this._checkLt("1.2.3-1", "1.2.3-alpha");
        this._checkLt("1.2.3-1.0", "1.2.3-1.a");

        this._checkLt("1.2.3-alpha", "1.2.3-alpha.0");
        this._checkLt("1.2.3-alpha.1", "1.2.3-alpha.1.1");
        this._checkLt("1.2.3-alpha.1.a", "1.2.3-alpha.1.a.0");

        this._checkEq("1.2.3-alpha+build", "1.2.3-alpha");
        this._checkEq("1.2.3+build", "1.2.3");
        this._checkLt("1.2.3-alpha", "1.2.3+build");

        this._checkLt("1..3", "1.1.3");
        this._checkLt("1..4", "1.1.3"); // `1.0.4` < `1.1.3`.
        this._checkEq("1.2.3a", "1.2.3a");
        this._checkLt("1.2.3a", "1.2.4");

        this._checkEq("1..4", "1.0.4"); // confirm parsing is consistent
        this._checkLt("1..4", "1.0.5"); // `1.0.4` < `1.0.5`
        this._checkLt("1..4", "1.1"); // `1.0.4` < `1.1.0`
        this._checkLt("1..", "1.0.1"); // `1.0.0` < `1.0.1` if final component is missing
        this._checkEq("1.0.", "1.0.0"); // forgiving trailing dot

        this._checkEq("01.002.0003", "1.2.3");
        this._checkEq("v01.2.03", "1.2.3");

        this._checkLt("", "1.0.0");
        this._checkEq("", "0.0.0");
    }
}
