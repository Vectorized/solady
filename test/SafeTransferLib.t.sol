// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {MockERC20} from "./utils/mocks/MockERC20.sol";
import {RevertingToken} from "./utils/weird-tokens/RevertingToken.sol";
import {ReturnsTwoToken} from "./utils/weird-tokens/ReturnsTwoToken.sol";
import {ReturnsFalseToken} from "./utils/weird-tokens/ReturnsFalseToken.sol";
import {MissingReturnToken} from "./utils/weird-tokens/MissingReturnToken.sol";
import {ReturnsTooMuchToken} from "./utils/weird-tokens/ReturnsTooMuchToken.sol";
import {ReturnsGarbageToken} from "./utils/weird-tokens/ReturnsGarbageToken.sol";
import {ReturnsTooLittleToken} from "./utils/weird-tokens/ReturnsTooLittleToken.sol";

import "forge-std/Test.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "../src/utils/SafeTransferLib.sol";

contract SafeTransferLibTest is Test {
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

    function testFuzzTransferWithMissingReturn(
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeTransfer(address(missingReturn), to, amount);
    }

    function testFuzzTransferWithStandardERC20(
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeTransfer(address(erc20), to, amount);
    }

    function testFuzzTransferWithReturnsTooMuch(
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeTransfer(address(returnsTooMuch), to, amount);
    }

    function testFuzzTransferWithGarbage(
        address to,
        uint256 amount,
        bytes memory garbage,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        if (
            (garbage.length < 32 ||
                (garbage[0] != 0 ||
                    garbage[1] != 0 ||
                    garbage[2] != 0 ||
                    garbage[3] != 0 ||
                    garbage[4] != 0 ||
                    garbage[5] != 0 ||
                    garbage[6] != 0 ||
                    garbage[7] != 0 ||
                    garbage[8] != 0 ||
                    garbage[9] != 0 ||
                    garbage[10] != 0 ||
                    garbage[11] != 0 ||
                    garbage[12] != 0 ||
                    garbage[13] != 0 ||
                    garbage[14] != 0 ||
                    garbage[15] != 0 ||
                    garbage[16] != 0 ||
                    garbage[17] != 0 ||
                    garbage[18] != 0 ||
                    garbage[19] != 0 ||
                    garbage[20] != 0 ||
                    garbage[21] != 0 ||
                    garbage[22] != 0 ||
                    garbage[23] != 0 ||
                    garbage[24] != 0 ||
                    garbage[25] != 0 ||
                    garbage[26] != 0 ||
                    garbage[27] != 0 ||
                    garbage[28] != 0 ||
                    garbage[29] != 0 ||
                    garbage[30] != 0 ||
                    garbage[31] != bytes1(0x01))) && garbage.length != 0
        ) return;

        returnsGarbage.setGarbage(garbage);

        verifySafeTransfer(address(returnsGarbage), to, amount);
    }

    function testFuzzTransferWithNonContract(
        address nonContract,
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        if (uint256(uint160(nonContract)) <= 18 || nonContract.code.length > 0) return;

        SafeTransferLib.safeTransfer(nonContract, to, amount);
    }

    function testFailTransferETHToContractWithoutFallback() public {
        SafeTransferLib.safeTransferETH(address(this), 1e18);
    }

    function testFuzzTransferFromWithMissingReturn(
        address from,
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeTransferFrom(address(missingReturn), from, to, amount);
    }

    function testFuzzTransferFromWithStandardERC20(
        address from,
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeTransferFrom(address(erc20), from, to, amount);
    }

    function testFuzzTransferFromWithReturnsTooMuch(
        address from,
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeTransferFrom(address(returnsTooMuch), from, to, amount);
    }

    function testFuzzTransferFromWithGarbage(
        address from,
        address to,
        uint256 amount,
        bytes memory garbage,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        if (
            (garbage.length < 32 ||
                (garbage[0] != 0 ||
                    garbage[1] != 0 ||
                    garbage[2] != 0 ||
                    garbage[3] != 0 ||
                    garbage[4] != 0 ||
                    garbage[5] != 0 ||
                    garbage[6] != 0 ||
                    garbage[7] != 0 ||
                    garbage[8] != 0 ||
                    garbage[9] != 0 ||
                    garbage[10] != 0 ||
                    garbage[11] != 0 ||
                    garbage[12] != 0 ||
                    garbage[13] != 0 ||
                    garbage[14] != 0 ||
                    garbage[15] != 0 ||
                    garbage[16] != 0 ||
                    garbage[17] != 0 ||
                    garbage[18] != 0 ||
                    garbage[19] != 0 ||
                    garbage[20] != 0 ||
                    garbage[21] != 0 ||
                    garbage[22] != 0 ||
                    garbage[23] != 0 ||
                    garbage[24] != 0 ||
                    garbage[25] != 0 ||
                    garbage[26] != 0 ||
                    garbage[27] != 0 ||
                    garbage[28] != 0 ||
                    garbage[29] != 0 ||
                    garbage[30] != 0 ||
                    garbage[31] != bytes1(0x01))) && garbage.length != 0
        ) return;

        returnsGarbage.setGarbage(garbage);

        verifySafeTransferFrom(address(returnsGarbage), from, to, amount);
    }

    function testFuzzTransferFromWithNonContract(
        address nonContract,
        address from,
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        if (uint256(uint160(nonContract)) <= 18 || nonContract.code.length > 0) return;

        SafeTransferLib.safeTransferFrom(nonContract, from, to, amount);
    }

    function testFuzzApproveWithMissingReturn(
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeApprove(address(missingReturn), to, amount);
    }

    function testFuzzApproveWithStandardERC20(
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeApprove(address(erc20), to, amount);
    }

    function testFuzzApproveWithReturnsTooMuch(
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeApprove(address(returnsTooMuch), to, amount);
    }

    function testFuzzApproveWithGarbage(
        address to,
        uint256 amount,
        bytes memory garbage,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        if (
            (garbage.length < 32 ||
                (garbage[0] != 0 ||
                    garbage[1] != 0 ||
                    garbage[2] != 0 ||
                    garbage[3] != 0 ||
                    garbage[4] != 0 ||
                    garbage[5] != 0 ||
                    garbage[6] != 0 ||
                    garbage[7] != 0 ||
                    garbage[8] != 0 ||
                    garbage[9] != 0 ||
                    garbage[10] != 0 ||
                    garbage[11] != 0 ||
                    garbage[12] != 0 ||
                    garbage[13] != 0 ||
                    garbage[14] != 0 ||
                    garbage[15] != 0 ||
                    garbage[16] != 0 ||
                    garbage[17] != 0 ||
                    garbage[18] != 0 ||
                    garbage[19] != 0 ||
                    garbage[20] != 0 ||
                    garbage[21] != 0 ||
                    garbage[22] != 0 ||
                    garbage[23] != 0 ||
                    garbage[24] != 0 ||
                    garbage[25] != 0 ||
                    garbage[26] != 0 ||
                    garbage[27] != 0 ||
                    garbage[28] != 0 ||
                    garbage[29] != 0 ||
                    garbage[30] != 0 ||
                    garbage[31] != bytes1(0x01))) && garbage.length != 0
        ) return;

        returnsGarbage.setGarbage(garbage);

        verifySafeApprove(address(returnsGarbage), to, amount);
    }

    function testFuzzApproveWithNonContract(
        address nonContract,
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        if (uint256(uint160(nonContract)) <= 18 || nonContract.code.length > 0) return;

        SafeTransferLib.safeApprove(nonContract, to, amount);
    }

    function testFuzzTransferETH(
        address recipient,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        // Transferring to msg.sender can fail because it's possible to overflow their ETH balance as it begins non-zero.
        if (recipient.code.length > 0 || uint256(uint160(recipient)) <= 18 || recipient == msg.sender) return;

        amount = bound(amount, 0, address(this).balance);

        SafeTransferLib.safeTransferETH(recipient, amount);
    }

    function testFailFuzzTransferWithReturnsFalse(
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeTransfer(address(returnsFalse), to, amount);
    }

    function testFailFuzzTransferWithReverting(
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeTransfer(address(reverting), to, amount);
    }

    function testFailFuzzTransferWithReturnsTooLittle(
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeTransfer(address(returnsTooLittle), to, amount);
    }

    function testFailFuzzTransferWithReturnsTwo(
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeTransfer(address(returnsTwo), to, amount);
    }

    function testFailFuzzTransferWithGarbage(
        address to,
        uint256 amount,
        bytes memory garbage,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        require(garbage.length != 0 && (garbage.length < 32 || garbage[31] != bytes1(0x01)));

        returnsGarbage.setGarbage(garbage);

        verifySafeTransfer(address(returnsGarbage), to, amount);
    }

    function testFailFuzzTransferFromWithReturnsFalse(
        address from,
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeTransferFrom(address(returnsFalse), from, to, amount);
    }

    function testFailFuzzTransferFromWithReverting(
        address from,
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeTransferFrom(address(reverting), from, to, amount);
    }

    function testFailFuzzTransferFromWithReturnsTooLittle(
        address from,
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeTransferFrom(address(returnsTooLittle), from, to, amount);
    }

    function testFailFuzzTransferFromWithReturnsTwo(
        address from,
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeTransferFrom(address(returnsTwo), from, to, amount);
    }

    function testFailFuzzTransferFromWithGarbage(
        address from,
        address to,
        uint256 amount,
        bytes memory garbage,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        require(garbage.length != 0 && (garbage.length < 32 || garbage[31] != bytes1(0x01)));

        returnsGarbage.setGarbage(garbage);

        verifySafeTransferFrom(address(returnsGarbage), from, to, amount);
    }

    function testFailFuzzApproveWithReturnsFalse(
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeApprove(address(returnsFalse), to, amount);
    }

    function testFailFuzzApproveWithReverting(
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeApprove(address(reverting), to, amount);
    }

    function testFailFuzzApproveWithReturnsTooLittle(
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeApprove(address(returnsTooLittle), to, amount);
    }

    function testFailFuzzApproveWithReturnsTwo(
        address to,
        uint256 amount,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        verifySafeApprove(address(returnsTwo), to, amount);
    }

    function testFailFuzzApproveWithGarbage(
        address to,
        uint256 amount,
        bytes memory garbage,
        bytes calldata brutalizeWith
    ) public brutalizeMemory(brutalizeWith) {
        require(garbage.length != 0 && (garbage.length < 32 || garbage[31] != bytes1(0x01)));

        returnsGarbage.setGarbage(garbage);

        verifySafeApprove(address(returnsGarbage), to, amount);
    }

    function testFailFuzzTransferETHToContractWithoutFallback(uint256 amount, bytes calldata brutalizeWith)
        public
        brutalizeMemory(brutalizeWith)
    {
        SafeTransferLib.safeTransferETH(address(this), amount);
    }

    function verifySafeTransfer(
        address token,
        address to,
        uint256 amount
    ) internal {
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
    ) internal {
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
    ) internal {
        SafeTransferLib.safeApprove(address(token), to, amount);

        assertEq(ERC20(token).allowance(address(this), to), amount);
    }

    function forceApprove(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        uint256 slot = token == address(erc20) ? 4 : 2; // Standard ERC20 name and symbol aren't constant.

        vm.store(
            token,
            keccak256(abi.encode(to, keccak256(abi.encode(from, uint256(slot))))),
            bytes32(uint256(amount))
        );

        assertEq(ERC20(token).allowance(from, to), amount, "wrong allowance");
    }

    modifier brutalizeMemory(bytes memory brutalizeWith) {
        /// @solidity memory-safe-assembly
        assembly {
            // Fill the 64 bytes of scratch space with the data.
            pop(
                staticcall(
                    gas(), // Pass along all the gas in the call.
                    0x04, // Call the identity precompile address.
                    brutalizeWith, // Offset is the bytes' pointer.
                    64, // Copy enough to only fill the scratch space.
                    0, // Store the return value in the scratch space.
                    64 // Scratch space is only 64 bytes in size, we don't want to write further.
                )
            )

            let size := add(mload(brutalizeWith), 32) // Add 32 to include the 32 byte length slot.

            // Fill the free memory pointer's destination with the data.
            pop(
                staticcall(
                    gas(), // Pass along all the gas in the call.
                    0x04, // Call the identity precompile address.
                    brutalizeWith, // Offset is the bytes' pointer.
                    size, // We want to pass the length of the bytes.
                    mload(0x40), // Store the return value at the free memory pointer.
                    size // Since the precompile just returns its input, we reuse size.
                )
            )
        }

        _;
    }
}
