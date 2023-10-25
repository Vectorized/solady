// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {SignatureCheckerLib} from "../src/utils/SignatureCheckerLib.sol";
import {ERC6551Proxy} from "../src/accounts/ERC6551Proxy.sol";
import {ERC6551, MockERC6551, MockERC6551V2} from "./utils/mocks/MockERC6551.sol";
import {MockERC6551Registry} from "./utils/mocks/MockERC6551Registry.sol";
import {MockERC721} from "./utils/mocks/MockERC721.sol";
import {MockERC1155} from "./utils/mocks/MockERC1155.sol";
import {LibZip} from "../src/utils/LibZip.sol";
import {LibClone} from "../src/utils/LibClone.sol";
import {LibString} from "../src/utils/LibString.sol";

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
    MockERC6551Registry internal _registry;

    address internal _erc6551;

    address internal _erc721;

    address internal _proxy;

    bytes32 internal constant _ERC1967_IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    struct _TestTemps {
        address owner;
        uint256 chainId;
        uint256 tokenId;
        bytes32 salt;
        MockERC6551 account;
        address signer;
        uint256 privateKey;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function setUp() public {
        _registry = new MockERC6551Registry();
        _erc6551 = address(new MockERC6551());
        _erc721 = address(new MockERC721());
        _proxy = address(new ERC6551Proxy(_erc6551));
    }

    function _testTempsMint(address owner) internal returns (uint256 tokenId) {
        while (true) {
            tokenId = _random() % 8 == 0 ? _random() % 32 : _random();
            (bool success,) =
                _erc721.call(abi.encodeWithSignature("mint(address,uint256)", owner, tokenId));
            if (success) return tokenId;
        }
    }

    function _testTemps() internal returns (_TestTemps memory t) {
        t.owner = _randomNonZeroAddress();
        t.tokenId = _testTempsMint(t.owner);
        t.chainId = block.chainid;
        t.salt = bytes32(_random());
        address account = _registry.createAccount(_proxy, t.salt, t.chainId, _erc721, t.tokenId);
        t.account = MockERC6551(payable(account));
    }

    function testDeployERC6551Proxy() public {
        console.log(LibString.toHexString(address(new ERC6551Proxy(_erc6551)).code));
    }

    function testInitializeERC6551ProxyImplementation() public {
        address account = address(_testTemps().account);
        (bool success,) = account.call("");
        assertTrue(success);
        bytes32 implementationSlotValue = bytes32(uint256(uint160(_erc6551)));
        assertEq(vm.load(account, _ERC1967_IMPLEMENTATION_SLOT), implementationSlotValue);
    }

    function testDeployERC6551(uint256) public {
        _TestTemps memory t = _testTemps();
        (uint256 chainId, address tokenContract, uint256 tokenId) = t.account.token();
        assertEq(chainId, t.chainId);
        assertEq(tokenContract, _erc721);
        assertEq(tokenId, t.tokenId);
        address owner = t.account.owner();
        assertEq(owner, t.owner);
        if (_random() % 8 == 0) {
            vm.prank(owner);
            address newOnwer = _randomNonZeroAddress();
            MockERC721(_erc721).transferFrom(owner, newOnwer, t.tokenId);
            assertEq(t.account.owner(), newOnwer);
        }
    }

    function testOnERC721ReceivedCycles() public {
        unchecked {
            uint256 n = 8;
            _TestTemps[] memory t = new _TestTemps[](n);
            for (uint256 i; i != n; ++i) {
                t[i] = _testTemps();
                if (i != 0) {
                    vm.prank(t[i].owner);
                    MockERC721(_erc721).safeTransferFrom(
                        t[i].owner, address(t[i - 1].account), t[i].tokenId
                    );
                    t[i].owner = address(t[i - 1].account);
                }
            }
            for (uint256 i; i != n; ++i) {
                for (uint256 j = i; j != n; ++j) {
                    vm.prank(t[i].owner);
                    vm.expectRevert(ERC6551.SelfOwnDetected.selector);
                    MockERC721(_erc721).safeTransferFrom(
                        t[i].owner, address(t[j].account), t[i].tokenId
                    );
                }
            }

            _TestTemps memory u = _testTemps();
            vm.prank(u.owner);
            MockERC721(_erc721).safeTransferFrom(u.owner, address(t[n - 1].account), u.tokenId);
        }
    }

    function testOnERC721ReceivedCyclesWithDifferentChainIds(uint256) public {
        _TestTemps[] memory t = new _TestTemps[](3);
        unchecked {
            for (uint256 i; i != 3; ++i) {
                vm.chainId(i);
                t[i] = _testTemps();
                if (i != 0) {
                    vm.prank(t[i].owner);
                    MockERC721(_erc721).safeTransferFrom(
                        t[i].owner, address(t[i - 1].account), t[i].tokenId
                    );
                    t[i].owner = address(t[i - 1].account);
                }
            }
        }
        unchecked {
            vm.chainId(_random() % 3);
            uint256 i = _random() % 3;
            uint256 j = _random() % 3;
            while (j == i) j = _random() % 3;
            vm.prank(t[i].owner);
            MockERC721(_erc721).safeTransferFrom(t[i].owner, address(t[j].account), t[i].tokenId);
        }
    }

    function testOnERC721Received() public {
        _TestTemps memory t = _testTemps();
        address alice = _randomNonZeroAddress();
        MockERC721 erc721 = new MockERC721();
        erc721.mint(alice, 1);
        vm.prank(alice);
        if (alice != address(t.account)) {
            erc721.safeTransferFrom(alice, address(t.account), 1);
        }
    }

    function testOnERC1155Received() public {
        _TestTemps memory t = _testTemps();
        address alice = _randomNonZeroAddress();
        MockERC1155 erc1155 = new MockERC1155();
        erc1155.mint(alice, 1, 1, "");
        vm.prank(alice);
        erc1155.safeTransferFrom(alice, address(t.account), 1, 1, "");
    }

    function testOnERC1155BatchReceived() public {
        _TestTemps memory t = _testTemps();
        address alice = _randomNonZeroAddress();
        MockERC1155 erc1155 = new MockERC1155();
        erc1155.mint(alice, 1, 1, "");
        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;
        uint256[] memory amts = new uint256[](1);
        amts[0] = 1;
        vm.prank(alice);
        erc1155.safeBatchTransferFrom(alice, address(t.account), ids, amts, "");
    }

    function testExecute() public {
        _TestTemps memory t = _testTemps();
        vm.deal(address(t.account), 1 ether);

        address target = address(new Target());
        bytes memory data = _randomBytes(111);

        assertEq(t.account.state(), 0);

        vm.prank(t.owner);
        t.account.execute(target, 123, abi.encodeWithSignature("setData(bytes)", data), 0);
        assertEq(Target(target).datahash(), keccak256(data));
        assertEq(target.balance, 123);

        vm.prank(_randomNonZeroAddress());
        vm.expectRevert(ERC6551.Unauthorized.selector);
        t.account.execute(target, 123, abi.encodeWithSignature("setData(bytes)", data), 0);

        vm.prank(t.owner);
        vm.expectRevert(abi.encodeWithSignature("TargetError(bytes)", data));
        t.account.execute(
            target, 123, abi.encodeWithSignature("revertWithTargetError(bytes)", data), 0
        );

        vm.prank(t.owner);
        vm.expectRevert(ERC6551.OperationNotSupported.selector);
        t.account.execute(
            target, 123, abi.encodeWithSignature("revertWithTargetError(bytes)", data), 1
        );

        assertEq(t.account.state(), 1);
    }

    function testExecuteBatch() public {
        _TestTemps memory t = _testTemps();
        vm.deal(address(t.account), 1 ether);

        ERC6551.Call[] memory calls = new ERC6551.Call[](2);
        calls[0].target = address(new Target());
        calls[1].target = address(new Target());
        calls[0].value = 123;
        calls[1].value = 456;
        calls[0].data = abi.encodeWithSignature("setData(bytes)", _randomBytes(111));
        calls[1].data = abi.encodeWithSignature("setData(bytes)", _randomBytes(222));

        assertEq(t.account.state(), 0);

        vm.prank(t.owner);
        t.account.executeBatch(calls, 0);
        assertEq(Target(calls[0].target).datahash(), keccak256(_randomBytes(111)));
        assertEq(Target(calls[1].target).datahash(), keccak256(_randomBytes(222)));
        assertEq(calls[0].target.balance, 123);
        assertEq(calls[1].target.balance, 456);

        calls[1].data = abi.encodeWithSignature("revertWithTargetError(bytes)", _randomBytes(111));
        vm.expectRevert(abi.encodeWithSignature("TargetError(bytes)", _randomBytes(111)));
        vm.prank(t.owner);
        t.account.executeBatch(calls, 0);

        vm.prank(t.owner);
        vm.expectRevert(ERC6551.OperationNotSupported.selector);
        t.account.executeBatch(calls, 1);

        assertEq(t.account.state(), 1);
    }

    function testExecuteBatch(uint256 r) public {
        _TestTemps memory t = _testTemps();
        vm.deal(address(t.account), 1 ether);

        assertEq(t.account.state(), 0);

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
                vm.prank(t.owner);
                results = t.account.executeBatch(_random(), calls, 0);
            } else {
                vm.prank(t.owner);
                results = t.account.executeBatch(calls, 0);
            }

            assertEq(results.length, n);
            for (uint256 i; i != n; ++i) {
                uint256 v = calls[i].value;
                assertEq(Target(calls[i].target).datahash(), keccak256(_randomBytes(v)));
                assertEq(calls[i].target.balance, v);
                assertEq(abi.decode(results[i], (bytes)), _randomBytes(v));
            }
        }

        assertEq(t.account.state(), 1);
    }

    function testUpgrade() public {
        _TestTemps memory t = _testTemps();
        address anotherImplementation = address(new MockERC6551V2());
        vm.expectRevert(ERC6551.Unauthorized.selector);
        t.account.upgradeTo(anotherImplementation);
        assertEq(t.account.state(), 0);
        assertEq(t.account.version(), "1");

        vm.prank(t.owner);
        t.account.upgradeTo(anotherImplementation);
        assertEq(t.account.state(), 1);
        assertEq(t.account.version(), "2");

        vm.prank(t.owner);
        t.account.upgradeTo(_erc6551);
        assertEq(t.account.state(), 2);
        assertEq(t.account.version(), "1");
    }

    function testSupportsInterface() public {
        _TestTemps memory t = _testTemps();
        assertTrue(t.account.supportsInterface(0x01ffc9a7));
        assertTrue(t.account.supportsInterface(0x6faff5f1));
        assertTrue(t.account.supportsInterface(0x74420f4c));
        assertFalse(t.account.supportsInterface(0x00000001));
    }

    function testCdFallback() public {
        _TestTemps memory t = _testTemps();
        vm.deal(t.owner, 1 ether);

        ERC6551.Call[] memory calls = new ERC6551.Call[](2);
        calls[0].target = address(new Target());
        calls[1].target = address(new Target());
        calls[0].value = 123;
        calls[1].value = 456;
        calls[0].data = abi.encodeWithSignature("setData(bytes)", _randomBytes(111));
        calls[1].data = abi.encodeWithSignature("setData(bytes)", _randomBytes(222));

        bytes memory data = LibZip.cdCompress(
            abi.encodeWithSignature("executeBatch((address,uint256,bytes)[],uint8)", calls, 0)
        );
        vm.prank(t.owner);
        (bool success,) = address(t.account).call{value: 1 ether}(data);
        assertTrue(success);
        assertEq(Target(calls[0].target).datahash(), keccak256(_randomBytes(111)));
        assertEq(Target(calls[1].target).datahash(), keccak256(_randomBytes(222)));
        assertEq(calls[0].target.balance, 123);
        assertEq(calls[1].target.balance, 456);
    }

    function testIsValidSignature() public {
        _TestTemps memory t = _testTemps();
        (t.signer, t.privateKey) = _randomSigner();
        (t.v, t.r, t.s) =
            vm.sign(t.privateKey, SignatureCheckerLib.toEthSignedMessageHash(keccak256("123")));

        vm.prank(t.owner);
        MockERC721(_erc721).safeTransferFrom(t.owner, t.signer, t.tokenId);

        // Success returns `0x1626ba7e`.
        bytes memory signature = abi.encodePacked(t.r, t.s, t.v);
        assert(
            t.account.isValidSignature(
                SignatureCheckerLib.toEthSignedMessageHash(keccak256("123")), signature
            ) == 0x1626ba7e
        );
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
