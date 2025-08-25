// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";

contract StructExtractTest is SoladyTest {
    struct S {
        uint256 nestedUint;
        bytes nestedBytes;
    }

    function testExtract() public {
        S memory s;
        s.nestedUint = 123456789;
        s.nestedBytes = hex"aabbcc";

        bytes memory toFooCalldata = abi.encodeCall(this.fooCalldata, s);
        emit LogBytes(toFooCalldata);

        bytes memory toFooMemory = abi.encodeCall(this.fooMemory, s);
        emit LogBytes(toFooMemory);

        assembly {
            // Just to make sure the call to `fooCalldata` works.
            pop(
                call(
                    gas(), address(), 0, add(0x20, toFooCalldata), mload(toFooCalldata), 0x00, 0x00
                )
            )

            let o := mload(add(0x44, add(0x20, toFooCalldata))) // Cache the original offset.
            // Try with a negative `nestedBytes` offset. This passes.
            mstore(add(0x44, add(0x20, toFooCalldata)), sub(0, 0x20))
            pop(
                call(
                    gas(), address(), 0, add(0x20, toFooCalldata), mload(toFooCalldata), 0x00, 0x00
                )
            )
            // Try with a slightly positive but wrong `nestedBytes` offset.
            // This reverts, because `nestedBytes` will be outside the range `[0, calldatasize()]`.
            mstore(add(0x44, add(0x20, toFooCalldata)), add(o, 1))
            pop(
                call(
                    gas(), address(), 0, add(0x20, toFooCalldata), mload(toFooCalldata), 0x00, 0x00
                )
            )

            // Just to make sure the call to `fooMemory` works.
            pop(call(gas(), address(), 0, add(0x20, toFooMemory), mload(toFooMemory), 0x00, 0x00))
            // Try with a negative `nestedBytes` offset. This reverts.
            mstore(add(0x44, add(0x20, toFooMemory)), sub(0, 0x20))
            pop(call(gas(), address(), 0, add(0x20, toFooMemory), mload(toFooMemory), 0x00, 0x00))
        }
    }

    function fooCalldata(S calldata s) external {
        emit LogUint(s.nestedUint);
        emit LogBytes(s.nestedBytes);
    }

    function fooMemory(S memory s) external {
        emit LogUint(s.nestedUint);
        emit LogBytes(s.nestedBytes);
    }
}
