from wake.testing import *
from pytypes.tests.ERC1155Mock import ERC1155Mock, ERC1155ReceiverMock


@default_chain.connect()
def test_erc1155_misc():
    a = default_chain.accounts[0]

    erc1155 = ERC1155Mock.deploy(False, from_=a)

    # ERC-165
    assert erc1155.supportsInterface(bytes.fromhex("01ffc9a7"))
    # ERC-1155
    assert erc1155.supportsInterface(bytes.fromhex("d9b67a26"))
    # ERC-1155 Metadata URI
    assert erc1155.supportsInterface(bytes.fromhex("0e89341c"))

    assert not erc1155.supportsInterface(bytes.fromhex("deadbeef"))

    erc1155.mint(a, 0, 100, b"\x00\x11", from_=a)
    erc1155.setApprovalForAll(a, False, from_=a)
    assert not erc1155.isApprovedForAll(a, a)
    erc1155.safeTransferFrom(a, a, 0, 100, b"\x00\x11", from_=a)
    assert erc1155.balanceOf(a, 0) == 100

    # check overflow when sending to self
    erc1155.mint(a, 0, 2 ** 256 - 1 - 100, b"", from_=a)
    erc1155.safeTransferFrom(a, a, 0, 2 ** 256 - 1, b"", from_=a)
    assert erc1155.balanceOf(a, 0) == 2 ** 256 - 1


