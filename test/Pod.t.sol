// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {Pod, MockPod} from "./utils/mocks/MockPod.sol";

contract Target {
    error TargetError(bytes data);

    bytes32 public datahash;

    bytes public data;

    function setData(bytes memory data_) public payable returns (bytes memory) {
        data = data_;
        datahash = keccak256(data_);
        return data_;
    }

    function revertWithTargetError(bytes memory data_) public payable {
        revert TargetError(data_);
    }

    function changeOwnerSlotValue(bool change) public payable {
        /// @solidity memory-safe-assembly
        assembly {
            if change { sstore(not(0x8b78c6d8), 0x112233) }
        }
    }
}

contract PodTest is SoladyTest {
    MockPod pod;

    function setUp() public {
        pod = new MockPod();
        pod.initializeMothership(address(this));
    }

    function testSetMothership() public {
        assertEq(pod.mothership(), address(this));
        pod.setMothership(address(0xABCD));
        assertEq(pod.mothership(), address(0xABCD));
    }

    function testInitializeMothership() public {
        vm.expectRevert(Pod.MothershipAlreadyInitialized.selector);
        pod.initializeMothership(address(this));
    }

    function testExecute() public {
        vm.deal(address(pod), 1 ether);

        address target = address(new Target());
        bytes memory data = _randomBytes();
        pod.execute(target, 123, abi.encodeWithSignature("setData(bytes)", data));
        assertEq(Target(target).datahash(), keccak256(data));
        assertEq(target.balance, 123);

        vm.prank(_randomNonZeroAddress());
        vm.expectRevert(Pod.CallerNotMothership.selector);
        pod.execute(target, 123, abi.encodeWithSignature("setData(bytes)", data));

        vm.expectRevert(abi.encodeWithSignature("TargetError(bytes)", data));
        pod.execute(target, 123, abi.encodeWithSignature("revertWithTargetError(bytes)", data));
    }

    function testExecuteBatch() public {
        vm.deal(address(pod), 1 ether);

        Pod.Call[] memory calls = new Pod.Call[](2);
        calls[0].target = address(new Target());
        calls[1].target = address(new Target());
        calls[0].value = 123;
        calls[1].value = 456;
        calls[0].data = abi.encodeWithSignature("setData(bytes)", _randomBytes(123));
        calls[1].data = abi.encodeWithSignature("setData(bytes)", _randomBytes(345));

        pod.executeBatch(calls);
        assertEq(Target(calls[0].target).datahash(), keccak256(_randomBytes(123)));
        assertEq(Target(calls[1].target).datahash(), keccak256(_randomBytes(345)));
        assertEq(calls[0].target.balance, 123);
        assertEq(calls[1].target.balance, 456);

        calls[1].data = abi.encodeWithSignature("revertWithTargetError(bytes)", _randomBytes(111));
        vm.expectRevert(abi.encodeWithSignature("TargetError(bytes)", _randomBytes(111)));
        pod.executeBatch(calls);
    }

    function testExecuteBatch(uint256 r) public {
        vm.deal(address(pod), 1 ether);

        unchecked {
            uint256 n = r & 3;
            Pod.Call[] memory calls = new Pod.Call[](n);

            for (uint256 i; i != n; ++i) {
                uint256 v = _random() & 0xff;
                calls[i].target = address(new Target());
                calls[i].value = v;
                calls[i].data = abi.encodeWithSignature("setData(bytes)", _randomBytes(v));
            }

            bytes[] memory results;
            if (_random() & 1 == 0) {
                results = pod.executeBatch(_random(), calls);
            } else {
                results = pod.executeBatch(calls);
            }

            assertEq(results.length, n);
            for (uint256 i; i != n; ++i) {
                uint256 v = calls[i].value;
                assertEq(Target(calls[i].target).datahash(), keccak256(_randomBytes(v)));
                assertEq(calls[i].target.balance, v);
                assertEq(abi.decode(results[i], (bytes)), _randomBytes(v));
            }
        }
    }

    function testFallback(bytes4 selector) public {
        if (
            selector == bytes4(0xf23a6e61) || selector == bytes4(0x150b7a02)
                || selector == bytes4(0xbc197c81)
        ) {
            (, bytes memory rD) = address(pod).call(abi.encodePacked(selector));
            assertEq(abi.decode(rD, (bytes4)), selector);
        } else {
            vm.expectRevert(Pod.FnSelectorNotRecognized.selector);
            (bool s,) = address(pod).call(abi.encodePacked(selector));
            s; // suppressed compiler warning
        }
    }

    function _randomBytes(uint256 seed) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, seed)
            let r := keccak256(0x00, 0x20)
            if lt(byte(2, r), 0x20) {
                result := mload(0x40)
                let n := and(r, 0x7f)
                mstore(result, n)
                codecopy(add(result, 0x20), byte(1, r), add(n, 0x40))
                mstore(0x40, add(add(result, 0x40), n))
            }
        }
    }
}
