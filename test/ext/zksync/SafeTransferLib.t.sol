// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {MockERC20} from "./../../utils/mocks/MockERC20.sol";
import {MockERC20LikeUSDT} from "./../../utils/mocks/MockERC20LikeUSDT.sol";
import {MockETHRecipient} from "./../../utils/mocks/MockETHRecipient.sol";
import {RevertingToken} from "./../../utils/weird-tokens/RevertingToken.sol";
import {ReturnsTwoToken} from "./../../utils/weird-tokens/ReturnsTwoToken.sol";
import {ReturnsFalseToken} from "./../../utils/weird-tokens/ReturnsFalseToken.sol";
import {MissingReturnToken} from "./../../utils/weird-tokens/MissingReturnToken.sol";
import {ReturnsTooMuchToken} from "./../../utils/weird-tokens/ReturnsTooMuchToken.sol";
import {ReturnsRawBytesToken} from "./../../utils/weird-tokens/ReturnsRawBytesToken.sol";
import {ReturnsTooLittleToken} from "./../../utils/weird-tokens/ReturnsTooLittleToken.sol";

import "./../../utils/SoladyTest.sol";

import {ERC20} from "../../../src/tokens/ERC20.sol";
import {SafeTransferLib} from "../../../src/utils/ext/zksync/SafeTransferLib.sol";

contract Griefer {
    uint256 public receiveNumLoops;

    uint256[] internal _junk;

    event Junk(uint256 indexed i);

    function setReceiveNumLoops(uint256 amount) public {
        receiveNumLoops = amount;
    }

    function execute(address to, bytes memory data) public {
        (bool success,) = to.call(data);
        require(success);
    }

    function doStuff() public payable {
        unchecked {
            uint256 n = receiveNumLoops;
            if (n > 0xffffffff) revert();
            for (uint256 i; i < n; ++i) {
                _junk.push(i);
            }
        }
    }

    receive() external payable {
        doStuff();
    }

    fallback() external payable {
        doStuff();
    }
}