@default_chain.connect()
def test_erc1155_events():
    assert keccak256("TransferSingle(address,address,address,uint256,uint256)".encode()) == bytes.fromhex("c3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62")
    assert keccak256("TransferBatch(address,address,address,uint256[],uint256[])".encode()) == bytes.fromhex("4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb")
    assert keccak256("ApprovalForAll(address,address,bool)".encode()) == bytes.fromhex("17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31")

    a = default_chain.accounts[0]
    b = default_chain.accounts[1]

    erc1155 = ERC1155Mock.deploy(True, from_=a)

    tx = erc1155.mint(a, 0, 100, b"\x00\x11", from_=a)
    assert tx.events == [
        ERC1155Mock.BeforeTokenTransfer(Address.ZERO, a.address, [0], [100], bytearray(b"\x00\x11")),
        ERC1155Mock.TransferSingle(a.address, Address.ZERO, a.address, 0, 100),
        ERC1155Mock.AfterTokenTransfer(Address.ZERO, a.address, [0], [100], bytearray(b"\x00\x11")),
    ]

    tx = erc1155.burn(a, 0, 100, from_=a)
    assert tx.events == [
        ERC1155Mock.BeforeTokenTransfer(a.address, Address.ZERO, [0], [100], bytearray(b"")),
        ERC1155Mock.TransferSingle(a.address, a.address, Address.ZERO, 0, 100),
        ERC1155Mock.AfterTokenTransfer(a.address, Address.ZERO, [0], [100], bytearray(b"")),
    ]

    tx = erc1155.batchMint(a, [0, 1, 2], [100, 200, 300], b"\x11\x22", from_=a)
    assert tx.events == [
        ERC1155Mock.BeforeTokenTransfer(Address.ZERO, a.address, [0, 1, 2], [100, 200, 300], bytearray(b"\x11\x22")),
        ERC1155Mock.TransferBatch(a.address, Address.ZERO, a.address, [0, 1, 2], [100, 200, 300]),
        ERC1155Mock.AfterTokenTransfer(Address.ZERO, a.address, [0, 1, 2], [100, 200, 300], bytearray(b"\x11\x22")),
    ]

    tx = erc1155.batchBurn(a, [0, 1, 2], [100, 200, 300], from_=a)
    assert tx.events == [
        ERC1155Mock.BeforeTokenTransfer(a.address, Address.ZERO, [0, 1, 2], [100, 200, 300], bytearray(b"")),
        ERC1155Mock.TransferBatch(a.address, a.address, Address.ZERO, [0, 1, 2], [100, 200, 300]),
        ERC1155Mock.AfterTokenTransfer(a.address, Address.ZERO, [0, 1, 2], [100, 200, 300], bytearray(b"")),
    ]

    erc1155.mint(a, 0, 100, b"", from_=a)
    tx = erc1155.safeTransferFrom(a, b, 0, 100, b"", from_=a)
    assert tx.events == [
        ERC1155Mock.BeforeTokenTransfer(a.address, b.address, [0], [100], bytearray(b"")),
        ERC1155Mock.TransferSingle(a.address, a.address, b.address, 0, 100),
        ERC1155Mock.AfterTokenTransfer(a.address, b.address, [0], [100], bytearray(b"")),
    ]

    tx = erc1155.safeTransferFrom(b, b, 0, 100, b"\x33", from_=b)
    assert tx.events == [
        ERC1155Mock.BeforeTokenTransfer(b.address, b.address, [0], [100], bytearray(b"\x33")),
        ERC1155Mock.TransferSingle(b.address, b.address, b.address, 0, 100),
        ERC1155Mock.AfterTokenTransfer(b.address, b.address, [0], [100], bytearray(b"\x33")),
    ]

    erc1155.setApprovalForAll(a, True, from_=b)
    tx = erc1155.safeTransferFrom(b, a, 0, 100, b"", from_=a)
    assert tx.events == [
        ERC1155Mock.BeforeTokenTransfer(b.address, a.address, [0], [100], bytearray(b"")),
        ERC1155Mock.TransferSingle(a.address, b.address, a.address, 0, 100),
        ERC1155Mock.AfterTokenTransfer(b.address, a.address, [0], [100], bytearray(b"")),
    ]
    erc1155.setApprovalForAll(a, False, from_=b)

    erc1155.setApprovalForAll(b, True, from_=a)
    tx = erc1155.safeBatchTransferFrom(a, b, [0, 0, 0], [35, 30, 35], b"", from_=b)
    assert tx.events == [
        ERC1155Mock.BeforeTokenTransfer(a.address, b.address, [0, 0, 0], [35, 30, 35], bytearray(b"")),
        ERC1155Mock.TransferBatch(b.address, a.address, b.address, [0, 0, 0], [35, 30, 35]),
        ERC1155Mock.AfterTokenTransfer(a.address, b.address, [0, 0, 0], [35, 30, 35], bytearray(b"")),
    ]
    erc1155.setApprovalForAll(b, False, from_=a)

    erc1155.setApprovalForAll(a, True, from_=b)
    tx = erc1155.burn(b, 0, 100, from_=a)
    assert tx.events == [
        ERC1155Mock.BeforeTokenTransfer(b.address, Address.ZERO, [0], [100], bytearray(b"")),
        ERC1155Mock.TransferSingle(a.address, b.address, Address.ZERO, 0, 100),
        ERC1155Mock.AfterTokenTransfer(b.address, Address.ZERO, [0], [100], bytearray(b"")),
    ]

    assert erc1155.isApprovedForAll(a, b) == False
    tx = erc1155.setApprovalForAll(b, False, from_=a)
    assert tx.events == [ERC1155Mock.ApprovalForAll(a.address, b.address, False)]
    assert erc1155.isApprovedForAll(a, b) == False

    tx = erc1155.setApprovalForAll(b, True, from_=a)
    assert tx.events == [ERC1155Mock.ApprovalForAll(a.address, b.address, True)]
    assert erc1155.isApprovedForAll(a, b) == True

    tx = erc1155.setApprovalForAll(b, True, from_=a)
    assert tx.events == [ERC1155Mock.ApprovalForAll(a.address, b.address, True)]
    assert erc1155.isApprovedForAll(a, b) == True

    tx = erc1155.setApprovalForAll(b, False, from_=a)
    assert tx.events == [ERC1155Mock.ApprovalForAll(a.address, b.address, False)]
    assert erc1155.isApprovedForAll(a, b) == False

    c = default_chain.accounts[2]

    tx = erc1155.setApprovalForAllUnchecked(a, b, True, from_=c)
    assert tx.events == [ERC1155Mock.ApprovalForAll(a.address, b.address, True)]
    tx = erc1155.setApprovalForAllUnchecked(a, b, True, from_=c)
    assert tx.events == [ERC1155Mock.ApprovalForAll(a.address, b.address, True)]
    tx = erc1155.setApprovalForAllUnchecked(a, b, False, from_=c)
    assert tx.events == [ERC1155Mock.ApprovalForAll(a.address, b.address, False)]

    erc1155.batchMint(a, [0, 1, 2], [100, 200, 300], b"", from_=a)
    tx = erc1155.burnUnchecked(Address.ZERO, a, 2, 100, from_=c)
    assert tx.events == [
        ERC1155Mock.BeforeTokenTransfer(a.address, Address.ZERO, [2], [100], bytearray(b"")),
        ERC1155Mock.TransferSingle(c.address, a.address, Address.ZERO, 2, 100),
        ERC1155Mock.AfterTokenTransfer(a.address, Address.ZERO, [2], [100], bytearray(b"")),
    ]

    tx = erc1155.batchBurnUnchecked(Address.ZERO, a, [0, 1, 2], [100, 100, 100], from_=c)
    assert tx.events == [
        ERC1155Mock.BeforeTokenTransfer(a.address, Address.ZERO, [0, 1, 2], [100, 100, 100], bytearray(b"")),
        ERC1155Mock.TransferBatch(c.address, a.address, Address.ZERO, [0, 1, 2], [100, 100, 100]),
        ERC1155Mock.AfterTokenTransfer(a.address, Address.ZERO, [0, 1, 2], [100, 100, 100], bytearray(b"")),
    ]

    tx = erc1155.safeTransferUnchecked(Address.ZERO, a, b, 1, 50, b"\x11", from_=c)
    assert tx.events == [
        ERC1155Mock.BeforeTokenTransfer(a.address, b.address, [1], [50], bytearray(b"\x11")),
        ERC1155Mock.TransferSingle(c.address, a.address, b.address, 1, 50),
        ERC1155Mock.AfterTokenTransfer(a.address, b.address, [1], [50], bytearray(b"\x11")),
    ]

    tx = erc1155.safeBatchTransferUnchecked(Address.ZERO, a, b, [0, 1, 2], [0, 50, 0], b"\x22", from_=c)
    assert tx.events == [
        ERC1155Mock.BeforeTokenTransfer(a.address, b.address, [0, 1, 2], [0, 50, 0], bytearray(b"\x22")),
        ERC1155Mock.TransferBatch(c.address, a.address, b.address, [0, 1, 2], [0, 50, 0]),
        ERC1155Mock.AfterTokenTransfer(a.address, b.address, [0, 1, 2], [0, 50, 0], bytearray(b"\x22")),
    ]


