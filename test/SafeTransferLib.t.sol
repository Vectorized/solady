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
    uint256 constant SUCCESS = 1;
    uint256 constant REVERTS_WITH_SELECTOR = 2;
    uint256 constant REVERTS_WITH_ANY = 3;

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
                address(recipient), 1e18, SafeTransferLib._GAS_STIPEND_NO_STORAGE_WRITES
            );
            assertFalse(success);
        }

        {
            uint256 counterBefore = recipient.counter();
            bool success = SafeTransferLib.trySafeTransferETH(
                address(recipient), 1e18, SafeTransferLib._GAS_STIPEND_NO_GRIEF
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
                address(recipient), 1e18, SafeTransferLib._GAS_STIPEND_NO_STORAGE_WRITES
            );
            assertFalse(success);
            assertTrue(recipient.garbage() == 0);
        }

        {
            bool success = SafeTransferLib.trySafeTransferETH(
                address(recipient), 1e18, SafeTransferLib._GAS_STIPEND_NO_GRIEF
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
                    address(recipient), amount, SafeTransferLib._GAS_STIPEND_NO_STORAGE_WRITES
                );
            } else if (r == 1) {
                this.forceSafeTransferETH(
                    address(recipient), amount, SafeTransferLib._GAS_STIPEND_NO_GRIEF
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

    function testFuzzBalanceOfStandardERC20(address to, uint256 amount) public {
        uint256 originalBalance = erc20.balanceOf(address(this));
        vm.assume(originalBalance >= amount);
        vm.assume(to != address(this));

        SafeTransferLib.safeTransfer(address(erc20), to, originalBalance - amount);
        assertEq(SafeTransferLib.balanceOf(address(erc20), address(this)), amount);
    }

    function testTransferAllWithStandardERC20() public {
        SafeTransferLib.safeTransferAll(address(erc20), address(1));
    }

    function testFuzzTransferAllWithStandardERC20(address to, uint256 amount) public {
        uint256 originalBalance = erc20.balanceOf(address(this));
        vm.assume(originalBalance >= amount);
        vm.assume(to != address(this));

        SafeTransferLib.safeTransfer(address(erc20), to, originalBalance - amount);
        assertEq(erc20.balanceOf(address(this)), amount);

        assertEq(SafeTransferLib.safeTransferAll(address(erc20), to), amount);

        assertEq(erc20.balanceOf(address(this)), 0);
        assertEq(erc20.balanceOf(to), originalBalance);
    }

    function testTransferAllFromWithStandardERC20() public {
        forceApprove(address(erc20), address(this), address(this), type(uint256).max);
        SafeTransferLib.safeTransferAllFrom(address(erc20), address(this), address(1));
    }

    function testFuzzTransferAllFromWithStandardERC20(address to, address from, uint256 amount)
        public
    {
        SafeTransferLib.safeTransferAll(address(erc20), from);

        uint256 originalBalance = erc20.balanceOf(from);
        vm.assume(originalBalance >= amount);
        vm.assume(to != from && to != address(this) && from != address(this));

        forceApprove(address(erc20), from, address(this), type(uint256).max);

        SafeTransferLib.safeTransferFrom(address(erc20), from, to, originalBalance - amount);
        assertEq(erc20.balanceOf(from), amount);

        assertEq(SafeTransferLib.safeTransferAllFrom(address(erc20), from, to), amount);

        assertEq(erc20.balanceOf(address(this)), 0);
        assertEq(erc20.balanceOf(to), originalBalance);
    }

    function testFuzzTransferWithMissingReturn(address to, uint256 amount) public {
        verifySafeTransfer(address(missingReturn), to, amount, SUCCESS);
    }

    function testFuzzTransferWithStandardERC20(address to, uint256 amount) public {
        verifySafeTransfer(address(erc20), to, amount, SUCCESS);
    }

    function testFuzzTransferWithReturnsTooMuch(address to, uint256 amount) public {
        verifySafeTransfer(address(returnsTooMuch), to, amount, SUCCESS);
    }

    function testFuzzTransferWithGarbage(address to, uint256 amount, bytes memory garbage) public {
        if (garbageIsGarbage(garbage)) return;

        returnsGarbage.setGarbage(garbage);

        verifySafeTransfer(address(returnsGarbage), to, amount, SUCCESS);
    }

    function testFuzzTransferWithNonContract(address nonContract, address to, uint256 amount)
        public
    {
        if (uint256(uint160(nonContract)) <= 18 || nonContract.code.length > 0) {
            return;
        }

        SafeTransferLib.safeTransfer(nonContract, to, amount);
    }

    function testTransferETHToContractWithoutFallbackReverts() public {
        vm.expectRevert(SafeTransferLib.ETHTransferFailed.selector);
        this.safeTransferETH(address(this), 1e18);
    }

    function testFuzzTransferFromWithMissingReturn(address from, address to, uint256 amount)
        public
    {
        verifySafeTransferFrom(address(missingReturn), from, to, amount, SUCCESS);
    }

    function testFuzzTransferFromWithStandardERC20(address from, address to, uint256 amount)
        public
    {
        verifySafeTransferFrom(address(erc20), from, to, amount, SUCCESS);
    }

    function testFuzzTransferFromWithReturnsTooMuch(address from, address to, uint256 amount)
        public
    {
        verifySafeTransferFrom(address(returnsTooMuch), from, to, amount, SUCCESS);
    }

    function testFuzzTransferFromWithGarbage(
        address from,
        address to,
        uint256 amount,
        bytes memory garbage
    ) public {
        if (garbageIsGarbage(garbage)) return;

        returnsGarbage.setGarbage(garbage);

        verifySafeTransferFrom(address(returnsGarbage), from, to, amount, SUCCESS);
    }

    function testFuzzTransferFromWithNonContract(
        address nonContract,
        address from,
        address to,
        uint256 amount
    ) public {
        if (uint256(uint160(nonContract)) <= 18 || nonContract.code.length > 0) {
            return;
        }

        SafeTransferLib.safeTransferFrom(nonContract, from, to, amount);
    }

    function testFuzzApproveWithMissingReturn(address to, uint256 amount) public {
        verifySafeApprove(address(missingReturn), to, amount, SUCCESS);
    }

    function testFuzzApproveWithStandardERC20(address to, uint256 amount) public {
        verifySafeApprove(address(erc20), to, amount, SUCCESS);
    }

    function testFuzzApproveWithReturnsTooMuch(address to, uint256 amount) public {
        verifySafeApprove(address(returnsTooMuch), to, amount, SUCCESS);
    }

    function testFuzzApproveWithGarbage(address to, uint256 amount, bytes memory garbage) public {
        if (garbageIsGarbage(garbage)) return;

        returnsGarbage.setGarbage(garbage);

        verifySafeApprove(address(returnsGarbage), to, amount, SUCCESS);
    }

    function testFuzzApproveWithNonContract(address nonContract, address to, uint256 amount)
        public
    {
        if (uint256(uint160(nonContract)) <= 18 || nonContract.code.length > 0) {
            return;
        }

        SafeTransferLib.safeApprove(nonContract, to, amount);
    }

    function testFuzzTransferETH(address recipient, uint256 amount) public {
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

    function testFuzzTransferWithReturnsFalseReverts(address to, uint256 amount) public {
        verifySafeTransfer(address(returnsFalse), to, amount, REVERTS_WITH_SELECTOR);
    }

    function testFuzzTransferWithRevertingReverts(address to, uint256 amount) public {
        verifySafeTransfer(address(reverting), to, amount, REVERTS_WITH_SELECTOR);
    }

    function testFuzzTransferWithReturnsTooLittleReverts(address to, uint256 amount) public {
        verifySafeTransfer(address(returnsTooLittle), to, amount, REVERTS_WITH_SELECTOR);
    }

    function testFuzzTransferWithReturnsTwoReverts(address to, uint256 amount) public {
        verifySafeTransfer(address(returnsTwo), to, amount, REVERTS_WITH_SELECTOR);
    }

    function testFuzzTransferWithGarbageReverts(address to, uint256 amount, bytes memory garbage)
        public
    {
        vm.assume(garbageIsGarbage(garbage));

        returnsGarbage.setGarbage(garbage);

        verifySafeTransfer(address(returnsGarbage), to, amount, REVERTS_WITH_ANY);
    }

    function testFuzzTransferFromWithReturnsFalseReverts(address from, address to, uint256 amount)
        public
    {
        verifySafeTransferFrom(address(returnsFalse), from, to, amount, REVERTS_WITH_SELECTOR);
    }

    function testFuzzTransferFromWithRevertingReverts(address from, address to, uint256 amount)
        public
    {
        verifySafeTransferFrom(address(reverting), from, to, amount, REVERTS_WITH_ANY);
    }

    function testFuzzTransferFromWithReturnsTooLittleReverts(
        address from,
        address to,
        uint256 amount
    ) public {
        verifySafeTransferFrom(address(returnsTooLittle), from, to, amount, REVERTS_WITH_SELECTOR);
    }

    function testFuzzTransferFromWithReturnsTwoReverts(address from, address to, uint256 amount)
        public
    {
        verifySafeTransferFrom(address(returnsTwo), from, to, amount, REVERTS_WITH_SELECTOR);
    }

    function testFuzzTransferFromWithGarbageReverts(
        address from,
        address to,
        uint256 amount,
        bytes memory garbage
    ) public {
        vm.assume(garbageIsGarbage(garbage));

        returnsGarbage.setGarbage(garbage);

        verifySafeTransferFrom(address(returnsGarbage), from, to, amount, REVERTS_WITH_ANY);
    }

    function testFuzzApproveWithReturnsFalseReverts(address to, uint256 amount) public {
        verifySafeApprove(address(returnsFalse), to, amount, REVERTS_WITH_SELECTOR);
    }

    function testFuzzApproveWithRevertingReverts(address to, uint256 amount) public {
        verifySafeApprove(address(reverting), to, amount, REVERTS_WITH_SELECTOR);
    }

    function testFuzzApproveWithReturnsTooLittleReverts(address to, uint256 amount) public {
        verifySafeApprove(address(returnsTooLittle), to, amount, REVERTS_WITH_SELECTOR);
    }

    function testFuzzApproveWithReturnsTwoReverts(address to, uint256 amount) public {
        verifySafeApprove(address(returnsTwo), to, amount, REVERTS_WITH_SELECTOR);
    }

    function testFuzzApproveWithGarbageReverts(address to, uint256 amount, bytes memory garbage)
        public
    {
        vm.assume(garbageIsGarbage(garbage));

        returnsGarbage.setGarbage(garbage);

        verifySafeApprove(address(returnsGarbage), to, amount, REVERTS_WITH_ANY);
    }

    function testFuzzTransferETHToContractWithoutFallbackReverts(uint256 amount) public {
        vm.expectRevert(SafeTransferLib.ETHTransferFailed.selector);
        this.safeTransferETH(address(this), amount);
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
            SafeTransferLib.safeTransferAll(address(token), to);
        } else {
            SafeTransferLib.safeTransfer(address(token), to, amount);
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
            SafeTransferLib.safeTransferAllFrom(address(token), from, to);
        } else {
            SafeTransferLib.safeTransferFrom(token, from, to, amount);
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
        SafeTransferLib.safeApprove(address(token), to, amount);

        assertEq(ERC20(token).allowance(address(this), to), amount);
    }

    function forceApprove(address token, address from, address to, uint256 amount) public {
        uint256 slot = token == address(erc20) ? 4 : 2; // Standard ERC20 name and symbol aren't constant.

        vm.store(
            token,
            keccak256(abi.encode(to, keccak256(abi.encode(from, uint256(slot))))),
            bytes32(uint256(amount))
        );

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

    function garbageIsGarbage(bytes memory garbage) public pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result :=
                and(
                    or(lt(mload(garbage), 32), iszero(eq(mload(add(garbage, 0x20)), 1))),
                    gt(mload(garbage), 0)
                )
        }
    }
}
