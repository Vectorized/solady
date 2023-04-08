// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/TestPlus.sol";

import {ERC1155, MockERC1155} from "./utils/mocks/MockERC1155.sol";

contract ERC1155Test is TestPlus {
    MockERC1155 token;

    function setUp() public {
        token = new MockERC1155();
    }

    function testSetAndGetIsApprovedForAll() public {
        address owner = address(0xa11ce);
        address operator = address(0xb0b);
        vm.prank(owner);
        token.setApprovalForAll(operator, true);
        assertEq(token.isApprovedForAll(owner, operator), true);
    }
}