@default_chain.connect()
def test_erc1155_mint_burn():
    a = default_chain.accounts[0]
    b = default_chain.accounts[1]

    erc1155 = ERC1155Mock.deploy(False, from_=a)

    assert erc1155.balanceOfBatch([], []) == []

    erc1155.mint(b, 0, 100, b"", from_=a)
    assert erc1155.balanceOf(b, 0) == 100

    erc1155.burn(b, 0, 50, from_=b)
    assert erc1155.balanceOf(b, 0) == 50

    # b is not owner nor approved
    with must_revert(UnknownTransactionRevertedError(ERC1155Mock.NotOwnerNorApproved.selector)):
        erc1155.burn(b, 0, 50, from_=a)

    # insufficient balance
    with must_revert(UnknownTransactionRevertedError(ERC1155Mock.InsufficientBalance.selector)):
        erc1155.burn(b, 0, 51, from_=b)

    erc1155.burn(b, 0, 50, from_=b)
    assert erc1155.balanceOf(b, 0) == 0

    # mint to zero address
    with must_revert(UnknownTransactionRevertedError(ERC1155Mock.TransferToZeroAddress.selector)):
        erc1155.mint(Address.ZERO, 0, 100, b"", from_=a)

    # balance overflow
    erc1155.mint(b, 0, 2 ** 256 - 1, b"", from_=a)
    assert erc1155.balanceOf(b, 0) == 2 ** 256 - 1
    with must_revert(UnknownTransactionRevertedError(ERC1155Mock.AccountBalanceOverflow.selector)):
        erc1155.mint(b, 0, 1, b"", from_=a)
    erc1155.burn(b, 0, 2 ** 256 - 1, from_=b)

    # ids and amounts length mismatch
    with must_revert(ERC1155Mock.ArrayLengthsMismatch):
        erc1155.batchMint(b, [0, 1], [100], b"", from_=a)

    # ids and amounts length mismatch
    with must_revert(ERC1155Mock.ArrayLengthsMismatch):
        erc1155.batchBurn(b, [0, 1], [100], from_=a)

    # mint to zero address
    with must_revert(UnknownTransactionRevertedError(ERC1155Mock.TransferToZeroAddress.selector)):
        erc1155.batchMint(Address.ZERO, [0, 1], [100, 200], b"", from_=a)

    # balance overflow
    with must_revert(UnknownTransactionRevertedError(ERC1155Mock.AccountBalanceOverflow.selector)):
        erc1155.batchMint(b, [0, 1, 0], [2 ** 256 - 1, 1, 1], b"", from_=a)

    # not owner nor approved
    with must_revert(UnknownTransactionRevertedError(ERC1155Mock.NotOwnerNorApproved.selector)):
        erc1155.batchBurn(b, [0, 1, 0], [1, 1, 1], from_=a)

    # insufficient balance
    erc1155.mint(b, 0, 100, b"", from_=a)
    erc1155.mint(b, 1, 1, b"", from_=a)
    assert erc1155.balanceOf(b, 0) == 100
    assert erc1155.balanceOf(b, 1) == 1
    with must_revert(UnknownTransactionRevertedError(ERC1155Mock.InsufficientBalance.selector)):
        erc1155.batchBurn(b, [0, 1, 0], [70, 1, 31], from_=b)
    erc1155.burn(b, 0, 100, from_=b)
    erc1155.burn(b, 1, 1, from_=b)
    assert erc1155.balanceOf(b, 0) == 0
    assert erc1155.balanceOf(b, 1) == 0


