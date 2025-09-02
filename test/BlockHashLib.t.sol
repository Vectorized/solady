// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {BlockHashLib, ShortHeader} from "../src/utils/BlockHashLib.sol";

contract BlockHashLibTest is SoladyTest {
    uint256 internal startingBlock;

    address internal constant SYSTEM_ADDRESS = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;

    bytes private constant _HISTORY_STORAGE_BYTECODE =
        hex"3373fffffffffffffffffffffffffffffffffffffffe14604657602036036042575f35600143038111604257611fff81430311604257611fff9006545f5260205ff35b5f5ffd5b5f35611fff60014303065500";

    // cast block 23270177  --raw
    // vm.getRawBlockHeader(23270177)
    bytes private constant _ETH_BLOCK_23270177 =
        hex"f9027da01581f4448b16694d5a728161cd65f8c80b88f5352a6f5bd2d2315b970582958da01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d4934794dadb0d80178819f2319190d340ce9a924f783711a010d2afa5dabcf2dbfe3aa82b758427938e07880bd6fef3c82c404d0dd7c3f0f3a0f81230c715a462c827898bf2e337982907a7af90e5be20f911785bda05dab93ca0740f11bc75cf25e40d78d892d2e03083eaa573e5b4c26913fcc1b833db854c94b9010085f734fb06ea8fe377abbcb2e27f9ac99751ba817dc327327db101fd76f964ed0b7ca161f148fc165b9e5b575dc7473f17f4b8ebbf4a7b02b3e1e642197f27b2af54680834449abaf833619ac7d18afb50b19d5f6944dca0dc952edfdd9837573783c339ee6a36353ce6e536eaaf29fcd569c426091d4e24568dc353347f98c74fb6f8c91d68d358467c437563f66566377fe6c3f9e8301dbeb5fc7e7adee7a85ef5f8fa905cedbaf26601e21ba91646cac4034601e51d889d49739ee6990943a6a41927660f68e1f50b9f9209ee29551a7dae478d88e0547eefc83334ea770bb6fbac620fc47479c2c59389622bf32f55e36a75e56a5fc47c38bf8ef211fc0e8084016313218402af50e883fc53b78468b5ea9b974275696c6465724e657420284e65746865726d696e6429a0580ca94e91c0e7aef26ffb0c86f6ae48ef40df6dd1629f203a1930e0ce0be9d188000000000000000084479c1e2aa00345740e1b79edb2fbb3a20220e1a497ea9bb82aaba7dc7a881f7f3cae8a8ea38080a06675ad2a40134499a753924a04b75898ae09efc6fba6b3d7a506203042cb7611a0e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";

    // keccak256(_ETH_BLOCK_23270177)
    bytes32 private constant _ETH_BLOCK_HASH_23270177 =
        0x5def79dc43d588fafa396f3fbf0bcfb9bf83eaf8003f4508a626b6d3e806b29f;

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

    function beforeTestSetup(bytes4 selector) public pure returns (bytes[] memory cd) {
        if (selector == this.testToShortHeader.selector) {
            cd = new bytes[](1);
            cd[0] = abi.encodeWithSelector(this.checkToShortHeader.selector, _ETH_BLOCK_23270177);
        }
        if (selector == this.testVerifyBlockHash.selector) {
            cd = new bytes[](1);
            cd[0] = abi.encodeWithSelector(this.checkVerifyBlockHash.selector, _ETH_BLOCK_23270177);
        }
    }

    function checkToShortHeader(bytes calldata h) public {
        ShortHeader memory expected = ShortHeader({
            parentHash: 0x1581f4448b16694d5a728161cd65f8c80b88f5352a6f5bd2d2315b970582958d,
            stateRoot: 0x10d2afa5dabcf2dbfe3aa82b758427938e07880bd6fef3c82c404d0dd7c3f0f3,
            transactionsRoot: 0xf81230c715a462c827898bf2e337982907a7af90e5be20f911785bda05dab93c,
            receiptsRoot: 0x740f11bc75cf25e40d78d892d2e03083eaa573e5b4c26913fcc1b833db854c94,
            logsBloom: [
                bytes32(0x85f734fb06ea8fe377abbcb2e27f9ac99751ba817dc327327db101fd76f964ed), // lol
                0x0b7ca161f148fc165b9e5b575dc7473f17f4b8ebbf4a7b02b3e1e642197f27b2,
                0xaf54680834449abaf833619ac7d18afb50b19d5f6944dca0dc952edfdd983757,
                0x3783c339ee6a36353ce6e536eaaf29fcd569c426091d4e24568dc353347f98c7,
                0x4fb6f8c91d68d358467c437563f66566377fe6c3f9e8301dbeb5fc7e7adee7a8,
                0x5ef5f8fa905cedbaf26601e21ba91646cac4034601e51d889d49739ee6990943,
                0xa6a41927660f68e1f50b9f9209ee29551a7dae478d88e0547eefc83334ea770b,
                0xb6fbac620fc47479c2c59389622bf32f55e36a75e56a5fc47c38bf8ef211fc0e
            ]
        });

        ShortHeader memory actual = BlockHashLib.toShortHeader(h);
        assertEq(actual.parentHash, expected.parentHash, "parentHash");
        assertEq(actual.stateRoot, expected.stateRoot, "stateRoot");
        assertEq(actual.transactionsRoot, expected.transactionsRoot, "transactionsRoot");
        assertEq(actual.receiptsRoot, expected.receiptsRoot, "receiptsRoot");
        assertEq(
            keccak256(abi.encodePacked(actual.logsBloom)),
            keccak256(abi.encodePacked(expected.logsBloom)),
            "logsBloom"
        );
    }

    function checkVerifyBlockHash(bytes calldata h) public {
        vm.roll(23270177 + 1);
        vm.setBlockhash(23270177, _ETH_BLOCK_HASH_23270177);
        assertEq(BlockHashLib.verifyBlockHash(h, 23270177), _ETH_BLOCK_HASH_23270177);
    }

    function testToShortHeader() public view {}

    function testVerifyBlockHash() public view {}
}
