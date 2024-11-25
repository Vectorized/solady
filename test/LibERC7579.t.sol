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
}