@default_chain.connect()
def test_erc1155_transfers():
    a = default_chain.accounts[0]
    b = default_chain.accounts[1]

    erc1155 = ERC1155Mock.deploy(False, from_=a)

    erc1155.mint(a, 0, 100, b"", from_=a)
    erc1155.mint(a, 1, 100, b"", from_=a)
    assert erc1155.balanceOf(a, 0) == 100
    assert erc1155.balanceOf(a, 1) == 100

    erc1155.safeTransferFrom(a, b, 0, 50, b"", from_=a)
    assert erc1155.balanceOf(a, 0) == 50
    assert erc1155.balanceOf(a, 1) == 100
    assert erc1155.balanceOf(b, 0) == 50
    assert erc1155.balanceOfBatch([a, a, b, a], [0, 1, 0, 2]) == [50, 100, 50, 0]

    erc1155.safeBatchTransferFrom(a, b, [], [], b"", from_=a)
    assert erc1155.balanceOfBatch([a, a, b, a], [0, 1, 0, 2]) == [50, 100, 50, 0]

    # owners and ids length mismatch
    with must_revert(ERC1155Mock.ArrayLengthsMismatch):
        assert erc1155.balanceOfBatch([a, a, b], [0, 1, 0, 2]) == [50, 100, 50, 0]

    # not owner nor approved
    with must_revert(UnknownTransactionRevertedError(ERC1155Mock.NotOwnerNorApproved.selector)):
        erc1155.safeTransferFrom(a, b, 0, 50, b"", from_=b)

    # insufficient balance
    with must_revert(UnknownTransactionRevertedError(ERC1155Mock.InsufficientBalance.selector)):
        erc1155.safeTransferFrom(a, b, 0, 51, b"", from_=a)

    # transfer to zero address
    with must_revert(UnknownTransactionRevertedError(ERC1155Mock.TransferToZeroAddress.selector)):
        erc1155.safeTransferFrom(a, Address.ZERO, 0, 50, b"", from_=a)

    # transfer to self
    erc1155.safeTransferFrom(a, a, 0, 50, b"", from_=a)
    assert erc1155.balanceOf(a, 0) == 50

    # balance overflow
    erc1155.mint(a, 0, 2 ** 256 - 1 - 50, b"", from_=a)
    with must_revert(UnknownTransactionRevertedError(ERC1155Mock.AccountBalanceOverflow.selector)):
        erc1155.safeTransferFrom(a, b, 0, 2 ** 256 - 1 - 49, b"", from_=a)

    # transfer to non-erc1155 receiver
    with must_revert(ERC1155Mock.TransferToNonERC1155ReceiverImplementer):
        erc1155.safeTransferFrom(a, erc1155, 0, 50, b"", from_=a)
    with must_revert(ERC1155Mock.TransferToNonERC1155ReceiverImplementer):
        erc1155.safeBatchTransferFrom(a, erc1155, [0], [50], b"", from_=a)

    # clear balances
    c = default_chain.accounts[2]
    assert erc1155.isApprovedForAll(a, c) is False
    erc1155.batchBurnUnchecked(Address.ZERO, a, [0, 1], [2 ** 256 - 1, 100], from_=c)
    erc1155.burnUnchecked(Address.ZERO, b, 0, 50, from_=c)

    erc1155.batchMint(a, [0, 1], [100, 100], b"", from_=a)
    erc1155.safeBatchTransferFrom(a, b, [0, 1], [70, 30], b"", from_=a)
    assert erc1155.balanceOfBatch([a, a, b, b], [0, 1, 0, 1]) == [30, 70, 70, 30]

    with must_revert(ERC1155Mock.ArrayLengthsMismatch()):
        erc1155.safeBatchTransferFrom(a, b, [0, 1], [30], b"", from_=a)

    with must_revert(UnknownTransactionRevertedError(ERC1155Mock.TransferToZeroAddress.selector)):
        erc1155.safeBatchTransferFrom(a, Address.ZERO, [0, 1], [30, 30], b"", from_=a)

    with must_revert(UnknownTransactionRevertedError(ERC1155Mock.NotOwnerNorApproved.selector)):
        erc1155.safeBatchTransferFrom(a, b, [0, 1], [30, 30], b"", from_=c)

    with must_revert(UnknownTransactionRevertedError(ERC1155Mock.InsufficientBalance.selector)):
        erc1155.safeBatchTransferFrom(a, b, [0, 1], [31, 30], b"", from_=a)

    erc1155.mint(a, 0, 2 ** 256 - 1 - 30, b"", from_=a)
    with must_revert(UnknownTransactionRevertedError(ERC1155Mock.AccountBalanceOverflow.selector)):
        erc1155.safeBatchTransferFrom(a, b, [0, 1], [2 ** 256 - 1 - 29, 30], b"", from_=a)


