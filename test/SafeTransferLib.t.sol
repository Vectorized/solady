// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {MockERC20} from "./utils/mocks/MockERC20.sol";
import {MockERC20LikeUSDT} from "./utils/mocks/MockERC20LikeUSDT.sol";
import {MockETHRecipient} from "./utils/mocks/MockETHRecipient.sol";
import {RevertingToken} from "./utils/weird-tokens/RevertingToken.sol";
import {ReturnsTwoToken} from "./utils/weird-tokens/ReturnsTwoToken.sol";
import {ReturnsFalseToken} from "./utils/weird-tokens/ReturnsFalseToken.sol";
import {MissingReturnToken} from "./utils/weird-tokens/MissingReturnToken.sol";
import {ReturnsTooMuchToken} from "./utils/weird-tokens/ReturnsTooMuchToken.sol";
import {ReturnsRawBytesToken} from "./utils/weird-tokens/ReturnsRawBytesToken.sol";
import {ReturnsTooLittleToken} from "./utils/weird-tokens/ReturnsTooLittleToken.sol";

import "./utils/SoladyTest.sol";

import {ERC20} from "../src/tokens/ERC20.sol";
import {SafeTransferLib} from "../src/utils/SafeTransferLib.sol";

contract SafeTransferLibTest is SoladyTest {
    uint256 constant SUCCESS = 1;
    uint256 constant REVERTS_WITH_SELECTOR = 2;
    uint256 constant REVERTS_WITH_ANY = 3;

    RevertingToken reverting;
    ReturnsTwoToken returnsTwo;
    ReturnsFalseToken returnsFalse;
    MissingReturnToken missingReturn;
    ReturnsTooMuchToken returnsTooMuch;
    ReturnsRawBytesToken returnsRawBytes;
    ReturnsTooLittleToken returnsTooLittle;

    MockERC20 erc20;

    function setUp() public {
        reverting = new RevertingToken();
        returnsTwo = new ReturnsTwoToken();
        returnsFalse = new ReturnsFalseToken();
        missingReturn = new MissingReturnToken();
        returnsTooMuch = new ReturnsTooMuchToken();
        returnsRawBytes = new ReturnsRawBytesToken();
        returnsTooLittle = new ReturnsTooLittleToken();

        erc20 = new MockERC20("StandardToken", "ST", 18);
        erc20.mint(address(this), type(uint256).max);
    }

    function testTransferWithMissingReturn() public {
        verifySafeTransfer(address(missingReturn), address(0xBEEF), 1e18, SUCCESS);
    }

    function testTransferWithStandardERC20() public {
        verifySafeTransfer(address(erc20), address(0xBEEF), 1e18, SUCCESS);
    }

    function testTransferWithReturnsTooMuch() public {
        verifySafeTransfer(address(returnsTooMuch), address(0xBEEF), 1e18, SUCCESS);
    }

    function testTransferWithNonContract() public {
        SafeTransferLib.safeTransfer(address(0xBADBEEF), address(0xBEEF), 1e18);
    }

    function testTransferFromWithMissingReturn() public {
        verifySafeTransferFrom(
            address(missingReturn), address(0xFEED), address(0xBEEF), 1e18, SUCCESS
        );
    }

    function testTransferFromWithStandardERC20() public {
        verifySafeTransferFrom(address(erc20), address(0xFEED), address(0xBEEF), 1e18, SUCCESS);
    }

    function testTransferFromWithReturnsTooMuch() public {
        verifySafeTransferFrom(
            address(returnsTooMuch), address(0xFEED), address(0xBEEF), 1e18, SUCCESS
        );
    }

    function testTransferFromWithNonContract() public {
        SafeTransferLib.safeTransferFrom(address(0xBADBEEF), address(0xFEED), address(0xBEEF), 1e18);
    }

    function testApproveWithMissingReturn() public {
        verifySafeApprove(address(missingReturn), address(0xBEEF), 1e18, SUCCESS);
    }

    function testApproveWithStandardERC20() public {
        verifySafeApprove(address(erc20), address(0xBEEF), 1e18, SUCCESS);
    }

    function testApproveWithReturnsTooMuch() public {
        verifySafeApprove(address(returnsTooMuch), address(0xBEEF), 1e18, SUCCESS);
    }

    function testApproveWithNonContract() public {
        SafeTransferLib.safeApprove(address(0xBADBEEF), address(0xBEEF), 1e18);
    }

    function testApproveWithRetryWithNonContract() public {
        SafeTransferLib.safeApproveWithRetry(address(0xBADBEEF), address(0xBEEF), 1e18);
    }

    function testTransferETH() public {
        SafeTransferLib.safeTransferETH(address(0xBEEF), 1e18);
    }

    function testTransferAllETH() public {
        SafeTransferLib.safeTransferAllETH(address(0xBEEF));
    }

    function testTryTransferETH() public {
        MockETHRecipient recipient = new MockETHRecipient(false, false);
        bool success = SafeTransferLib.trySafeTransferETH(address(recipient), 1e18, gasleft());
        assertTrue(success);
    }

    function testTryTransferETHWithNoStorageWrites() public {
        MockETHRecipient recipient = new MockETHRecipient(true, false);

        {
            bool success = SafeTransferLib.trySafeTransferETH(
                address(recipient), 1e18, SafeTransferLib.GAS_STIPEND_NO_STORAGE_WRITES
            );
            assertFalse(success);
        }

        {
            uint256 counterBefore = recipient.counter();
            bool success = SafeTransferLib.trySafeTransferETH(
                address(recipient), 1e18, SafeTransferLib.GAS_STIPEND_NO_GRIEF
            );
            assertTrue(success);
            assertEq(recipient.counter(), counterBefore + 1);
        }

        {
            uint256 counterBefore = recipient.counter();
            bool success = SafeTransferLib.trySafeTransferETH(address(recipient), 1e18, gasleft());
            assertTrue(success);
            assertEq(recipient.counter(), counterBefore + 1);
        }
    }

    function testTryTransferETHWithNoGrief() public {
        MockETHRecipient recipient = new MockETHRecipient(false, true);

        {
            bool success = SafeTransferLib.trySafeTransferETH(
                address(recipient), 1e18, SafeTransferLib.GAS_STIPEND_NO_STORAGE_WRITES
            );
            assertFalse(success);
            assertTrue(recipient.garbage() == 0);
        }

        {
            bool success = SafeTransferLib.trySafeTransferETH(
                address(recipient), 1e18, SafeTransferLib.GAS_STIPEND_NO_GRIEF
            );
            assertFalse(success);
            assertTrue(recipient.garbage() == 0);
        }

        {
            bool success = SafeTransferLib.trySafeTransferETH(address(recipient), 1e18, gasleft());
            assertTrue(success);
            assertTrue(recipient.garbage() != 0);
        }
    }

    function testForceTransferETHToGriever(uint256 amount, uint256 randomness) public {
        amount = amount % 1000 ether;
        uint256 originalBalance = address(this).balance;
        vm.deal(address(this), amount * 2);

        MockETHRecipient recipient = new MockETHRecipient(false, true);

        {
            uint256 receipientBalanceBefore = address(recipient).balance;
            uint256 senderBalanceBefore = address(this).balance;
            uint256 r = uint256(keccak256(abi.encode(randomness))) % 3;
            // Send to a griever with a gas stipend. Should not revert.
            if (r == 0) {
                this.forceSafeTransferETH(
                    address(recipient), amount, SafeTransferLib.GAS_STIPEND_NO_STORAGE_WRITES
                );
            } else if (r == 1) {
                this.forceSafeTransferETH(
                    address(recipient), amount, SafeTransferLib.GAS_STIPEND_NO_GRIEF
                );
            } else {
                this.forceSafeTransferETH(address(recipient), amount);
            }
            assertEq(address(recipient).balance - receipientBalanceBefore, amount);
            assertEq(senderBalanceBefore - address(this).balance, amount);
            // We use the `SELFDESTRUCT` to send, and thus the `garbage` should NOT be updated.
            assertTrue(recipient.garbage() == 0);
        }

        {
            uint256 receipientBalanceBefore = address(recipient).balance;
            uint256 senderBalanceBefore = address(this).balance;
            // Send more than remaining balance without gas stipend. Should revert.
            vm.expectRevert(SafeTransferLib.ETHTransferFailed.selector);
            this.forceSafeTransferETH(address(recipient), address(this).balance + 1, gasleft());
            assertEq(address(recipient).balance - receipientBalanceBefore, 0);
            assertEq(senderBalanceBefore - address(this).balance, 0);
            // We did not send anything, and thus the `garbage` should NOT be updated.
            assertTrue(recipient.garbage() == 0);
        }

        {
            uint256 receipientBalanceBefore = address(recipient).balance;
            uint256 senderBalanceBefore = address(this).balance;
            // Send all the remaining balance without gas stipend. Should not revert.
            amount = address(this).balance;
            this.forceSafeTransferETH(address(recipient), amount, gasleft());
            assertEq(address(recipient).balance - receipientBalanceBefore, amount);
            assertEq(senderBalanceBefore - address(this).balance, amount);
            // We use the normal `CALL` to send, and thus the `garbage` should be updated.
            assertTrue(recipient.garbage() != 0);
        }

        vm.deal(address(this), originalBalance);
    }

    function testForceTransferETHToGriever() public {
        testForceTransferETHToGriever(1 ether, 0);
        testForceTransferETHToGriever(1 ether, 1);
        testForceTransferETHToGriever(1 ether, 2);
    }

    function testTransferWithReturnsFalseReverts() public {
        verifySafeTransfer(address(returnsFalse), address(0xBEEF), 1e18, REVERTS_WITH_SELECTOR);
    }

    function testTransferWithRevertingReverts() public {
        verifySafeTransfer(address(reverting), address(0xBEEF), 1e18, REVERTS_WITH_SELECTOR);
    }

    function testTransferWithReturnsTooLittleReverts() public {
        verifySafeTransfer(address(returnsTooLittle), address(0xBEEF), 1e18, REVERTS_WITH_SELECTOR);
    }

    function testTransferFromWithReturnsFalseReverts() public {
        verifySafeTransferFrom(
            address(returnsFalse), address(0xFEED), address(0xBEEF), 1e18, REVERTS_WITH_SELECTOR
        );
    }

    function testTransferFromWithRevertingReverts() public {
        verifySafeTransferFrom(
            address(reverting), address(0xFEED), address(0xBEEF), 1e18, REVERTS_WITH_ANY
        );
    }

    function testTransferFromWithReturnsTooLittleReverts() public {
        verifySafeTransferFrom(
            address(returnsTooLittle), address(0xFEED), address(0xBEEF), 1e18, REVERTS_WITH_SELECTOR
        );
    }

    function testApproveWithReturnsFalseReverts() public {
        verifySafeApprove(address(returnsFalse), address(0xBEEF), 1e18, REVERTS_WITH_SELECTOR);
    }

    function testApproveWithRevertingReverts() public {
        verifySafeApprove(address(reverting), address(0xBEEF), 1e18, REVERTS_WITH_SELECTOR);
    }

    function testApproveWithReturnsTooLittleReverts() public {
        verifySafeApprove(address(returnsTooLittle), address(0xBEEF), 1e18, REVERTS_WITH_SELECTOR);
    }

    function testBalanceOfStandardERC20() public view {
        erc20.balanceOf(address(this));
    }

    function testBalanceOfStandardERC20(address to, uint256 amount) public {
        uint256 originalBalance = erc20.balanceOf(address(this));
        vm.assume(originalBalance >= amount);
        vm.assume(to != address(this));

        SafeTransferLib.safeTransfer(address(erc20), _brutalized(to), originalBalance - amount);
        assertEq(SafeTransferLib.balanceOf(address(erc20), _brutalized(address(this))), amount);
    }

    function testTransferAllWithStandardERC20() public {
        SafeTransferLib.safeTransferAll(address(erc20), address(1));
    }

    function testTransferAllWithStandardERC20(address to, uint256 amount) public {
        uint256 originalBalance = erc20.balanceOf(address(this));
        vm.assume(originalBalance >= amount);
        vm.assume(to != address(this));

        SafeTransferLib.safeTransfer(address(erc20), _brutalized(to), originalBalance - amount);
        assertEq(erc20.balanceOf(address(this)), amount);

        assertEq(SafeTransferLib.safeTransferAll(address(erc20), _brutalized(to)), amount);

        assertEq(erc20.balanceOf(address(this)), 0);
        assertEq(erc20.balanceOf(to), originalBalance);
    }

    function testTransferAllFromWithStandardERC20() public {
        forceApprove(address(erc20), address(this), address(this), type(uint256).max);
        SafeTransferLib.safeTransferAllFrom(address(erc20), address(this), address(1));
    }

    function testTransferAllFromWithStandardERC20(address to, address from, uint256 amount)
        public
    {
        SafeTransferLib.safeTransferAll(address(erc20), _brutalized(from));

        uint256 originalBalance = erc20.balanceOf(from);
        vm.assume(originalBalance >= amount);
        vm.assume(to != from && to != address(this) && from != address(this));

        forceApprove(address(erc20), from, address(this), type(uint256).max);

        SafeTransferLib.safeTransferFrom(
            address(erc20), _brutalized(from), _brutalized(to), originalBalance - amount
        );
        assertEq(erc20.balanceOf(from), amount);

        assertEq(
            SafeTransferLib.safeTransferAllFrom(address(erc20), _brutalized(from), _brutalized(to)),
            amount
        );

        assertEq(erc20.balanceOf(address(this)), 0);
        assertEq(erc20.balanceOf(to), originalBalance);
    }

    function testTransferWithMissingReturn(address to, uint256 amount) public {
        verifySafeTransfer(address(missingReturn), to, amount, SUCCESS);
    }

    function testTransferWithStandardERC20(address to, uint256 amount) public {
        verifySafeTransfer(address(erc20), to, amount, SUCCESS);
    }

    function testTransferWithReturnsTooMuch(address to, uint256 amount) public {
        verifySafeTransfer(address(returnsTooMuch), to, amount, SUCCESS);
    }

    function testTransferWithNonGarbage(address to, uint256 amount) public {
        returnsRawBytes.setRawBytes(_generateNonGarbage());

        verifySafeTransfer(address(returnsRawBytes), to, amount, SUCCESS);
    }

    function testTransferWithNonContract(address nonContract, address to, uint256 amount) public {
        if (uint256(uint160(nonContract)) <= 18 || nonContract.code.length > 0) {
            return;
        }

        SafeTransferLib.safeTransfer(nonContract, _brutalized(to), amount);
    }

    function testTransferETHToContractWithoutFallbackReverts() public {
        vm.expectRevert(SafeTransferLib.ETHTransferFailed.selector);
        this.safeTransferETH(address(this), 1e18);
    }

    function testTransferAllETHToContractWithoutFallbackReverts() public {
        vm.expectRevert(SafeTransferLib.ETHTransferFailed.selector);
        this.safeTransferAllETH(address(this));
    }

    function testTransferFromWithMissingReturn(address from, address to, uint256 amount) public {
        verifySafeTransferFrom(address(missingReturn), from, to, amount, SUCCESS);
    }

    function testTransferFromWithStandardERC20(address from, address to, uint256 amount) public {
        verifySafeTransferFrom(address(erc20), from, to, amount, SUCCESS);
    }

    function testTransferFromWithReturnsTooMuch(address from, address to, uint256 amount) public {
        verifySafeTransferFrom(address(returnsTooMuch), from, to, amount, SUCCESS);
    }

    function testTransferFromWithNonGarbage(address from, address to, uint256 amount) public {
        returnsRawBytes.setRawBytes(_generateNonGarbage());

        verifySafeTransferFrom(address(returnsRawBytes), from, to, amount, SUCCESS);
    }

    function testTransferFromWithNonContract(
        address nonContract,
        address from,
        address to,
        uint256 amount
    ) public {
        if (uint256(uint160(nonContract)) <= 18 || nonContract.code.length > 0) {
            return;
        }

        SafeTransferLib.safeTransferFrom(nonContract, _brutalized(from), _brutalized(to), amount);
    }

    function testApproveWithMissingReturn(address to, uint256 amount) public {
        verifySafeApprove(address(missingReturn), to, amount, SUCCESS);
    }

    function testApproveWithStandardERC20(address to, uint256 amount) public {
        verifySafeApprove(address(erc20), to, amount, SUCCESS);
    }

    function testApproveWithReturnsTooMuch(address to, uint256 amount) public {
        verifySafeApprove(address(returnsTooMuch), to, amount, SUCCESS);
    }

    function testApproveWithNonGarbage(address to, uint256 amount) public {
        returnsRawBytes.setRawBytes(_generateNonGarbage());

        verifySafeApprove(address(returnsRawBytes), to, amount, SUCCESS);
    }

    function testApproveWithNonContract(address nonContract, address to, uint256 amount) public {
        if (uint256(uint160(nonContract)) <= 18 || nonContract.code.length > 0) {
            return;
        }

        SafeTransferLib.safeApprove(nonContract, _brutalized(to), amount);
    }

    function testApproveWithRetryWithNonContract(address nonContract, address to, uint256 amount)
        public
    {
        if (uint256(uint160(nonContract)) <= 18 || nonContract.code.length > 0) {
            return;
        }

        SafeTransferLib.safeApproveWithRetry(nonContract, _brutalized(to), amount);
    }

    function testApproveWithRetry(address to, uint256 amount0, uint256 amount1) public {
        MockERC20LikeUSDT usdt = new MockERC20LikeUSDT();
        assertEq(usdt.allowance(address(this), to), 0);
        SafeTransferLib.safeApproveWithRetry(address(usdt), _brutalized(to), amount0);
        assertEq(usdt.allowance(address(this), to), amount0);
        if (amount0 != 0 && amount1 != 0) {
            verifySafeApprove(address(usdt), to, amount1, REVERTS_WITH_SELECTOR);
        }
        SafeTransferLib.safeApproveWithRetry(address(usdt), _brutalized(to), amount1);
        assertEq(usdt.allowance(address(this), to), amount1);
    }

    function testApproveWithRetry() public {
        testApproveWithRetry(address(1), 123, 456);
    }

    function testTransferETH(address recipient, uint256 amount) public {
        // Transferring to msg.sender can fail because it's possible to overflow their ETH balance as it begins non-zero.
        if (
            recipient.code.length > 0 || uint256(uint160(recipient)) <= 18
                || recipient == msg.sender
        ) {
            return;
        }

        amount = _bound(amount, 0, address(this).balance);

        SafeTransferLib.safeTransferETH(recipient, amount);
    }

    function testTransferAllETH(address recipient) public {
        // Transferring to msg.sender can fail because it's possible to overflow their ETH balance as it begins non-zero.
        if (
            recipient.code.length > 0 || uint256(uint160(recipient)) <= 18
                || recipient == msg.sender
        ) {
            return;
        }

        SafeTransferLib.safeTransferAllETH(recipient);
    }

    function testTransferWithReturnsFalseReverts(address to, uint256 amount) public {
        verifySafeTransfer(address(returnsFalse), to, amount, REVERTS_WITH_SELECTOR);
    }

    function testTransferWithRevertingReverts(address to, uint256 amount) public {
        verifySafeTransfer(address(reverting), to, amount, REVERTS_WITH_SELECTOR);
    }

    function testTransferWithReturnsTooLittleReverts(address to, uint256 amount) public {
        verifySafeTransfer(address(returnsTooLittle), to, amount, REVERTS_WITH_SELECTOR);
    }

    function testTransferWithReturnsTwoReverts(address to, uint256 amount) public {
        verifySafeTransfer(address(returnsTwo), to, amount, REVERTS_WITH_SELECTOR);
    }

    function testTransferWithGarbageReverts(address to, uint256 amount) public {
        returnsRawBytes.setRawBytes(_generateGarbage());

        verifySafeTransfer(address(returnsRawBytes), to, amount, REVERTS_WITH_ANY);
    }

    function testTransferFromWithReturnsFalseReverts(address from, address to, uint256 amount)
        public
    {
        verifySafeTransferFrom(address(returnsFalse), from, to, amount, REVERTS_WITH_SELECTOR);
    }

    function testTransferFromWithRevertingReverts(address from, address to, uint256 amount)
        public
    {
        verifySafeTransferFrom(address(reverting), from, to, amount, REVERTS_WITH_ANY);
    }

    function testTransferFromWithReturnsTooLittleReverts(address from, address to, uint256 amount)
        public
    {
        verifySafeTransferFrom(address(returnsTooLittle), from, to, amount, REVERTS_WITH_SELECTOR);
    }

    function testTransferFromWithReturnsTwoReverts(address from, address to, uint256 amount)
        public
    {
        verifySafeTransferFrom(address(returnsTwo), from, to, amount, REVERTS_WITH_SELECTOR);
    }

    function testTransferFromWithGarbageReverts(address from, address to, uint256 amount) public {
        returnsRawBytes.setRawBytes(_generateGarbage());

        verifySafeTransferFrom(address(returnsRawBytes), from, to, amount, REVERTS_WITH_ANY);
    }

    function testApproveWithReturnsFalseReverts(address to, uint256 amount) public {
        verifySafeApprove(address(returnsFalse), to, amount, REVERTS_WITH_SELECTOR);
    }

    function testApproveWithRevertingReverts(address to, uint256 amount) public {
        verifySafeApprove(address(reverting), to, amount, REVERTS_WITH_SELECTOR);
    }

    function testApproveWithReturnsTooLittleReverts(address to, uint256 amount) public {
        verifySafeApprove(address(returnsTooLittle), to, amount, REVERTS_WITH_SELECTOR);
    }

    function testApproveWithReturnsTwoReverts(address to, uint256 amount) public {
        verifySafeApprove(address(returnsTwo), to, amount, REVERTS_WITH_SELECTOR);
    }

    function testApproveWithGarbageReverts(address to, uint256 amount) public {
        returnsRawBytes.setRawBytes(_generateGarbage());

        verifySafeApprove(address(returnsRawBytes), to, amount, REVERTS_WITH_ANY);
    }

    function testTransferETHToContractWithoutFallbackReverts(uint256 amount) public {
        vm.expectRevert(SafeTransferLib.ETHTransferFailed.selector);
        this.safeTransferETH(address(this), amount);
    }

    function testTransferAllETHToContractWithoutFallbackReverts(uint256) public {
        vm.expectRevert(SafeTransferLib.ETHTransferFailed.selector);
        this.safeTransferAllETH(address(this));
    }

    function verifySafeTransfer(address token, address to, uint256 amount, uint256 mode) public {
        if (mode == REVERTS_WITH_SELECTOR) {
            vm.expectRevert(SafeTransferLib.TransferFailed.selector);
        } else if (mode == REVERTS_WITH_ANY) {
            (bool success,) = address(this).call(
                abi.encodeWithSignature(
                    "verifySafeTransfer(address,address,uint256)", token, to, amount
                )
            );
            assertFalse(success);
            return;
        }
        this.verifySafeTransfer(token, to, amount);
    }

    function verifySafeTransfer(address token, address to, uint256 amount) public brutalizeMemory {
        uint256 preBal = ERC20(token).balanceOf(to);
        if (amount == ERC20(token).balanceOf(address(this)) && _random() % 2 == 0) {
            SafeTransferLib.safeTransferAll(address(token), _brutalized(to));
        } else {
            SafeTransferLib.safeTransfer(address(token), _brutalized(to), amount);
        }

        uint256 postBal = ERC20(token).balanceOf(to);

        if (to == address(this)) {
            assertEq(preBal, postBal);
        } else {
            assertEq(postBal - preBal, amount);
        }
    }

    function verifySafeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount,
        uint256 mode
    ) public {
        if (mode == REVERTS_WITH_SELECTOR) {
            vm.expectRevert(SafeTransferLib.TransferFromFailed.selector);
        } else if (mode == REVERTS_WITH_ANY) {
            (bool success,) = address(this).call(
                abi.encodeWithSignature(
                    "verifySafeTransferFrom(address,address,address,uint256)",
                    token,
                    from,
                    to,
                    amount
                )
            );
            assertFalse(success);
            return;
        }
        this.verifySafeTransferFrom(token, from, to, amount);
    }

    function verifySafeTransferFrom(address token, address from, address to, uint256 amount)
        public
        brutalizeMemory
    {
        forceApprove(token, from, address(this), amount);

        // We cast to MissingReturnToken here because it won't check
        // that there was return data, which accommodates all tokens.
        MissingReturnToken(token).transfer(from, amount);

        uint256 preBal = ERC20(token).balanceOf(to);
        if (amount == ERC20(token).balanceOf(from) && _random() % 2 == 0) {
            SafeTransferLib.safeTransferAllFrom(address(token), _brutalized(from), _brutalized(to));
        } else {
            SafeTransferLib.safeTransferFrom(token, _brutalized(from), _brutalized(to), amount);
        }
        uint256 postBal = ERC20(token).balanceOf(to);

        if (from == to) {
            assertEq(preBal, postBal);
        } else {
            assertEq(postBal - preBal, amount);
        }
    }

    function verifySafeApprove(address token, address to, uint256 amount, uint256 mode) public {
        if (mode == REVERTS_WITH_SELECTOR) {
            vm.expectRevert(SafeTransferLib.ApproveFailed.selector);
        } else if (mode == REVERTS_WITH_ANY) {
            (bool success,) = address(this).call(
                abi.encodeWithSignature(
                    "verifySafeApprove(address,address,uint256)", token, to, amount
                )
            );
            assertFalse(success);
            return;
        }
        this.verifySafeApprove(token, to, amount);
    }

    function verifySafeApprove(address token, address to, uint256 amount) public {
        SafeTransferLib.safeApprove(_brutalized(address(token)), _brutalized(to), amount);

        assertEq(ERC20(token).allowance(address(this), to), amount);
    }

    function forceApprove(address token, address from, address to, uint256 amount) public {
        if (token == address(erc20)) {
            bytes32 allowanceSlot;
            /// @solidity memory-safe-assembly
            assembly {
                mstore(0x20, to)
                mstore(0x0c, 0x7f5e9f20) // `_ALLOWANCE_SLOT_SEED`.
                mstore(0x00, from)
                allowanceSlot := keccak256(0x0c, 0x34)
            }
            vm.store(token, allowanceSlot, bytes32(uint256(amount)));
        } else {
            vm.store(
                token,
                keccak256(abi.encode(to, keccak256(abi.encode(from, uint256(2))))),
                bytes32(uint256(amount))
            );
        }

        assertEq(ERC20(token).allowance(from, to), amount, "wrong allowance");
    }

    function forceSafeTransferETH(address to, uint256 amount, uint256 gasStipend) public {
        SafeTransferLib.forceSafeTransferETH(to, amount, gasStipend);
    }

    function forceSafeTransferETH(address to, uint256 amount) public {
        SafeTransferLib.forceSafeTransferETH(to, amount);
    }

    function safeTransferETH(address to, uint256 amount) public {
        SafeTransferLib.safeTransferETH(to, amount);
    }

    function safeTransferAllETH(address to) public {
        SafeTransferLib.safeTransferAllETH(to);
    }

    function _generateGarbage() internal returns (bytes memory result) {
        uint256 r = _random();
        /// @solidity memory-safe-assembly
        assembly {
            for {} 1 {} {
                mstore(0x00, r)
                result := mload(0x40)
                let n := and(r, 0x7f)
                mstore(result, n)
                r := keccak256(0x00, 0x40)
                mstore(add(result, 0x20), r)
                mstore(0x40, add(result, 0x100))
                if and(or(lt(n, 0x20), iszero(eq(r, 1))), gt(n, 0)) { break }
            }
        }
    }

    function _generateNonGarbage() internal returns (bytes memory result) {
        uint256 r = _random();
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(and(r, 1)) {
                result := mload(0x40)
                mstore(result, 0x20)
                mstore(add(result, 0x20), 1)
                mstore(0x40, add(result, 0x40))
            }
        }
    }

    function _brutalized(address a) internal pure returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := or(a, shl(160, keccak256(0x00, 0x20)))
        }
    }
}
