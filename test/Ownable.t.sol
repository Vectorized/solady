// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/TestPlus.sol";
import "./utils/mocks/MockOwnable.sol";

contract OwnableTest is TestPlus {
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    event OwnershipHandoverRequested(address indexed pendingOwner);

    event OwnershipHandoverCanceled(address indexed pendingOwner);

    MockOwnable mockOwnable;

    function setUp() public {
        mockOwnable = new MockOwnable();
    }
}