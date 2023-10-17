// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {Receiver} from "../src/accounts/Receiver.sol";
import {MockERC721} from "./utils/mocks/MockERC721.sol";
import {MockERC1155} from "./utils/mocks/MockERC1155.sol";
import {MockReceiver} from "./utils/mocks/MockReceiver.sol";

contract ReceiverTest is SoladyTest {
    MockERC721 immutable erc721 = new MockERC721();
    MockERC1155 immutable erc1155 = new MockERC1155();
    MockReceiver immutable receiver = new MockReceiver();
    address immutable alice = address(bytes20("milady"));

    function setUp() public {}

    function testETHReceived() public {
        payable(address(receiver)).transfer(1 ether);
    }

    function testOnERC721Received() public {
        erc721.mint(alice, 1);
        vm.prank(alice);
        erc721.safeTransferFrom(alice, address(receiver), 1);
    }

    function testOnERC1155Received() public {
        erc1155.mint(alice, 1, 1, "");
        vm.prank(alice);
        erc1155.safeTransferFrom(alice, address(receiver), 1, 1, "");
    }

    function testOnERC1155BatchReceived() public {
        erc1155.mint(alice, 1, 1, "");
        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;
        uint256[] memory amts = new uint256[](1);
        amts[0] = 1;
        vm.prank(alice);
        erc1155.safeBatchTransferFrom(alice, address(receiver), ids, amts, "");
    }
}
