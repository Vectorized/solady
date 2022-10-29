// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {MockERC20} from "./utils/mocks/MockERC20.sol";
import {MockETHRecipient} from "./utils/mocks/MockETHRecipient.sol";
import {RevertingToken} from "./utils/weird-tokens/RevertingToken.sol";
import {ReturnsTwoToken} from "./utils/weird-tokens/ReturnsTwoToken.sol";
import {ReturnsFalseToken} from "./utils/weird-tokens/ReturnsFalseToken.sol";
import {MissingReturnToken} from "./utils/weird-tokens/MissingReturnToken.sol";
import {ReturnsTooMuchToken} from "./utils/weird-tokens/ReturnsTooMuchToken.sol";
import {ReturnsGarbageToken} from "./utils/weird-tokens/ReturnsGarbageToken.sol";
import {ReturnsTooLittleToken} from "./utils/weird-tokens/ReturnsTooLittleToken.sol";

import "./utils/TestPlus.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "../src/utils/SafeTransferLib.sol";

contract SafeTransferLibTest is TestPlus {
    RevertingToken reverting;
    ReturnsTwoToken returnsTwo;
    ReturnsFalseToken returnsFalse;
    MissingReturnToken missingReturn;
    ReturnsTooMuchToken returnsTooMuch;
    ReturnsGarbageToken returnsGarbage;
    ReturnsTooLittleToken returnsTooLittle;

    MockERC20 erc20;

    function setUp() public {
        reverting = new RevertingToken();
        returnsTwo = new ReturnsTwoToken();
        returnsFalse = new ReturnsFalseToken();
        missingReturn = new MissingReturnToken();
        returnsTooMuch = new ReturnsTooMuchToken();
        returnsGarbage = new ReturnsGarbageToken();
        returnsTooLittle = new ReturnsTooLittleToken();

        erc20 = new MockERC20("StandardToken", "ST", 18);
        erc20.mint(address(this), type(uint256).max);
    }

    function testTransferWithMissingReturn() public {
        verifySafeTransfer(address(missingReturn), address(0xBEEF), 1e18);
    }

    function testTransferWithStandardERC20() public {
        verifySafeTransfer(address(erc20), address(0xBEEF), 1e18);
    }

    function testTransferWithReturnsTooMuch() public {
        verifySafeTransfer(address(returnsTooMuch), address(0xBEEF), 1e18);
    }

    function testTransferWithNonContract() public {
        SafeTransferLib.safeTransfer(address(0xBADBEEF), address(0xBEEF), 1e18);
    }

    function testTransferFromWithMissingReturn() public {
        verifySafeTransferFrom(address(missingReturn), address(0xFEED), address(0xBEEF), 1e18);
    }

    function testTransferFromWithStandardERC20() public {
        verifySafeTransferFrom(address(erc20), address(0xFEED), address(0xBEEF), 1e18);
    }

    function testTransferFromWithReturnsTooMuch() public {
        verifySafeTransferFrom(address(returnsTooMuch), address(0xFEED), address(0xBEEF), 1e18);
    }

    function testTransferFromWithNonContract() public {
        SafeTransferLib.safeTransferFrom(address(0xBADBEEF), address(0xFEED), address(0xBEEF), 1e18);
    }

    function testApproveWithMissingReturn() public {
        verifySafeApprove(address(missingReturn), address(0xBEEF), 1e18);
    }

    function testApproveWithStandardERC20() public {
        verifySafeApprove(address(erc20), address(0xBEEF), 1e18);
    }

    function testApproveWithReturnsTooMuch() public {
        verifySafeApprove(address(returnsTooMuch), address(0xBEEF), 1e18);
    }

    function testApproveWithNonContract() public {
        SafeTransferLib.safeApprove(address(0xBADBEEF), address(0xBEEF), 1e18);
    }

    function testTransferETH() public {
        SafeTransferLib.safeTransferETH(address(0xBEEF), 1e18);
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
                address(recipient),
                1e18,
                SafeTransferLib._GAS_STIPEND_NO_STORAGE_WRITES
            );
            assertFalse(success);
        }

        {
            uint256 counterBefore = recipient.counter();
            bool success = SafeTransferLib.trySafeTransferETH(
                address(recipient),
                1e18,
                SafeTransferLib._GAS_STIPEND_NO_GRIEF
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
                address(recipient),
                1e18,
                SafeTransferLib._GAS_STIPEND_NO_STORAGE_WRITES
            );
            assertFalse(success);
            assertTrue(recipient.garbage() == 0);
        }

        {
            bool success = SafeTransferLib.trySafeTransferETH(
                address(recipient),
                1e18,
                SafeTransferLib._GAS_STIPEND_NO_GRIEF
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
                this.forceSafeTransferETH(address(recipient), amount, SafeTransferLib._GAS_STIPEND_NO_STORAGE_WRITES);
            } else if (r == 1) {
                this.forceSafeTransferETH(address(recipient), amount, SafeTransferLib._GAS_STIPEND_NO_GRIEF);
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

    function testTransferRevertSelector() public {
        vm.expectRevert(SafeTransferLib.TransferFailed.selector);
        this.testFailTransferWithReturnsFalse();
    }

    function testTransferFromRevertSelector() public {
        vm.expectRevert(SafeTransferLib.TransferFromFailed.selector);
        this.testFailTransferFromWithReturnsFalse();
    }

    function testApproveRevertSelector() public {
        vm.expectRevert(SafeTransferLib.ApproveFailed.selector);
        this.testFailApproveWithReturnsFalse();
    }

    function testTransferETHRevertSelector() public {
        vm.expectRevert(SafeTransferLib.ETHTransferFailed.selector);
        this.testFailTransferETHToContractWithoutFallback();
    }

    function testFailTransferWithReturnsFalse() public {
        verifySafeTransfer(address(returnsFalse), address(0xBEEF), 1e18);
    }

    function testFailTransferWithReverting() public {
        verifySafeTransfer(address(reverting), address(0xBEEF), 1e18);
    }

    function testFailTransferWithReturnsTooLittle() public {
        verifySafeTransfer(address(returnsTooLittle), address(0xBEEF), 1e18);
    }

    function testFailTransferFromWithReturnsFalse() public {
        verifySafeTransferFrom(address(returnsFalse), address(0xFEED), address(0xBEEF), 1e18);
    }

    function testFailTransferFromWithReverting() public {
        verifySafeTransferFrom(address(reverting), address(0xFEED), address(0xBEEF), 1e18);
    }

    function testFailTransferFromWithReturnsTooLittle() public {
        verifySafeTransferFrom(address(returnsTooLittle), address(0xFEED), address(0xBEEF), 1e18);
    }

    function testFailApproveWithReturnsFalse() public {
        verifySafeApprove(address(returnsFalse), address(0xBEEF), 1e18);
    }

    function testFailApproveWithReverting() public {
        verifySafeApprove(address(reverting), address(0xBEEF), 1e18);
    }

    function testFailApproveWithReturnsTooLittle() public {
        verifySafeApprove(address(returnsTooLittle), address(0xBEEF), 1e18);
    }

    function testFuzzTransferWithMissingReturn(address to, uint256 amount) public brutalizeMemory {
        verifySafeTransfer(address(missingReturn), to, amount);
    }

    function testFuzzTransferWithStandardERC20(address to, uint256 amount) public brutalizeMemory {
        verifySafeTransfer(address(erc20), to, amount);
    }

    function testFuzzTransferWithReturnsTooMuch(address to, uint256 amount) public brutalizeMemory {
        verifySafeTransfer(address(returnsTooMuch), to, amount);
    }

    function testFuzzTransferWithGarbage(
        address to,
        uint256 amount,
        bytes memory garbage
    ) public brutalizeMemory {
        if (garbageIsGarbage(garbage)) return;

        returnsGarbage.setGarbage(garbage);

        verifySafeTransfer(address(returnsGarbage), to, amount);
    }

    function testFuzzTransferWithNonContract(
        address nonContract,
        address to,
        uint256 amount
    ) public brutalizeMemory {
        if (uint256(uint160(nonContract)) <= 18 || nonContract.code.length > 0) return;

        SafeTransferLib.safeTransfer(nonContract, to, amount);
    }

    function testFailTransferETHToContractWithoutFallback() public {
        SafeTransferLib.safeTransferETH(address(this), 1e18);
    }

    function testFuzzTransferFromWithMissingReturn(
        address from,
        address to,
        uint256 amount
    ) public brutalizeMemory {
        verifySafeTransferFrom(address(missingReturn), from, to, amount);
    }

    function testFuzzTransferFromWithStandardERC20(
        address from,
        address to,
        uint256 amount
    ) public brutalizeMemory {
        verifySafeTransferFrom(address(erc20), from, to, amount);
    }

    function testFuzzTransferFromWithReturnsTooMuch(
        address from,
        address to,
        uint256 amount
    ) public brutalizeMemory {
        verifySafeTransferFrom(address(returnsTooMuch), from, to, amount);
    }

    function testFuzzTransferFromWithGarbage(
        address from,
        address to,
        uint256 amount,
        bytes memory garbage
    ) public brutalizeMemory {
        if (garbageIsGarbage(garbage)) return;

        returnsGarbage.setGarbage(garbage);

        verifySafeTransferFrom(address(returnsGarbage), from, to, amount);
    }

    function testFuzzTransferFromWithNonContract(
        address nonContract,
        address from,
        address to,
        uint256 amount
    ) public brutalizeMemory {
        if (uint256(uint160(nonContract)) <= 18 || nonContract.code.length > 0) return;

        SafeTransferLib.safeTransferFrom(nonContract, from, to, amount);
    }

    function testFuzzApproveWithMissingReturn(address to, uint256 amount) public brutalizeMemory {
        verifySafeApprove(address(missingReturn), to, amount);
    }

    function testFuzzApproveWithStandardERC20(address to, uint256 amount) public brutalizeMemory {
        verifySafeApprove(address(erc20), to, amount);
    }

    function testFuzzApproveWithReturnsTooMuch(address to, uint256 amount) public brutalizeMemory {
        verifySafeApprove(address(returnsTooMuch), to, amount);
    }

    function testFuzzApproveWithGarbage(
        address to,
        uint256 amount,
        bytes memory garbage
    ) public brutalizeMemory {
        if (garbageIsGarbage(garbage)) return;

        returnsGarbage.setGarbage(garbage);

        verifySafeApprove(address(returnsGarbage), to, amount);
    }

    function testFuzzApproveWithNonContract(
        address nonContract,
        address to,
        uint256 amount
    ) public brutalizeMemory {
        if (uint256(uint160(nonContract)) <= 18 || nonContract.code.length > 0) return;

        SafeTransferLib.safeApprove(nonContract, to, amount);
    }

    function testFuzzTransferETH(address recipient, uint256 amount) public brutalizeMemory {
        // Transferring to msg.sender can fail because it's possible to overflow their ETH balance as it begins non-zero.
        if (recipient.code.length > 0 || uint256(uint160(recipient)) <= 18 || recipient == msg.sender) return;

        amount = bound(amount, 0, address(this).balance);

        SafeTransferLib.safeTransferETH(recipient, amount);
    }

    function testFailFuzzTransferWithReturnsFalse(address to, uint256 amount) public brutalizeMemory {
        verifySafeTransfer(address(returnsFalse), to, amount);
    }

    function testFailFuzzTransferWithReverting(address to, uint256 amount) public brutalizeMemory {
        verifySafeTransfer(address(reverting), to, amount);
    }

    function testFailFuzzTransferWithReturnsTooLittle(address to, uint256 amount) public brutalizeMemory {
        verifySafeTransfer(address(returnsTooLittle), to, amount);
    }

    function testFailFuzzTransferWithReturnsTwo(address to, uint256 amount) public brutalizeMemory {
        verifySafeTransfer(address(returnsTwo), to, amount);
    }

    function testFailFuzzTransferWithGarbage(
        address to,
        uint256 amount,
        bytes memory garbage
    ) public brutalizeMemory {
        require(garbageIsGarbage(garbage));

        returnsGarbage.setGarbage(garbage);

        verifySafeTransfer(address(returnsGarbage), to, amount);
    }

    function testFailFuzzTransferFromWithReturnsFalse(
        address from,
        address to,
        uint256 amount
    ) public brutalizeMemory {
        verifySafeTransferFrom(address(returnsFalse), from, to, amount);
    }

    function testFailFuzzTransferFromWithReverting(
        address from,
        address to,
        uint256 amount
    ) public brutalizeMemory {
        verifySafeTransferFrom(address(reverting), from, to, amount);
    }

    function testFailFuzzTransferFromWithReturnsTooLittle(
        address from,
        address to,
        uint256 amount
    ) public brutalizeMemory {
        verifySafeTransferFrom(address(returnsTooLittle), from, to, amount);
    }

    function testFailFuzzTransferFromWithReturnsTwo(
        address from,
        address to,
        uint256 amount
    ) public brutalizeMemory {
        verifySafeTransferFrom(address(returnsTwo), from, to, amount);
    }

    function testFailFuzzTransferFromWithGarbage(
        address from,
        address to,
        uint256 amount,
        bytes memory garbage
    ) public brutalizeMemory {
        require(garbageIsGarbage(garbage));

        returnsGarbage.setGarbage(garbage);

        verifySafeTransferFrom(address(returnsGarbage), from, to, amount);
    }

    function testFailFuzzApproveWithReturnsFalse(address to, uint256 amount) public brutalizeMemory {
        verifySafeApprove(address(returnsFalse), to, amount);
    }

    function testFailFuzzApproveWithReverting(address to, uint256 amount) public brutalizeMemory {
        verifySafeApprove(address(reverting), to, amount);
    }

    function testFailFuzzApproveWithReturnsTooLittle(address to, uint256 amount) public brutalizeMemory {
        verifySafeApprove(address(returnsTooLittle), to, amount);
    }

    function testFailFuzzApproveWithReturnsTwo(address to, uint256 amount) public brutalizeMemory {
        verifySafeApprove(address(returnsTwo), to, amount);
    }

    function testFailFuzzApproveWithGarbage(
        address to,
        uint256 amount,
        bytes memory garbage
    ) public brutalizeMemory {
        require(garbageIsGarbage(garbage));

        returnsGarbage.setGarbage(garbage);

        verifySafeApprove(address(returnsGarbage), to, amount);
    }

    function testFailFuzzTransferETHToContractWithoutFallback(uint256 amount) public brutalizeMemory {
        SafeTransferLib.safeTransferETH(address(this), amount);
    }

    function verifySafeTransfer(
        address token,
        address to,
        uint256 amount
    ) public {
        uint256 preBal = ERC20(token).balanceOf(to);
        SafeTransferLib.safeTransfer(address(token), to, amount);
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
        uint256 amount
    ) public {
        forceApprove(token, from, address(this), amount);

        // We cast to MissingReturnToken here because it won't check
        // that there was return data, which accommodates all tokens.
        MissingReturnToken(token).transfer(from, amount);

        uint256 preBal = ERC20(token).balanceOf(to);
        SafeTransferLib.safeTransferFrom(token, from, to, amount);
        uint256 postBal = ERC20(token).balanceOf(to);

        if (from == to) {
            assertEq(preBal, postBal);
        } else {
            assertEq(postBal - preBal, amount);
        }
    }

    function verifySafeApprove(
        address token,
        address to,
        uint256 amount
    ) public {
        SafeTransferLib.safeApprove(address(token), to, amount);

        assertEq(ERC20(token).allowance(address(this), to), amount);
    }

    function forceApprove(
        address token,
        address from,
        address to,
        uint256 amount
    ) public {
        uint256 slot = token == address(erc20) ? 4 : 2; // Standard ERC20 name and symbol aren't constant.

        vm.store(
            token,
            keccak256(abi.encode(to, keccak256(abi.encode(from, uint256(slot))))),
            bytes32(uint256(amount))
        );

        assertEq(ERC20(token).allowance(from, to), amount, "wrong allowance");
    }

    function forceSafeTransferETH(
        address to,
        uint256 amount,
        uint256 gasStipend
    ) public {
        SafeTransferLib.forceSafeTransferETH(to, amount, gasStipend);
    }

    function forceSafeTransferETH(address to, uint256 amount) public {
        SafeTransferLib.forceSafeTransferETH(to, amount);
    }

    function garbageIsGarbage(bytes memory garbage) public pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := and(or(lt(mload(garbage), 32), iszero(eq(mload(add(garbage, 0x20)), 1))), gt(mload(garbage), 0))
        }
    }
}
