// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {Ownable, ECDSA} from "../src/accounts/ERC4337.sol";
import {ERC4337, MockERC4337} from "./utils/mocks/MockERC4337.sol";
import {MockEntryPoint} from "./utils/mocks/MockEntryPoint.sol";
import {MockERC721} from "./utils/mocks/MockERC721.sol";
import {MockERC1155} from "./utils/mocks/MockERC1155.sol";
import {LibClone} from "../src/utils/LibClone.sol";

contract Target {
    error TargetError(bytes data);

    bytes32 public datahash;

    bytes public data;

    function setData(bytes memory data_) public payable {
        data = data_;
        datahash = keccak256(data_);
    }

    function revertWithTargetError(bytes memory data_) public payable {
        revert TargetError(data_);
    }
}

contract ERC4337Test is SoladyTest {
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    ERC4337 account;

    function setUp() public {
        account = ERC4337(new MockERC4337());
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
        account.execute(target, 123, abi.encodeWithSignature("setData(bytes)", data));
        assertEq(Target(target).datahash(), keccak256(data));
        assertEq(target.balance, 123);

        vm.prank(_randomNonZeroAddress());
        vm.expectRevert(Ownable.Unauthorized.selector);
        account.execute(target, 123, abi.encodeWithSignature("setData(bytes)", data));

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
        data[0] = abi.encodeWithSignature("setData(bytes)", _randomBytes(111));
        data[1] = abi.encodeWithSignature("setData(bytes)", _randomBytes(222));

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

    function testExecuteBatch(uint256 r) public {
        vm.deal(address(account), 1 ether);
        account.initialize(address(this));

        unchecked {
            uint256 n = r & 3;
            address[] memory targets = new address[](n);
            uint256[] memory values = new uint256[](n);
            bytes[] memory data = new bytes[](n);

            for (uint256 i; i != n; ++i) {
                uint256 v = _random() & 0xff;
                targets[i] = address(new Target());
                values[i] = v;
                data[i] = abi.encodeWithSignature("setData(bytes)", _randomBytes(v));
            }

            account.executeBatch(targets, values, data);

            for (uint256 i; i != n; ++i) {
                uint256 v = values[i];
                assertEq(Target(targets[i]).datahash(), keccak256(_randomBytes(v)));
                assertEq(targets[i].balance, v);
            }
        }
    }

    function testExecuteBatchWithZeroValues() public {
        vm.deal(address(account), 1 ether);
        account.initialize(address(this));

        address[] memory targets = new address[](2);
        targets[0] = address(new Target());
        targets[1] = address(new Target());

        uint256[] memory values;

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSignature("setData(bytes)", _randomBytes(111));
        data[1] = abi.encodeWithSignature("setData(bytes)", _randomBytes(222));

        account.executeBatch(targets, values, data);
        assertEq(Target(targets[0]).datahash(), keccak256(_randomBytes(111)));
        assertEq(Target(targets[1]).datahash(), keccak256(_randomBytes(222)));
        assertEq(targets[0].balance, 0);
        assertEq(targets[1].balance, 0);
    }

    function testDelegateExecute() public {
        vm.deal(address(account), 1 ether);
        account.initialize(address(this));

        address delegate = address(new Target());

        bytes memory data;
        data = account.delegateExecute(delegate, abi.encodeWithSignature("datahash()"));
        assertEq(abi.decode(data, (bytes32)), bytes32(0));
        assertEq(vm.load(address(account), bytes32(0)), bytes32(0));
        data = abi.encodeWithSignature("setData(bytes)", _randomBytes(111));
        data = account.delegateExecute(delegate, data);
        assertEq(data, "");
        data = account.delegateExecute(delegate, abi.encodeWithSignature("datahash()"));
        assertEq(abi.decode(data, (bytes32)), keccak256(_randomBytes(111)));
        assertEq(vm.load(address(account), bytes32(0)), keccak256(_randomBytes(111)));
        data = account.delegateExecute(delegate, abi.encodeWithSignature("data()"));
        assertEq(abi.decode(data, (bytes)), _randomBytes(111));
    }

    function testDelegateExecute(uint256 r) public {
        vm.deal(address(account), 1 ether);
        account.initialize(address(this));

        address delegate = address(new Target());

        bytes memory data;
        data = abi.encodeWithSignature("setData(bytes)", _randomBytes(r));
        data = account.delegateExecute(delegate, data);
        assertEq(data, "");

        data = account.delegateExecute(delegate, abi.encodeWithSignature("datahash()"));
        assertEq(abi.decode(data, (bytes32)), keccak256(_randomBytes(r)));
        data = account.delegateExecute(delegate, abi.encodeWithSignature("data()"));
        assertEq(abi.decode(data, (bytes)), _randomBytes(r));
    }

    function testDepositFunctions() public {
        vm.deal(address(account), 1 ether);
        account.initialize(address(this));

        vm.etch(account.entryPoint(), address(new MockEntryPoint()).code);
        assertEq(account.getDeposit(), 0);
        account.addDeposit{value: 123}();
        assertEq(account.getDeposit(), 123);
        address to = _randomNonZeroAddress();
        assertEq(to.balance, 0);
        account.withdrawDepositTo(to, 12);
        assertEq(to.balance, 12);
        assertEq(account.getDeposit(), 123 - 12);
    }

    struct _TestTemps {
        bytes32 userOpHash;
        address signer;
        uint256 privateKey;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 missingAccountFunds;
    }

    function testValidateUserOp() public {
        _TestTemps memory t;
        t.userOpHash = keccak256("123");
        (t.signer, t.privateKey) = _randomSigner();
        (t.v, t.r, t.s) = vm.sign(t.privateKey, ECDSA.toEthSignedMessageHash(t.userOpHash));
        t.missingAccountFunds = 456;
        vm.deal(address(account), 1 ether);
        assertEq(address(account).balance, 1 ether);

        account.initialize(t.signer);

        vm.etch(account.entryPoint(), address(new MockEntryPoint()).code);
        MockEntryPoint ep = MockEntryPoint(payable(account.entryPoint()));

        ERC4337.UserOperation memory userOp;
        // Success returns 0.
        userOp.signature = abi.encodePacked(t.r, t.s, t.v);
        assertEq(
            ep.validateUserOp(address(account), userOp, t.userOpHash, t.missingAccountFunds), 0
        );
        assertEq(address(ep).balance, t.missingAccountFunds);
        // Failure returns 1.
        userOp.signature = abi.encodePacked(t.r, bytes32(uint256(t.s) ^ 1), t.v);
        assertEq(
            ep.validateUserOp(address(account), userOp, t.userOpHash, t.missingAccountFunds), 1
        );
        assertEq(address(ep).balance, t.missingAccountFunds * 2);
        // Not entry point reverts.
        vm.expectRevert(Ownable.Unauthorized.selector);
        account.validateUserOp(userOp, t.userOpHash, t.missingAccountFunds);
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
            let r := keccak256(0x00, 0x20)
            let n := add(0x0f, and(r, 0x7f))
            mstore(result, n)
            codecopy(add(result, 0x20), byte(1, r), add(n, 0x40))
            mstore(0x40, add(add(result, 0x40), n))
        }
    }
}
