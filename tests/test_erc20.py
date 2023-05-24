from woke.testing import *

from pytypes.tests.ERC20Mock import ERC20Mock
from pytypes.tests.NoETHMock import NoETHMock
from pytypes.tests.weird.Approval import ApprovalRaceToken
from pytypes.tests.weird.ApprovalToZero import ApprovalToZeroToken
from pytypes.tests.weird.BlockList import BlockableToken
from pytypes.tests.weird.HighDecimals import HighDecimalToken
from pytypes.tests.weird.Bytes32Metadata import ERC20 as Bytes32MetadataToken
from pytypes.tests.weird.MissingReturns import MissingReturnToken
from pytypes.tests.weird.NoRevert import NoRevertToken
from pytypes.tests.weird.Pausable import PausableToken
from pytypes.tests.weird.Proxied import ProxiedToken, TokenProxy
from pytypes.tests.weird.Reentrant import ReentrantToken
from pytypes.tests.weird.ReturnsFalse import ReturnsFalseToken
from pytypes.tests.weird.TransferFee import TransferFeeToken
from pytypes.tests.weird.Uint96 import Uint96ERC20
from pytypes.tests.weird.Upgradable import Proxy as UpgradableToken

from pytypes.src.utils.SafeTransferLib import SafeTransferLib


@default_chain.connect()
def test_erc20():
    milady = default_chain.accounts[0]
    accountoor = default_chain.accounts[1]
    default_chain.set_default_accounts(milady)

    tokenoor = ERC20Mock.deploy("Mockoor", "MOCK", 18)

    tokenoor.mint(milady, 2**30)
    assert tokenoor.balanceOf(milady) == 2**30

    tokenoor.approve(accountoor, 2**30)
    assert tokenoor.allowance(milady, accountoor) == 2**30

    tokenoor.transferFrom(milady, accountoor, 2**30, from_=accountoor)
    assert tokenoor.allowance(milady, accountoor) == 0

    assert tokenoor.balanceOf(milady) == 0
    assert tokenoor.balanceOf(accountoor) == 2**30

@default_chain.connect()
def test_safe_transfer_eth():
    milady = default_chain.accounts[0]
    accountoor = default_chain.accounts[1]
    default_chain.set_default_accounts(milady)

    SafeTransferLib.deploy()

    tokenoor = ERC20Mock.deploy("Mockoor", "MOCK", 18)
    tokenoor.balance = 5000
    accountoor.balance = 0

    # should change balance
    tokenoor.safeTransferETH(accountoor, 1000)
    assert tokenoor.balance == 4000
    assert accountoor.balance == 1000

    noeth = NoETHMock.deploy()

    # should revert
    with must_revert():
        tokenoor.safeTransferETH(noeth, 1000)

    # should change balance
    tokenoor.forceSafeTransferETH(noeth, 1000)
    assert tokenoor.balance == 3000
    assert noeth.balance == 1000

    # should force on bad gas stipend
    tokenoor.forceSafeTransferETHGas(accountoor, 1000, 0)
    assert tokenoor.balance == 2000
    assert accountoor.balance == 2000

    # should change balance
    tokenoor.trySafeTransferETH(accountoor, 1000, 0)
    assert tokenoor.balance == 1000
    assert accountoor.balance == 3000

    # should not revert
    tokenoor.trySafeTransferETH(noeth, 1000, 0)
    assert tokenoor.balance == 1000
    assert noeth.balance == 1000

@default_chain.connect()
def test_safe_transfer():
    milady = default_chain.accounts[0]
    default_chain.set_default_accounts(milady)

    SafeTransferLib.deploy()

    tokenoor = ERC20Mock.deploy("Mockoor", "MOCK", 18)
    tokenoor.mint(tokenoor, 2**30)

    tokenoor.safeTransfer(tokenoor, milady, 2**30)
    assert tokenoor.balanceOf(milady) == 2**30
    assert tokenoor.balanceOf(tokenoor) == 0

    tokenoor.approve(tokenoor, 2**30)
    assert tokenoor.allowance(milady, tokenoor) == 2**30
    tokenoor.safeTransferFrom(tokenoor, milady, tokenoor, 2**30)
    assert tokenoor.balanceOf(milady) == 0
    assert tokenoor.balanceOf(tokenoor) == 2**30

    tokenoor.mint(tokenoor, 2**30)
    tokenoor.safeTransferAll(tokenoor, milady)
    assert tokenoor.balanceOf(milady) == 2**30 * 2
    assert tokenoor.balanceOf(tokenoor) == 0

    # test safe balanceOf
    assert tokenoor.balanceOfoor(milady, milady) == 0
    assert tokenoor.balanceOfoor(tokenoor, milady) == 2**30 * 2

