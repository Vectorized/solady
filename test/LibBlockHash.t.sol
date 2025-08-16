// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {LibBlockHash} from "../src/utils/LibBlockHash.sol";

contract LibBlockHashTest is SoladyTest {
    uint256 internal startingBlock;

    address internal constant SYSTEM_ADDRESS = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;

    bytes private constant _HISTORY_STORAGE_BYTECODE =
        hex"3373fffffffffffffffffffffffffffffffffffffffe14604657602036036042575f35600143038111604257611fff81430311604257611fff9006545f5260205ff35b5f5ffd5b5f35611fff60014303065500";

    function setUp() public {
        vm.roll(block.number + 100);
        startingBlock = block.number;
        vm.etch(LibBlockHash.HISTORY_STORAGE_ADDRESS, _HISTORY_STORAGE_BYTECODE);
    }

    function __blockHash(uint256 blockNumber, bytes32 expectedHash, bytes32 sysExpectedHash)
        internal
        view
        returns (bool)
    {
        if (expectedHash != sysExpectedHash) return false;
        return sysExpectedHash == LibBlockHash.blockHash(blockNumber);
    }

    function testFuzzRecentBlocks(uint8 offset, uint64 currentBlock, bytes32 expectedHash) public {
        // Recent blocks (1-256 blocks old)
        uint256 boundedOffset = uint256(offset) + 1;
        vm.assume(currentBlock > boundedOffset);
        vm.roll(currentBlock);

        uint256 targetBlock = currentBlock - boundedOffset;
        vm.setBlockhash(targetBlock, expectedHash);

        assertTrue(__blockHash(targetBlock, expectedHash, blockhash(targetBlock)));
    }

    function testFuzzVeryOldBlocks(uint256 offset, uint256 currentBlock) public {
        // Very old blocks (>8191 blocks old)
        offset = _bound(offset, 8192, type(uint256).max);
        vm.assume(currentBlock > offset);
        vm.roll(currentBlock);

        uint256 targetBlock = currentBlock - offset;
        assertTrue(__blockHash(targetBlock, bytes32(0), bytes32(0)));
    }

    function testFuzzFutureBlocks(uint256 offset, uint256 currentBlock) public {
        // Future blocks
        offset = _bound(offset, 1, type(uint256).max);
        currentBlock = _bound(currentBlock, 0, type(uint256).max - offset);
        vm.roll(currentBlock);

        unchecked {
            uint256 targetBlock = currentBlock + offset;
            assertTrue(__blockHash(targetBlock, blockhash(targetBlock), blockhash(targetBlock)));
        }
    }

    function testUnsupportedChainsReturnZeroWhenOutOfRange() public {
        vm.etch(LibBlockHash.HISTORY_STORAGE_ADDRESS, hex"");

        vm.roll(block.number + 1000);
        assertEq(LibBlockHash.blockHash(block.number - 1000), bytes32(0));
    }
}
