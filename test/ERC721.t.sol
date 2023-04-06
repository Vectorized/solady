// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/TestPlus.sol";

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

contract ERC721Test is TestPlus {
    MockERC721 token;

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed approved, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setUp() public {
        token = new MockERC721("Token", "TKN");
    }

    function invariantMetadata() public {
        assertEq(token.name(), "Token");
        assertEq(token.symbol(), "TKN");
    }

    function testMint() public {
        token.mint(address(0xBEEF), 1337);

        assertEq(token.balanceOf(address(0xBEEF)), 1);
        assertEq(token.ownerOf(1337), address(0xBEEF));
    }

    function testBurn() public {
        token.mint(address(0xBEEF), 1337);
        token.burn(1337);

        assertEq(token.balanceOf(address(0xBEEF)), 0);

        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        token.ownerOf(1337);
    }

    function testApprove() public {
        token.mint(address(this), 1337);

        token.approve(address(0xBEEF), 1337);

        assertEq(token.getApproved(1337), address(0xBEEF));
    }

    function testApproveBurn() public {
        token.mint(address(this), 1337);

        token.approve(address(0xBEEF), 1337);

        token.burn(1337);

        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.getApproved(1337), address(0));

        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        token.ownerOf(1337);
    }

    function testApproveAll() public {
        token.setApprovalForAll(address(0xBEEF), true);

        assertTrue(token.isApprovedForAll(address(this), address(0xBEEF)));
    }

    function testTransferFrom() public {
        address from = address(0xABCD);

        token.mint(from, 1337);

        vm.prank(from);
        token.approve(address(this), 1337);

        token.transferFrom(from, address(0xBEEF), 1337);

        assertEq(token.getApproved(1337), address(0));
        assertEq(token.ownerOf(1337), address(0xBEEF));
        assertEq(token.balanceOf(address(0xBEEF)), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testTransferFromSelf() public {
        token.mint(address(this), 1337);

        token.transferFrom(address(this), address(0xBEEF), 1337);

        assertEq(token.getApproved(1337), address(0));
        assertEq(token.ownerOf(1337), address(0xBEEF));
        assertEq(token.balanceOf(address(0xBEEF)), 1);
        assertEq(token.balanceOf(address(this)), 0);
    }

    function testTransferFromApproveAll() public {
        address from = address(0xABCD);

        token.mint(from, 1337);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.transferFrom(from, address(0xBEEF), 1337);

        assertEq(token.getApproved(1337), address(0));
        assertEq(token.ownerOf(1337), address(0xBEEF));
        assertEq(token.balanceOf(address(0xBEEF)), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testSafeTransferFromToEOA() public {
        address from = address(0xABCD);

        token.mint(from, 1337);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, address(0xBEEF), 1337);

        assertEq(token.getApproved(1337), address(0));
        assertEq(token.ownerOf(1337), address(0xBEEF));
        assertEq(token.balanceOf(address(0xBEEF)), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testSafeTransferFromToERC721Recipient() public {
        address from = address(0xABCD);
        ERC721Recipient recipient = new ERC721Recipient();

        token.mint(from, 1337);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, address(recipient), 1337);

        assertEq(token.getApproved(1337), address(0));
        assertEq(token.ownerOf(1337), address(recipient));
        assertEq(token.balanceOf(address(recipient)), 1);
        assertEq(token.balanceOf(from), 0);

        assertEq(recipient.operator(), address(this));
        assertEq(recipient.from(), from);
        assertEq(recipient.id(), 1337);
        assertEq(recipient.data(), "");
    }

    function testSafeTransferFromToERC721RecipientWithData() public {
        address from = address(0xABCD);
        ERC721Recipient recipient = new ERC721Recipient();

        token.mint(from, 1337);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, address(recipient), 1337, "testing 123");

        assertEq(token.getApproved(1337), address(0));
        assertEq(token.ownerOf(1337), address(recipient));
        assertEq(token.balanceOf(address(recipient)), 1);
        assertEq(token.balanceOf(from), 0);

        assertEq(recipient.operator(), address(this));
        assertEq(recipient.from(), from);
        assertEq(recipient.id(), 1337);
        assertEq(recipient.data(), "testing 123");
    }

    function testSafeMintToEOA() public {
        token.safeMint(address(0xBEEF), 1337);

        assertEq(token.ownerOf(1337), address(address(0xBEEF)));
        assertEq(token.balanceOf(address(address(0xBEEF))), 1);
    }

    function testSafeMintToERC721Recipient() public {
        ERC721Recipient to = new ERC721Recipient();

        token.safeMint(address(to), 1337);

        assertEq(token.ownerOf(1337), address(to));
        assertEq(token.balanceOf(address(to)), 1);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), 1337);
        assertEq(to.data(), "");
    }

    function testSafeMintToERC721RecipientWithData() public {
        ERC721Recipient to = new ERC721Recipient();

        token.safeMint(address(to), 1337, "testing 123");

        assertEq(token.ownerOf(1337), address(to));
        assertEq(token.balanceOf(address(to)), 1);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), 1337);
        assertEq(to.data(), "testing 123");
    }

    function testMintToZeroReverts() public {
        vm.expectRevert(ERC721.TransferToZeroAddress.selector);
        token.mint(address(0), 1337);
    }

    function testDoubleMintReverts() public {
        token.mint(address(0xBEEF), 1337);
        vm.expectRevert(ERC721.TokenAlreadyExists.selector);
        token.mint(address(0xBEEF), 1337);
    }

    function testBurnNonExistentReverts() public {
        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        token.burn(1337);
    }

    function testDoubleBurnReverts() public {
        token.mint(address(0xBEEF), 1337);

        token.burn(1337);
        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        token.burn(1337);
    }

    function testApproveNonExistentReverts() public {
        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        token.approve(address(0xBEEF), 1337);
    }

    function testApproveUnAuthorizedReverts() public {
        token.mint(address(0xCAFE), 1337);
        vm.expectRevert(ERC721.NotOwnerNorApproved.selector);
        token.approve(address(0xBEEF), 1337);
    }

    function testTransferFromNonExistentReverts() public {
        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        token.transferFrom(address(0xFEED), address(0xBEEF), 1337);
    }

    function testTransferFromWrongFromReverts() public {
        token.mint(address(0xCAFE), 1337);
        vm.expectRevert(ERC721.TransferFromIncorrectOwner.selector);
        token.transferFrom(address(0xFEED), address(0xBEEF), 1337);
    }

    function testTransferFromToZeroReverts() public {
        token.mint(address(this), 1337);
        vm.expectRevert(ERC721.TransferToZeroAddress.selector);
        token.transferFrom(address(this), address(0), 1337);
    }

    function testTransferFromNotOwnerReverts() public {
        token.mint(address(0xFEED), 1337);
        vm.expectRevert(ERC721.NotOwnerNorApproved.selector);
        token.transferFrom(address(0xFEED), address(0xBEEF), 1337);
    }

    function testSafeTransferFromToNonERC721RecipientReverts() public {
        token.mint(address(this), 1337);
        address to = address(new NonERC721Recipient());
        vm.expectRevert(ERC721.TransferToNonERC721ReceiverImplementer.selector);
        token.safeTransferFrom(address(this), to, 1337);
    }

    function testSafeTransferFromToNonERC721RecipientWithDataReverts() public {
        token.mint(address(this), 1337);
        address to = address(new NonERC721Recipient());
        vm.expectRevert(ERC721.TransferToNonERC721ReceiverImplementer.selector);
        token.safeTransferFrom(address(this), to, 1337, "testing 123");
    }

    function testSafeTransferFromToRevertingERC721RecipientReverts() public {
        token.mint(address(this), 1337);
        address to = address(new RevertingERC721Recipient());
        vm.expectRevert(abi.encodePacked(ERC721TokenReceiver.onERC721Received.selector));
        token.safeTransferFrom(address(this), to, 1337);
    }

    function testSafeTransferFromToRevertingERC721RecipientWithDataReverts() public {
        token.mint(address(this), 1337);
        address to = address(new RevertingERC721Recipient());
        vm.expectRevert(abi.encodePacked(ERC721TokenReceiver.onERC721Received.selector));
        token.safeTransferFrom(address(this), to, 1337, "testing 123");
    }

    function testSafeTransferFromToERC721RecipientWithWrongReturnDataReverts() public {
        token.mint(address(this), 1337);
        address to = address(new WrongReturnDataERC721Recipient());
        vm.expectRevert(ERC721.TransferToNonERC721ReceiverImplementer.selector);
        token.safeTransferFrom(address(this), to, 1337);
    }

    function testSafeTransferFromToERC721RecipientWithWrongReturnDataWithDataReverts() public {
        token.mint(address(this), 1337);
        address to = address(new WrongReturnDataERC721Recipient());
        vm.expectRevert(ERC721.TransferToNonERC721ReceiverImplementer.selector);
        token.safeTransferFrom(address(this), to, 1337, "testing 123");
    }

    function testSafeMintToNonERC721RecipientReverts() public {
        address to = address(new NonERC721Recipient());
        vm.expectRevert(ERC721.TransferToNonERC721ReceiverImplementer.selector);
        token.safeMint(to, 1337);
    }

    function testSafeMintToNonERC721RecipientWithDataReverts() public {
        address to = address(new NonERC721Recipient());
        vm.expectRevert(ERC721.TransferToNonERC721ReceiverImplementer.selector);
        token.safeMint(to, 1337, "testing 123");
    }

    function testSafeMintToRevertingERC721RecipientReverts() public {
        address to = address(new RevertingERC721Recipient());
        vm.expectRevert(abi.encodePacked(ERC721TokenReceiver.onERC721Received.selector));
        token.safeMint(to, 1337);
    }

    function testSafeMintToRevertingERC721RecipientWithDataReverts() public {
        address to = address(new RevertingERC721Recipient());
        vm.expectRevert(abi.encodePacked(ERC721TokenReceiver.onERC721Received.selector));
        token.safeMint(to, 1337, "testing 123");
    }

    function testSafeMintToERC721RecipientWithWrongReturnDataReverts() public {
        address to = address(new WrongReturnDataERC721Recipient());
        vm.expectRevert(ERC721.TransferToNonERC721ReceiverImplementer.selector);
        token.safeMint(to, 1337);
    }

    function testSafeMintToERC721RecipientWithWrongReturnDataWithDataReverts() public {
        address to = address(new WrongReturnDataERC721Recipient());
        vm.expectRevert(ERC721.TransferToNonERC721ReceiverImplementer.selector);
        token.safeMint(to, 1337, "testing 123");
    }

    function testBalanceOfZeroAddressReverts() public {
        vm.expectRevert(ERC721.BalanceQueryForZeroAddress.selector);
        token.balanceOf(address(0));
    }

    function testOwnerOfNonExistentReverts() public {
        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        token.ownerOf(1337);
    }

    function testMetadata(string memory name, string memory symbol) public {
        MockERC721 tkn = new MockERC721(name, symbol);

        assertEq(tkn.name(), name);
        assertEq(tkn.symbol(), symbol);
    }

    function testMint(address to, uint256 id) public {
        if (to == address(0)) to = address(0xBEEF);

        token.mint(to, id);

        assertEq(token.balanceOf(to), 1);
        assertEq(token.ownerOf(id), to);
    }

    function testBurn(address to, uint256 id) public {
        if (to == address(0)) to = address(0xBEEF);

        token.mint(to, id);
        token.burn(id);

        assertEq(token.balanceOf(to), 0);

        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        token.ownerOf(id);
    }

    function testIsApprovedOrOwner(uint256) public {
        uint256 id = _random();
        (address owner0,) = _randomSigner();
        (address owner1,) = _randomSigner();
        while (owner0 == owner1) (owner1,) = _randomSigner();

        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        token.isApprovedOrOwner(owner0, id);

        token.mint(owner0, id);
        assertEq(token.isApprovedOrOwner(owner0, id), true);

        vm.prank(owner0);
        token.transferFrom(owner0, owner1, id);
        assertEq(token.isApprovedOrOwner(owner0, id), false);

        vm.prank(owner1);
        token.setApprovalForAll(owner0, true);
        assertEq(token.isApprovedOrOwner(owner0, id), true);

        vm.prank(owner1);
        token.setApprovalForAll(owner0, false);
        assertEq(token.isApprovedOrOwner(owner0, id), false);

        vm.prank(owner1);
        token.approve(owner0, id);
        assertEq(token.isApprovedOrOwner(owner0, id), true);
    }

    function testExtraData(uint256) public {
        uint256 id = _random();
        (address owner0,) = _randomSigner();
        (address owner1,) = _randomSigner();
        while (owner0 == owner1) (owner1,) = _randomSigner();

        bool setExtraData = _random() % 2 == 0;
        uint96 extraData = uint96(_bound(_random(), 0, type(uint96).max));
        if (setExtraData) {
            token.setExtraData(id, extraData);
        }
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), owner0, id);
        token.mint(owner0, id);
        if (setExtraData) {
            assertEq(token.getExtraData(id), extraData);
        } else {
            assertEq(token.getExtraData(id), 0);
        }

        vm.prank(owner0);
        vm.expectEmit(true, true, true, true);
        emit Transfer(owner0, owner1, id);
        token.transferFrom(owner0, owner1, id);
        if (setExtraData) {
            assertEq(token.getExtraData(id), extraData);
        } else {
            assertEq(token.getExtraData(id), 0);
        }
        assertEq(token.ownerOf(id), owner1);

        if (_random() % 2 == 0) {
            extraData = uint96(_bound(_random(), 0, type(uint96).max));
            token.setExtraData(id, extraData);
            setExtraData = true;
        }

        vm.expectEmit(true, true, true, true);
        emit Transfer(owner1, address(0), id);
        token.burn(id);
        if (setExtraData) {
            assertEq(token.getExtraData(id), extraData);
        } else {
            assertEq(token.getExtraData(id), 0);
        }
        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        token.ownerOf(id);
    }

    function testExtraData2(uint256) public {
        uint256 id0 = _random();
        uint256 id1 = _random();
        while (id0 == id1) id1 = _random();
        uint96 extraData0 = uint96(_bound(_random(), 0, type(uint96).max));
        uint96 extraData1 = uint96(_bound(_random(), 0, type(uint96).max));
        token.setExtraData(id0, extraData0);
        token.setExtraData(id1, extraData1);
        assertEq(token.getExtraData(id0), extraData0);
        assertEq(token.getExtraData(id1), extraData1);
    }

    function testAux(uint256) public {
        (address owner0,) = _randomSigner();
        (address owner1,) = _randomSigner();
        while (owner0 == owner1) (owner1,) = _randomSigner();

        bool setAux = _random() % 2 == 0;
        uint224 aux0 = uint224(_bound(_random(), 0, type(uint224).max));
        uint224 aux1 = uint224(_bound(_random(), 0, type(uint224).max));
        if (setAux) {
            token.setAux(owner0, aux0);
            token.setAux(owner1, aux1);
        }

        for (uint256 i; i < 2; ++i) {
            vm.expectEmit(true, true, true, true);
            emit Transfer(address(0), owner0, i * 2 + 0);
            token.mint(owner0, i * 2 + 0);
            assertEq(token.balanceOf(owner0), i + 1);

            vm.expectEmit(true, true, true, true);
            emit Transfer(address(0), owner1, i * 2 + 1);
            token.mint(owner1, i * 2 + 1);
            assertEq(token.balanceOf(owner1), i + 1);

            if (setAux) {
                assertEq(token.getAux(owner0), aux0);
                assertEq(token.getAux(owner1), aux1);
            } else {
                assertEq(token.getAux(owner0), 0);
                assertEq(token.getAux(owner1), 0);
            }
        }

        for (uint256 i; i < 2; ++i) {
            vm.expectEmit(true, true, true, true);
            emit Transfer(owner0, address(0), i * 2 + 0);
            token.burn(i * 2 + 0);
            assertEq(token.balanceOf(owner0), 1 - i);

            vm.expectEmit(true, true, true, true);
            emit Transfer(owner1, address(0), i * 2 + 1);
            token.burn(i * 2 + 1);
            assertEq(token.balanceOf(owner1), 1 - i);

            if (setAux) {
                assertEq(token.getAux(owner0), aux0);
                assertEq(token.getAux(owner1), aux1);
            } else {
                assertEq(token.getAux(owner0), 0);
                assertEq(token.getAux(owner1), 0);
            }
        }
    }

    function testApprove(address to, uint256 id) public {
        if (to == address(0)) to = address(0xBEEF);

        token.mint(address(this), id);

        if (_random() % 2 == 0) {
            vm.expectEmit(true, true, true, true);
            emit Approval(address(this), to, id);
            token.approve(to, id);
            assertEq(token.getApproved(id), to);
        } else {
            vm.expectEmit(true, true, true, true);
            emit Approval(address(this), to, id);
            token.directApprove(to, id);
            assertEq(token.getApproved(id), to);
        }
    }

    function testApproveBurn(address to, uint256 id) public {
        token.mint(address(this), id);

        token.approve(address(to), id);

        token.burn(id);

        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.getApproved(id), address(0));

        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        token.ownerOf(id);
    }

    function testApproveAll(address to, bool approved) public {
        if (_random() % 2 == 0) {
            vm.expectEmit(true, true, true, true);
            emit ApprovalForAll(address(this), to, approved);
            token.setApprovalForAll(to, approved);
            assertEq(token.isApprovedForAll(address(this), to), approved);
        } else {
            vm.expectEmit(true, true, true, true);
            emit ApprovalForAll(address(this), to, approved);
            token.directSetApprovalForAll(to, approved);
            assertEq(token.isApprovedForAll(address(this), to), approved);
        }
    }

    function testTransferFrom(uint256 id, address to) public {
        address from = address(0xABCD);

        if (to == address(0) || to == from) to = address(0xBEEF);

        token.mint(from, id);

        vm.prank(from);
        token.approve(address(this), id);

        if (_random() % 2 == 0) {
            vm.expectEmit(true, true, true, true);
            emit Transfer(from, to, id);
            token.transferFrom(from, to, id);
        } else {
            vm.expectEmit(true, true, true, true);
            emit Transfer(from, to, id);
            token.directTransferFrom(from, to, id);
        }

        assertEq(token.getApproved(id), address(0));
        assertEq(token.ownerOf(id), to);
        assertEq(token.balanceOf(to), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testTransferFromSelf(uint256 id, address to) public {
        if (to == address(0) || to == address(this)) to = address(0xBEEF);

        token.mint(address(this), id);

        token.transferFrom(address(this), to, id);

        assertEq(token.getApproved(id), address(0));
        assertEq(token.ownerOf(id), to);
        assertEq(token.balanceOf(to), 1);
        assertEq(token.balanceOf(address(this)), 0);
    }

    function testTransferFromApproveAll(uint256 id, address to) public {
        address from = address(0xABCD);

        if (to == address(0) || to == from) to = address(0xBEEF);

        token.mint(from, id);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.transferFrom(from, to, id);

        assertEq(token.getApproved(id), address(0));
        assertEq(token.ownerOf(id), to);
        assertEq(token.balanceOf(to), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testSafeTransferFromToEOA(uint256 id, address to) public {
        address from = address(0xABCD);

        if (to == address(0) || to == from) to = address(0xBEEF);

        if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;

        token.mint(from, id);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, to, id);

        assertEq(token.getApproved(id), address(0));
        assertEq(token.ownerOf(id), to);
        assertEq(token.balanceOf(to), 1);
        assertEq(token.balanceOf(from), 0);
    }

    function testSafeTransferFromToERC721Recipient(uint256 id) public {
        address from = address(0xABCD);

        ERC721Recipient recipient = new ERC721Recipient();

        token.mint(from, id);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, address(recipient), id);

        assertEq(token.getApproved(id), address(0));
        assertEq(token.ownerOf(id), address(recipient));
        assertEq(token.balanceOf(address(recipient)), 1);
        assertEq(token.balanceOf(from), 0);

        assertEq(recipient.operator(), address(this));
        assertEq(recipient.from(), from);
        assertEq(recipient.id(), id);
        assertEq(recipient.data(), "");
    }

    function testSafeTransferFromToERC721RecipientWithData(uint256 id, bytes calldata data)
        public
    {
        address from = address(0xABCD);
        ERC721Recipient recipient = new ERC721Recipient();

        token.mint(from, id);

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, address(recipient), id, data);

        assertEq(token.getApproved(id), address(0));
        assertEq(token.ownerOf(id), address(recipient));
        assertEq(token.balanceOf(address(recipient)), 1);
        assertEq(token.balanceOf(from), 0);

        assertEq(recipient.operator(), address(this));
        assertEq(recipient.from(), from);
        assertEq(recipient.id(), id);
        assertEq(recipient.data(), data);
    }

    function testSafeMintToEOA(uint256 id, address to) public {
        if (to == address(0)) to = address(0xBEEF);

        if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;

        token.safeMint(to, id);

        assertEq(token.ownerOf(id), address(to));
        assertEq(token.balanceOf(address(to)), 1);
    }

    function testSafeMintToERC721Recipient(uint256 id) public {
        ERC721Recipient to = new ERC721Recipient();

        token.safeMint(address(to), id);

        assertEq(token.ownerOf(id), address(to));
        assertEq(token.balanceOf(address(to)), 1);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), id);
        assertEq(to.data(), "");
    }

    function testSafeMintToERC721RecipientWithData(uint256 id, bytes calldata data) public {
        ERC721Recipient to = new ERC721Recipient();

        token.safeMint(address(to), id, data);

        assertEq(token.ownerOf(id), address(to));
        assertEq(token.balanceOf(address(to)), 1);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), id);
        assertEq(to.data(), data);
    }

    function testMintToZeroReverts(uint256 id) public {
        vm.expectRevert(ERC721.TransferToZeroAddress.selector);
        token.mint(address(0), id);
    }

    function testDoubleMintReverts(uint256 id, address to) public {
        if (to == address(0)) to = address(0xBEEF);

        token.mint(to, id);
        vm.expectRevert(ERC721.TokenAlreadyExists.selector);
        token.mint(to, id);
    }

    function testBurnNonExistentReverts(uint256 id) public {
        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        token.burn(id);
    }

    function testDoubleBurnReverts(uint256 id, address to) public {
        if (to == address(0)) to = address(0xBEEF);

        token.mint(to, id);

        token.burn(id);
        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        token.burn(id);
    }

    function testApproveNonExistentReverts(uint256 id, address to) public {
        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        token.approve(to, id);
    }

    function testApproveUnauthorizedReverts(address owner, uint256 id, address to) public {
        if (owner == address(0) || owner == address(this)) owner = address(0xBEEF);

        token.mint(owner, id);
        vm.expectRevert(ERC721.NotOwnerNorApproved.selector);
        token.approve(to, id);
    }

    function testTransferFromNotExistentReverts(address from, address to, uint256 id) public {
        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        token.transferFrom(from, to, id);
    }

    function testTransferFromWrongFromReverts(address to, uint256 id) public {
        (address owner,) = _randomSigner();
        (address from,) = _randomSigner();
        while (owner == from) (from,) = _randomSigner();

        token.mint(owner, id);
        vm.expectRevert(ERC721.TransferFromIncorrectOwner.selector);
        token.transferFrom(from, to, id);
    }

    function testTransferFromToZeroReverts(uint256 id) public {
        token.mint(address(this), id);

        vm.expectRevert(ERC721.TransferToZeroAddress.selector);
        token.transferFrom(address(this), address(0), id);
    }

    function testTransferFromNotOwner(uint256 id) public {
        (address from,) = _randomSigner();
        (address to,) = _randomSigner();

        token.mint(from, id);

        vm.expectRevert(ERC721.NotOwnerNorApproved.selector);
        token.transferFrom(from, to, id);
    }

    function testSafeTransferFromToNonERC721RecipientReverts(uint256 id) public {
        token.mint(address(this), id);
        address to = address(new NonERC721Recipient());
        vm.expectRevert(ERC721.TransferToNonERC721ReceiverImplementer.selector);
        token.safeTransferFrom(address(this), address(to), id);
    }

    function testSafeTransferFromToNonERC721RecipientWithDataReverts(
        uint256 id,
        bytes calldata data
    ) public {
        token.mint(address(this), id);
        address to = address(new NonERC721Recipient());
        vm.expectRevert(ERC721.TransferToNonERC721ReceiverImplementer.selector);
        token.safeTransferFrom(address(this), to, id, data);
    }

    function testSafeTransferFromToRevertingERC721RecipientReverts(uint256 id) public {
        token.mint(address(this), id);
        address to = address(new RevertingERC721Recipient());
        vm.expectRevert(abi.encodePacked(ERC721TokenReceiver.onERC721Received.selector));
        token.safeTransferFrom(address(this), to, id);
    }

    function testSafeTransferFromToRevertingERC721RecipientWithDataReverts(
        uint256 id,
        bytes calldata data
    ) public {
        token.mint(address(this), id);
        address to = address(new RevertingERC721Recipient());
        vm.expectRevert(abi.encodePacked(ERC721TokenReceiver.onERC721Received.selector));
        token.safeTransferFrom(address(this), to, id, data);
    }

    function testSafeTransferFromToERC721RecipientWithWrongReturnDataReverts(uint256 id) public {
        token.mint(address(this), id);
        address to = address(new WrongReturnDataERC721Recipient());
        vm.expectRevert(ERC721.TransferToNonERC721ReceiverImplementer.selector);
        token.safeTransferFrom(address(this), to, id);
    }

    function testSafeTransferFromToERC721RecipientWithWrongReturnDataWithDataReverts(
        uint256 id,
        bytes calldata data
    ) public {
        token.mint(address(this), id);
        address to = address(new WrongReturnDataERC721Recipient());
        vm.expectRevert(ERC721.TransferToNonERC721ReceiverImplementer.selector);
        token.safeTransferFrom(address(this), to, id, data);
    }

    function testSafeMintToNonERC721RecipientReverts(uint256 id) public {
        address to = address(new NonERC721Recipient());
        vm.expectRevert(ERC721.TransferToNonERC721ReceiverImplementer.selector);
        token.safeMint(to, id);
    }

    function testSafeMintToNonERC721RecipientWithDataReverts(uint256 id, bytes calldata data)
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

    function testSafeMintToRevertingERC721RecipientWithDataReverts(uint256 id, bytes calldata data)
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

    function testSafeMintToERC721RecipientWithWrongReturnDataWithData(
        uint256 id,
        bytes calldata data
    ) public {
        address to = address(new WrongReturnDataERC721Recipient());
        vm.expectRevert(ERC721.TransferToNonERC721ReceiverImplementer.selector);
        token.safeMint(to, id, data);
    }

    function testOwnerOfNonExistent(uint256 id) public {
        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        token.ownerOf(id);
    }
}
