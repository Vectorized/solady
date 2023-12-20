// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {Ownable, SignatureCheckerLib} from "../src/accounts/ERC4337.sol";
import {ERC4337, MockERC4337} from "./utils/mocks/MockERC4337.sol";
import {MockEntryPoint} from "./utils/mocks/MockEntryPoint.sol";
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

    function changeOwnerSlotValue(bool change) public payable {
        /// @solidity memory-safe-assembly
        assembly {
            if change { sstore(not(0x8b78c6d8), 0x112233) }
        }
    }
}

contract ERC4337Test is SoladyTest {
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    // By right, this should be the keccak256 of some long-ass string:
    // (e.g. `keccak256("Parent(bytes32 childHash,Mail child)Mail(Person from,Person to,string contents)Person(string name,address wallet)")`).
    // But I'm lazy and will use something randomish here.
    bytes32 internal constant _PARENT_TYPEHASH =
        0xd61db970ec8a2edc5f9fd31d876abe01b785909acb16dcd4baaf3b434b4c439b;

    // By right, this should be a proper domain separator, but I'm lazy.
    bytes32 internal constant _DOMAIN_SEP_B =
        0xa1a044077d7677adbbfa892ded5390979b33993e0e2a457e3f974bbcda53821b;

    address internal constant _ENTRY_POINT = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;

    address erc4337;

    MockERC4337 account;

    function setUp() public {
        // Etch something onto `_ENTRY_POINT` such that we can deploy the account implementation.
        vm.etch(_ENTRY_POINT, hex"00");
        erc4337 = address(new MockERC4337());
        account = MockERC4337(payable(LibClone.deployERC1967(erc4337)));
    }

    function testDisableInitializerForImplementation() public {
        MockERC4337 mock = new MockERC4337();
        assertEq(mock.owner(), address(0));
        vm.expectRevert(Ownable.AlreadyInitialized.selector);
        mock.initialize(address(this));
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

        account = MockERC4337(payable(LibClone.deployERC1967(erc4337)));
        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(address(0), address(0));
        account.initialize(address(0));
        assertEq(account.owner(), address(0));

        vm.expectRevert(Ownable.AlreadyInitialized.selector);
        account.initialize(address(this));
        assertEq(account.owner(), address(0));

        account = MockERC4337(payable(LibClone.deployERC1967(erc4337)));
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

        ERC4337.Call[] memory calls = new ERC4337.Call[](2);
        calls[0].target = address(new Target());
        calls[1].target = address(new Target());
        calls[0].value = 123;
        calls[1].value = 456;
        calls[0].data = abi.encodeWithSignature("setData(bytes)", _randomBytes(111));
        calls[1].data = abi.encodeWithSignature("setData(bytes)", _randomBytes(222));

        account.executeBatch(calls);
        assertEq(Target(calls[0].target).datahash(), keccak256(_randomBytes(111)));
        assertEq(Target(calls[1].target).datahash(), keccak256(_randomBytes(222)));
        assertEq(calls[0].target.balance, 123);
        assertEq(calls[1].target.balance, 456);

        calls[1].data = abi.encodeWithSignature("revertWithTargetError(bytes)", _randomBytes(111));
        vm.expectRevert(abi.encodeWithSignature("TargetError(bytes)", _randomBytes(111)));
        account.executeBatch(calls);
    }

    function testExecuteBatch(uint256 r) public {
        vm.deal(address(account), 1 ether);
        account.initialize(address(this));

        unchecked {
            uint256 n = r & 3;
            ERC4337.Call[] memory calls = new ERC4337.Call[](n);

            for (uint256 i; i != n; ++i) {
                uint256 v = _random() & 0xff;
                calls[i].target = address(new Target());
                calls[i].value = v;
                calls[i].data = abi.encodeWithSignature("setData(bytes)", _randomBytes(v));
            }

            bytes[] memory results;
            if (_random() & 1 == 0) {
                results = account.executeBatch(_random(), calls);
            } else {
                results = account.executeBatch(calls);
            }

            assertEq(results.length, n);
            for (uint256 i; i != n; ++i) {
                uint256 v = calls[i].value;
                assertEq(Target(calls[i].target).datahash(), keccak256(_randomBytes(v)));
                assertEq(calls[i].target.balance, v);
                assertEq(abi.decode(results[i], (bytes)), _randomBytes(v));
            }
        }
    }

    function testDelegateExecute() public {
        testDelegateExecute(123);
    }

    function testDelegateExecute(uint256 r) public {
        vm.deal(address(account), 1 ether);
        account.initialize(address(this));

        address delegate = address(new Target());

        bytes memory data;
        data = abi.encodeWithSignature("setData(bytes)", _randomBytes(r));
        data = account.delegateExecute(delegate, data);
        assertEq(abi.decode(data, (bytes)), _randomBytes(r));
        data = account.delegateExecute(delegate, abi.encodeWithSignature("datahash()"));
        assertEq(abi.decode(data, (bytes32)), keccak256(_randomBytes(r)));
        data = account.delegateExecute(delegate, abi.encodeWithSignature("data()"));
        assertEq(abi.decode(data, (bytes)), _randomBytes(r));
    }

    function testDelegateExecuteRevertsIfOwnerSlotValueChanged() public {
        account.initialize(address(this));

        address delegate = address(new Target());

        bytes memory data;
        data = abi.encodeWithSignature("changeOwnerSlotValue(bool)", false);
        account.delegateExecute(delegate, data);
        vm.expectRevert();
        data = abi.encodeWithSignature("changeOwnerSlotValue(bool)", true);
        account.delegateExecute(delegate, data);
        data = abi.encodeWithSignature("changeOwnerSlotValue(bool)", false);
        account.delegateExecute(delegate, data);
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

    function testCdFallback() public {
        vm.deal(address(account), 1 ether);
        account.initialize(address(this));

        vm.etch(account.entryPoint(), address(new MockEntryPoint()).code);
        assertEq(account.getDeposit(), 0);

        bytes memory data = LibZip.cdCompress(abi.encodeWithSignature("addDeposit()"));
        (bool success,) = address(account).call{value: 123}(data);
        assertTrue(success);
        assertEq(account.getDeposit(), 123);
    }

    function testCdFallback2() public {
        vm.deal(address(account), 1 ether);
        account.initialize(address(this));

        vm.etch(account.entryPoint(), address(new MockEntryPoint()).code);
        assertEq(account.getDeposit(), 0);

        ERC4337.Call[] memory calls = new ERC4337.Call[](2);
        calls[0].target = address(new Target());
        calls[1].target = address(new Target());
        calls[0].value = 123;
        calls[1].value = 456;
        calls[0].data = abi.encodeWithSignature("setData(bytes)", _randomBytes(111));
        calls[1].data = abi.encodeWithSignature("setData(bytes)", _randomBytes(222));

        bytes memory data = LibZip.cdCompress(
            abi.encodeWithSignature("executeBatch((address,uint256,bytes)[])", calls)
        );
        (bool success,) = address(account).call(data);
        assertTrue(success);
        assertEq(Target(calls[0].target).datahash(), keccak256(_randomBytes(111)));
        assertEq(Target(calls[1].target).datahash(), keccak256(_randomBytes(222)));
        assertEq(calls[0].target.balance, 123);
        assertEq(calls[1].target.balance, 456);
    }

    struct _TestTemps {
        bytes32 userOpHash;
        bytes32 hash;
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
        (t.v, t.r, t.s) =
            vm.sign(t.privateKey, SignatureCheckerLib.toEthSignedMessageHash(t.userOpHash));
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

    function testIsValidSignature() public {
        _TestTemps memory t;
        t.hash = keccak256("123");
        (t.signer, t.privateKey) = _randomSigner();
        (t.v, t.r, t.s) = vm.sign(t.privateKey, _toERC1271Hash(t.hash));

        account.initialize(t.signer);

        bytes memory signature =
            abi.encodePacked(t.r, t.s, t.v, _PARENT_TYPEHASH, _DOMAIN_SEP_B, t.hash);
        assertEq(account.isValidSignature(_toChildHash(t.hash), signature), bytes4(0x1626ba7e));

        unchecked {
            uint256 vs = uint256(t.s) | uint256(t.v - 27) << 255;
            signature = abi.encodePacked(t.r, vs, _PARENT_TYPEHASH, _DOMAIN_SEP_B, t.hash);
            assertEq(account.isValidSignature(_toChildHash(t.hash), signature), bytes4(0x1626ba7e));
        }

        signature =
            abi.encodePacked(t.r, t.s, t.v, uint256(_PARENT_TYPEHASH) ^ 1, _DOMAIN_SEP_B, t.hash);
        assertEq(account.isValidSignature(_toChildHash(t.hash), signature), bytes4(0xffffffff));

        signature =
            abi.encodePacked(t.r, t.s, t.v, _PARENT_TYPEHASH, uint256(_DOMAIN_SEP_B) ^ 1, t.hash);
        assertEq(account.isValidSignature(_toChildHash(t.hash), signature), bytes4(0xffffffff));

        signature =
            abi.encodePacked(t.r, t.s, t.v, _PARENT_TYPEHASH, _DOMAIN_SEP_B, uint256(t.hash) ^ 1);
        assertEq(account.isValidSignature(_toChildHash(t.hash), signature), bytes4(0xffffffff));

        signature = abi.encodePacked(t.r, t.s, t.v, _PARENT_TYPEHASH);
        assertEq(account.isValidSignature(t.hash, signature), bytes4(0xffffffff));

        signature = abi.encodePacked(t.r, t.s, _PARENT_TYPEHASH);
        assertEq(account.isValidSignature(t.hash, signature), bytes4(0xffffffff));

        signature = abi.encodePacked(t.r, _PARENT_TYPEHASH);
        assertEq(account.isValidSignature(t.hash, signature), bytes4(0xffffffff));

        signature = "";
        assertEq(account.isValidSignature(t.hash, signature), bytes4(0xffffffff));
    }

    function testIsValidSignaturePersonalSign() public {
        _TestTemps memory t;
        t.hash = keccak256("123");
        (t.signer, t.privateKey) = _randomSigner();
        (t.v, t.r, t.s) = vm.sign(t.privateKey, _toERC1271HashPersonalSign(t.hash));

        account.initialize(t.signer);

        bytes memory signature = abi.encodePacked(t.r, t.s, t.v, _PARENT_TYPEHASH);
        assertEq(account.isValidSignature(t.hash, signature), bytes4(0x1626ba7e));

        unchecked {
            uint256 vs = uint256(t.s) | uint256(t.v - 27) << 255;
            signature = abi.encodePacked(t.r, vs, _PARENT_TYPEHASH);
            assertEq(account.isValidSignature(t.hash, signature), bytes4(0x1626ba7e));
        }

        signature = abi.encodePacked(t.r, t.s, _PARENT_TYPEHASH, _DOMAIN_SEP_B, t.hash);
        assertEq(account.isValidSignature(t.hash, signature), bytes4(0xffffffff));

        signature = abi.encodePacked(t.r, t.s, _PARENT_TYPEHASH, _DOMAIN_SEP_B);
        assertEq(account.isValidSignature(t.hash, signature), bytes4(0xffffffff));

        signature = abi.encodePacked(t.r, t.s, _PARENT_TYPEHASH);
        assertEq(account.isValidSignature(t.hash, signature), bytes4(0xffffffff));

        signature = abi.encodePacked(t.r, _PARENT_TYPEHASH);
        assertEq(account.isValidSignature(t.hash, signature), bytes4(0xffffffff));

        signature = "";
        assertEq(account.isValidSignature(t.hash, signature), bytes4(0xffffffff));
    }

    function testIsValidSignatureWrapped() public {
        _TestTemps memory t;
        t.hash = keccak256("123");
        (t.signer, t.privateKey) = _randomSigner();
        (t.v, t.r, t.s) = vm.sign(t.privateKey, _toERC1271Hash(t.hash));

        MockERC1271Wallet wrappedSigner = new MockERC1271Wallet(t.signer);
        account.initialize(address(wrappedSigner));

        bytes memory signature =
            abi.encodePacked(t.r, t.s, t.v, _PARENT_TYPEHASH, _DOMAIN_SEP_B, t.hash);
        assertEq(account.isValidSignature(_toChildHash(t.hash), signature), bytes4(0x1626ba7e));
    }

    function _toERC1271Hash(bytes32 child) internal view returns (bytes32) {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256("Milady"),
                keccak256("1"),
                block.chainid,
                address(account)
            )
        );
        bytes32 parentStructHash =
            keccak256(abi.encode(_PARENT_TYPEHASH, _toChildHash(child), child));
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, parentStructHash));
    }

    function _toChildHash(bytes32 child) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(hex"1901", _DOMAIN_SEP_B, child));
    }

    function _toERC1271HashPersonalSign(bytes32 childHash) internal view returns (bytes32) {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256("Milady"),
                keccak256("1"),
                block.chainid,
                address(account)
            )
        );
        bytes32 parentStructHash = keccak256(abi.encode(_PARENT_TYPEHASH, childHash));
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, parentStructHash));
    }

    function testETHReceived() public {
        (bool success,) = address(account).call{value: 1 ether}("");
        assertTrue(success);
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

    function testDirectStorage() public {
        bytes32 storageSlot = bytes32(uint256(123));
        bytes32 storageValue = bytes32(uint256(456));

        vm.expectRevert(Ownable.Unauthorized.selector);
        account.storageStore(storageSlot, storageValue);

        account.initialize(address(this));
        assertEq(account.storageLoad(storageSlot), bytes32(0));
        account.storageStore(storageSlot, storageValue);
        assertEq(account.storageLoad(storageSlot), storageValue);
    }

    function testOwnerRecovery() public {
        ERC4337.UserOperation memory userOp;

        userOp.sender = address(account);
        userOp.nonce = 4337;

        // `bob` is set as recovery.
        address bob = address(0xb);
        userOp.callData = abi.encodeWithSelector(
            ERC4337.execute.selector,
            address(account),
            0,
            abi.encodeWithSelector(Ownable.completeOwnershipHandover.selector, bob)
        );

        // `bob` must accept recovery.
        // IRL this would follow need.
        vm.prank(bob);
        account.requestOwnershipHandover();

        _TestTemps memory t;
        t.userOpHash = keccak256(abi.encode(userOp));
        (t.signer, t.privateKey) = _randomSigner();
        (t.v, t.r, t.s) =
            vm.sign(t.privateKey, SignatureCheckerLib.toEthSignedMessageHash(t.userOpHash));

        t.missingAccountFunds = 456;
        vm.deal(address(account), 1 ether);

        account.initialize(t.signer);
        assertEq(account.owner(), t.signer);

        vm.etch(account.entryPoint(), address(new MockEntryPoint()).code);
        MockEntryPoint ep = MockEntryPoint(payable(account.entryPoint()));

        // Success returns 0.
        userOp.signature = abi.encodePacked(t.r, t.s, t.v);
        assertEq(
            ep.validateUserOp(address(account), userOp, t.userOpHash, t.missingAccountFunds), 0
        );
        // Check recovery to `bob`.
        vm.prank(address(ep));
        (bool success,) = address(account).call(userOp.callData);
        assertTrue(success);
        assertEq(account.owner(), bob);
    }

    function _randomBytes(uint256 seed) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, seed)
            let r := keccak256(0x00, 0x20)
            if lt(byte(2, r), 0x20) {
                result := mload(0x40)
                let n := and(r, 0x7f)
                mstore(result, n)
                codecopy(add(result, 0x20), byte(1, r), add(n, 0x40))
                mstore(0x40, add(add(result, 0x40), n))
            }
        }
    }
}
