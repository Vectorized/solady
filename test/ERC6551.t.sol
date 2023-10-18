// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {SignatureCheckerLib} from "../src/accounts/ERC6551.sol";
import {ERC6551, MockERC6551} from "./utils/mocks/MockERC6551.sol";
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
}

contract ERC6551Test is SoladyTest {
    address erc6551;

    MockERC6551 account;

    MockERC721 token;

    address payable internal constant _ENTRY_POINT =
        payable(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789);

    function setUp() public {
        erc6551 = address(new MockERC6551());
        account = MockERC6551(payable(LibClone.deployERC1967(erc6551)));
        token = new MockERC721();
    }

    function testInitializer() public {
        token.mint(address(this), 1);

        account.initialize(block.chainid, address(token), 1);
        assertEq(account.owner(), address(this));

        (uint256 chainId, address tokenContract, uint256 tokenId) = account.token();
        assertEq(chainId, block.chainid);
        assertEq(tokenContract, address(token));
        assertEq(tokenId, 1);
    }

    function testIsValidSigner() public {
        token.mint(address(this), 1);
        account.initialize(block.chainid, address(token), 1);
        assert(account.isValidSigner(address(this), "") == 0x523e3260);
    }

    function testExecute() public {
        vm.deal(address(account), 1 ether);
        token.mint(address(this), 1);
        account.initialize(block.chainid, address(token), 1);

        address target = address(new Target());
        bytes memory data = _randomBytes(111);

        assertEq(account.state(), 0);

        account.execute(target, 123, abi.encodeWithSignature("setData(bytes)", data));
        assertEq(Target(target).datahash(), keccak256(data));
        assertEq(target.balance, 123);

        vm.prank(_randomNonZeroAddress());
        vm.expectRevert(ERC6551.Unauthorized.selector);
        account.execute(target, 123, abi.encodeWithSignature("setData(bytes)", data));

        vm.expectRevert(abi.encodeWithSignature("TargetError(bytes)", data));
        account.execute(target, 123, abi.encodeWithSignature("revertWithTargetError(bytes)", data));

        assertEq(account.state(), 1);
    }

    function testExecuteBatch() public {
        vm.deal(address(account), 1 ether);
        token.mint(address(this), 1);
        account.initialize(block.chainid, address(token), 1);

        ERC6551.Call[] memory calls = new ERC6551.Call[](2);
        calls[0].target = address(new Target());
        calls[1].target = address(new Target());
        calls[0].value = 123;
        calls[1].value = 456;
        calls[0].data = abi.encodeWithSignature("setData(bytes)", _randomBytes(111));
        calls[1].data = abi.encodeWithSignature("setData(bytes)", _randomBytes(222));

        assertEq(account.state(), 0);

        account.executeBatch(calls);
        assertEq(Target(calls[0].target).datahash(), keccak256(_randomBytes(111)));
        assertEq(Target(calls[1].target).datahash(), keccak256(_randomBytes(222)));
        assertEq(calls[0].target.balance, 123);
        assertEq(calls[1].target.balance, 456);

        calls[1].data = abi.encodeWithSignature("revertWithTargetError(bytes)", _randomBytes(111));
        vm.expectRevert(abi.encodeWithSignature("TargetError(bytes)", _randomBytes(111)));
        account.executeBatch(calls);

        assertEq(account.state(), 1);
    }

    function testExecuteBatch(uint256 r) public {
        vm.deal(address(account), 1 ether);
        token.mint(address(this), 1);
        account.initialize(block.chainid, address(token), 1);

        assertEq(account.state(), 0);

        unchecked {
            uint256 n = r & 3;
            ERC6551.Call[] memory calls = new ERC6551.Call[](n);

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

        assertEq(account.state(), 1);
    }

    function testCdFallback() public {
        vm.deal(address(account), 1 ether);
        token.mint(address(this), 1);
        account.initialize(block.chainid, address(token), 1);

        vm.etch(_ENTRY_POINT, address(new MockEntryPoint()).code);
        assertEq(MockEntryPoint(_ENTRY_POINT).balanceOf(address(account)), 0);

        bytes memory data = LibZip.cdCompress(
            abi.encodeWithSignature("execute(address,uint256,bytes)", _ENTRY_POINT, 123, "")
        );
        (bool success,) = address(account).call{value: 123}(data);
        assertTrue(success);
        assertEq(MockEntryPoint(_ENTRY_POINT).balanceOf(address(account)), 123);

        ERC6551.Call[] memory calls = new ERC6551.Call[](2);
        calls[0].target = address(new Target());
        calls[1].target = address(new Target());
        calls[0].value = 123;
        calls[1].value = 456;
        calls[0].data = abi.encodeWithSignature("setData(bytes)", _randomBytes(111));
        calls[1].data = abi.encodeWithSignature("setData(bytes)", _randomBytes(222));

        data = LibZip.cdCompress(
            abi.encodeWithSignature("executeBatch((address,uint256,bytes)[])", calls)
        );
        (success,) = address(account).call(data);
        assertTrue(success);
        assertEq(Target(calls[0].target).datahash(), keccak256(_randomBytes(111)));
        assertEq(Target(calls[1].target).datahash(), keccak256(_randomBytes(222)));
        assertEq(calls[0].target.balance, 123);
        assertEq(calls[1].target.balance, 456);
    }

    struct _TestTemps {
        bytes32 hash;
        address signer;
        uint256 privateKey;
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes signature;
    }

    function testIsValidSignature() public {
        _TestTemps memory t;
        t.hash = keccak256("123");
        (t.signer, t.privateKey) = _randomSigner();
        (t.v, t.r, t.s) = vm.sign(t.privateKey, SignatureCheckerLib.toEthSignedMessageHash(t.hash));

        token.mint(t.signer, 1);
        account.initialize(block.chainid, address(token), 1);

        // Success returns `0x1626ba7e`.
        t.signature = abi.encodePacked(t.r, t.s, t.v);
        assert(account.isValidSignature(t.hash, t.signature) == 0x1626ba7e);
    }

    function testIsValidSignatureWrapped() public {
        _TestTemps memory t;
        t.hash = keccak256("123");
        (t.signer, t.privateKey) = _randomSigner();
        (t.v, t.r, t.s) = vm.sign(t.privateKey, SignatureCheckerLib.toEthSignedMessageHash(t.hash));

        MockERC1271Wallet wrappedSigner = new MockERC1271Wallet(t.signer);
        token.mint(address(wrappedSigner), 1);
        account.initialize(block.chainid, address(token), 1);

        // Success returns `0x1626ba7e`.
        t.signature = abi.encodePacked(t.r, t.s, t.v);
        assert(account.isValidSignature(t.hash, t.signature) == 0x1626ba7e);
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