contract SafeTransferLibTest is SoladyTest {
    uint256 internal constant _SUCCESS = 1;
    uint256 internal constant _REVERTS_WITH_SELECTOR = 2;
    uint256 internal constant _REVERTS_WITH_ANY = 3;

    address internal constant _REGULAR_EVM_PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    RevertingToken reverting;
    ReturnsTwoToken returnsTwo;
    ReturnsFalseToken returnsFalse;
    MissingReturnToken missingReturn;
    ReturnsTooMuchToken returnsTooMuch;
    ReturnsRawBytesToken returnsRawBytes;
    ReturnsTooLittleToken returnsTooLittle;

    MockERC20 erc20;

    Griefer griefer;

    function setUp() public {
        vm.chainId(1);
        reverting = new RevertingToken();
        returnsTwo = new ReturnsTwoToken();
        returnsFalse = new ReturnsFalseToken();
        missingReturn = new MissingReturnToken();
        returnsTooMuch = new ReturnsTooMuchToken();
        returnsRawBytes = new ReturnsRawBytesToken();
        returnsTooLittle = new ReturnsTooLittleToken();

        erc20 = new MockERC20("StandardToken", "ST", 18);
        erc20.mint(address(this), type(uint256).max);

        griefer = new Griefer();
    }

    function testTransferWithMissingReturn() public {
        verifySafeTransfer(address(missingReturn), address(0xBEEF), 1e18, _SUCCESS);
    }

    function testTransferWithStandardERC20() public {
        verifySafeTransfer(address(erc20), address(0xBEEF), 1e18, _SUCCESS);
    }

    function testTransferWithReturnsTooMuch() public {
        verifySafeTransfer(address(returnsTooMuch), address(0xBEEF), 1e18, _SUCCESS);
    }

    function testTransferWithNonContractReverts() public {
        vm.expectRevert(SafeTransferLib.TransferFailed.selector);
        this.safeTransfer(address(0xBADBEEF), address(0xBEEF), 1e18);
    }

    function testTransferFromWithMissingReturn() public {
        verifySafeTransferFrom(
            address(missingReturn), address(0xFEED), address(0xBEEF), 1e18, _SUCCESS
        );
    }

    function testTransferFromWithStandardERC20() public {
        verifySafeTransferFrom(address(erc20), address(0xFEED), address(0xBEEF), 1e18, _SUCCESS);
    }

    function testTransferFromWithReturnsTooMuch() public {
        verifySafeTransferFrom(
            address(returnsTooMuch), address(0xFEED), address(0xBEEF), 1e18, _SUCCESS
        );
    }

    function testTransferFromWithNonContractReverts() public {
        vm.expectRevert(SafeTransferLib.TransferFromFailed.selector);
        this.safeTransferFrom(address(0xBADBEEF), address(0xFEED), address(0xBEEF), 1e18);
    }

    function safeTransferFrom(address token, address from, address to, uint256 amount) public {
        SafeTransferLib.safeTransferFrom(
            _brutalized(token), _brutalized(from), _brutalized(to), amount
        );
    }

    function testApproveWithMissingReturn() public {
        verifySafeApprove(address(missingReturn), address(0xBEEF), 1e18, _SUCCESS);
    }

    function testApproveWithStandardERC20() public {
        verifySafeApprove(address(erc20), address(0xBEEF), 1e18, _SUCCESS);
    }

    function testApproveWithReturnsTooMuch() public {
        verifySafeApprove(address(returnsTooMuch), address(0xBEEF), 1e18, _SUCCESS);
    }

    function testApproveWithNonContractReverts() public {
        vm.expectRevert(SafeTransferLib.ApproveFailed.selector);
        this.safeApprove(address(0xBADBEEF), address(0xBEEF), 1e18);
    }

    function safeApprove(address token, address to, uint256 amount) public {
        SafeTransferLib.safeApprove(token, to, amount);
    }

    function testApproveWithRetryWithNonContractReverts() public {
        vm.expectRevert(SafeTransferLib.ApproveFailed.selector);
        this.safeApproveWithRetry(address(0xBADBEEF), address(0xBEEF), 1e18);
    }

    function safeApproveWithRetry(address token, address to, uint256 amount) public {
        SafeTransferLib.safeApproveWithRetry(token, to, amount);
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

    function testTryTransferAllETH() public {
        MockETHRecipient recipient = new MockETHRecipient(false, false);
        bool success = SafeTransferLib.trySafeTransferAllETH(address(recipient), gasleft());
        assertTrue(success);
    }

    function testTransferWithReturnsFalseReverts() public {
        verifySafeTransfer(address(returnsFalse), address(0xBEEF), 1e18, _REVERTS_WITH_SELECTOR);
    }

    function testTransferWithRevertingReverts() public {
        verifySafeTransfer(address(reverting), address(0xBEEF), 1e18, _REVERTS_WITH_SELECTOR);
    }

    function testTransferWithReturnsTooLittleReverts() public {
        verifySafeTransfer(address(returnsTooLittle), address(0xBEEF), 1e18, _REVERTS_WITH_SELECTOR);
    }

    function testTransferFromWithReturnsFalseReverts() public {
        verifySafeTransferFrom(
            address(returnsFalse), address(0xFEED), address(0xBEEF), 1e18, _REVERTS_WITH_SELECTOR
        );
    }

    function testTransferFromWithRevertingReverts() public {
        verifySafeTransferFrom(
            address(reverting), address(0xFEED), address(0xBEEF), 1e18, _REVERTS_WITH_ANY
        );
    }

    function testTransferFromWithReturnsTooLittleReverts() public {
        verifySafeTransferFrom(
            address(returnsTooLittle),
            address(0xFEED),
            address(0xBEEF),
            1e18,
            _REVERTS_WITH_SELECTOR
        );
    }

    function testApproveWithReturnsFalseReverts() public {
        verifySafeApprove(address(returnsFalse), address(0xBEEF), 1e18, _REVERTS_WITH_SELECTOR);
    }

    function testApproveWithRevertingReverts() public {
        verifySafeApprove(address(reverting), address(0xBEEF), 1e18, _REVERTS_WITH_SELECTOR);
    }

    function testApproveWithReturnsTooLittleReverts() public {
        verifySafeApprove(address(returnsTooLittle), address(0xBEEF), 1e18, _REVERTS_WITH_SELECTOR);
    }

    function testBalanceOfStandardERC20() public view {
        erc20.balanceOf(address(this));
    }

    function testBalanceOfStandardERC20(address to, uint256 amount) public {
        uint256 originalBalance = erc20.balanceOf(address(this));
        while (originalBalance < amount) amount = _random();
        while (to == address(this)) to = _randomHashedAddress();

        SafeTransferLib.safeTransfer(address(erc20), _brutalized(to), originalBalance - amount);
        assertEq(SafeTransferLib.balanceOf(address(erc20), _brutalized(address(this))), amount);
    }

    function testTransferAllWithStandardERC20() public {
        SafeTransferLib.safeTransferAll(address(erc20), address(1));
    }

    function testTransferAllWithStandardERC20(address to, uint256 amount) public {
        uint256 originalBalance = erc20.balanceOf(address(this));
        while (originalBalance < amount) amount = _random();
        while (to == address(this)) to = _randomHashedAddress();

        SafeTransferLib.safeTransfer(address(erc20), _brutalized(to), originalBalance - amount);
        assertEq(erc20.balanceOf(address(this)), amount);

        assertEq(SafeTransferLib.safeTransferAll(address(erc20), _brutalized(to)), amount);

        assertEq(erc20.balanceOf(address(this)), 0);
        assertEq(erc20.balanceOf(to), originalBalance);
    }

    function testTrySafeTransferFrom(address from, address to, uint256 amount) public {
        uint256 balance = _random();
        while (from == address(this) || to == address(this) || from == to) {
            from = _randomNonZeroAddress();
            to = _randomNonZeroAddress();
        }
        erc20.transfer(from, balance);
        vm.prank(from);
        erc20.approve(address(this), type(uint256).max);
        bool result = SafeTransferLib.trySafeTransferFrom(address(erc20), from, to, amount);
        assertEq(result, amount <= balance);
    }

    function testTransferAllFromWithStandardERC20() public {
        forceApprove(address(erc20), address(this), address(this), type(uint256).max);
        SafeTransferLib.safeTransferAllFrom(address(erc20), address(this), address(1));
    }

    function testTransferAllFromWithStandardERC20(address from, address to, uint256 amount)
        public
    {
        while (!(to != from && to != address(this) && from != address(this))) {
            to = _randomNonZeroAddress();
            from = _randomNonZeroAddress();
        }

        SafeTransferLib.safeTransferAll(address(erc20), _brutalized(from));

        uint256 originalBalance = erc20.balanceOf(from);
        while (originalBalance < amount) amount = _random();

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
        verifySafeTransfer(address(missingReturn), to, amount, _SUCCESS);
    }

    function testTransferWithStandardERC20(address to, uint256 amount) public {
        verifySafeTransfer(address(erc20), to, amount, _SUCCESS);
    }

    function testTransferWithReturnsTooMuch(address to, uint256 amount) public {
        verifySafeTransfer(address(returnsTooMuch), to, amount, _SUCCESS);
    }

    function testTransferWithNonGarbage(address to, uint256 amount) public {
        returnsRawBytes.setRawBytes(_generateNonGarbage());

        verifySafeTransfer(address(returnsRawBytes), to, amount, _SUCCESS);
    }

    function testTransferWithNonContractReverts(bytes32, address to, uint256 amount) public {
        vm.expectRevert(SafeTransferLib.TransferFailed.selector);
        this.safeTransfer(_randomHashedAddress(), to, amount);
    }

    function safeTransfer(address token, address to, uint256 amount) public {
        SafeTransferLib.safeTransfer(token, to, amount);
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
        verifySafeTransferFrom(address(missingReturn), from, to, amount, _SUCCESS);
    }

    function testTransferFromWithStandardERC20(address from, address to, uint256 amount) public {
        verifySafeTransferFrom(address(erc20), from, to, amount, _SUCCESS);
    }

    function testTransferFromWithReturnsTooMuch(address from, address to, uint256 amount) public {
        verifySafeTransferFrom(address(returnsTooMuch), from, to, amount, _SUCCESS);
    }

    function testTransferFromWithNonGarbage(address from, address to, uint256 amount) public {
        returnsRawBytes.setRawBytes(_generateNonGarbage());

        verifySafeTransferFrom(address(returnsRawBytes), from, to, amount, _SUCCESS);
    }

    function testTransferFromWithNonContractReverts(
        address nonContract,
        address from,
        address to,
        uint256 amount
    ) public {
        if (uint256(uint160(nonContract)) <= 18 || nonContract.code.length > 0) {
            return;
        }
        vm.expectRevert(SafeTransferLib.TransferFromFailed.selector);
        this.safeTransferFrom(nonContract, from, to, amount);
    }

    function testApproveWithMissingReturn(address to, uint256 amount) public {
        if (to == _REGULAR_EVM_PERMIT2) return;
        verifySafeApprove(address(missingReturn), to, amount, _SUCCESS);
    }

    function testApproveWithStandardERC20(address to, uint256 amount) public {
        if (to == _REGULAR_EVM_PERMIT2) return;
        verifySafeApprove(address(erc20), to, amount, _SUCCESS);
    }

    function testApproveWithReturnsTooMuch(address to, uint256 amount) public {
        if (to == _REGULAR_EVM_PERMIT2) return;
        verifySafeApprove(address(returnsTooMuch), to, amount, _SUCCESS);
    }

    function testApproveWithNonGarbage(address to, uint256 amount) public {
        if (to == _REGULAR_EVM_PERMIT2) return;
        returnsRawBytes.setRawBytes(_generateNonGarbage());

        verifySafeApprove(address(returnsRawBytes), to, amount, _SUCCESS);
    }

    function testApproveWithNonContractReverts(address nonContract, address to, uint256 amount)
        public
    {
        if (to == _REGULAR_EVM_PERMIT2) return;
        if (uint256(uint160(nonContract)) <= 18 || nonContract.code.length > 0) {
            return;
        }
        vm.expectRevert(SafeTransferLib.ApproveFailed.selector);
        this.safeApprove(nonContract, to, amount);
    }

    function testApproveWithRetryWithNonContractReverts(
        address nonContract,
        address to,
        uint256 amount
    ) public {
        if (to == _REGULAR_EVM_PERMIT2) return;
        if (uint256(uint160(nonContract)) <= 18 || nonContract.code.length > 0) {
            return;
        }
        vm.expectRevert(SafeTransferLib.ApproveFailed.selector);
        this.safeApproveWithRetry(nonContract, to, amount);
    }

    function testApproveWithRetry(address to, uint256 amount0, uint256 amount1) public {
        if (to == _REGULAR_EVM_PERMIT2) return;
        MockERC20LikeUSDT usdt = new MockERC20LikeUSDT();
        assertEq(usdt.allowance(address(this), to), 0);
        SafeTransferLib.safeApproveWithRetry(address(usdt), _brutalized(to), amount0);
        assertEq(usdt.allowance(address(this), to), amount0);
        if (amount0 != 0 && amount1 != 0) {
            verifySafeApprove(address(usdt), to, amount1, _REVERTS_WITH_SELECTOR);
        }
        SafeTransferLib.safeApproveWithRetry(address(usdt), _brutalized(to), amount1);
        assertEq(usdt.allowance(address(this), to), amount1);
    }

    function testApproveWithRetry() public {
        testApproveWithRetry(address(1), 123, 456);
    }

    function testTransferETH(bytes32, uint256 amount) public {
        amount = _bound(amount, 0, address(this).balance);
        SafeTransferLib.safeTransferETH(_randomHashedAddress(), amount);
    }

    function testTransferAllETH(bytes32) public {
        SafeTransferLib.safeTransferAllETH(_randomHashedAddress());
    }

    function testTransferWithReturnsFalseReverts(address to, uint256 amount) public {
        verifySafeTransfer(address(returnsFalse), to, amount, _REVERTS_WITH_SELECTOR);
    }

    function testTransferWithRevertingReverts(address to, uint256 amount) public {
        verifySafeTransfer(address(reverting), to, amount, _REVERTS_WITH_SELECTOR);
    }

    function testTransferWithReturnsTooLittleReverts(address to, uint256 amount) public {
        verifySafeTransfer(address(returnsTooLittle), to, amount, _REVERTS_WITH_SELECTOR);
    }

    function testTransferWithReturnsTwoReverts(address to, uint256 amount) public {
        verifySafeTransfer(address(returnsTwo), to, amount, _REVERTS_WITH_SELECTOR);
    }

    function testTransferWithGarbageReverts(address to, uint256 amount) public {
        returnsRawBytes.setRawBytes(_generateGarbage());

        verifySafeTransfer(address(returnsRawBytes), to, amount, _REVERTS_WITH_ANY);
    }

    function testTransferFromWithReturnsFalseReverts(address from, address to, uint256 amount)
        public
    {
        verifySafeTransferFrom(address(returnsFalse), from, to, amount, _REVERTS_WITH_SELECTOR);
    }

    function testTransferFromWithRevertingReverts(address from, address to, uint256 amount)
        public
    {
        verifySafeTransferFrom(address(reverting), from, to, amount, _REVERTS_WITH_ANY);
    }

    function testTransferFromWithReturnsTooLittleReverts(address from, address to, uint256 amount)
        public
    {
        verifySafeTransferFrom(address(returnsTooLittle), from, to, amount, _REVERTS_WITH_SELECTOR);
    }

    function testTransferFromWithReturnsTwoReverts(address from, address to, uint256 amount)
        public
    {
        verifySafeTransferFrom(address(returnsTwo), from, to, amount, _REVERTS_WITH_SELECTOR);
    }

    function testTransferFromWithGarbageReverts(address from, address to, uint256 amount) public {
        returnsRawBytes.setRawBytes(_generateGarbage());

        verifySafeTransferFrom(address(returnsRawBytes), from, to, amount, _REVERTS_WITH_ANY);
    }

    function testApproveWithReturnsFalseReverts(address to, uint256 amount) public {
        verifySafeApprove(address(returnsFalse), to, amount, _REVERTS_WITH_SELECTOR);
    }

    function testApproveWithRevertingReverts(address to, uint256 amount) public {
        verifySafeApprove(address(reverting), to, amount, _REVERTS_WITH_SELECTOR);
    }

    function testApproveWithReturnsTooLittleReverts(address to, uint256 amount) public {
        verifySafeApprove(address(returnsTooLittle), to, amount, _REVERTS_WITH_SELECTOR);
    }

    function testApproveWithReturnsTwoReverts(address to, uint256 amount) public {
        verifySafeApprove(address(returnsTwo), to, amount, _REVERTS_WITH_SELECTOR);
    }

    function testApproveWithGarbageReverts(address to, uint256 amount) public {
        returnsRawBytes.setRawBytes(_generateGarbage());

        verifySafeApprove(address(returnsRawBytes), to, amount, _REVERTS_WITH_ANY);
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
        if (mode == _REVERTS_WITH_SELECTOR) {
            vm.expectRevert(SafeTransferLib.TransferFailed.selector);
        } else if (mode == _REVERTS_WITH_ANY) {
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
        if (amount == ERC20(token).balanceOf(address(this)) && _randomChance(2)) {
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
        if (mode == _REVERTS_WITH_SELECTOR) {
            vm.expectRevert(SafeTransferLib.TransferFromFailed.selector);
        } else if (mode == _REVERTS_WITH_ANY) {
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
        if (amount == ERC20(token).balanceOf(from) && _randomChance(2)) {
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
        if (mode == _REVERTS_WITH_SELECTOR) {
            vm.expectRevert(SafeTransferLib.ApproveFailed.selector);
        } else if (mode == _REVERTS_WITH_ANY) {
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

    function testTotalSupplyQuery() public {
        uint256 totalSupplyBefore = this.totalSupplyQuery(address(erc20));
        erc20.burn(address(this), 123);
        assertEq(this.totalSupplyQuery(address(erc20)), totalSupplyBefore - 123);
        vm.expectRevert(SafeTransferLib.TotalSupplyQueryFailed.selector);
        this.totalSupplyQuery(address(0));
    }

    function totalSupplyQuery(address token) public view returns (uint256) {
        return SafeTransferLib.totalSupply(token);
    }

    function testForceSafeTransferETH(uint256 amount) public {
        address vault;
        amount = _bound(amount, 0, 1 ether);
        vm.deal(address(this), 1 ether);
        griefer.setReceiveNumLoops(1 << 128);

        vault = SafeTransferLib.forceSafeTransferETH(address(griefer), 1 ether);
        assertNotEq(vault, address(0));
        assertEq(vault.balance, 1 ether);

        griefer.setReceiveNumLoops(0);

        if (_randomChance(2)) {
            vm.prank(address(griefer));
            (bool success,) = vault.call("");
            assertTrue(success);
            assertEq(address(griefer).balance, 1 ether);
        } else {
            (address to, bytes memory data) = _sampleToAndVaultCalldata();
            if (uint160(to) < 0xffff) return;
            vm.prank(address(griefer));
            (bool success,) = vault.call(data);
            assertTrue(success);
            assertEq(to.balance, 1 ether);
        }
    }

    function _sampleToAndVaultCalldata() internal returns (address to, bytes memory data) {
        if (_randomChance(2)) {
            to = _randomHashedAddress();
            data = abi.encodePacked(abi.encode(to), new bytes(_randomUniform() % 64));
            return (to, data);
        }
        uint256 r = _randomUniform();
        uint256 n = _bound(_randomUniform(), 1, 32);
        /// @solidity memory-safe-assembly
        assembly {
            data := mload(0x40)
            mstore(add(data, 0x20), r)
            mstore(data, n)
            mstore(0x40, add(n, add(0x20, data)))
            mstore(0x00, 0)
            mstore(sub(0x20, n), r)
            to := mload(0x00)
        }
    }

    function testForceSafeTransferETH() public {
        address vault;
        vm.deal(address(this), 1 ether);
        vault = SafeTransferLib.forceSafeTransferETH(address(griefer), 0.1 ether);
        assertEq(address(griefer).balance, 0.1 ether);

        griefer.setReceiveNumLoops(1 << 128);
        vault = SafeTransferLib.forceSafeTransferETH(address(griefer), 0.1 ether);
        assertEq(address(griefer).balance, 0.1 ether);

        griefer.setReceiveNumLoops(0);
        griefer.execute(vault, abi.encode(address(griefer)));
        assertEq(address(griefer).balance, 0.2 ether);

        griefer.setReceiveNumLoops(1 << 128);
        vault = SafeTransferLib.forceSafeTransferETH(address(griefer), 0.1 ether);

        griefer.setReceiveNumLoops(0);
        griefer.execute(vault, "");
        assertEq(address(griefer).balance, 0.3 ether);

        griefer.setReceiveNumLoops(1 << 128);
        vault = SafeTransferLib.forceSafeTransferETH(address(griefer), 0.1 ether);

        griefer.setReceiveNumLoops(0);
        griefer.execute(vault, abi.encodePacked(address(griefer)));
        assertEq(address(griefer).balance, 0.4 ether);

        address anotherRecipient = address(new Griefer());

        griefer.setReceiveNumLoops(1 << 128);
        vault = SafeTransferLib.forceSafeTransferETH(address(griefer), 0.1 ether);

        griefer.setReceiveNumLoops(0);
        griefer.execute(vault, abi.encodePacked(address(anotherRecipient)));
        assertEq(address(anotherRecipient).balance, 0.1 ether);
    }
}
