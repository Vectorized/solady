// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {Ownable, UUPSUpgradeable, LibZip, ECDSA, ERC4337} from "../src/accounts/ERC4337.sol";
import {MockERC721} from "./utils/mocks/MockERC721.sol";
import {MockERC1155} from "./utils/mocks/MockERC1155.sol";
import {LibClone} from "../src/utils/LibClone.sol";

contract Target {
    error TargetError(bytes data);

    bytes32 public datahash;

    function setDataHash(bytes memory data) public payable {
        datahash = keccak256(data);
    }

    function revertWithTargetError(bytes memory data) public payable {
        revert TargetError(data);
    }
}

contract ERC4337Test is SoladyTest {
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    ERC4337 account;

    function setUp() public {
        account = new ERC4337();
    }

    function testInitializer() public {
        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(address(0), address(this));
        account.initialize(address(this));
        assertEq(account.owner(), address(this));
        vm.expectRevert(Ownable.AlreadyInitialized.selector);
        account.initialize(address(this));

        address newOwner = _randomNonZeroAddress();
        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(address(this), newOwner);
        account.transferOwnership(newOwner);
        assertEq(account.owner(), newOwner);

        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(newOwner, address(this));
        vm.prank(newOwner);
        account.transferOwnership(address(this));

        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(address(this), address(0));
        account.renounceOwnership();
        assertEq(account.owner(), address(0));

        vm.expectRevert(Ownable.AlreadyInitialized.selector);
        account.initialize(address(this));
        assertEq(account.owner(), address(0));

        account = new ERC4337();
        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(address(0), address(0));
        account.initialize(address(0));
        assertEq(account.owner(), address(0));

        vm.expectRevert(Ownable.AlreadyInitialized.selector);
        account.initialize(address(this));
        assertEq(account.owner(), address(0));

        account = new ERC4337();
        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(address(0), address(1));
        account.initialize(address(1));
        assertEq(account.owner(), address(1));

        vm.expectRevert(Ownable.AlreadyInitialized.selector);
        account.initialize(address(this));
        assertEq(account.owner(), address(1));
    }

    function testExecute() public {
        vm.deal(address(account), 1 ether);
        account.initialize(address(this));

        address target = address(new Target());
        bytes memory data = _randomBytes(111);
        account.execute(target, 123, abi.encodeWithSignature("setDataHash(bytes)", data));
        assertEq(Target(target).datahash(), keccak256(data));
        assertEq(target.balance, 123);

        vm.prank(_randomNonZeroAddress());
        vm.expectRevert(Ownable.Unauthorized.selector);
        account.execute(target, 123, abi.encodeWithSignature("setDataHash(bytes)", data));

        vm.expectRevert(abi.encodeWithSignature("TargetError(bytes)", data));
        account.execute(target, 123, abi.encodeWithSignature("revertWithTargetError(bytes)", data));
    }

    function testExecuteBatch() public {
        vm.deal(address(account), 1 ether);
        account.initialize(address(this));

        address[] memory targets = new address[](2);
        targets[0] = address(new Target());
        targets[1] = address(new Target());

        uint256[] memory values = new uint256[](2);
        values[0] = 123;
        values[1] = 456;

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSignature("setDataHash(bytes)", _randomBytes(111));
        data[1] = abi.encodeWithSignature("setDataHash(bytes)", _randomBytes(222));

        account.executeBatch(targets, values, data);
        assertEq(Target(targets[0]).datahash(), keccak256(_randomBytes(111)));
        assertEq(Target(targets[1]).datahash(), keccak256(_randomBytes(222)));
        assertEq(targets[0].balance, 123);
        assertEq(targets[1].balance, 456);

        vm.expectRevert(ERC4337.ArrayLengthsMismatch.selector);
        account.executeBatch(targets, new uint256[](1), data);

        vm.expectRevert(ERC4337.ArrayLengthsMismatch.selector);
        account.executeBatch(targets, values, new bytes[](3));

        account.executeBatch(new address[](0), new uint256[](0), new bytes[](0));
        account.executeBatch(new address[](1), new uint256[](1), new bytes[](1));

        data[1] = abi.encodeWithSignature("revertWithTargetError(bytes)", _randomBytes(111));
        vm.expectRevert(abi.encodeWithSignature("TargetError(bytes)", _randomBytes(111)));
        account.executeBatch(targets, values, data);
    }

    function testExecuteBatchWithZeroValues() public {
        vm.deal(address(account), 1 ether);
        account.initialize(address(this));

        address[] memory targets = new address[](2);
        targets[0] = address(new Target());
        targets[1] = address(new Target());

        uint256[] memory values;

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSignature("setDataHash(bytes)", _randomBytes(111));
        data[1] = abi.encodeWithSignature("setDataHash(bytes)", _randomBytes(222));

        account.executeBatch(targets, values, data);
        assertEq(Target(targets[0]).datahash(), keccak256(_randomBytes(111)));
        assertEq(Target(targets[1]).datahash(), keccak256(_randomBytes(222)));
        assertEq(targets[0].balance, 0);
        assertEq(targets[1].balance, 0);
    }

    function testETHReceived() public {
        payable(address(account)).transfer(1 ether);
    }

    function testOnERC721Received() public {
        address alice = _randomNonZeroAddress();
        MockERC721 erc721 = new MockERC721();
        erc721.mint(alice, 1);
        vm.prank(alice);
        erc721.safeTransferFrom(alice, address(account), 1);
    }

    function testOnERC1155Received() public {
        address alice = _randomNonZeroAddress();
        MockERC1155 erc1155 = new MockERC1155();
        erc1155.mint(alice, 1, 1, "");
        vm.prank(alice);
        erc1155.safeTransferFrom(alice, address(account), 1, 1, "");
    }

    function testOnERC1155BatchReceived() public {
        address alice = _randomNonZeroAddress();
        MockERC1155 erc1155 = new MockERC1155();
        erc1155.mint(alice, 1, 1, "");
        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;
        uint256[] memory amts = new uint256[](1);
        amts[0] = 1;
        vm.prank(alice);
        erc1155.safeBatchTransferFrom(alice, address(account), ids, amts, "");
    }

    function _randomBytes(uint256 seed) internal pure returns (bytes memory result) {
        assembly {
            result := mload(0x40)
            mstore(0x00, seed)
            let n := add(0x0f, and(keccak256(0x00, 0x20), 0xff))
            mstore(result, n)
            for { let i := 0 } lt(i, n) { i := add(i, 0x20) } {
                mstore(0x20, i)
                mstore(add(i, add(result, 0x20)), keccak256(0x00, 0x40))
            }
            mstore(0x40, add(add(result, 0x40), n))
        }
    }
}