def safe_transfer_weird(weird: Account):
    milady = default_chain.accounts[0]
    weird = ERC20Mock(weird)

    SafeTransferLib.deploy()

    tokenoor = ERC20Mock.deploy("Mockoor", "MOCK", 18)

    weird.mint(tokenoor, 2**30)
    tokenoor.safeTransfer(weird, milady, 2**30)
    assert weird.balanceOf(milady) == 2**30
    assert weird.balanceOf(tokenoor) == 0

    weird.mint(tokenoor, 2**30)
    tokenoor.safeTransferAll(weird, milady)
    assert weird.balanceOf(milady) == 2**30 * 2
    assert weird.balanceOf(tokenoor) == 0

    weird.mint(tokenoor, 2**30)
    tokenoor.safeTransferFrom(weird, tokenoor, milady, 2**30)
    assert weird.balanceOf(milady) == 2**30 * 3
    assert weird.balanceOf(tokenoor) == 0

    weird.approve(tokenoor, 2**30)
    assert weird.allowance(milady, tokenoor) == 2**30
    tokenoor.safeTransferFrom(weird, milady, tokenoor, 2**30)
    assert weird.balanceOf(milady) == 2**30 * 2
    assert weird.balanceOf(tokenoor) == 2**30

    # test safe balanceOf
    assert tokenoor.balanceOfoor(milady, milady) == 0
    assert tokenoor.balanceOfoor(weird, milady) == 2**30 * 2

@default_chain.connect()
def test_safe_transfer_weird_1():
    default_chain.set_default_accounts(default_chain.accounts[0])
    weird = ApprovalRaceToken.deploy(0)
    safe_transfer_weird(weird)

@default_chain.connect()
def test_safe_transfer_weird_2():
    default_chain.set_default_accounts(default_chain.accounts[0])
    weird = ApprovalToZeroToken.deploy(0)
    safe_transfer_weird(weird)

@default_chain.connect()
def test_safe_transfer_weird_3():
    default_chain.set_default_accounts(default_chain.accounts[0])
    weird = BlockableToken.deploy(0)
    safe_transfer_weird(weird)

@default_chain.connect()
def test_safe_transfer_weird_4():
    default_chain.set_default_accounts(default_chain.accounts[0])
    weird = HighDecimalToken.deploy(0)
    safe_transfer_weird(weird)

@default_chain.connect()
def test_safe_transfer_weird_5():
    default_chain.set_default_accounts(default_chain.accounts[0])
    weird = Bytes32MetadataToken.deploy(0)
    safe_transfer_weird(weird)

@default_chain.connect()
def test_safe_transfer_weird_6():
    default_chain.set_default_accounts(default_chain.accounts[0])
    weird = MissingReturnToken.deploy(0)
    safe_transfer_weird(weird)

@default_chain.connect()
def test_safe_transfer_weird_7():
    default_chain.set_default_accounts(default_chain.accounts[0])
    weird = NoRevertToken.deploy(0)
    safe_transfer_weird(weird)

@default_chain.connect()
def test_safe_transfer_weird_8():
    default_chain.set_default_accounts(default_chain.accounts[0])
    weird = PausableToken.deploy(0)
    safe_transfer_weird(weird)

@default_chain.connect()
def test_safe_transfer_weird_9():
    default_chain.set_default_accounts(default_chain.accounts[0])
    impl = ProxiedToken.deploy(0)
    weird_proxy = TokenProxy.deploy(impl)
    weird = ProxiedToken(weird_proxy)
    weird.setDelegator(weird_proxy, True)
    safe_transfer_weird(weird)

@default_chain.connect()
def test_safe_transfer_weird_10():
    default_chain.set_default_accounts(default_chain.accounts[0])
    weird = ReturnsFalseToken.deploy(0)
    with must_revert():
        safe_transfer_weird(weird)

@default_chain.connect()
def test_safe_transfer_weird_11():
    default_chain.set_default_accounts(default_chain.accounts[0])
    weird = ReentrantToken.deploy(0)
    safe_transfer_weird(weird)

@default_chain.connect()
def test_safe_transfer_weird_12():
    default_chain.set_default_accounts(default_chain.accounts[0])
    weird = TransferFeeToken.deploy(0,0)
    safe_transfer_weird(weird)

@default_chain.connect()
def test_safe_transfer_weird_13():
    default_chain.set_default_accounts(default_chain.accounts[0])
    weird = Uint96ERC20.deploy(0)
    safe_transfer_weird(weird)

@default_chain.connect()
def test_safe_transfer_weird_14():
    default_chain.set_default_accounts(default_chain.accounts[0])
    weird = UpgradableToken.deploy(0)
    safe_transfer_weird(weird)

@default_chain.connect()
def test_mint_to_zero_address():
    milady = default_chain.accounts[0]
    default_chain.set_default_accounts(milady)
    tokenoor = ERC20Mock.deploy("Mockoor", "MOCK", 18)
    tokenoor.mint(Address(0), 2**256-1)
    assert tokenoor.balanceOf(Address(0)) == 2**256-1