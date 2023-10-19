// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {SignatureCheckerLib} from "../src/accounts/ERC6551.sol";
import {ERC6551, MockERC6551} from "./utils/mocks/MockERC6551.sol";
import {IERC6551Registry, MockERC6551Registry} from "./utils/mocks/MockERC6551Registry.sol";
import {MockERC721} from "./utils/mocks/MockERC721.sol";
import {MockERC1155} from "./utils/mocks/MockERC1155.sol";

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
    address private _registry;

    address private _erc6551;

    address private _erc721;

    mapping(uint256 => bool) private _minted;

    struct _TestTemps {
        IERC6551Registry registry;
        address erc6551;
        address owner;
        uint256 chainId;
        MockERC721 tokenContract;
        uint256 tokenId;
        bytes32 salt;
        MockERC6551 account;
    }

    function _deploy() internal {
        if (_registry == address(0)) {
            _registry = address(new MockERC6551Registry());
        }
        if (_erc6551 == address(0)) {
            _erc6551 = address(new MockERC6551());
        }
        if (_erc721 == address(0)) {
            _erc721 = address(new MockERC721());
        }
    }

    function _testTemps() internal returns (_TestTemps memory t) {
        _deploy();
        t.registry = IERC6551Registry(_registry);
        t.erc6551 = address(_erc6551);
        t.owner = _randomNonZeroAddress();
        t.tokenContract = MockERC721(_erc721);
        do {
            t.tokenId = _random();
            _minted[t.tokenId] = true;
        } while (_minted[t.tokenId] == false);
        t.tokenContract.mint(t.owner, t.tokenId);
        t.chainId = block.chainid;
        t.salt = bytes32(_random());
        address account = t.registry.createAccount(
            t.erc6551, t.salt, t.chainId, address(t.tokenContract), t.tokenId
        );
        t.account = MockERC6551(payable(account));
    }

    function testDeployERC6551(uint256) public {
        _TestTemps memory t = _testTemps();
        (uint256 chainId, address tokenContract, uint256 tokenId) = t.account.token();
        assertEq(chainId, t.chainId);
        assertEq(tokenContract, address(t.tokenContract));
        assertEq(tokenId, t.tokenId);
        address owner = t.account.owner();
        assertEq(owner, t.owner);
        if (_random() % 8 == 0) {
            vm.prank(owner);
            address newOnwer = _randomNonZeroAddress();
            t.tokenContract.transferFrom(owner, newOnwer, t.tokenId);
            assertEq(t.account.owner(), newOnwer);
        }
    }

    function testOnERC721ReceivedCycles() public {
        unchecked {
            uint256 n = 15;
            _TestTemps[] memory t = new _TestTemps[](n);
            for (uint256 i; i != n; ++i) {
                t[i] = _testTemps();
                if (i != 0) {
                    vm.prank(t[i].owner);
                    t[i].tokenContract.safeTransferFrom(
                        t[i].owner, address(t[i - 1].account), t[i].tokenId
                    );
                    t[i].owner = address(t[i - 1].account);
                }
            }

            vm.prank(t[0].owner);
            vm.expectRevert(ERC6551.SelfOwnDetected.selector);
            t[0].tokenContract.safeTransferFrom(t[0].owner, address(t[0].account), t[0].tokenId);

            vm.prank(t[0].owner);
            vm.expectRevert(ERC6551.SelfOwnDetected.selector);
            t[0].tokenContract.safeTransferFrom(t[0].owner, address(t[n - 1].account), t[0].tokenId);

            _TestTemps memory u = _testTemps();
            vm.prank(u.owner);
            u.tokenContract.safeTransferFrom(u.owner, address(t[n - 1].account), u.tokenId);
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