@default_chain.connect()
def test_erc1155_contract_receiver():
    a = default_chain.accounts[0]

    erc1155 = ERC1155Mock.deploy(False, from_=a)
    receiver = ERC1155ReceiverMock.deploy(from_=a)

    erc1155.mint(receiver, 0, 100, b"\x00\x11\x22\x33", from_=a)
    assert erc1155.balanceOf(receiver, 0) == 100

    with must_revert(Error("ERC1155ReceiverMock: invalid payload received")):
        erc1155.mint(receiver, 0, 100, b"", from_=a)

    erc1155.mint(a, 1, 100, b"", from_=a)
    erc1155.safeTransferFrom(a, receiver, 1, 50, b"\x00\x11\x22\x33", from_=a)
    assert erc1155.balanceOfBatch([receiver, receiver], [0, 1]) == [100, 50]

    with must_revert(Error("ERC1155ReceiverMock: invalid payload received")):
        erc1155.safeTransferFrom(a, receiver, 1, 50, b"\x00\x11\x22", from_=a)

    erc1155.safeBatchTransferFrom(a, receiver, [0, 1], [0, 50], b"\x00\x11\x22\x33", from_=a)
    assert erc1155.balanceOfBatch([receiver, receiver], [0, 1]) == [100, 100]

    with must_revert(Error("ERC1155ReceiverMock: invalid payload received")):
        erc1155.safeBatchTransferFrom(a, receiver, [0, 1], [0, 0], b"\x11\x22\x33", from_=a)

    erc1155.batchMint(receiver, [0, 1], [100, 100], b"\x00\x11\x22\x33", from_=a)
    assert erc1155.balanceOfBatch([receiver, receiver], [0, 1]) == [200, 200]

    with must_revert(Error("ERC1155ReceiverMock: invalid payload received")):
        erc1155.batchMint(receiver, [0, 1], [100, 100], b"", from_=a)


