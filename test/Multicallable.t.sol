// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {MockMulticallable} from "./utils/mocks/MockMulticallable.sol";

contract MulticallableTest is SoladyTest {
    MockMulticallable multicallable;

    function setUp() public {
        multicallable = new MockMulticallable();
    }

    function testMulticallableRevertWithMessage(string memory revertMessage) public {
        bytes[] memory data = new bytes[](1);
        data[0] =
            abi.encodeWithSelector(MockMulticallable.revertsWithString.selector, revertMessage);
        vm.expectRevert(bytes(revertMessage));
        multicallable.multicall(data);
    }

    function testMulticallableRevertWithMessage() public {
        testMulticallableRevertWithMessage("Milady");
    }

    function testMulticallableRevertWithCustomError() public {
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSelector(MockMulticallable.revertsWithCustomError.selector);
        vm.expectRevert(MockMulticallable.CustomError.selector);
        multicallable.multicall(data);
    }

    function testMulticallableRevertWithNothing() public {
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSelector(MockMulticallable.revertsWithNothing.selector);
        vm.expectRevert();
        multicallable.multicall(data);
    }

    function testMulticallableReturnDataIsProperlyEncoded(
        uint256 a0,
        uint256 b0,
        uint256 a1,
        uint256 b1
    ) public {
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSelector(MockMulticallable.returnsTuple.selector, a0, b0);
        data[1] = abi.encodeWithSelector(MockMulticallable.returnsTuple.selector, a1, b1);
        bytes[] memory returnedData = multicallable.multicall(data);
        MockMulticallable.Tuple memory t0 = abi.decode(returnedData[0], (MockMulticallable.Tuple));
        MockMulticallable.Tuple memory t1 = abi.decode(returnedData[1], (MockMulticallable.Tuple));
        assertEq(t0.a, a0);
        assertEq(t0.b, b0);
        assertEq(t1.a, a1);
        assertEq(t1.b, b1);
    }

    function testMulticallableReturnDataIsProperlyEncoded(
        string memory sIn0,
        string memory sIn1,
        uint256 n
    ) public {
        n = n % 2;
        bytes[] memory dataIn = new bytes[](n);
        if (n > 0) {
            dataIn[0] = abi.encodeWithSelector(MockMulticallable.returnsString.selector, sIn0);
        }
        if (n > 1) {
            dataIn[1] = abi.encodeWithSelector(MockMulticallable.returnsString.selector, sIn1);
        }
        bytes[] memory dataOut = multicallable.multicall(dataIn);
        if (n > 0) {
            assertEq(abi.decode(dataOut[0], (string)), sIn0);
        }
        if (n > 1) {
            assertEq(abi.decode(dataOut[1], (string)), sIn1);
        }
    }

    function testMulticallableReturnDataIsProperlyEncoded() public {
        testMulticallableReturnDataIsProperlyEncoded(0, 1, 2, 3);
    }

    function testMulticallableBenchmark() public {
        unchecked {
            bytes[] memory data = new bytes[](10);
            for (uint256 i; i != data.length; ++i) {
                data[i] = abi.encodeWithSelector(MockMulticallable.returnsTuple.selector, i, i + 1);
            }
            bytes[] memory returnedData = multicallable.multicall(data);
            assertEq(returnedData.length, data.length);
        }
    }

    function testMulticallableOriginalBenchmark() public {
        unchecked {
            bytes[] memory data = new bytes[](10);
            for (uint256 i; i != data.length; ++i) {
                data[i] = abi.encodeWithSelector(MockMulticallable.returnsTuple.selector, i, i + 1);
            }
            bytes[] memory returnedData = multicallable.multicallOriginal(data);
            assertEq(returnedData.length, data.length);
        }
    }

    function testMulticallableWithNoData() public {
        bytes[] memory data = new bytes[](0);
        assertEq(multicallable.multicall(data).length, 0);
    }

    function testMulticallablePreservesMsgSender() public {
        address caller = address(uint160(0xbeef));
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSelector(MockMulticallable.returnsSender.selector);
        vm.prank(caller);
        address returnedAddress = abi.decode(multicallable.multicall(data)[0], (address));
        assertEq(caller, returnedAddress);
    }
}
