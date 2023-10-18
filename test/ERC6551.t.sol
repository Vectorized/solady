// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {SignatureCheckerLib} from "../src/accounts/ERC6551.sol";
import {ERC6551, MockERC6551} from "./utils/mocks/MockERC6551.sol";
import {MockERC721} from "./utils/mocks/MockERC721.sol";
import {MockERC1155} from "./utils/mocks/MockERC1155.sol";
import {MockERC1271Wallet} from "./utils/mocks/MockERC1271Wallet.sol";
import {LibClone} from "../src/utils/LibClone.sol";
import {LibString} from "../src/utils/LibString.sol";
import {LibZip} from "../src/utils/LibZip.sol";

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
}

contract ERC6551Test is SoladyTest {
    address erc6551;

    MockERC6551 account;

    function setUp() public {
        erc6551 = address(new MockERC6551());
        account = MockERC6551(payable(LibClone.deployERC1967(erc6551)));
    }
}