@default_chain.connect()
def test_erc1155_unchecked():
    a = default_chain.accounts[0]
    b = default_chain.accounts[1]
    c = default_chain.accounts[2]
    default_chain.set_default_accounts(c)

    erc1155 = ERC1155Mock.deploy(False, from_=a)

    erc1155.mint(a, 0, 100, b"", from_=c)
    assert erc1155.balanceOf(a, 0) == 100

    erc1155.safeBatchTransferUnchecked(Address.ZERO, a, b, [0], [100], b"", from_=c)
    assert erc1155.balanceOf(a, 0) == 0
    assert erc1155.balanceOf(b, 0) == 100

    erc1155.setApprovalForAllUnchecked(b, a, True, from_=c)
    erc1155.safeTransferUnchecked(a, b, a, 0, 100, b"", from_=c)
    assert erc1155.balanceOf(a, 0) == 100
    assert erc1155.balanceOf(b, 0) == 0

    erc1155.setApprovalForAllUnchecked(a, b, True, from_=c)
    erc1155.burnUnchecked(b, a, 0, 100, from_=c)
    assert erc1155.balanceOf(a, 0) == 0
    assert erc1155.balanceOf(b, 0) == 0

    erc1155.batchMint(a, [0, 1], [100, 100], b"", from_=c)
    erc1155.batchBurnUnchecked(b, a, [0, 1], [100, 100], from_=c)
    assert erc1155.balanceOf(a, 0) == 0
    assert erc1155.balanceOf(a, 1) == 0

    erc1155.setApprovalForAllUnchecked(a, b, False, from_=c)
    erc1155.setApprovalForAllUnchecked(b, a, False, from_=c)
    erc1155.mint(a, 0, 100, b"", from_=c)
    assert erc1155.balanceOf(a, 0) == 100

    with must_revert(UnknownTransactionRevertedError(ERC1155Mock.NotOwnerNorApproved.selector)):
        erc1155.safeTransferUnchecked(b, a, b, 0, 100, b"", from_=c)

    with must_revert(UnknownTransactionRevertedError(ERC1155Mock.NotOwnerNorApproved.selector)):
        erc1155.safeBatchTransferUnchecked(b, a, b, [0], [100], b"", from_=c)

    with must_revert(UnknownTransactionRevertedError(ERC1155Mock.TransferToZeroAddress.selector)):
        erc1155.safeTransferUnchecked(Address.ZERO, a, Address.ZERO, 0, 100, b"", from_=c)

    with must_revert(UnknownTransactionRevertedError(ERC1155Mock.TransferToZeroAddress.selector)):
        erc1155.safeTransferUnchecked(a, a, Address.ZERO, 0, 100, b"", from_=c)

    with must_revert(UnknownTransactionRevertedError(ERC1155Mock.TransferToZeroAddress.selector)):
        erc1155.safeBatchTransferUnchecked(Address.ZERO, a, Address.ZERO, [0], [100], b"", from_=c)

    with must_revert(UnknownTransactionRevertedError(ERC1155Mock.TransferToZeroAddress.selector)):
        erc1155.safeBatchTransferUnchecked(a, a, Address.ZERO, [0], [100], b"", from_=c)

    with must_revert(UnknownTransactionRevertedError(ERC1155Mock.InsufficientBalance.selector)):
        erc1155.safeTransferUnchecked(Address.ZERO, a, b, 0, 101, b"", from_=c)

    with must_revert(UnknownTransactionRevertedError(ERC1155Mock.InsufficientBalance.selector)):
        erc1155.safeTransferUnchecked(a, a, b, 0, 101, b"", from_=c)

    with must_revert(UnknownTransactionRevertedError(ERC1155Mock.InsufficientBalance.selector)):
        erc1155.safeBatchTransferUnchecked(Address.ZERO, a, b, [0], [101], b"", from_=c)

    with must_revert(UnknownTransactionRevertedError(ERC1155Mock.InsufficientBalance.selector)):
        erc1155.safeBatchTransferUnchecked(a, a, b, [0], [101], b"", from_=c)

    erc1155.mint(b, 0, 2 ** 256 - 10, b"", from_=c)

    with must_revert(UnknownTransactionRevertedError(ERC1155Mock.AccountBalanceOverflow.selector)):
        erc1155.safeTransferUnchecked(Address.ZERO, a, b, 0, 100, b"", from_=c)

    with must_revert(UnknownTransactionRevertedError(ERC1155Mock.AccountBalanceOverflow.selector)):
        erc1155.safeTransferUnchecked(a, a, b, 0, 100, b"", from_=c)

    with must_revert(UnknownTransactionRevertedError(ERC1155Mock.AccountBalanceOverflow.selector)):
        erc1155.safeBatchTransferUnchecked(Address.ZERO, a, b, [0, 0], [9, 21], b"", from_=c)

    with must_revert(UnknownTransactionRevertedError(ERC1155Mock.AccountBalanceOverflow.selector)):
        erc1155.safeBatchTransferUnchecked(a, a, b, [0, 0], [9, 21], b"", from_=c)

    with must_revert(ERC1155Mock.ArrayLengthsMismatch):
        erc1155.safeBatchTransferUnchecked(Address.ZERO, a, b, [0], [100, 100], b"", from_=c)

    with must_revert(ERC1155Mock.TransferToNonERC1155ReceiverImplementer):
        erc1155.safeTransferUnchecked(Address.ZERO, a, erc1155, 0, 100, b"", from_=c)

    with must_revert(ERC1155Mock.TransferToNonERC1155ReceiverImplementer):
        erc1155.safeTransferUnchecked(a, a, erc1155, 0, 100, b"", from_=c)

    with must_revert(ERC1155Mock.TransferToNonERC1155ReceiverImplementer):
        erc1155.safeBatchTransferUnchecked(Address.ZERO, a, erc1155, [0], [100], b"", from_=c)

    with must_revert(ERC1155Mock.TransferToNonERC1155ReceiverImplementer):
        erc1155.safeBatchTransferUnchecked(a, a, erc1155, [0], [100], b"", from_=c)
