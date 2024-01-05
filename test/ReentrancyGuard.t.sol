// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {ReentrancyGuard} from "../src/utils/ReentrancyGuard.sol";

contract ReentrancyGuardTest is SoladyTest, ReentrancyGuard {
    uint256 enterTimes;

    function testUnprotectedCall() public {
        this.unprotectedCall(0);
        assertEq(enterTimes, (1 + 0));
        this.unprotectedCall(2);
        assertEq(enterTimes, (1 + 0) + (1 + 2));
    }

    function testProtectedCall() public {
        this.protectedCall(0);
        assertEq(enterTimes, 1);
    }

    function testProtectedCallRevertsOnReentrancy() public {
        vm.expectRevert();
        this.protectedCall(1);
    }

    function unprotectedCall(uint256 recurse) public {
        unchecked {
            enterTimes++;
            if (recurse == 0) return;
            this.unprotectedCall(recurse - 1);
        }
    }

    function protectedCall(uint256 recurse) public nonReentrant {
        unchecked {
            enterTimes++;
            if (recurse == 0) return;
            this.protectedCall(recurse - 1);
        }
    }
}
