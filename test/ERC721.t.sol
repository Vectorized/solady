// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";

import {ERC721, MockERC721} from "./utils/mocks/MockERC721.sol";

abstract contract ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata)
        external
        virtual
        returns (bytes4)
    {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

contract ERC721Recipient is ERC721TokenReceiver {
    address public operator;
    address public from;
    uint256 public id;
    bytes public data;

    function onERC721Received(address _operator, address _from, uint256 _id, bytes calldata _data)
        public
        virtual
        override
        returns (bytes4)
    {
        operator = _operator;
        from = _from;
        id = _id;
        data = _data;

        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

contract RevertingERC721Recipient is ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata)
        public
        virtual
        override
        returns (bytes4)
    {
        revert(string(abi.encodePacked(ERC721TokenReceiver.onERC721Received.selector)));
    }
}

contract WrongReturnDataERC721Recipient is ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata)
        public
        virtual
        override
        returns (bytes4)
    {
        return 0xCAFEBEEF;
    }
}

contract NonERC721Recipient {}

contract MockERC721WithHooks is MockERC721 {
    uint256 public beforeCounter;
    uint256 public afterCounter;

    function _beforeTokenTransfer(address, address, uint256) internal virtual override {
        beforeCounter++;
    }

    function _afterTokenTransfer(address, address, uint256) internal virtual override {
        afterCounter++;
    }
}

contract ERC721HooksTest is SoladyTest, ERC721TokenReceiver {
    uint256 public expectedBeforeCounter;
    uint256 public expectedAfterCounter;
    uint256 public ticker;

    function _checkCounters() internal view {
        require(
            expectedBeforeCounter == MockERC721WithHooks(msg.sender).beforeCounter(),
            "Before counter mismatch."
        );
        require(
            expectedAfterCounter == MockERC721WithHooks(msg.sender).afterCounter(),
            "After counter mismatch."
        );
    }

    function onERC721Received(address, address, uint256, bytes calldata)
        external
        virtual
        override
        returns (bytes4)
    {
        _checkCounters();
        return ERC721TokenReceiver.onERC721Received.selector;
    }

    function _testHooks(MockERC721WithHooks token) internal {
        address from = _randomNonZeroAddress();
        uint256 tokenId =
            uint256(keccak256(abi.encode(expectedBeforeCounter, expectedAfterCounter)));
        expectedBeforeCounter++;
        expectedAfterCounter++;
        token.mint(address(this), tokenId);

        expectedBeforeCounter++;
        expectedAfterCounter++;
        token.transferFrom(address(this), from, tokenId);

        expectedBeforeCounter++;
        expectedAfterCounter++;
        uint256 r = ticker < 4 ? ticker : _random() % 4;
        vm.prank(from);
        if (r == 0) {
            token.safeTransferFrom(from, address(this), tokenId);
        } else if (r == 1) {
            token.safeTransferFrom(from, address(this), tokenId, "");
        } else if (r == 2) {
            token.directSafeTransferFrom(from, address(this), tokenId);
        } else if (r == 3) {
            token.directSafeTransferFrom(from, address(this), tokenId, "");
        } else {
            revert();
        }
    }

    function testERC721Hooks() public {
        MockERC721WithHooks token = new MockERC721WithHooks();

        for (uint256 i; i < 32; ++i) {
            _testHooks(token);
        }
    }
}

