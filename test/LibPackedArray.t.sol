// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {LibPackedArray, pack} from "../src/utils/LibPackedArray.sol";

contract LibPackedArrayTest is SoladyTest {
    using LibPackedArray for bytes;

    /*//////////////////////////////////////////////////////////////
                                  PACK
    //////////////////////////////////////////////////////////////*/

    function test_pack0(uint256 chunkSize) public {
        chunkSize = _bound(chunkSize, 0, 28);

        uint256[] memory items = new uint256[](0);
        bytes memory newList = pack(items, chunkSize);

        assertEq(newList.length, 0);
    }

    function test_pack1(uint256 a, uint256 chunkSize) public {
        chunkSize = _bound(chunkSize, 0, 28);
        a = _bound(a, 0, (1 << (chunkSize << 3)) - 1);

        uint256[] memory items = new uint256[](1);
        items[0] = a;
        bytes memory newList = pack(items, chunkSize);

        assertEq(newList.length, chunkSize);
        uint256 shift = 256 - (chunkSize << 3);
        assertEq(uint256(bytes32(newList)), a << shift);
    }

    function test_pack2(uint256 a, uint256 b, uint256 chunkSize) public {
        chunkSize = _bound(chunkSize, 1, 28);
        a = _bound(a, 0, (1 << (chunkSize << 3)) - 1);
        b = _bound(b, 0, (1 << (chunkSize << 3)) - 1);

        uint256[] memory items = new uint256[](2);
        items[0] = a;
        items[1] = b;
        bytes memory newList = pack(items, chunkSize);

        assertEq(newList.length, chunkSize * 2);
        this._assertBytesMatchItems(newList, items, chunkSize, 0);
    }

    function test_pack4(uint256 a, uint256 b, uint256 c, uint256 d, uint256 chunkSize) public {
        chunkSize = _bound(chunkSize, 1, 28);
        a = _bound(a, 0, (1 << (chunkSize << 3)) - 1);
        b = _bound(b, 0, (1 << (chunkSize << 3)) - 1);
        c = _bound(c, 0, (1 << (chunkSize << 3)) - 1);
        d = _bound(d, 0, (1 << (chunkSize << 3)) - 1);

        uint256[] memory items = new uint256[](4);
        items[0] = a;
        items[1] = b;
        items[2] = c;
        items[3] = d;
        bytes memory newList = pack(items, chunkSize);

        assertEq(newList.length, chunkSize * 4);
        this._assertBytesMatchItems(newList, items, chunkSize, 0);
    }

    function test_packMatchesAbiEncodePacked(uint256 a, uint256 b, uint256 c, uint256 d) public {
        uint256[] memory arr = new uint256[](4);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;

        bytes memory x = abi.encodePacked(uint32(a), uint32(b), uint32(c), uint32(d));
        bytes memory y = pack(arr, 32 / 8);
        _assertBytesMatch(x, y);

        x = abi.encodePacked(uint128(a), uint128(b), uint128(c), uint128(d));
        y = pack(arr, 128 / 8);
        _assertBytesMatch(x, y);

        x = abi.encodePacked(uint224(a), uint224(b), uint224(c), uint224(d));
        y = pack(arr, 224 / 8);
        _assertBytesMatch(x, y);
    }

    /*//////////////////////////////////////////////////////////////
                                 UNPACK
    //////////////////////////////////////////////////////////////*/

    function test_unpackProper(uint256[] memory items, uint256 chunkSize) public {
        chunkSize = _bound(chunkSize, 1, 32);
        uint256 max;
        unchecked {
            max = (1 << (chunkSize << 3)) - 1;
        }
        for (uint256 i; i < items.length; i++) {
            items[i] %= max;
        }

        bytes memory packed = pack(items, chunkSize);
        uint256[] memory recovered = packed.unpack(chunkSize);

        assertEq(recovered.length, items.length, "length");
        for (uint256 i; i < recovered.length; i++) {
            assertEq(recovered[i], items[i]);
        }
    }

    function test_unpackMessy(uint256[] memory items, uint256 chunkSize) public {
        chunkSize = _bound(chunkSize, 1, 31);

        bytes memory packed = pack(items, chunkSize);
        uint256[] memory recovered = packed.unpack(chunkSize);

        uint256 max;
        unchecked {
            max = (1 << (chunkSize << 3));
        }
        for (uint256 i; i < items.length; i++) {
            items[i] %= max;
        }

        assertEq(recovered.length, items.length, "length");
        for (uint256 i; i < recovered.length; i++) {
            assertEq(recovered[i], items[i]);
        }
    }

    /*//////////////////////////////////////////////////////////////
                             APPEND SINGLE
    //////////////////////////////////////////////////////////////*/

    function test_appendSingle32(bytes memory data, uint32 a) public {
        bytes memory newList = data.push(a, 32 / 8);
        _assertBytesMatch(newList, abi.encodePacked(data, a));
    }

    function test_appendSingle64(bytes memory data, uint64 a) public {
        bytes memory newList = data.push(a, 64 / 8);
        _assertBytesMatch(newList, abi.encodePacked(data, a));
    }

    function test_appendSingle128(bytes memory data, uint128 a) public {
        bytes memory newList = data.push(a, 128 / 8);
        _assertBytesMatch(newList, abi.encodePacked(data, a));
    }

    function test_appendSingle224(bytes memory data, uint224 a) public {
        bytes memory newList = data.push(a, 224 / 8);
        _assertBytesMatch(newList, abi.encodePacked(data, a));
    }

    /*//////////////////////////////////////////////////////////////
                              APPEND LIST
    //////////////////////////////////////////////////////////////*/

    function test_appendList0(bytes memory data, uint256 chunkSize) public {
        chunkSize = _bound(chunkSize, 0, 28);
        uint256[] memory arr = new uint256[](0);
        _assertBytesMatch(data, data.push(arr, chunkSize));
    }

    function test_appendList1(bytes memory data, uint256 a, uint256 chunkSize) public {
        chunkSize = _bound(chunkSize, 1, 28);
        a = _bound(a, 0, (1 << (chunkSize << 3)) - 1);

        uint256[] memory arr = new uint256[](1);
        arr[0] = a;
        bytes memory newList = data.push(arr, chunkSize);

        _assertBytesMatchUpTo(data, newList, data.length);
        this._assertBytesMatchItems(newList, arr, chunkSize, data.length);
    }

    function test_appendList2(bytes memory data, uint256 a, uint256 b, uint256 chunkSize) public {
        chunkSize = _bound(chunkSize, 1, 28);
        a = _bound(a, 0, (1 << (chunkSize << 3)) - 1);
        b = _bound(b, 0, (1 << (chunkSize << 3)) - 1);

        uint256[] memory arr = new uint256[](2);
        arr[0] = a;
        arr[1] = b;
        bytes memory newList = data.push(arr, chunkSize);

        _assertBytesMatchUpTo(data, newList, data.length);
        this._assertBytesMatchItems(newList, arr, chunkSize, data.length);
    }

    function test_appendList4(
        bytes memory data,
        uint256 a,
        uint256 b,
        uint256 c,
        uint256 d,
        uint256 chunkSize
    ) public {
        chunkSize = _bound(chunkSize, 1, 28);
        a = _bound(a, 0, (1 << (chunkSize << 3)) - 1);
        b = _bound(b, 0, (1 << (chunkSize << 3)) - 1);
        c = _bound(c, 0, (1 << (chunkSize << 3)) - 1);
        d = _bound(d, 0, (1 << (chunkSize << 3)) - 1);

        uint256[] memory arr = new uint256[](4);
        arr[0] = a;
        arr[1] = b;
        arr[2] = c;
        arr[3] = d;
        bytes memory newList = data.push(arr, chunkSize);

        _assertBytesMatchUpTo(data, newList, data.length);
        this._assertBytesMatchItems(newList, arr, chunkSize, data.length);
    }

    function test_appendToEmptyMatchesPack(
        uint256 a,
        uint256 b,
        uint256 c,
        uint256 d,
        uint256 chunkSize
    ) public {
        chunkSize = _bound(chunkSize, 1, 28);
        a = _bound(a, 0, (1 << (chunkSize << 3)) - 1);
        b = _bound(b, 0, (1 << (chunkSize << 3)) - 1);
        c = _bound(c, 0, (1 << (chunkSize << 3)) - 1);
        d = _bound(d, 0, (1 << (chunkSize << 3)) - 1);

        uint256[] memory items = new uint256[](4);
        items[0] = a;
        items[1] = b;
        items[2] = c;
        items[3] = d;

        bytes memory x = pack(items, chunkSize);
        bytes memory y = bytes("").push(items, chunkSize);
        _assertBytesMatch(x, y);
    }

    /*//////////////////////////////////////////////////////////////
                                 FILTER
    //////////////////////////////////////////////////////////////*/

    function test_filter(bytes calldata raw, uint256 item, uint256 chunkSize) public {
        chunkSize = _bound(chunkSize, 1, 28);
        item = _bound(item, 0, (1 << (chunkSize << 3)) - 1);

        bytes memory data;
        {
            uint256 length = (raw.length / chunkSize) * chunkSize;
            data = raw[0:length];
        }

        bytes memory newList = data.filter(item, chunkSize);
        assertFalse(newList.includes(item, chunkSize));

        data = data.push(item, chunkSize);
        data = bytes.concat(data, data);
        assertTrue(data.includes(item, chunkSize));

        newList = data.filter(item, chunkSize);
        assertFalse(newList.includes(item, chunkSize));
    }

    function test_spec_filter(uint256 x) public {
        vm.assume(x != 12 && x != 34 && x != 56 && x != 78);
        bytes memory a = abi.encodePacked(uint56(12), uint56(34), uint56(56), uint56(78));

        bytes memory b = a.filter(12, 7);
        assertEq(b, abi.encodePacked(uint56(34), uint56(56), uint56(78)));

        b = a.filter(34, 7);
        assertEq(b, abi.encodePacked(uint56(12), uint56(56), uint56(78)));

        b = a.filter(56, 7);
        assertEq(b, abi.encodePacked(uint56(12), uint56(34), uint56(78)));

        b = a.filter(78, 7);
        assertEq(b, abi.encodePacked(uint56(12), uint56(34), uint56(56)));

        b = a.filter(x, 7);
        assertEq(b, a);
    }

    /*//////////////////////////////////////////////////////////////
                                INCLUDES
    //////////////////////////////////////////////////////////////*/

    function test_includes0_any(uint256 a, uint256 chunkSize) public {
        chunkSize = _bound(chunkSize, 0, 28);
        assertFalse(bytes("").includes(a, chunkSize));
    }

    function test_includes1_32(uint32 a, uint32 b) public {
        vm.assume(a != b);

        bytes memory newList = abi.encodePacked(a);
        assertTrue(newList.includes(a, 4));
        assertFalse(newList.includes(b, 4));
    }

    function test_includes1_128(uint128 a, uint128 b) public {
        vm.assume(a != b);

        bytes memory newList = abi.encodePacked(a);
        assertTrue(newList.includes(a, 16));
        assertFalse(newList.includes(b, 16));
    }

    function test_includes1_224(uint224 a, uint224 b) public {
        vm.assume(a != b);

        bytes memory newList = abi.encodePacked(a);
        assertTrue(newList.includes(a, 28));
        assertFalse(newList.includes(b, 28));
    }

    function test_includes2_32(uint32 a, uint32 b, uint32 c) public {
        vm.assume(c != a && c != b);

        bytes memory newList = abi.encodePacked(a, b);
        assertTrue(newList.includes(a, 4));
        assertTrue(newList.includes(b, 4));
        assertFalse(newList.includes(c, 4));
    }

    function test_includes2_128(uint128 a, uint128 b, uint128 c) public {
        vm.assume(c != a && c != b);

        bytes memory newList = abi.encodePacked(a, b);
        assertTrue(newList.includes(a, 16));
        assertTrue(newList.includes(b, 16));
        assertFalse(newList.includes(c, 16));
    }

    function test_includes2_224(uint224 a, uint224 b, uint224 c) public {
        vm.assume(c != a && c != b);

        bytes memory newList = abi.encodePacked(a, b);
        assertTrue(newList.includes(a, 28));
        assertTrue(newList.includes(b, 28));
        assertFalse(newList.includes(c, 28));
    }

    function test_includes4_32(uint32 a, uint32 b, uint32 c, uint32 d, uint32 e) public {
        vm.assume(e != a && e != b && e != c && e != d);

        bytes memory newList = abi.encodePacked(a, b, c, d);
        assertTrue(newList.includes(a, 4));
        assertTrue(newList.includes(b, 4));
        assertTrue(newList.includes(c, 4));
        assertTrue(newList.includes(d, 4));
        assertFalse(newList.includes(e, 4));
    }

    function test_includes4_128(uint128 a, uint128 b, uint128 c, uint128 d, uint128 e) public {
        vm.assume(e != a && e != b && e != c && e != d);

        bytes memory newList = abi.encodePacked(a, b, c, d);
        assertTrue(newList.includes(a, 16));
        assertTrue(newList.includes(b, 16));
        assertTrue(newList.includes(c, 16));
        assertTrue(newList.includes(d, 16));
        assertFalse(newList.includes(e, 16));
    }

    function test_includes4_224(uint224 a, uint224 b, uint224 c, uint224 d, uint224 e) public {
        vm.assume(e != a && e != b && e != c && e != d);

        bytes memory newList = abi.encodePacked(a, b, c, d);
        assertTrue(newList.includes(a, 28));
        assertTrue(newList.includes(b, 28));
        assertTrue(newList.includes(c, 28));
        assertTrue(newList.includes(d, 28));
        assertFalse(newList.includes(e, 28));
    }

    /*//////////////////////////////////////////////////////////////
                                   AT
    //////////////////////////////////////////////////////////////*/

    function test_at(uint256[] memory arr, uint256 chunkSize) public {
        chunkSize = _bound(chunkSize, 1, 32);

        bytes memory data = pack(arr, chunkSize);

        for (uint256 i; i < arr.length; i++) {
            uint256 expected = chunkSize == 32 ? arr[i] : (arr[i] % (1 << (chunkSize << 3)));
            assertEq(data.at(i, chunkSize), expected);
        }
    }

    function testFail_atBadIndex(uint256[] memory arr, uint256 chunkSize, uint128 i) public pure {
        chunkSize = _bound(chunkSize, 1, 32);

        bytes memory data = pack(arr, chunkSize);
        data.at(arr.length + i, chunkSize);
    }

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/

    function _assertBytesMatchItems(
        bytes calldata a,
        uint256[] memory items,
        uint256 chunkSize,
        uint256 start
    ) external {
        assertEq((a.length - start) / chunkSize, items.length, "different lengths");

        uint256 shift = 256 - (chunkSize << 3);

        for (uint256 i = start; i < a.length; i += chunkSize) {
            uint256 fromBytes = uint256(bytes32(a[i:i + chunkSize]));
            assertEq(fromBytes >> shift, items[(i - start) / chunkSize], "different data");
        }
    }

    function _assertBytesMatch(bytes memory a, bytes memory b) private {
        assertEq(a.length, b.length, "different lengths");
        for (uint256 i; i < a.length; i++) {
            assertEq(a[i], b[i], "different data");
        }
    }

    function _assertBytesMatchUpTo(bytes memory a, bytes memory b, uint256 end) private {
        for (uint256 i; i < end; i++) {
            assertEq(a[i], b[i], "different data");
        }
    }
}
