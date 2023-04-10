// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/TestPlus.sol";

import {ERC1155, MockERC1155} from "./utils/mocks/MockERC1155.sol";

abstract contract ERC1155TokenReceiver {
    function onERC1155Received(address, address, uint256, uint256, bytes calldata)
        external
        virtual
        returns (bytes4)
    {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

contract ERC1155Recipient is ERC1155TokenReceiver {
    address public operator;
    address public from;
    uint256 public id;
    uint256 public amount;
    bytes public mintData;

    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) public override returns (bytes4) {
        operator = _operator;
        from = _from;
        id = _id;
        amount = _amount;
        mintData = _data;

        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    address public batchOperator;
    address public batchFrom;
    uint256[] internal _batchIds;
    uint256[] internal _batchAmounts;
    bytes public batchData;

    function batchIds() external view returns (uint256[] memory) {
        return _batchIds;
    }

    function batchAmounts() external view returns (uint256[] memory) {
        return _batchAmounts;
    }

    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external override returns (bytes4) {
        batchOperator = _operator;
        batchFrom = _from;
        _batchIds = _ids;
        _batchAmounts = _amounts;
        batchData = _data;

        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

contract RevertingERC1155Recipient is ERC1155TokenReceiver {
    function onERC1155Received(address, address, uint256, uint256, bytes calldata)
        public
        pure
        override
        returns (bytes4)
    {
        revert(string(abi.encodePacked(ERC1155TokenReceiver.onERC1155Received.selector)));
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        revert(string(abi.encodePacked(ERC1155TokenReceiver.onERC1155BatchReceived.selector)));
    }
}

contract WrongReturnDataERC1155Recipient is ERC1155TokenReceiver {
    function onERC1155Received(address, address, uint256, uint256, bytes calldata)
        public
        pure
        override
        returns (bytes4)
    {
        return 0xCAFEBEEF;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0xCAFEBEEF;
    }
}

contract NonERC1155Recipient {}

contract ERC1155Test is TestPlus, ERC1155TokenReceiver {
    MockERC1155 token;

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    mapping(address => mapping(uint256 => uint256)) public userMintAmounts;
    mapping(address => mapping(uint256 => uint256)) public userTransferOrBurnAmounts;

    struct _TestTemps {
        address from;
        address to;
        uint256 n;
        uint256[] ids;
        uint256[] mintAmounts;
        uint256[] transferAmounts;
        uint256[] burnAmounts;
        uint256 id;
        uint256 mintAmount;
        uint256 transferAmount;
        uint256 burnAmount;
        bytes mintData;
        bytes burnData;
        bytes transferData;
    }

    function _randomBytes() internal returns (bytes memory b) {
        uint256 n = _random() % 64;
        uint256 r0 = _random();
        uint256 r1 = _random();
        /// @solidity memory-safe-assembly
        assembly {
            b := mload(0x40)
            mstore(b, n)
            mstore(add(b, 0x20), r0)
            mstore(add(b, 0x40), r1)
            mstore(0x40, add(b, 0x60))
        }
    }

    function _randomArray(uint256 n) internal returns (uint256[] memory a) {
        /// @solidity memory-safe-assembly
        assembly {
            a := mload(0x40)
            mstore(a, n)
            mstore(0x40, add(add(a, 0x20), shl(5, n)))
        }
        unchecked {
            for (uint256 i; i != n; ++i) {
                a[i] = _random();
            }
        }
    }

    function _testTemps() internal returns (_TestTemps memory t) {
        unchecked {
            (t.from,) = _randomSigner();
            (t.to,) = _randomSigner();
            while (t.from == t.to) (t.to,) = _randomSigner();
            uint256 n = _random() % 8;
            t.n = n;
            t.ids = _randomArray(n);
            t.mintAmounts = _randomArray(n);
            t.transferAmounts = _randomArray(n);
            t.burnAmounts = _randomArray(n);
            t.mintData = _randomBytes();
            t.burnData = _randomBytes();
            t.transferData = _randomBytes();
            t.id = _random();
            t.transferAmount = _random();
            t.burnAmount = _random();
            t.mintAmount = _random();
        }
    }

    function _expectMintEvent(address to, uint256 id, uint256 amount) internal {
        _expectMintEvent(address(this), to, id, amount);
    }

    function _expectMintEvent(address operator, address to, uint256 id, uint256 amount) internal {
        _expectTransferEvent(operator, address(0), to, id, amount);
    }

    function _expectBurnEvent(address from, uint256 id, uint256 amount) internal {
        _expectBurnEvent(address(this), from, id, amount);
    }

    function _expectBurnEvent(address operator, address from, uint256 id, uint256 amount)
        internal
    {
        _expectTransferEvent(operator, from, address(0), id, amount);
    }

    function _expectTransferEvent(address from, address to, uint256 id, uint256 amount) internal {
        _expectTransferEvent(address(this), from, to, id, amount);
    }

    function _expectTransferEvent(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) internal {
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(operator, from, to, id, amount);
    }

    function _expectMintEvent(address to, uint256[] memory ids, uint256[] memory amounts)
        internal
    {
        _expectMintEvent(address(this), to, ids, amounts);
    }

    function _expectMintEvent(
        address operator,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        _expectTransferEvent(operator, address(0), to, ids, amounts);
    }

    function _expectBurnEvent(address from, uint256[] memory ids, uint256[] memory amounts)
        internal
    {
        _expectBurnEvent(address(this), from, ids, amounts);
    }

    function _expectBurnEvent(
        address operator,
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        _expectTransferEvent(operator, from, address(0), ids, amounts);
    }

    function _expectTransferEvent(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        _expectTransferEvent(address(this), from, to, ids, amounts);
    }

    function _expectTransferEvent(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        vm.expectEmit(true, true, true, true);
        emit TransferBatch(operator, from, to, ids, amounts);
    }

    function setUp() public {
        token = new MockERC1155();
    }

    function testMintToEOA() public {
        token.mint(address(0xBEEF), 1337, 1, "");

        assertEq(token.balanceOf(address(0xBEEF), 1337), 1);
    }

    function testMintToERC1155Recipient() public {
        ERC1155Recipient to = new ERC1155Recipient();

        token.mint(address(to), 1337, 1, "testing 123");

        assertEq(token.balanceOf(address(to), 1337), 1);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), 1337);
        assertEq(to.mintData(), "testing 123");
    }

    function testBatchMintToEOA() public {
        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory amounts = new uint256[](5);
        amounts[0] = 100;
        amounts[1] = 200;
        amounts[2] = 300;
        amounts[3] = 400;
        amounts[4] = 500;

        token.batchMint(address(0xBEEF), ids, amounts, "");

        assertEq(token.balanceOf(address(0xBEEF), 1337), 100);
        assertEq(token.balanceOf(address(0xBEEF), 1338), 200);
        assertEq(token.balanceOf(address(0xBEEF), 1339), 300);
        assertEq(token.balanceOf(address(0xBEEF), 1340), 400);
        assertEq(token.balanceOf(address(0xBEEF), 1341), 500);
    }

    function testBatchMintToERC1155Recipient() public {
        ERC1155Recipient to = new ERC1155Recipient();

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory amounts = new uint256[](5);
        amounts[0] = 100;
        amounts[1] = 200;
        amounts[2] = 300;
        amounts[3] = 400;
        amounts[4] = 500;

        token.batchMint(address(to), ids, amounts, "testing 123");

        assertEq(to.batchOperator(), address(this));
        assertEq(to.batchFrom(), address(0));
        assertEq(to.batchIds(), ids);
        assertEq(to.batchAmounts(), amounts);
        assertEq(to.batchData(), "testing 123");

        assertEq(token.balanceOf(address(to), 1337), 100);
        assertEq(token.balanceOf(address(to), 1338), 200);
        assertEq(token.balanceOf(address(to), 1339), 300);
        assertEq(token.balanceOf(address(to), 1340), 400);
        assertEq(token.balanceOf(address(to), 1341), 500);
    }

    function testBurn() public {
        token.mint(address(0xBEEF), 1337, 100, "");

        token.burn(address(0xBEEF), 1337, 70);

        assertEq(token.balanceOf(address(0xBEEF), 1337), 30);
    }

    function testBatchBurn() public {
        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        uint256[] memory burnAmounts = new uint256[](5);
        burnAmounts[0] = 50;
        burnAmounts[1] = 100;
        burnAmounts[2] = 150;
        burnAmounts[3] = 200;
        burnAmounts[4] = 250;

        token.batchMint(address(0xBEEF), ids, mintAmounts, "");

        token.batchBurn(address(0xBEEF), ids, burnAmounts);

        assertEq(token.balanceOf(address(0xBEEF), 1337), 50);
        assertEq(token.balanceOf(address(0xBEEF), 1338), 100);
        assertEq(token.balanceOf(address(0xBEEF), 1339), 150);
        assertEq(token.balanceOf(address(0xBEEF), 1340), 200);
        assertEq(token.balanceOf(address(0xBEEF), 1341), 250);
    }

    function testApproveAll() public {
        token.setApprovalForAll(address(0xBEEF), true);

        assertTrue(token.isApprovedForAll(address(this), address(0xBEEF)));
    }

    function testSafeTransferFromToEOA() public {
        address from = address(0xABCD);

        token.mint(from, 1337, 100, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, address(0xBEEF), 1337, 70, "");

        assertEq(token.balanceOf(address(0xBEEF), 1337), 70);
        assertEq(token.balanceOf(from, 1337), 30);
    }

    function testSafeTransferFromToERC1155Recipient() public {
        ERC1155Recipient to = new ERC1155Recipient();

        address from = address(0xABCD);

        token.mint(from, 1337, 100, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, address(to), 1337, 70, "testing 123");

        assertEq(to.operator(), address(this));
        assertEq(to.from(), from);
        assertEq(to.id(), 1337);
        assertEq(to.mintData(), "testing 123");

        assertEq(token.balanceOf(address(to), 1337), 70);
        assertEq(token.balanceOf(from, 1337), 30);
    }

    function testSafeTransferFromSelf() public {
        token.mint(address(this), 1337, 100, "");

        token.safeTransferFrom(address(this), address(0xBEEF), 1337, 70, "");

        assertEq(token.balanceOf(address(0xBEEF), 1337), 70);
        assertEq(token.balanceOf(address(this), 1337), 30);
    }

    function testSafeBatchTransferFromToEOA() public {
        address from = address(0xABCD);

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        uint256[] memory transferAmounts = new uint256[](5);
        transferAmounts[0] = 50;
        transferAmounts[1] = 100;
        transferAmounts[2] = 150;
        transferAmounts[3] = 200;
        transferAmounts[4] = 250;

        token.batchMint(from, ids, mintAmounts, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeBatchTransferFrom(from, address(0xBEEF), ids, transferAmounts, "");

        assertEq(token.balanceOf(from, 1337), 50);
        assertEq(token.balanceOf(address(0xBEEF), 1337), 50);

        assertEq(token.balanceOf(from, 1338), 100);
        assertEq(token.balanceOf(address(0xBEEF), 1338), 100);

        assertEq(token.balanceOf(from, 1339), 150);
        assertEq(token.balanceOf(address(0xBEEF), 1339), 150);

        assertEq(token.balanceOf(from, 1340), 200);
        assertEq(token.balanceOf(address(0xBEEF), 1340), 200);

        assertEq(token.balanceOf(from, 1341), 250);
        assertEq(token.balanceOf(address(0xBEEF), 1341), 250);
    }

    function testSafeBatchTransferFromToERC1155Recipient() public {
        address from = address(0xABCD);

        ERC1155Recipient to = new ERC1155Recipient();

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        uint256[] memory transferAmounts = new uint256[](5);
        transferAmounts[0] = 50;
        transferAmounts[1] = 100;
        transferAmounts[2] = 150;
        transferAmounts[3] = 200;
        transferAmounts[4] = 250;

        token.batchMint(from, ids, mintAmounts, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeBatchTransferFrom(from, address(to), ids, transferAmounts, "testing 123");

        assertEq(to.batchOperator(), address(this));
        assertEq(to.batchFrom(), from);
        assertEq(to.batchIds(), ids);
        assertEq(to.batchAmounts(), transferAmounts);
        assertEq(to.batchData(), "testing 123");

        assertEq(token.balanceOf(from, 1337), 50);
        assertEq(token.balanceOf(address(to), 1337), 50);

        assertEq(token.balanceOf(from, 1338), 100);
        assertEq(token.balanceOf(address(to), 1338), 100);

        assertEq(token.balanceOf(from, 1339), 150);
        assertEq(token.balanceOf(address(to), 1339), 150);

        assertEq(token.balanceOf(from, 1340), 200);
        assertEq(token.balanceOf(address(to), 1340), 200);

        assertEq(token.balanceOf(from, 1341), 250);
        assertEq(token.balanceOf(address(to), 1341), 250);
    }

    function testBatchBalanceOf() public {
        address[] memory tos = new address[](5);
        tos[0] = address(0xBEEF);
        tos[1] = address(0xCAFE);
        tos[2] = address(0xFACE);
        tos[3] = address(0xDEAD);
        tos[4] = address(0xFEED);

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        token.mint(address(0xBEEF), 1337, 100, "");
        token.mint(address(0xCAFE), 1338, 200, "");
        token.mint(address(0xFACE), 1339, 300, "");
        token.mint(address(0xDEAD), 1340, 400, "");
        token.mint(address(0xFEED), 1341, 500, "");

        uint256[] memory balances = token.balanceOfBatch(tos, ids);

        assertEq(balances[0], 100);
        assertEq(balances[1], 200);
        assertEq(balances[2], 300);
        assertEq(balances[3], 400);
        assertEq(balances[4], 500);
    }

    function testFailMintToZero() public {
        token.mint(address(0), 1337, 1, "");
    }

    function testFailMintToNonERC155Recipient() public {
        token.mint(address(new NonERC1155Recipient()), 1337, 1, "");
    }

    function testFailMintToRevertingERC155Recipient() public {
        token.mint(address(new RevertingERC1155Recipient()), 1337, 1, "");
    }

    function testFailMintToWrongReturnDataERC155Recipient() public {
        token.mint(address(new RevertingERC1155Recipient()), 1337, 1, "");
    }

    function testFailBurnInsufficientBalance() public {
        token.mint(address(0xBEEF), 1337, 70, "");
        token.burn(address(0xBEEF), 1337, 100);
    }

    function testFailSafeTransferFromInsufficientBalance() public {
        address from = address(0xABCD);

        token.mint(from, 1337, 70, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(from, address(0xBEEF), 1337, 100, "");
    }

    function testFailSafeTransferFromSelfInsufficientBalance() public {
        token.mint(address(this), 1337, 70, "");
        token.safeTransferFrom(address(this), address(0xBEEF), 1337, 100, "");
    }

    function testFailSafeTransferFromToZero() public {
        token.mint(address(this), 1337, 100, "");
        token.safeTransferFrom(address(this), address(0), 1337, 70, "");
    }

    function testFailSafeTransferFromToNonERC155Recipient() public {
        token.mint(address(this), 1337, 100, "");
        token.safeTransferFrom(address(this), address(new NonERC1155Recipient()), 1337, 70, "");
    }

    function testFailSafeTransferFromToRevertingERC1155Recipient() public {
        token.mint(address(this), 1337, 100, "");
        token.safeTransferFrom(
            address(this), address(new RevertingERC1155Recipient()), 1337, 70, ""
        );
    }

    function testFailSafeTransferFromToWrongReturnDataERC1155Recipient() public {
        token.mint(address(this), 1337, 100, "");
        token.safeTransferFrom(
            address(this), address(new WrongReturnDataERC1155Recipient()), 1337, 70, ""
        );
    }

    function testFailSafeBatchTransferInsufficientBalance() public {
        address from = address(0xABCD);

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);

        mintAmounts[0] = 50;
        mintAmounts[1] = 100;
        mintAmounts[2] = 150;
        mintAmounts[3] = 200;
        mintAmounts[4] = 250;

        uint256[] memory transferAmounts = new uint256[](5);
        transferAmounts[0] = 100;
        transferAmounts[1] = 200;
        transferAmounts[2] = 300;
        transferAmounts[3] = 400;
        transferAmounts[4] = 500;

        token.batchMint(from, ids, mintAmounts, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeBatchTransferFrom(from, address(0xBEEF), ids, transferAmounts, "");
    }

    function testFailSafeBatchTransferFromToZero() public {
        address from = address(0xABCD);

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        uint256[] memory transferAmounts = new uint256[](5);
        transferAmounts[0] = 50;
        transferAmounts[1] = 100;
        transferAmounts[2] = 150;
        transferAmounts[3] = 200;
        transferAmounts[4] = 250;

        token.batchMint(from, ids, mintAmounts, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeBatchTransferFrom(from, address(0), ids, transferAmounts, "");
    }

    function testFailSafeBatchTransferFromToNonERC1155Recipient() public {
        address from = address(0xABCD);

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        uint256[] memory transferAmounts = new uint256[](5);
        transferAmounts[0] = 50;
        transferAmounts[1] = 100;
        transferAmounts[2] = 150;
        transferAmounts[3] = 200;
        transferAmounts[4] = 250;

        token.batchMint(from, ids, mintAmounts, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeBatchTransferFrom(
            from, address(new NonERC1155Recipient()), ids, transferAmounts, ""
        );
    }

    function testFailSafeBatchTransferFromToRevertingERC1155Recipient() public {
        address from = address(0xABCD);

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        uint256[] memory transferAmounts = new uint256[](5);
        transferAmounts[0] = 50;
        transferAmounts[1] = 100;
        transferAmounts[2] = 150;
        transferAmounts[3] = 200;
        transferAmounts[4] = 250;

        token.batchMint(from, ids, mintAmounts, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeBatchTransferFrom(
            from, address(new RevertingERC1155Recipient()), ids, transferAmounts, ""
        );
    }

    function testFailSafeBatchTransferFromToWrongReturnDataERC1155Recipient() public {
        address from = address(0xABCD);

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        uint256[] memory transferAmounts = new uint256[](5);
        transferAmounts[0] = 50;
        transferAmounts[1] = 100;
        transferAmounts[2] = 150;
        transferAmounts[3] = 200;
        transferAmounts[4] = 250;

        token.batchMint(from, ids, mintAmounts, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeBatchTransferFrom(
            from, address(new WrongReturnDataERC1155Recipient()), ids, transferAmounts, ""
        );
    }

    function testFailSafeBatchTransferFromWithArrayLengthMismatch() public {
        address from = address(0xABCD);

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        uint256[] memory transferAmounts = new uint256[](4);
        transferAmounts[0] = 50;
        transferAmounts[1] = 100;
        transferAmounts[2] = 150;
        transferAmounts[3] = 200;

        token.batchMint(from, ids, mintAmounts, "");

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        token.safeBatchTransferFrom(from, address(0xBEEF), ids, transferAmounts, "");
    }

    function testFailBatchMintToZero() public {
        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        token.batchMint(address(0), ids, mintAmounts, "");
    }

    function testFailBatchMintToNonERC1155Recipient() public {
        NonERC1155Recipient to = new NonERC1155Recipient();

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        token.batchMint(address(to), ids, mintAmounts, "");
    }

    function testFailBatchMintToRevertingERC1155Recipient() public {
        RevertingERC1155Recipient to = new RevertingERC1155Recipient();

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        token.batchMint(address(to), ids, mintAmounts, "");
    }

    function testFailBatchMintToWrongReturnDataERC1155Recipient() public {
        WrongReturnDataERC1155Recipient to = new WrongReturnDataERC1155Recipient();

        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        token.batchMint(address(to), ids, mintAmounts, "");
    }

    function testFailBatchMintWithArrayMismatch() public {
        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 100;
        amounts[1] = 200;
        amounts[2] = 300;
        amounts[3] = 400;

        token.batchMint(address(0xBEEF), ids, amounts, "");
    }

    function testFailBatchBurnInsufficientBalance() public {
        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 50;
        mintAmounts[1] = 100;
        mintAmounts[2] = 150;
        mintAmounts[3] = 200;
        mintAmounts[4] = 250;

        uint256[] memory burnAmounts = new uint256[](5);
        burnAmounts[0] = 100;
        burnAmounts[1] = 200;
        burnAmounts[2] = 300;
        burnAmounts[3] = 400;
        burnAmounts[4] = 500;

        token.batchMint(address(0xBEEF), ids, mintAmounts, "");

        token.batchBurn(address(0xBEEF), ids, burnAmounts);
    }

    function testFailBatchBurnWithArrayLengthMismatch() public {
        uint256[] memory ids = new uint256[](5);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;
        ids[4] = 1341;

        uint256[] memory mintAmounts = new uint256[](5);
        mintAmounts[0] = 100;
        mintAmounts[1] = 200;
        mintAmounts[2] = 300;
        mintAmounts[3] = 400;
        mintAmounts[4] = 500;

        uint256[] memory burnAmounts = new uint256[](4);
        burnAmounts[0] = 50;
        burnAmounts[1] = 100;
        burnAmounts[2] = 150;
        burnAmounts[3] = 200;

        token.batchMint(address(0xBEEF), ids, mintAmounts, "");

        token.batchBurn(address(0xBEEF), ids, burnAmounts);
    }

    function testFailBalanceOfBatchWithArrayMismatch() public view {
        address[] memory tos = new address[](5);
        tos[0] = address(0xBEEF);
        tos[1] = address(0xCAFE);
        tos[2] = address(0xFACE);
        tos[3] = address(0xDEAD);
        tos[4] = address(0xFEED);

        uint256[] memory ids = new uint256[](4);
        ids[0] = 1337;
        ids[1] = 1338;
        ids[2] = 1339;
        ids[3] = 1340;

        token.balanceOfBatch(tos, ids);
    }

    function testMintToEOA(uint256) public {
        _TestTemps memory t = _testTemps();

        _expectMintEvent(t.to, t.id, t.mintAmount);
        token.mint(t.to, t.id, t.mintAmount, t.mintData);

        assertEq(token.balanceOf(t.to, t.id), t.mintAmount);
    }

    function testMintToERC1155Recipient(uint256) public {
        _TestTemps memory t = _testTemps();

        ERC1155Recipient to = new ERC1155Recipient();

        _expectMintEvent(address(to), t.id, t.mintAmount);
        token.mint(address(to), t.id, t.mintAmount, t.mintData);

        assertEq(token.balanceOf(address(to), t.id), t.mintAmount);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), t.id);
        assertEq(to.mintData(), t.mintData);
    }

    function testBatchMintToEOA(uint256) public {
        _TestTemps memory t = _testTemps();

        for (uint256 i = 0; i != t.n; i++) {
            uint256 id = t.ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[t.to][id];

            uint256 mintAmount = _bound(t.mintAmounts[i], 0, remainingMintAmountForId);

            t.mintAmounts[i] = mintAmount;

            userMintAmounts[t.to][id] += mintAmount;
        }

        _expectMintEvent(t.to, t.ids, t.mintAmounts);
        token.batchMint(t.to, t.ids, t.mintAmounts, t.mintData);

        for (uint256 i = 0; i != t.n; i++) {
            uint256 id = t.ids[i];

            assertEq(token.balanceOf(t.to, id), userMintAmounts[t.to][id]);
        }
    }

    function testBatchMintToERC1155Recipient(uint256) public {
        _TestTemps memory t = _testTemps();

        ERC1155Recipient to = new ERC1155Recipient();

        for (uint256 i = 0; i != t.n; i++) {
            uint256 id = t.ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[address(to)][id];

            uint256 mintAmount = _bound(t.mintAmounts[i], 0, remainingMintAmountForId);

            t.mintAmounts[i] = mintAmount;

            userMintAmounts[address(to)][id] += mintAmount;
        }

        _expectMintEvent(address(to), t.ids, t.mintAmounts);
        token.batchMint(address(to), t.ids, t.mintAmounts, t.mintData);

        assertEq(to.batchOperator(), address(this));
        assertEq(to.batchFrom(), address(0));
        assertEq(to.batchIds(), t.ids);
        assertEq(to.batchAmounts(), t.mintAmounts);
        assertEq(to.batchData(), t.mintData);

        for (uint256 i = 0; i != t.n; i++) {
            uint256 id = t.ids[i];

            assertEq(token.balanceOf(address(to), id), userMintAmounts[address(to)][id]);
        }
    }

    function testBurn(uint256) public {
        _TestTemps memory t = _testTemps();

        t.burnAmount = _bound(t.burnAmount, 0, t.mintAmount);

        _expectMintEvent(t.to, t.id, t.mintAmount);
        token.mint(t.to, t.id, t.mintAmount, t.mintData);

        _expectBurnEvent(t.to, t.id, t.burnAmount);
        token.burn(t.to, t.id, t.burnAmount);

        assertEq(token.balanceOf(t.to, t.id), t.mintAmount - t.burnAmount);
    }

    function testBatchBurn(uint256) public {
        _TestTemps memory t = _testTemps();

        for (uint256 i = 0; i != t.n; i++) {
            uint256 id = t.ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[t.to][id];

            t.mintAmounts[i] = _bound(t.mintAmounts[i], 0, remainingMintAmountForId);
            t.burnAmounts[i] = _bound(t.burnAmounts[i], 0, t.mintAmounts[i]);

            userMintAmounts[t.to][id] += t.mintAmounts[i];
            userTransferOrBurnAmounts[t.to][id] += t.burnAmounts[i];
        }

        _expectMintEvent(t.to, t.ids, t.mintAmounts);
        token.batchMint(t.to, t.ids, t.mintAmounts, t.mintData);
        _expectBurnEvent(t.to, t.ids, t.burnAmounts);
        token.batchBurn(t.to, t.ids, t.burnAmounts);

        for (uint256 i = 0; i < t.ids.length; i++) {
            uint256 id = t.ids[i];

            assertEq(
                token.balanceOf(t.to, id),
                userMintAmounts[t.to][id] - userTransferOrBurnAmounts[t.to][id]
            );
        }
    }

    function testApproveAll(address to, bool approved) public {
        token.setApprovalForAll(to, approved);

        assertEq(token.isApprovedForAll(address(this), to), approved);
    }

    function testSafeTransferFromToEOA(uint256) public {
        _TestTemps memory t = _testTemps();

        t.transferAmount = _bound(t.transferAmount, 0, t.mintAmount);

        _expectMintEvent(t.from, t.id, t.mintAmount);
        token.mint(t.from, t.id, t.mintAmount, t.mintData);

        vm.prank(t.from);
        token.setApprovalForAll(address(this), true);

        _expectTransferEvent(t.from, t.to, t.id, t.transferAmount);
        token.safeTransferFrom(t.from, t.to, t.id, t.transferAmount, t.transferData);

        if (t.to == t.from) {
            assertEq(token.balanceOf(t.to, t.id), t.mintAmount);
        } else {
            assertEq(token.balanceOf(t.to, t.id), t.transferAmount);
            assertEq(token.balanceOf(t.from, t.id), t.mintAmount - t.transferAmount);
        }
    }

    function testSafeTransferFromToERC1155Recipient(uint256) public {
        _TestTemps memory t = _testTemps();
        ERC1155Recipient to = new ERC1155Recipient();

        t.transferAmount = _bound(t.transferAmount, 0, t.mintAmount);

        _expectMintEvent(t.from, t.id, t.mintAmount);
        token.mint(t.from, t.id, t.mintAmount, t.mintData);

        vm.prank(t.from);
        token.setApprovalForAll(address(this), true);

        _expectTransferEvent(t.from, address(to), t.id, t.transferAmount);
        token.safeTransferFrom(t.from, address(to), t.id, t.transferAmount, t.transferData);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), t.from);
        assertEq(to.id(), t.id);
        assertEq(to.mintData(), t.transferData);

        assertEq(token.balanceOf(address(to), t.id), t.transferAmount);
        assertEq(token.balanceOf(t.from, t.id), t.mintAmount - t.transferAmount);
    }

    function testSafeTransferFromSelf(uint256) public {
        _TestTemps memory t = _testTemps();

        t.transferAmount = _bound(t.transferAmount, 0, t.mintAmount);

        _expectMintEvent(address(this), t.id, t.mintAmount);
        token.mint(address(this), t.id, t.mintAmount, t.mintData);

        _expectTransferEvent(address(this), t.to, t.id, t.transferAmount);
        token.safeTransferFrom(address(this), t.to, t.id, t.transferAmount, t.transferData);

        assertEq(token.balanceOf(t.to, t.id), t.transferAmount);
        assertEq(token.balanceOf(address(this), t.id), t.mintAmount - t.transferAmount);
    }

    function testSafeBatchTransferFromToEOA(uint256) public {
        _TestTemps memory t = _testTemps();

        for (uint256 i = 0; i != t.n; i++) {
            uint256 id = t.ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[t.from][id];

            uint256 mintAmount = _bound(t.mintAmounts[i], 0, remainingMintAmountForId);
            uint256 transferAmount = _bound(t.transferAmounts[i], 0, mintAmount);

            t.mintAmounts[i] = mintAmount;
            t.transferAmounts[i] = transferAmount;

            userMintAmounts[t.from][id] += mintAmount;
            userTransferOrBurnAmounts[t.from][id] += transferAmount;
        }
        _expectMintEvent(t.from, t.ids, t.mintAmounts);
        token.batchMint(t.from, t.ids, t.mintAmounts, t.mintData);

        vm.prank(t.from);
        token.setApprovalForAll(address(this), true);

        _expectTransferEvent(t.from, t.to, t.ids, t.transferAmounts);
        token.safeBatchTransferFrom(t.from, t.to, t.ids, t.transferAmounts, t.transferData);

        for (uint256 i = 0; i != t.n; i++) {
            uint256 id = t.ids[i];

            assertEq(token.balanceOf(t.to, id), userTransferOrBurnAmounts[t.from][id]);
            assertEq(
                token.balanceOf(t.from, id),
                userMintAmounts[t.from][id] - userTransferOrBurnAmounts[t.from][id]
            );
        }
    }

    function testSafeBatchTransferFromToERC1155Recipient(uint256) public {
        _TestTemps memory t = _testTemps();

        ERC1155Recipient to = new ERC1155Recipient();

        for (uint256 i = 0; i != t.n; i++) {
            uint256 id = t.ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[t.from][id];

            uint256 mintAmount = _bound(t.mintAmounts[i], 0, remainingMintAmountForId);
            uint256 transferAmount = _bound(t.transferAmounts[i], 0, mintAmount);

            t.mintAmounts[i] = mintAmount;
            t.transferAmounts[i] = transferAmount;

            userMintAmounts[t.from][id] += mintAmount;
            userTransferOrBurnAmounts[t.from][id] += transferAmount;
        }

        _expectMintEvent(t.from, t.ids, t.mintAmounts);
        token.batchMint(t.from, t.ids, t.mintAmounts, t.mintData);

        vm.prank(t.from);
        token.setApprovalForAll(address(this), true);

        _expectTransferEvent(t.from, address(to), t.ids, t.transferAmounts);
        token.safeBatchTransferFrom(t.from, address(to), t.ids, t.transferAmounts, t.transferData);

        assertEq(to.batchOperator(), address(this));
        assertEq(to.batchFrom(), t.from);
        assertEq(to.batchIds(), t.ids);
        assertEq(to.batchAmounts(), t.transferAmounts);
        assertEq(to.batchData(), t.transferData);

        for (uint256 i = 0; i != t.n; i++) {
            uint256 id = t.ids[i];
            uint256 transferAmount = userTransferOrBurnAmounts[t.from][id];

            assertEq(token.balanceOf(address(to), id), transferAmount);
            assertEq(token.balanceOf(t.from, id), userMintAmounts[t.from][id] - transferAmount);
        }
    }

    function testBatchBalanceOf(uint256) public {
        _TestTemps memory t = _testTemps();

        address[] memory tos = new address[](t.n);

        for (uint256 i = 0; i != t.n; i++) {
            uint256 id = t.ids[i];
            (address to,) = _randomSigner();
            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[to][id];

            tos[i] = to;

            uint256 mintAmount = _bound(t.mintAmounts[i], 0, remainingMintAmountForId);

            token.mint(to, id, mintAmount, t.mintData);

            userMintAmounts[to][id] += mintAmount;
        }

        uint256[] memory balances = token.balanceOfBatch(tos, t.ids);

        for (uint256 i = 0; i != t.n; i++) {
            assertEq(balances[i], token.balanceOf(tos[i], t.ids[i]));
        }
    }

    function testMintToZeroReverts(uint256) public {
        vm.expectRevert(ERC1155.TransferToZeroAddress.selector);
        token.mint(address(0), _random(), _random(), _randomBytes());
    }

    function testMintToNonERC155RecipientReverts(uint256) public {
        address to = address(new NonERC1155Recipient());
        vm.expectRevert(ERC1155.TransferToNonERC1155ReceiverImplementer.selector);
        token.mint(to, _random(), _random(), _randomBytes());
    }

    function testMintToRevertingERC155RecipientReverts(uint256) public {
        address to = address(new RevertingERC1155Recipient());
        vm.expectRevert(abi.encodePacked(ERC1155TokenReceiver.onERC1155Received.selector));
        token.mint(to, _random(), _random(), _randomBytes());
    }

    function testMintToWrongReturnDataERC155RecipientReverts(uint256) public {
        address to = address(new WrongReturnDataERC1155Recipient());
        vm.expectRevert(ERC1155.TransferToNonERC1155ReceiverImplementer.selector);
        token.mint(to, _random(), _random(), _randomBytes());
    }

    function testBurnInsufficientBalanceReverts(uint256) public {
        _TestTemps memory t = _testTemps();
        while (t.mintAmount == type(uint256).max) t.mintAmount = _random();
        t.burnAmount = _bound(t.burnAmount, t.mintAmount + 1, type(uint256).max);

        token.mint(t.to, t.id, t.mintAmount, t.mintData);

        vm.expectRevert(ERC1155.InsufficientBalance.selector);
        token.burn(t.to, t.id, t.burnAmount);
    }

    function testSafeTransferFromInsufficientBalanceReverts(uint256) public {
        _TestTemps memory t = _testTemps();
        while (t.mintAmount == type(uint256).max) t.mintAmount = _random();

        t.transferAmount = _bound(t.transferAmount, t.mintAmount + 1, type(uint256).max);

        token.mint(t.from, t.id, t.mintAmount, t.mintData);

        vm.prank(t.from);
        token.setApprovalForAll(address(this), true);

        vm.expectRevert(ERC1155.InsufficientBalance.selector);
        token.safeTransferFrom(t.from, t.to, t.id, t.transferAmount, t.transferData);
    }

    function testSafeTransferFromSelfInsufficientBalanceReverts(uint256) public {
        _TestTemps memory t = _testTemps();
        while (t.mintAmount == type(uint256).max) t.mintAmount = _random();

        t.transferAmount = _bound(t.transferAmount, t.mintAmount + 1, type(uint256).max);

        token.mint(address(this), t.id, t.mintAmount, t.mintData);

        vm.expectRevert(ERC1155.InsufficientBalance.selector);
        token.safeTransferFrom(address(this), t.to, t.id, t.transferAmount, t.transferData);
    }

    function testSafeTransferFromToZeroReverts(uint256) public {
        _TestTemps memory t = _testTemps();
        t.transferAmount = _bound(t.transferAmount, 0, t.mintAmount);

        token.mint(address(this), t.id, t.mintAmount, t.mintData);

        vm.expectRevert(ERC1155.TransferToZeroAddress.selector);
        token.safeTransferFrom(address(this), address(0), t.id, t.transferAmount, t.transferData);
    }

    function testSafeTransferFromToNonERC155RecipientReverts(uint256) public {
        _TestTemps memory t = _testTemps();
        t.transferAmount = _bound(t.transferAmount, 0, t.mintAmount);

        token.mint(address(this), t.id, t.mintAmount, t.mintData);
        t.to = address(new NonERC1155Recipient());

        vm.expectRevert(ERC1155.TransferToNonERC1155ReceiverImplementer.selector);
        token.safeTransferFrom(address(this), t.to, t.id, t.transferAmount, t.transferData);
    }

    function testSafeTransferFromToRevertingERC1155RecipientReverts(uint256) public {
        _TestTemps memory t = _testTemps();
        t.transferAmount = _bound(t.transferAmount, 0, t.mintAmount);

        token.mint(address(this), t.id, t.mintAmount, t.mintData);
        t.to = address(new RevertingERC1155Recipient());

        vm.expectRevert(abi.encodePacked(ERC1155TokenReceiver.onERC1155Received.selector));
        token.safeTransferFrom(address(this), t.to, t.id, t.transferAmount, t.transferData);
    }

    function testSafeTransferFromToWrongReturnDataERC1155RecipientReverts(uint256) public {
        _TestTemps memory t = _testTemps();
        t.transferAmount = _bound(t.transferAmount, 0, t.mintAmount);

        token.mint(address(this), t.id, t.mintAmount, t.mintData);
        t.to = address(new WrongReturnDataERC1155Recipient());

        vm.expectRevert(ERC1155.TransferToNonERC1155ReceiverImplementer.selector);
        token.safeTransferFrom(address(this), t.to, t.id, t.transferAmount, t.transferData);
    }

    function testSafeBatchTransferInsufficientBalanceReverts(uint256) public {
        _TestTemps memory t = _testTemps();

        while (t.n == 0) t = _testTemps();

        for (uint256 i = 0; i != t.n; i++) {
            uint256 id = t.ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[t.from][id];

            uint256 mintAmount = _bound(t.mintAmounts[i], 0, remainingMintAmountForId);
            if (mintAmount == type(uint256).max) return;
            uint256 transferAmount = _bound(t.transferAmounts[i], mintAmount + 1, type(uint256).max);

            t.mintAmounts[i] = mintAmount;
            t.transferAmounts[i] = transferAmount;

            userMintAmounts[t.from][id] += mintAmount;
        }

        token.batchMint(t.from, t.ids, t.mintAmounts, t.mintData);

        vm.prank(t.from);
        token.setApprovalForAll(address(this), true);

        vm.expectRevert(ERC1155.InsufficientBalance.selector);
        token.safeBatchTransferFrom(t.from, t.to, t.ids, t.transferAmounts, t.transferData);
    }

    function testSafeBatchTransferFromToZeroReverts(uint256) public {
        _TestTemps memory t = _testTemps();

        for (uint256 i = 0; i != t.n; i++) {
            uint256 id = t.ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[t.from][id];

            uint256 mintAmount = _bound(t.mintAmounts[i], 0, remainingMintAmountForId);
            uint256 transferAmount = _bound(t.transferAmounts[i], 0, mintAmount);

            t.mintAmounts[i] = mintAmount;
            t.transferAmounts[i] = transferAmount;

            userMintAmounts[t.from][id] += mintAmount;
        }

        token.batchMint(t.from, t.ids, t.mintAmounts, t.mintData);

        vm.prank(t.from);
        token.setApprovalForAll(address(this), true);

        vm.expectRevert(ERC1155.TransferToZeroAddress.selector);
        token.safeBatchTransferFrom(t.from, address(0), t.ids, t.transferAmounts, t.transferData);
    }

    function testSafeBatchTransferFromToNonERC1155RecipientReverts(uint256) public {
        _TestTemps memory t = _testTemps();

        for (uint256 i = 0; i != t.n; i++) {
            uint256 id = t.ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[t.from][id];

            uint256 mintAmount = _bound(t.mintAmounts[i], 0, remainingMintAmountForId);
            uint256 transferAmount = _bound(t.transferAmounts[i], 0, mintAmount);

            t.mintAmounts[i] = mintAmount;
            t.transferAmounts[i] = transferAmount;

            userMintAmounts[t.from][id] += mintAmount;
        }

        token.batchMint(t.from, t.ids, t.mintAmounts, t.mintData);

        vm.prank(t.from);
        token.setApprovalForAll(address(this), true);

        t.to = address(new NonERC1155Recipient());

        vm.expectRevert(ERC1155.TransferToNonERC1155ReceiverImplementer.selector);
        token.safeBatchTransferFrom(t.from, t.to, t.ids, t.transferAmounts, t.transferData);
    }

    function testSafeBatchTransferFromToRevertingERC1155RecipientReverts(uint256) public {
        _TestTemps memory t = _testTemps();

        for (uint256 i = 0; i != t.n; i++) {
            uint256 id = t.ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[t.from][id];

            uint256 mintAmount = _bound(t.mintAmounts[i], 0, remainingMintAmountForId);
            uint256 transferAmount = _bound(t.transferAmounts[i], 0, mintAmount);

            t.mintAmounts[i] = mintAmount;
            t.transferAmounts[i] = transferAmount;

            userMintAmounts[t.from][id] += mintAmount;
        }

        token.batchMint(t.from, t.ids, t.mintAmounts, t.mintData);

        vm.prank(t.from);
        token.setApprovalForAll(address(this), true);

        t.to = address(new RevertingERC1155Recipient());
        vm.expectRevert(abi.encodePacked(ERC1155TokenReceiver.onERC1155BatchReceived.selector));
        token.safeBatchTransferFrom(t.from, t.to, t.ids, t.transferAmounts, t.transferData);
    }

    function testSafeBatchTransferFromToWrongReturnDataERC1155RecipientReverts(uint256) public {
        _TestTemps memory t = _testTemps();

        for (uint256 i = 0; i != t.n; i++) {
            uint256 id = t.ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[t.from][id];

            uint256 mintAmount = _bound(t.mintAmounts[i], 0, remainingMintAmountForId);
            uint256 transferAmount = _bound(t.transferAmounts[i], 0, mintAmount);

            t.mintAmounts[i] = mintAmount;
            t.transferAmounts[i] = transferAmount;

            userMintAmounts[t.from][id] += mintAmount;
        }

        token.batchMint(t.from, t.ids, t.mintAmounts, t.mintData);

        vm.prank(t.from);
        token.setApprovalForAll(address(this), true);

        t.to = address(new WrongReturnDataERC1155Recipient());
        vm.expectRevert(ERC1155.TransferToNonERC1155ReceiverImplementer.selector);
        token.safeBatchTransferFrom(t.from, t.to, t.ids, t.transferAmounts, t.transferData);
    }

    function testSafeBatchTransferFromWithArrayLengthMismatchReverts(uint256) public {
        uint256[] memory ids = new uint256[](_random() % 4);
        uint256[] memory mintAmounts = new uint256[](_random() % 4);

        if (ids.length == mintAmounts.length) return;

        address from = address(0xABCD);

        vm.expectRevert(ERC1155.ArrayLengthsMismatch.selector);
        token.batchMint(from, ids, mintAmounts, _randomBytes());

        uint256[] memory transferAmounts = new uint256[](_random() % 4);
        if (ids.length == transferAmounts.length) return;

        vm.prank(from);
        token.setApprovalForAll(address(this), true);

        (address to,) = _randomSigner();

        vm.expectRevert(ERC1155.ArrayLengthsMismatch.selector);
        token.safeBatchTransferFrom(from, to, ids, transferAmounts, _randomBytes());
    }

    function testBatchMintToZeroReverts(uint256) public {
        _TestTemps memory t = _testTemps();

        for (uint256 i = 0; i != t.n; i++) {
            uint256 id = t.ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[address(0)][id];

            uint256 mintAmount = _bound(t.mintAmounts[i], 0, remainingMintAmountForId);

            t.mintAmounts[i] = mintAmount;

            userMintAmounts[address(0)][id] += mintAmount;
        }

        vm.expectRevert(ERC1155.TransferToZeroAddress.selector);
        token.batchMint(address(0), t.ids, t.mintAmounts, t.mintData);
    }

    function testBatchMintToNonERC1155RecipientReverts(uint256) public {
        _TestTemps memory t = _testTemps();

        NonERC1155Recipient to = new NonERC1155Recipient();

        for (uint256 i = 0; i != t.n; i++) {
            uint256 id = t.ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[address(to)][id];

            uint256 mintAmount = _bound(t.mintAmounts[i], 0, remainingMintAmountForId);

            t.mintAmounts[i] = mintAmount;

            userMintAmounts[address(to)][id] += mintAmount;
        }

        vm.expectRevert(ERC1155.TransferToNonERC1155ReceiverImplementer.selector);
        token.batchMint(address(to), t.ids, t.mintAmounts, t.mintData);
    }

    function testBatchMintToRevertingERC1155RecipientReverts(uint256) public {
        _TestTemps memory t = _testTemps();

        RevertingERC1155Recipient to = new RevertingERC1155Recipient();

        for (uint256 i = 0; i != t.n; i++) {
            uint256 id = t.ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[address(to)][id];

            uint256 mintAmount = _bound(t.mintAmounts[i], 0, remainingMintAmountForId);

            t.mintAmounts[i] = mintAmount;

            userMintAmounts[address(to)][id] += mintAmount;
        }
        vm.expectRevert(abi.encodePacked(ERC1155TokenReceiver.onERC1155BatchReceived.selector));
        token.batchMint(address(to), t.ids, t.mintAmounts, t.mintData);
    }

    function testBatchMintToWrongReturnDataERC1155RecipientReverts(uint256) public {
        _TestTemps memory t = _testTemps();

        WrongReturnDataERC1155Recipient to = new WrongReturnDataERC1155Recipient();

        for (uint256 i = 0; i != t.n; i++) {
            uint256 id = t.ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[address(to)][id];

            uint256 mintAmount = _bound(t.mintAmounts[i], 0, remainingMintAmountForId);

            t.mintAmounts[i] = mintAmount;

            userMintAmounts[address(to)][id] += mintAmount;
        }
        vm.expectRevert(ERC1155.TransferToNonERC1155ReceiverImplementer.selector);
        token.batchMint(address(to), t.ids, t.mintAmounts, t.mintData);
    }

    function testBatchMintWithArrayMismatchReverts(uint256) public {
        uint256[] memory ids = new uint256[](_random() % 4);
        uint256[] memory amounts = new uint256[](_random() % 4);

        if (ids.length == amounts.length) return;

        (address to,) = _randomSigner();

        vm.expectRevert(ERC1155.ArrayLengthsMismatch.selector);
        token.batchMint(to, ids, amounts, _randomBytes());
    }

    function testBatchBurnInsufficientBalanceReverts(uint256) public {
        _TestTemps memory t = _testTemps();

        while (t.n == 0) t = _testTemps();

        for (uint256 i = 0; i != t.n; i++) {
            uint256 id = t.ids[i];

            uint256 remainingMintAmountForId = type(uint256).max - userMintAmounts[t.to][id];

            t.mintAmounts[i] = _bound(t.mintAmounts[i], 0, remainingMintAmountForId);
            if (t.mintAmounts[i] == type(uint256).max) return;
            t.burnAmounts[i] = _bound(t.burnAmounts[i], t.mintAmounts[i] + 1, type(uint256).max);

            userMintAmounts[t.to][id] += t.mintAmounts[i];
        }

        token.batchMint(t.to, t.ids, t.mintAmounts, t.mintData);

        vm.expectRevert(ERC1155.InsufficientBalance.selector);
        token.batchBurn(t.to, t.ids, t.burnAmounts);
    }

    function testBatchBurnWithArrayLengthMismatchReverts(uint256) public {
        _TestTemps memory t = _testTemps();

        if (t.ids.length == t.burnAmounts.length) t.burnAmounts = _randomArray(t.n + 1);

        vm.expectRevert(ERC1155.ArrayLengthsMismatch.selector);
        token.batchBurn(t.to, t.ids, t.burnAmounts);
    }

    function testBalanceOfBatchWithArrayMismatch(uint256) public {
        address[] memory tos = new address[](_random() % 4);
        uint256[] memory ids = new uint256[](_random() % 4);
        if (tos.length == ids.length) return;

        vm.expectRevert(ERC1155.ArrayLengthsMismatch.selector);
        token.balanceOfBatch(tos, ids);
    }
}
