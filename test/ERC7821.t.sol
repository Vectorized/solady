// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {ERC7821, MockERC7821} from "./utils/mocks/MockERC7821.sol";
import {LibClone} from "../src/utils/LibClone.sol";

contract ERC7821Test is SoladyTest {
    error CustomError();

    MockERC7821 mbe;

    address target;

    bytes32 internal constant _SUPPORTED_MODE = bytes10(0x01000000000078210001);
    bytes32 internal constant _CALLDATA_OPTIMAL_MODE = bytes10(0x01000000000078210003);
    bytes[] internal _bytes;

    function setUp() public {
        mbe = new MockERC7821();
        mbe.setAuthorizedCaller(address(this), true);
        target = LibClone.clone(address(this));
    }

    function revertsWithCustomError() external payable {
        revert CustomError();
    }

    function returnsBytes(bytes memory b) external payable returns (bytes memory) {
        return b;
    }

    function returnsHash(bytes memory b) external payable returns (bytes32) {
        return keccak256(b);
    }

    function testERC7821Gas() public {
        vm.pauseGasMetering();
        vm.deal(address(this), 1 ether);

        ERC7821.Call[] memory calls = new ERC7821.Call[](2);

        calls[0].to = target;
        calls[0].value = 123;
        calls[0].data = abi.encodeWithSignature("returnsBytes(bytes)", "hehe");

        calls[1].to = target;
        calls[1].value = 789;
        calls[1].data = abi.encodeWithSignature("returnsHash(bytes)", "lol");

        bytes memory data = abi.encode(calls);
        vm.resumeGasMetering();

        mbe.execute{value: _totalValue(calls)}(_SUPPORTED_MODE, data);
    }

    function testERC7821CalldataOptimalGas() public {
        vm.pauseGasMetering();
        vm.deal(address(this), 1 ether);

        bytes[] memory datas = new bytes[](2);

        datas[0] = abi.encodeWithSignature("returnsBytes(bytes)", "hehe");
        datas[1] = abi.encodeWithSignature("returnsHash(bytes)", "lol");

        bytes memory data = abi.encode(target, datas);
        vm.resumeGasMetering();

        mbe.execute(_CALLDATA_OPTIMAL_MODE, data);
    }

    function testERC7821(bytes memory opData) public {
        vm.deal(address(this), 1 ether);

        ERC7821.Call[] memory calls = new ERC7821.Call[](2);

        calls[0].to = target;
        calls[0].value = 123;
        calls[0].data = abi.encodeWithSignature("returnsBytes(bytes)", "hehe");

        calls[1].to = target;
        calls[1].value = 789;
        calls[1].data = abi.encodeWithSignature("returnsHash(bytes)", "lol");

        mbe.execute{value: _totalValue(calls)}(_SUPPORTED_MODE, _encode(calls, opData));

        assertEq(mbe.lastOpData(), opData);
    }

    function testERC7821CalldataOptimal(bytes memory opData) public {
        vm.deal(address(this), 1 ether);

        bytes[] memory datas = new bytes[](2);
        datas[0] = abi.encodeWithSignature("returnsBytes(bytes)", "hehe");
        datas[1] = abi.encodeWithSignature("returnsHash(bytes)", "lol");

        mbe.execute(_CALLDATA_OPTIMAL_MODE, _encodeCalldataOptimal(target, datas, opData));

        assertEq(mbe.lastOpData(), opData);
    }

    function testERC7821ForRevert() public {
        ERC7821.Call[] memory calls = new ERC7821.Call[](1);
        calls[0].to = target;
        calls[0].value = 0;
        calls[0].data = abi.encodeWithSignature("revertsWithCustomError()");

        vm.expectRevert(CustomError.selector);
        mbe.execute{value: _totalValue(calls)}(_SUPPORTED_MODE, _encode(calls, ""));
    }

    function testERC7821CalldataOptimalForRevert() public {
        bytes[] memory datas = new bytes[](1);
        datas[0] = abi.encodeWithSignature("revertsWithCustomError()");

        vm.expectRevert(CustomError.selector);
        mbe.execute(_CALLDATA_OPTIMAL_MODE, _encodeCalldataOptimal(target, datas, ""));
    }

    function _encode(ERC7821.Call[] memory calls, bytes memory opData)
        internal
        returns (bytes memory)
    {
        if (_randomChance(2) && opData.length == 0) return abi.encode(calls);
        return abi.encode(calls, opData);
    }

    function _encodeCalldataOptimal(address to, bytes[] memory datas, bytes memory opData)
        internal
        returns (bytes memory)
    {
        if (_randomChance(2) && opData.length == 0) return abi.encode(to, datas);
        return abi.encode(to, datas, opData);
    }

    struct Payload {
        bytes data;
        uint256 mode;
    }

    function testERC7821(bytes32) public {
        vm.deal(address(this), 1 ether);

        ERC7821.Call[] memory calls = new ERC7821.Call[](_randomUniform() & 3);
        Payload[] memory payloads = new Payload[](calls.length);

        for (uint256 i; i < calls.length; ++i) {
            calls[i].to = target;
            calls[i].value = _randomUniform() & 0xff;
            bytes memory data = _truncateBytes(_randomBytes(), 0x1ff);
            payloads[i].data = data;
            if (_randomChance(2)) {
                payloads[i].mode = 0;
                calls[i].data = abi.encodeWithSignature("returnsBytes(bytes)", data);
            } else {
                payloads[i].mode = 1;
                calls[i].data = abi.encodeWithSignature("returnsHash(bytes)", data);
            }
        }

        mbe.executeDirect{value: _totalValue(calls)}(calls);

        if (calls.length != 0 && _randomChance(32)) {
            calls[_randomUniform() % calls.length].data =
                abi.encodeWithSignature("revertsWithCustomError()");
            vm.expectRevert(CustomError.selector);
            mbe.executeDirect{value: _totalValue(calls)}(calls);
        }
    }

    function testERC7821CalldataOptimal(bytes32) public {
        vm.deal(address(this), 1 ether);

        bytes[] memory datas = new bytes[](_randomUniform() & 3);
        Payload[] memory payloads = new Payload[](datas.length);

        for (uint256 i; i < datas.length; ++i) {
            bytes memory data = _truncateBytes(_randomBytes(), 0x1ff);
            payloads[i].data = data;
            if (_randomChance(2)) {
                payloads[i].mode = 0;
                datas[i] = abi.encodeWithSignature("returnsBytes(bytes)", data);
            } else {
                payloads[i].mode = 1;
                datas[i] = abi.encodeWithSignature("returnsHash(bytes)", data);
            }
        }

        mbe.executeDirect(datas, target);

        if (datas.length != 0 && _randomChance(32)) {
            datas[_randomUniform() % datas.length] =
                abi.encodeWithSignature("revertsWithCustomError()");
            vm.expectRevert(CustomError.selector);
            mbe.executeDirect(datas, target);
        }
    }

    function _totalValue(ERC7821.Call[] memory calls) internal pure returns (uint256 result) {
        unchecked {
            for (uint256 i; i < calls.length; ++i) {
                result += calls[i].value;
            }
        }
    }


    function testERC7821ExecuteBatchOfBatches() public {
        bytes32 mode = bytes32(0x0100000000007821000200000000000000000000000000000000000000000000);
        bytes[] memory batchBytes = new bytes[](3);
        batchBytes[0] = hex"112233";
        batchBytes[1] = hex"";
        batchBytes[2] =
            hex"112233445566778899112233445566778899112233445566778899112233445566778899112233445566778899";
        bytes[] memory batches = new bytes[](batchBytes.length);
        for (uint256 i; i < batches.length; ++i) {
            batches[i] = _encodePushBytesBatch(batchBytes[i]);
        }
        mbe.execute(mode, abi.encode(batches));
        for (uint256 i; i < batches.length; ++i) {
            assertEq(_bytes[i], batchBytes[i]);
        }
        assertEq(_bytes.length, batchBytes.length);

        // Test that batch of batches is executed with the correct `msg.sender`.

        address pranker = _randomUniqueHashedAddress();
        vm.startPrank(pranker);

        vm.expectRevert(MockERC7821.Unauthorized.selector);
        mbe.execute(mode, abi.encode(batches));

        mbe.setAuthorizedCaller(pranker, true);
        mbe.execute(mode, abi.encode(batches));

        assertEq(_bytes.length, batchBytes.length * 2);

        mbe.setAuthorizedCaller(pranker, false);
        vm.expectRevert(MockERC7821.Unauthorized.selector);
        mbe.execute(mode, abi.encode(batches));

        assertEq(_bytes.length, batchBytes.length * 2);

        vm.stopPrank();
    }

    function _encodePushBytesBatch(bytes memory x) internal view returns (bytes memory) {
        ERC7821.Call[] memory calls = new ERC7821.Call[](1);
        calls[0].data = abi.encodeWithSignature("pushBytes(bytes)", x);
        calls[0].to = address(this);
        return abi.encode(calls);
    }

    function pushBytes(bytes memory x) public {
        _bytes.push(x);
    }

    function testERC7821CalldataOptimalWithZeroAddress() public {
        // Test that when to=address(0), it gets replaced with address(this) (the MockERC7821 contract)
        // We'll call executeDirect which directly calls the internal _execute function
        bytes[] memory datas = new bytes[](1);
        datas[0] = abi.encodeWithSignature("setAuthorizedCaller(address,bool)", address(0x123), true);

        // This should replace address(0) with address(mbe) and call setAuthorizedCaller on itself
        mbe.executeDirect(datas, address(0));

        // Verify the call succeeded by checking that address(0x123) is now authorized
        assertTrue(mbe.isAuthorizedCaller(address(0x123)));
    }
}
