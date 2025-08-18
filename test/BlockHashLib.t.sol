// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {BlockHashLib} from "../src/utils/BlockHashLib.sol";

contract BlockHashLibTest is SoladyTest {
    uint256 internal startingBlock;

    address internal constant SYSTEM_ADDRESS = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;

    bytes private constant _HISTORY_STORAGE_BYTECODE =
        hex"3373fffffffffffffffffffffffffffffffffffffffe14604657602036036042575f35600143038111604257611fff81430311604257611fff9006545f5260205ff35b5f5ffd5b5f35611fff60014303065500";

    function testBlockHash(
        uint256 simulationBlockNumber,
        uint256 queryBlockNumber,
        uint256 savedBlockedNumber,
        bytes32 hashToSave
    ) public {
        if (_randomChance(2)) {
            vm.etch(BlockHashLib.HISTORY_STORAGE_ADDRESS, _HISTORY_STORAGE_BYTECODE);
        }

        savedBlockedNumber = _bound(savedBlockedNumber, 0, 2 ** 64 - 1);

        vm.roll(savedBlockedNumber + 1);
        vm.prank(SYSTEM_ADDRESS);
        (bool success,) = BlockHashLib.HISTORY_STORAGE_ADDRESS.call(abi.encode(hashToSave));
        require(success);

        vm.setBlockhash(savedBlockedNumber, hashToSave);

        vm.roll(simulationBlockNumber);

        assertEq(BlockHashLib.blockHash(queryBlockNumber), _blockHash(queryBlockNumber));

        // Some random comment to trigger the CI via a visible diff. 3287623879676
    }

    function _blockHash(uint256 blockNumber) internal view returns (bytes32) {
        (bool success, bytes memory result) =
            address(this).staticcall(abi.encodeWithSignature("blockHash(uint256)", blockNumber));
        if (!success) return 0;
        return abi.decode(result, (bytes32));
    }

    function blockHash(uint256 blockNumber) public view returns (bytes32 result) {
        if (block.number <= blockNumber + 256) return blockhash(blockNumber);
        address a = BlockHashLib.HISTORY_STORAGE_ADDRESS;
        if (a.code.length == 0) return 0;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, blockNumber)
            mstore(0x00, 0)
            pop(staticcall(gas(), a, 0x20, 0x20, 0x00, 0x20))
            result := mload(0x00)
        }
    }
}