contract ERC721Test is SoladyTest {
    MockERC721 token;

    uint256 private constant _ERC721_MASTER_SLOT_SEED = 0x7d8825530a5a2e7a << 192;

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed approved, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setUp() public {
        token = new MockERC721();
    }

    function _expectMintEvent(address to, uint256 id) internal {
        _expectTransferEvent(address(0), to, id);
    }

    function _expectBurnEvent(address from, uint256 id) internal {
        _expectTransferEvent(from, address(0), id);
    }

    function _expectTransferEvent(address from, address to, uint256 id) internal {
        vm.expectEmit(true, true, true, true);
        emit Transfer(from, to, id);
    }

    function _expectApprovalEvent(address owner, address approved, uint256 id) internal {
        vm.expectEmit(true, true, true, true);
        emit Approval(owner, approved, id);
    }

    function _expectApprovalForAllEvent(address owner, address operator, bool approved) internal {
        vm.expectEmit(true, true, true, true);
        emit ApprovalForAll(owner, operator, approved);
    }

    function _aux(address owner) internal pure returns (uint224 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, owner)
            result := shr(32, shl(32, keccak256(0x0c, 0x14)))
        }
    }

    function _extraData(uint256 id) internal pure returns (uint96 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, id)
            result := shr(160, shl(160, keccak256(0x00, 0x20)))
        }
    }

    function _transferFrom(address from, address to, uint256 id) internal {
        if (_random() % 2 == 0) {
            token.transferFrom(from, to, id);
        } else {
            token.directTransferFrom(from, to, id);
        }
    }

    function _safeTransferFrom(address from, address to, uint256 id) internal {
        if (_random() % 2 == 0) {
            token.safeTransferFrom(from, to, id);
        } else {
            token.directSafeTransferFrom(from, to, id);
        }
    }

    function _safeTransferFrom(address from, address to, uint256 id, bytes memory data) internal {
        if (_random() % 2 == 0) {
            token.safeTransferFrom(from, to, id, data);
        } else {
            token.directSafeTransferFrom(from, to, id, data);
        }
    }

    function _approve(address spender, uint256 id) internal {
        if (_random() % 2 == 0) {
            token.approve(spender, id);
        } else {
            token.directApprove(spender, id);
        }
    }

    function _setApprovalForAll(address operator, bool approved) internal {
        if (_random() % 2 == 0) {
            token.setApprovalForAll(operator, approved);
        } else {
            token.directSetApprovalForAll(operator, approved);
        }
    }

    function _ownerOf(uint256 id) internal returns (address) {
        if (_random() % 2 == 0) {
            return token.ownerOf(id);
        } else {
            return token.directOwnerOf(id);
        }
    }

    function _getApproved(uint256 id) internal returns (address) {
        if (_random() % 2 == 0) {
            return token.getApproved(id);
        } else {
            return token.directGetApproved(id);
        }
    }

    function _owners() internal returns (address a, address b) {
        a = _randomNonZeroAddress();
        b = _randomNonZeroAddress();
        while (a == b) b = _randomNonZeroAddress();
    }

    function testSafetyOfCustomStorage(uint256 id0, uint256 id1) public {
        bool safe;
        while (id0 == id1) id1 = _random();
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, id0)
            mstore(0x1c, _ERC721_MASTER_SLOT_SEED)
            let slot0 := add(id0, add(id0, keccak256(0x00, 0x20)))
            let slot2 := add(1, slot0)
            mstore(0x00, id1)
            mstore(0x1c, _ERC721_MASTER_SLOT_SEED)
            let slot1 := add(id1, add(id1, keccak256(0x00, 0x20)))
            let slot3 := add(1, slot1)
            safe := 1
            if eq(slot0, slot1) { safe := 0 }
            if eq(slot0, slot2) { safe := 0 }
            if eq(slot0, slot3) { safe := 0 }
            if eq(slot1, slot2) { safe := 0 }
            if eq(slot1, slot3) { safe := 0 }
            if eq(slot2, slot3) { safe := 0 }
        }
        require(safe, "Custom storage not safe");
    }

    function testAuthorizedEquivalence(address by, bool isOwnerOrOperator, bool isApprovedAccount)
        public
    {
        bool a = true;
        bool b = true;
        /// @solidity memory-safe-assembly
        assembly {
            if by { if iszero(isOwnerOrOperator) { a := isApprovedAccount } }
            if iszero(or(iszero(by), isOwnerOrOperator)) { b := isApprovedAccount }
        }
        assertEq(a, b);
    }

    function testCannotExceedMaxBalance() public {
        bytes32 balanceSlot;
        (address owner0, address owner1) = _owners();

        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x1c, _ERC721_MASTER_SLOT_SEED)
            mstore(0x00, owner0)
            balanceSlot := keccak256(0x0c, 0x1c)
        }

        vm.store(address(token), balanceSlot, bytes32(uint256(0xfffffffe)));
        token.setAux(owner0, type(uint224).max);
        assertEq(token.balanceOf(owner0), 0xfffffffe);
        assertEq(token.getAux(owner0), type(uint224).max);
        token.mint(owner0, 0);
        assertEq(token.balanceOf(owner0), 0xffffffff);

        vm.expectRevert(ERC721.AccountBalanceOverflow.selector);
        token.mint(owner0, 1);

        vm.expectRevert(ERC721.AccountBalanceOverflow.selector);
        token.mintWithExtraDataUnchecked(owner0, 1, _extraData(1));

        token.uncheckedBurn(0);
        assertEq(token.balanceOf(owner0), 0xfffffffe);

        token.mint(owner1, 0);
        vm.prank(owner1);
        _transferFrom(owner1, owner0, 0);

        token.mint(owner1, 1);
        vm.expectRevert(ERC721.AccountBalanceOverflow.selector);
        vm.prank(owner1);
        _transferFrom(owner1, owner0, 1);
        assertEq(token.getAux(owner0), type(uint224).max);
    }

    function testMint(uint256 id) public {
        address owner = _randomNonZeroAddress();

        _expectMintEvent(owner, id);
        token.mint(owner, id);

        assertEq(token.balanceOf(owner), 1);
        assertEq(_ownerOf(id), owner);
    }

    function testMintAndSetExtraDataUnchecked(uint256 id) public {
        address owner = _randomNonZeroAddress();

        _expectMintEvent(owner, id);
        token.mintWithExtraDataUnchecked(owner, id, _extraData(id));

        assertEq(token.balanceOf(owner), 1);
        assertEq(_ownerOf(id), owner);
        assertEq(token.getExtraData(id), _extraData(id));
    }

    function testMintAndSetExtraDataUncheckedWithOverwrite(uint256 id, uint96 random) public {
        address owner = _randomNonZeroAddress();

        token.setExtraData(id, random);
        assertEq(token.getExtraData(id), random);

        _expectMintEvent(owner, id);
        token.mintWithExtraDataUnchecked(owner, id, _extraData(id));

        assertEq(token.getExtraData(id), _extraData(id));
    }

    function testBurn(uint256 id) public {
        address owner = _randomNonZeroAddress();

        _expectMintEvent(owner, id);
        token.mint(owner, id);

        if (_random() % 2 == 0) {
            _expectBurnEvent(owner, id);
            token.uncheckedBurn(id);
        } else {
            vm.expectRevert(ERC721.NotOwnerNorApproved.selector);
            token.burn(id);
            uint256 r = _random() % 3;
            if (r == 0) {
                vm.prank(owner);
                _transferFrom(owner, address(this), id);
                _expectBurnEvent(address(this), id);
                token.burn(id);
            }
            if (r == 1) {
                vm.prank(owner);
                _setApprovalForAll(address(this), true);
                _expectBurnEvent(owner, id);
                token.burn(id);
            }
            if (r == 2) {
                vm.prank(owner);
                _approve(address(this), id);
                _expectBurnEvent(owner, id);
                token.burn(id);
            }
        }

        assertEq(token.balanceOf(owner), 0);

        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        _ownerOf(id);
    }

    function testTransferFrom() public {
        address owner = _randomNonZeroAddress();
        token.mint(owner, 0);
        vm.prank(owner);
        token.transferFrom(owner, address(this), 0);
    }

    function testEverything(uint256) public {
        address[2] memory owners;
        uint256[][2] memory tokens;

        unchecked {
            (owners[0], owners[1]) = _owners();
            for (uint256 j; j != 2; ++j) {
                tokens[j] = new uint256[](_random() % 3);
            }

            for (uint256 j; j != 2; ++j) {
                token.setAux(owners[j], _aux(owners[j]));
                for (uint256 i; i != tokens[j].length;) {
                    uint256 id = _random();
                    if (!token.exists(id)) {
                        tokens[j][i++] = id;
                        _expectMintEvent(owners[j], id);
                        token.mint(owners[j], id);
                        token.setExtraData(id, _extraData(id));
                    }
                }
            }
            for (uint256 j; j != 2; ++j) {
                assertEq(token.balanceOf(owners[j]), tokens[j].length);
                for (uint256 i; i != tokens[j].length; ++i) {
                    vm.prank(owners[j]);
                    _expectApprovalEvent(owners[j], address(this), tokens[j][i]);
                    _approve(address(this), tokens[j][i]);
                }
            }
            for (uint256 j; j != 2; ++j) {
                for (uint256 i; i != tokens[j].length; ++i) {
                    assertEq(_getApproved(tokens[j][i]), address(this));
                    uint256 fromBalanceBefore = token.balanceOf(owners[j]);
                    uint256 toBalanceBefore = token.balanceOf(owners[j ^ 1]);
                    _expectTransferEvent(owners[j], owners[j ^ 1], tokens[j][i]);
                    _transferFrom(owners[j], owners[j ^ 1], tokens[j][i]);
                    assertEq(token.balanceOf(owners[j]), fromBalanceBefore - 1);
                    assertEq(token.balanceOf(owners[j ^ 1]), toBalanceBefore + 1);
                    assertEq(_getApproved(tokens[j][i]), address(0));
                }
            }
            for (uint256 j; j != 2; ++j) {
                for (uint256 i; i != tokens[j].length; ++i) {
                    assertEq(_ownerOf(tokens[j][i]), owners[j ^ 1]);
                    assertEq(token.getExtraData(tokens[j][i]), _extraData(tokens[j][i]));
                }
            }
            if (_random() % 2 == 0) {
                for (uint256 j; j != 2; ++j) {
                    for (uint256 i; i != tokens[j].length; ++i) {
                        vm.expectRevert(ERC721.NotOwnerNorApproved.selector);
                        _transferFrom(owners[j ^ 1], owners[j], tokens[j][i]);
                        vm.prank(owners[j ^ 1]);
                        _expectApprovalEvent(owners[j ^ 1], address(this), tokens[j][i]);
                        _approve(address(this), tokens[j][i]);
                        _expectTransferEvent(owners[j ^ 1], owners[j], tokens[j][i]);
                        _transferFrom(owners[j ^ 1], owners[j], tokens[j][i]);
                    }
                }
            } else {
                for (uint256 j; j != 2; ++j) {
                    vm.prank(owners[j ^ 1]);
                    _expectApprovalForAllEvent(owners[j ^ 1], address(this), true);
                    token.setApprovalForAll(address(this), true);
                    for (uint256 i; i != tokens[j].length; ++i) {
                        _expectTransferEvent(owners[j ^ 1], owners[j], tokens[j][i]);
                        _transferFrom(owners[j ^ 1], owners[j], tokens[j][i]);
                    }
                }
            }
            for (uint256 j; j != 2; ++j) {
                assertEq(token.getAux(owners[j]), _aux(owners[j]));
                for (uint256 i; i != tokens[j].length; ++i) {
                    assertEq(_ownerOf(tokens[j][i]), owners[j]);
                    assertEq(token.getExtraData(tokens[j][i]), _extraData(tokens[j][i]));
                }
            }
            for (uint256 j; j != 2; ++j) {
                for (uint256 i; i != tokens[j].length; ++i) {
                    token.uncheckedBurn(tokens[j][i]);
                }
            }
            for (uint256 j; j != 2; ++j) {
                assertEq(token.balanceOf(owners[j]), 0);
                for (uint256 i; i != tokens[j].length; ++i) {
                    assertEq(token.getExtraData(tokens[j][i]), _extraData(tokens[j][i]));
                }
            }
        }
    }

    function testIsApprovedOrOwner(uint256 id) public {
        (address owner0, address owner1) = _owners();

        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        token.isApprovedOrOwner(owner0, id);

        token.mint(owner0, id);
        assertEq(token.isApprovedOrOwner(owner0, id), true);

        vm.prank(owner0);
        _transferFrom(owner0, owner1, id);
        assertEq(token.isApprovedOrOwner(owner0, id), false);

        vm.prank(owner1);
        _setApprovalForAll(owner0, true);
        assertEq(token.isApprovedOrOwner(owner0, id), true);

        vm.prank(owner1);
        _setApprovalForAll(owner0, false);
        assertEq(token.isApprovedOrOwner(owner0, id), false);

        vm.prank(owner1);
        _approve(owner0, id);
        assertEq(token.isApprovedOrOwner(owner0, id), true);
    }

    function testExtraData(uint256 id) public {
        (address owner0, address owner1) = _owners();

        bool setExtraData = _random() % 2 == 0;
        uint96 extraData = uint96(_bound(_random(), 0, type(uint96).max));
        if (setExtraData) {
            token.setExtraData(id, extraData);
        }
        _expectMintEvent(owner0, id);
        token.mint(owner0, id);
        if (setExtraData) {
            assertEq(token.getExtraData(id), extraData);
        } else {
            assertEq(token.getExtraData(id), 0);
        }

        vm.prank(owner0);
        _expectTransferEvent(owner0, owner1, id);
        _transferFrom(owner0, owner1, id);
        if (setExtraData) {
            assertEq(token.getExtraData(id), extraData);
        } else {
            assertEq(token.getExtraData(id), 0);
        }
        assertEq(_ownerOf(id), owner1);

        if (_random() % 2 == 0) {
            extraData = uint96(_bound(_random(), 0, type(uint96).max));
            token.setExtraData(id, extraData);
            setExtraData = true;
        }

        _expectBurnEvent(owner1, id);
        token.uncheckedBurn(id);
        if (setExtraData) {
            assertEq(token.getExtraData(id), extraData);
        } else {
            assertEq(token.getExtraData(id), 0);
        }
        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        _ownerOf(id);
    }

    function testExtraData2(uint256 id0, uint256 id1) public {
        while (id0 == id1) id1 = _random();
        token.setExtraData(id0, _extraData(id0));
        token.setExtraData(id1, _extraData(id1));
        assertEq(token.getExtraData(id0), _extraData(id0));
        assertEq(token.getExtraData(id1), _extraData(id1));
    }

    function testAux(uint256) public {
        (address owner0, address owner1) = _owners();

        bool setAux = _random() % 2 == 0;
        if (setAux) {
            token.setAux(owner0, _aux(owner0));
            token.setAux(owner1, _aux(owner1));
        }

        for (uint256 i; i < 2; ++i) {
            _expectMintEvent(owner0, i * 2 + 0);
            token.mint(owner0, i * 2 + 0);
            assertEq(token.balanceOf(owner0), i + 1);

            _expectMintEvent(owner1, i * 2 + 1);
            token.mint(owner1, i * 2 + 1);
            assertEq(token.balanceOf(owner1), i + 1);

            if (setAux) {
                assertEq(token.getAux(owner0), _aux(owner0));
                assertEq(token.getAux(owner1), _aux(owner1));
            } else {
                assertEq(token.getAux(owner0), 0);
                assertEq(token.getAux(owner1), 0);
            }
        }

        for (uint256 i; i < 2; ++i) {
            _expectBurnEvent(owner0, i * 2 + 0);
            token.uncheckedBurn(i * 2 + 0);
            assertEq(token.balanceOf(owner0), 1 - i);

            _expectBurnEvent(owner1, i * 2 + 1);
            token.uncheckedBurn(i * 2 + 1);
            assertEq(token.balanceOf(owner1), 1 - i);

            if (setAux) {
                assertEq(token.getAux(owner0), _aux(owner0));
                assertEq(token.getAux(owner1), _aux(owner1));
            } else {
                assertEq(token.getAux(owner0), 0);
                assertEq(token.getAux(owner1), 0);
            }
        }
    }

    function testApprove(uint256 id) public {
        (address spender,) = _randomSigner();

        token.mint(address(this), id);

        _expectApprovalEvent(address(this), spender, id);
        _approve(spender, id);
        assertEq(_getApproved(id), spender);
    }

    function testApproveBurn(uint256 id) public {
        (address spender,) = _randomSigner();

        token.mint(address(this), id);

        _approve(spender, id);

        token.uncheckedBurn(id);

        assertEq(token.balanceOf(address(this)), 0);

        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        _getApproved(id);

        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        _ownerOf(id);
    }

    function testApproveAll(uint256) public {
        (address operator,) = _randomSigner();
        bool approved = _random() % 2 == 0;
        _expectApprovalForAllEvent(address(this), operator, approved);
        _setApprovalForAll(operator, approved);
        assertEq(token.isApprovedForAll(address(this), operator), approved);
    }

    function testTransferFrom(uint256 id) public {
        (address from, address to) = _owners();

        token.mint(from, id);

        if (_random() % 2 == 0) {
            uint256 r = _random() % 3;
            if (r == 0) {
                vm.prank(from);
                _approve(address(this), id);
                _expectTransferEvent(from, to, id);
                _transferFrom(from, to, id);
            }
            if (r == 1) {
                vm.prank(from);
                _setApprovalForAll(address(this), true);
                _expectTransferEvent(from, to, id);
                _transferFrom(from, to, id);
            }
            if (r == 2) {
                vm.prank(from);
                _expectTransferEvent(from, address(this), id);
                _transferFrom(from, address(this), id);
                _expectTransferEvent(address(this), to, id);
                _transferFrom(address(this), to, id);
            }
        } else {
            (address temp,) = _randomSigner();
            while (temp == from || temp == to) (temp,) = _randomSigner();
            if (_random() % 2 == 0) {
                _expectTransferEvent(from, temp, id);
                token.uncheckedTransferFrom(from, temp, id);
            } else {
                vm.prank(from);
                _expectTransferEvent(from, temp, id);
                _transferFrom(from, temp, id);
            }
            _expectTransferEvent(temp, to, id);
            token.uncheckedTransferFrom(temp, to, id);
        }

        assertEq(_getApproved(id), address(0));
        assertEq(_ownerOf(id), to);
        assertEq(token.balanceOf(to), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testTransferFromSelf(uint256 id) public {
        (address to,) = _randomSigner();

        token.mint(address(this), id);

        _transferFrom(address(this), to, id);

        assertEq(_getApproved(id), address(0));
        assertEq(_ownerOf(id), to);
        assertEq(token.balanceOf(to), 1);
        assertEq(token.balanceOf(address(this)), 0);
    }

    function testTransferFromApproveAll(uint256 id) public {
        (address from, address to) = _owners();

        token.mint(from, id);

        vm.prank(from);
        _setApprovalForAll(address(this), true);

        _transferFrom(from, to, id);

        assertEq(_getApproved(id), address(0));
        assertEq(_ownerOf(id), to);
        assertEq(token.balanceOf(to), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testSafeTransferFromToEOA(uint256 id) public {
        (address from, address to) = _owners();

        token.mint(from, id);

        vm.prank(from);
        _setApprovalForAll(address(this), true);

        _safeTransferFrom(from, to, id);

        assertEq(_getApproved(id), address(0));
        assertEq(_ownerOf(id), to);
        assertEq(token.balanceOf(to), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testSafeTransferFromToERC721Recipient(uint256 id) public {
        (address from,) = _randomSigner();

        ERC721Recipient recipient = new ERC721Recipient();

        token.mint(from, id);

        vm.prank(from);
        _setApprovalForAll(address(this), true);

        _safeTransferFrom(from, address(recipient), id);

        assertEq(_getApproved(id), address(0));
        assertEq(_ownerOf(id), address(recipient));
        assertEq(token.balanceOf(address(recipient)), 1);
        assertEq(token.balanceOf(from), 0);

        assertEq(recipient.operator(), address(this));
        assertEq(recipient.from(), from);
        assertEq(recipient.id(), id);
        assertEq(recipient.data(), "");
    }

    function testSafeTransferFromToERC721RecipientWithData(uint256 id, bytes memory data) public {
        (address from,) = _randomSigner();

        ERC721Recipient recipient = new ERC721Recipient();

        token.mint(from, id);

        vm.prank(from);
        _setApprovalForAll(address(this), true);

        _safeTransferFrom(from, address(recipient), id, data);

        assertEq(recipient.data(), data);
        assertEq(recipient.id(), id);
        assertEq(recipient.operator(), address(this));
        assertEq(recipient.from(), from);

        assertEq(_getApproved(id), address(0));
        assertEq(_ownerOf(id), address(recipient));
        assertEq(token.balanceOf(address(recipient)), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testSafeMintToEOA(uint256 id) public {
        (address to,) = _randomSigner();

        token.safeMint(to, id);

        assertEq(_ownerOf(id), address(to));
        assertEq(token.balanceOf(address(to)), 1);
    }

    function testSafeMintToERC721Recipient(uint256 id) public {
        ERC721Recipient to = new ERC721Recipient();

        token.safeMint(address(to), id);

        assertEq(_ownerOf(id), address(to));
        assertEq(token.balanceOf(address(to)), 1);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), id);
        assertEq(to.data(), "");
    }

    function testSafeMintToERC721RecipientWithData(uint256 id, bytes memory data) public {
        ERC721Recipient to = new ERC721Recipient();

        token.safeMint(address(to), id, data);

        assertEq(_ownerOf(id), address(to));
        assertEq(token.balanceOf(address(to)), 1);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), id);
        assertEq(to.data(), data);
    }

    function testMintToZeroReverts(uint256 id) public {
        vm.expectRevert(ERC721.TransferToZeroAddress.selector);
        token.mint(address(0), id);

        vm.expectRevert(ERC721.TransferToZeroAddress.selector);
        token.mintWithExtraDataUnchecked(address(0), id, _extraData(id));
    }

    function testDoubleMintReverts(uint256 id) public {
        (address to,) = _randomSigner();

        token.mint(to, id);
        vm.expectRevert(ERC721.TokenAlreadyExists.selector);
        token.mint(to, id);
    }

    function testBurnNonExistentReverts(uint256 id) public {
        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        token.uncheckedBurn(id);
    }

    function testDoubleBurnReverts(uint256 id) public {
        (address to,) = _randomSigner();

        token.mint(to, id);

        token.uncheckedBurn(id);
        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        token.uncheckedBurn(id);
    }

    function testApproveNonExistentReverts(uint256 id, address to) public {
        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        _approve(to, id);
    }

    function testApproveUnauthorizedReverts(uint256 id) public {
        (address owner, address to) = _owners();

        token.mint(owner, id);
        vm.expectRevert(ERC721.NotOwnerNorApproved.selector);
        _approve(to, id);
    }

    function testTransferFromNotExistentReverts(address from, address to, uint256 id) public {
        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        _transferFrom(from, to, id);
    }

    function testTransferFromWrongFromReverts(address to, uint256 id) public {
        (address owner, address from) = _owners();

        token.mint(owner, id);
        vm.expectRevert(ERC721.TransferFromIncorrectOwner.selector);
        _transferFrom(from, to, id);
    }

    function testTransferFromToZeroReverts(uint256 id) public {
        token.mint(address(this), id);

        vm.expectRevert(ERC721.TransferToZeroAddress.selector);
        _transferFrom(address(this), address(0), id);
    }

    function testTransferFromNotOwner(uint256 id) public {
        (address from, address to) = _owners();

        token.mint(from, id);

        vm.expectRevert(ERC721.NotOwnerNorApproved.selector);
        _transferFrom(from, to, id);
    }

    function testSafeTransferFromToNonERC721RecipientReverts(uint256 id) public {
        token.mint(address(this), id);
        address to = address(new NonERC721Recipient());
        vm.expectRevert(ERC721.TransferToNonERC721ReceiverImplementer.selector);
        _safeTransferFrom(address(this), address(to), id);
    }

    function testSafeTransferFromToNonERC721RecipientWithDataReverts(uint256 id, bytes memory data)
        public
    {
        token.mint(address(this), id);
        address to = address(new NonERC721Recipient());
        vm.expectRevert(ERC721.TransferToNonERC721ReceiverImplementer.selector);
        _safeTransferFrom(address(this), to, id, data);
    }

    function testSafeTransferFromToRevertingERC721RecipientReverts(uint256 id) public {
        token.mint(address(this), id);
        address to = address(new RevertingERC721Recipient());
        vm.expectRevert(abi.encodePacked(ERC721TokenReceiver.onERC721Received.selector));
        _safeTransferFrom(address(this), to, id);
    }

    function testSafeTransferFromToRevertingERC721RecipientWithDataReverts(
        uint256 id,
        bytes memory data
    ) public {
        token.mint(address(this), id);
        address to = address(new RevertingERC721Recipient());
        vm.expectRevert(abi.encodePacked(ERC721TokenReceiver.onERC721Received.selector));
        _safeTransferFrom(address(this), to, id, data);
    }

    function testSafeTransferFromToERC721RecipientWithWrongReturnDataReverts(uint256 id) public {
        token.mint(address(this), id);
        address to = address(new WrongReturnDataERC721Recipient());
        vm.expectRevert(ERC721.TransferToNonERC721ReceiverImplementer.selector);
        _safeTransferFrom(address(this), to, id);
    }

    function testSafeTransferFromToERC721RecipientWithWrongReturnDataWithDataReverts(
        uint256 id,
        bytes memory data
    ) public {
        token.mint(address(this), id);
        address to = address(new WrongReturnDataERC721Recipient());
        vm.expectRevert(ERC721.TransferToNonERC721ReceiverImplementer.selector);
        _safeTransferFrom(address(this), to, id, data);
    }

    function testSafeMintToNonERC721RecipientReverts(uint256 id) public {
        address to = address(new NonERC721Recipient());
        vm.expectRevert(ERC721.TransferToNonERC721ReceiverImplementer.selector);
        token.safeMint(to, id);
    }

    function testSafeMintToNonERC721RecipientWithDataReverts(uint256 id, bytes memory data)
        public
    {
        address to = address(new NonERC721Recipient());
        vm.expectRevert(ERC721.TransferToNonERC721ReceiverImplementer.selector);
        token.safeMint(to, id, data);
    }

    function testSafeMintToRevertingERC721RecipientReverts(uint256 id) public {
        address to = address(new RevertingERC721Recipient());
        vm.expectRevert(abi.encodePacked(ERC721TokenReceiver.onERC721Received.selector));
        token.safeMint(to, id);
    }

    function testSafeMintToRevertingERC721RecipientWithDataReverts(uint256 id, bytes memory data)
        public
    {
        address to = address(new RevertingERC721Recipient());
        vm.expectRevert(abi.encodePacked(ERC721TokenReceiver.onERC721Received.selector));
        token.safeMint(to, id, data);
    }

    function testSafeMintToERC721RecipientWithWrongReturnData(uint256 id) public {
        address to = address(new WrongReturnDataERC721Recipient());
        vm.expectRevert(ERC721.TransferToNonERC721ReceiverImplementer.selector);
        token.safeMint(to, id);
    }

    function testSafeMintToERC721RecipientWithWrongReturnDataWithData(uint256 id, bytes memory data)
        public
    {
        address to = address(new WrongReturnDataERC721Recipient());
        vm.expectRevert(ERC721.TransferToNonERC721ReceiverImplementer.selector);
        token.safeMint(to, id, data);
    }

    function testOwnerOfNonExistent(uint256 id) public {
        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        _ownerOf(id);
    }
}
