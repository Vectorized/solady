// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./../../utils/SoladyTest.sol";

import {LibAGW} from "../../../src/utils/ext/zksync/LibAGW.sol";

contract IsAGW {
    function agwMessageTypeHash() public pure returns (bytes32) {
        return 0x1c334118468bfd2aaf55a01d63456d9c538a41e57aac74ff33bf6975696323f3;
    }
}

contract LibAGWTest is SoladyTest {
    function testMaybeAGW() public {
        assertFalse(LibAGW.maybeAGW(address(this)));
        assertTrue(LibAGW.maybeAGW(address(new IsAGW())));
    }
}
