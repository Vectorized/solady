// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {LibERC7579} from "../src/accounts/LibERC7579.sol";

contract LibERC7579Test is SoladyTest {
    function testEncodeAndDecodeMode(bytes32) public {
        bytes1 callType = bytes1(bytes32(_randomUniform()));
        bytes1 execType = bytes1(bytes32(_randomUniform()));
        bytes4 selector = bytes4(bytes32(_randomUniform()));
        bytes22 payload = bytes22(bytes32(_randomUniform()));
        bytes32 mode = LibERC7579.encodeMode(callType, execType, selector, payload);
        assertEq(LibERC7579.getCallType(mode), callType);
        assertEq(LibERC7579.getExecType(mode), execType);
        assertEq(LibERC7579.getSelector(mode), selector);
        assertEq(LibERC7579.getPayload(mode), payload);
        for (uint256 i = 2; i < 2 + 4; ++i) {
            assertEq(bytes1(mode[i]), 0);
        }
    }

    function testEncodeAndDecodeMode() public {
        bytes32 mode = LibERC7579.encodeMode(
            0x01, 0x00, 0x11223344, 0xffaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabb
        );
        assertEq(mode, 0x01000000000011223344ffaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabb);
    }

    struct Call {
        address target;
        uint256 value;
        bytes data;
    }

    struct _TestTemps {
        address target;
        uint256 value;
        bytes data;
        Call[] calls;
        bytes opData;
    }

    function testDecodeSingle(address target, uint256 value, bytes memory data) public {
        bytes memory executionData = abi.encodePacked(target, value, data);
        _TestTemps memory t;
        (t.target, t.value, t.data) = this.decodeSingle(executionData);
        assertEq(t.target, target);
        assertEq(t.value, value);
        assertEq(t.data, data);
    }

    function decodeSingle(bytes calldata executionData)
        public
        pure
        returns (address, uint256, bytes memory)
    {
        return LibERC7579.decodeSingle(executionData);
    }

    function testDecodeDelegate(address target, bytes memory data) public {
        bytes memory executionData = abi.encodePacked(target, data);
        _TestTemps memory t;
        (t.target, t.data) = this.decodeDelegate(executionData);
        assertEq(t.target, target);
        assertEq(t.data, data);
    }

    function decodeDelegate(bytes calldata executionData)
        public
        pure
        returns (address, bytes memory)
    {
        return LibERC7579.decodeDelegate(executionData);
    }

    function testReencodeBatchAsExecuteCalldata(bytes32 mode) public {
        Call[] memory calls = new Call[](_randomUniform() & 3);
        for (uint256 i; i != calls.length; ++i) {
            Call memory c = calls[i];
            c.target = address(uint160(_randomUniform()));
            c.value = _random();
            c.data = _truncateBytes(_randomBytes(), 0x1ff);
        }
        bytes memory executionData;
        if (_randomChance(2)) {
            executionData = abi.encode(calls);
        } else {
            executionData = abi.encode(calls, _truncateBytes(_randomBytes(), 0xff));
        }
        this.subTestReencodeBatchAsExecuteCalldata(mode, executionData);
    }

    function subTestReencodeBatchAsExecuteCalldata(bytes32 mode, bytes calldata executionData)
        public
    {
        _misalignFreeMemoryPointer();
        _brutalizeMemory();
        bytes memory opData = _truncateBytes(_randomBytes(), 0x1ff);
        bytes memory t = LibERC7579.reencodeBatch(executionData, opData);
        _checkMemory(t);
        bytes memory computed =
            LibERC7579.reencodeBatchAsExecuteCalldata(mode, executionData, opData);
        _checkMemory(computed);
        assertEq(computed, abi.encodeWithSignature("execute(bytes32,bytes)", mode, t));
        (bool success, bytes memory results) = address(this).call(computed);
        assertEq(success, true);
        assertEq(abi.decode(results, (bytes32)), keccak256(abi.encode(mode, keccak256(t))));
    }

    function execute(bytes32 mode, bytes calldata executionData) public pure returns (bytes32) {
        return keccak256(abi.encode(mode, keccak256(executionData)));
    }

    function testDecodeBatchAndOpData(bytes32) public {
        Call[] memory calls = new Call[](_randomUniform() & 3);
        bytes memory opData = _truncateBytes(_randomBytes(), 0x1ff);
        for (uint256 i; i != calls.length; ++i) {
            Call memory c = calls[i];
            c.target = address(uint160(_randomUniform()));
            c.value = _random();
            c.data = _truncateBytes(_randomBytes(), 0x1ff);
        }
        _TestTemps memory t;
        bool useOpData = _randomChance(2);
        if (useOpData) {
            (t.calls, t.opData) = this.decodeBatchAndOpData(abi.encode(calls, opData));
        } else {
            bytes memory executionData;
            if (_randomChance(2)) {
                executionData = abi.encode(calls);
            } else {
                executionData = abi.encode(calls, opData);
            }
            if (_randomChance(2)) {
                t.calls = this.decodeBatch(executionData);
            } else {
                (t.calls, t.opData) = this.decodeBatchAndOpData(executionData);
            }
        }

        assertEq(t.calls.length, calls.length);
        for (uint256 i; i != calls.length; ++i) {
            assertEq(t.calls[i].target, calls[i].target);
            assertEq(t.calls[i].value, calls[i].value);
            assertEq(t.calls[i].data, calls[i].data);
        }
        if (useOpData) {
            assertEq(t.opData, opData);
        }

        if (calls.length > 0 && _randomChance(8)) {
            uint256 i = _bound(_randomUniform(), 0, calls.length - 1);
            (t.target, t.value, t.data) = this.decodeBatchAndGetExecution(abi.encode(calls), i);
            assertEq(t.target, calls[i].target);
            assertEq(t.value, calls[i].value);
            assertEq(t.data, calls[i].data);
        }

        if (_randomChance(2)) {
            bytes memory executionData;
            if (_randomChance(2)) {
                executionData = abi.encode(calls);
            } else {
                executionData = abi.encode(calls, opData);
            }
            opData = _truncateBytes(_randomBytes(), 0x1ff);
            (t.calls, t.opData) = this.reencodeBatchAndDecodeBatch(executionData, opData);
            for (uint256 i; i != calls.length; ++i) {
                assertEq(t.calls[i].target, calls[i].target);
                assertEq(t.calls[i].value, calls[i].value);
                assertEq(t.calls[i].data, calls[i].data);
            }
            assertEq(t.opData, opData);
        }
    }

    function reencodeBatchAndDecodeBatch(bytes calldata executionData, bytes memory opData)
        public
        returns (Call[] memory, bytes memory)
    {
        bytes memory reencoded;
        if (_randomChance(2)) {
            reencoded = LibERC7579.reencodeBatch(executionData, opData);
        } else {
            reencoded = abi.encode(abi.decode(executionData, (Call[])), opData);
        }
        _checkMemory(reencoded);
        if (_randomChance(2)) {
            return this.decodeBatchAndOpData(reencoded);
        } else {
            return abi.decode(reencoded, (Call[], bytes));
        }
    }

    function decodeBatch(bytes calldata executionData) public pure returns (Call[] memory) {
        Call[] calldata calls;
        bytes32[] calldata pointers = LibERC7579.decodeBatch(executionData);
        /// @solidity memory-safe-assembly
        assembly {
            calls.offset := pointers.offset
            calls.length := pointers.length
        }
        return calls;
    }

    function decodeBatchAndOpData(bytes calldata executionData)
        public
        pure
        returns (Call[] memory, bytes memory)
    {
        Call[] calldata calls;
        (bytes32[] calldata pointers, bytes calldata opData) =
            LibERC7579.decodeBatchAndOpData(executionData);
        /// @solidity memory-safe-assembly
        assembly {
            calls.offset := pointers.offset
            calls.length := pointers.length
        }
        return (calls, opData);
    }

    struct S {
        bytes executionData;
        bytes garbage;
    }

    function testDecodeBatchEdgeCase() public {
        /*
        Calldata is as follows when S is passed to a function:

        9988592b (function selector)
        0000000000000000000000000000000000000000000000000000000000000020 (offset of s)
        0000000000000000000000000000000000000000000000000000000000000040 (offset of s.executionData)
        0000000000000000000000000000000000000000000000000000000000000080 (offset of s.garbage)
        0000000000000000000000000000000000000000000000000000000000000020 (s.executionData.length)
        0000000000000000000000000000000000000000000000000000000000000040 (s.executionData)
        0000000000000000000000000000000000000000000000000000000000000020 (s.garbage.length)
        0000000000000000000000000000000000000000000000000000000000000000 (s.garbage)
        */
        S memory s = S({executionData: abi.encode(uint256(0x40)), garbage: abi.encode(uint256(0))});

        vm.expectRevert(LibERC7579.DecodingError.selector);
        this.decodeBatch(s);

        vm.expectRevert();
        this.abiDecodeBatch(s);
    }

    function decodeBatch(S calldata s) public pure returns (uint256) {
        bytes32[] calldata pointers = LibERC7579.decodeBatch(s.executionData);
        return pointers.length;
    }

    function testDecodeBatchEdgeCase2() public {
        (bool success,) = address(this).call(
            abi.encodePacked(
                bytes4(keccak256("propose2(bytes32,bytes,uint256)")),
                hex"0100000000007821000100000000000000000000000000000000000000000000",
                hex"0000000000000000000000000000000000000000000000000000000000000060", // offset to executionData
                _randomUniform(),
                uint256(32 * 5), // length of executionData (THIS SHOULD ACTUALLY BE 32 * 6 BUT WE REDUCE TO 32 * 5)
                hex"0000000000000000000000000000000000000000000000000000000000000020", // offset to pointers array
                hex"0000000000000000000000000000000000000000000000000000000000000004", // pointers array length
                hex"0000000000000000000000000000000000000000000000000000000000000000", // offset to pointers[0]
                hex"0000000000000000000000000000000000000000000000000000000000000000", // offset to pointers[1]
                hex"0000000000000000000000000000000000000000000000000000000000000000", // offset to pointers[2]
                hex"0000000000000000000000000000000000000000000000000000000000000000" // offset to pointers[3]
            )
        );
        assertFalse(success);
    }

    function propose2(bytes32, bytes calldata executionData, uint256)
        public
        pure
        returns (uint256)
    {
        bytes32[] memory pointers = LibERC7579.decodeBatch(executionData);
        return pointers.length;
    }

    function abiDecodeBatch(S calldata s) public pure returns (uint256) {
        Call[] memory pointers = abi.decode(s.executionData, (Call[]));
        return pointers.length;
    }

    function testDecodeBatchAndOpDataReverts(bytes32) public {
        bytes memory opData = hex"3232323232323232323232323232323232323232323232323232323232323232";
        Call[] memory calls = new Call[](1);
        calls[0].target = address(this);
        calls[0].value = 1 ether;
        calls[0].data = hex"5656565656565656565656565656565656565656565656565656565656565656";
        bytes memory executionData = abi.encode(calls, opData);
        if (_randomChance(128)) {
            // Check that it works.
            this.decodeBatchAndOpData(executionData);
        }
        // 0000000000000000000000000000000000000000000000000000000000000040 : 0x20
        // 0000000000000000000000000000000000000000000000000000000000000120 : 0x40
        // 0000000000000000000000000000000000000000000000000000000000000001 : 0x60
        // 0000000000000000000000000000000000000000000000000000000000000020 : 0x80
        // 0000000000000000000000007fa9385be102ac3eac297483dd6233d62b3e1496 : 0xa0
        // 0000000000000000000000000000000000000000000000000de0b6b3a7640000 : 0xc0
        // 0000000000000000000000000000000000000000000000000000000000000060 : 0xe0
        // 0000000000000000000000000000000000000000000000000000000000000020 : 0x100
        // 5656565656565656565656565656565656565656565656565656565656565656 : 0x120
        // 0000000000000000000000000000000000000000000000000000000000000020 : 0x140
        // 3232323232323232323232323232323232323232323232323232323232323232 : 0x160

        if (_randomChance(4)) {
            _testDecodeBatchAndOpDataRevert(executionData, 0x20, 0x140);
        }
        if (_randomChance(4)) {
            _testDecodeBatchAndOpDataRevert(executionData, 0x60, 0x02);
        }
        if (_randomChance(4)) {
            _testDecodeBatchAndOpDataRevert(executionData, 0x40, 0x140);
        }
        if (_randomChance(4)) {
            _testDecodeBatchAndOpDataRevert(executionData, 0x140, 0x21);
        }
        if (_randomChance(4)) {
            _testDecodeBatchAndOpDataRevert(executionData, 0x100, 0x61);
        }
        if (_randomChance(4)) {
            _testDecodeBatchAndOpDataRevert(executionData, 0x80, 0x1c0);
        }
    }

    function _testDecodeBatchAndOpDataRevert(
        bytes memory executionData,
        uint256 o,
        uint256 startingFrom
    ) internal {
        uint256 r = _randomLengthOrOffset(startingFrom);
        bytes memory cd = abi.encodeWithSignature("decodeBatchAndOpData(bytes)", executionData);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(add(o, add(cd, 0x44)), r)
        }
        (bool success,) = address(this).staticcall(cd);
        assertFalse(success);
    }

    function _randomLengthOrOffset(uint256 startingFrom) internal returns (uint256) {
        if (_randomChance(2)) {
            return _bound(_random(), startingFrom, startingFrom + 0x1ff);
        }
        return _bound(_random(), startingFrom, type(uint256).max);
    }

    function decodeBatchAndGetExecution(bytes calldata executionData, uint256 i)
        public
        pure
        returns (address, uint256, bytes memory)
    {
        return LibERC7579.getExecution(LibERC7579.decodeBatch(executionData), i);
    }
}
