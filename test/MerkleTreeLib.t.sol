// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {MerkleTreeLib} from "../src/utils/MerkleTreeLib.sol";
import {MerkleProofLib} from "../src/utils/MerkleProofLib.sol";
import {LibSort} from "../src/utils/LibSort.sol";
import {LibPRNG} from "../src/utils/LibPRNG.sol";
import {EfficientHashLib} from "../src/utils/EfficientHashLib.sol";

contract MerkleTreeLibTest is SoladyTest {
    using MerkleTreeLib for bytes32[];
    using LibPRNG for *;

    function testBuildCompleteMerkleTree(bytes32[] memory leafs, bytes32 r) public {
        _maybeBrutalizeMemory(r);
        if (leafs.length <= 1) {
            leafs = new bytes32[](1);
            leafs[0] = r;
        }
        bytes32[] memory t = MerkleTreeLib.build(leafs);
        assertEq(t.length, leafs.length * 2 - 1);
        if (leafs.length == 1) {
            assertEq(t[0], r);
        } else {
            assertNotEq(t[0], 0);
        }
        assertEq(t.root(), t[0]);
        assertEq(leafs.length, t.numLeafs());
        assertEq(t.length, t.numLeafs() + t.numInternalNodes());
        _checkMemory(t);
        if (leafs.length >= 1) {
            uint256 i = _randomUniform() % leafs.length;
            assertEq(t.leaf(i), leafs[i]);
        }
    }

    function testPad(bytes32[] memory leafs, bytes32 defaultFill, uint256 r) public {
        _maybeBrutalizeMemory(r);
        if (leafs.length == 0) return;
        assertEq(MerkleTreeLib.pad(leafs, defaultFill), _padOriginal(leafs, defaultFill));
        _checkMemory();
    }

    function _padOriginal(bytes32[] memory leafs, bytes32 defaultFill)
        internal
        pure
        returns (bytes32[] memory result)
    {
        unchecked {
            uint256 p = 1;
            while (p < leafs.length) p = p << 1;
            result = new bytes32[](p);
            for (uint256 i; i < p; ++i) {
                if (i < leafs.length) {
                    result[i] = leafs[i];
                } else {
                    result[i] = defaultFill;
                }
            }
        }
    }

    function _maybeBrutalizeMemory(uint256 r) internal view {
        _maybeBrutalizeMemory(bytes32(r));
    }

    function _maybeBrutalizeMemory(bytes32 r) internal view {
        uint256 h = uint256(EfficientHashLib.hash(r, "hehe"));
        if (h & 0xf0 == 0) _misalignFreeMemoryPointer();
        if (h & 0x0f == 0) _brutalizeMemory();
    }

    function testBuildAndGetLeaf(bytes32[] memory leafs, uint256 leafIndex) public {
        if (leafs.length == 0) return;

        if (leafIndex < leafs.length) {
            assertEq(this.buildAndGetLeaf(leafs, leafIndex), leafs[leafIndex]);
        } else {
            vm.expectRevert(MerkleTreeLib.MerkleTreeOutOfBoundsAccess.selector);
            this.buildAndGetLeaf(leafs, leafIndex);
        }
    }

    function buildAndGetLeaf(bytes32[] memory leafs, uint256 leafIndex)
        public
        pure
        returns (bytes32)
    {
        return MerkleTreeLib.build(leafs).leaf(leafIndex);
    }

    function testBuildAndGetLeafProof(bytes32[] memory leafs, uint256 leafIndex) public {
        if (leafs.length == 0) return _testBuildAndGetRoot(leafs);
        bytes32[] memory t = MerkleTreeLib.build(leafs);
        if (leafIndex < leafs.length) {
            bytes32[] memory proof = this.buildAndGetLeafProof(leafs, leafIndex);
            assertTrue(MerkleProofLib.verify(proof, t.root(), leafs[leafIndex]));
        } else {
            vm.expectRevert(MerkleTreeLib.MerkleTreeOutOfBoundsAccess.selector);
            this.buildAndGetLeafProof(leafs, leafIndex);
        }
    }

    function buildAndGetLeafProof(bytes32[] memory leafs, uint256 leafIndex)
        public
        pure
        returns (bytes32[] memory proof)
    {
        bytes32[] memory t = MerkleTreeLib.build(leafs);
        proof = t.leafProof(leafIndex);
        _checkMemory();
    }

    function testBuildAndGetNodeProof(bytes32[] memory leafs, uint256 nodeIndex) public {
        if (leafs.length == 0) return _testBuildAndGetRoot(leafs);
        bytes32[] memory t = MerkleTreeLib.build(leafs);
        if (nodeIndex < t.length) {
            bytes32[] memory proof = this.buildAndGetNodeProof(leafs, nodeIndex);
            assertTrue(MerkleProofLib.verify(proof, t.root(), t[nodeIndex]));
        } else {
            vm.expectRevert(MerkleTreeLib.MerkleTreeOutOfBoundsAccess.selector);
            this.buildAndGetNodeProof(leafs, nodeIndex);
        }
    }

    function buildAndGetNodeProof(bytes32[] memory leafs, uint256 nodeIndex)
        public
        pure
        returns (bytes32[] memory proof)
    {
        bytes32[] memory t = MerkleTreeLib.build(leafs);
        proof = t.nodeProof(nodeIndex);
        _checkMemory();
    }

    function _testBuildAndGetRoot(bytes32[] memory leafs) internal {
        vm.expectRevert(MerkleTreeLib.MerkleTreeLeafsEmpty.selector);
        this.buildAndGetRoot(leafs);
    }

    function buildAndGetRoot(bytes32[] memory leafs) public pure returns (bytes32) {
        return MerkleTreeLib.build(leafs).root();
    }

    function testGetRootFromEmptyTree() public {
        vm.expectRevert(MerkleTreeLib.MerkleTreeOutOfBoundsAccess.selector);
        this.getRootFromEmptyTree();
    }

    function getRootFromEmptyTree() public pure returns (bytes32) {
        return (new bytes32[](0)).root();
    }

    struct TestMultiProofTemps {
        bytes32[] leafs;
        uint256[] leafIndices;
        bytes32[] gathered;
        bytes32[] tree;
        bytes32[] proof;
        bool[] flags;
    }

    function testBuildAndGetLeafsMultiProof(bytes32) public {
        TestMultiProofTemps memory t;
        t.leafs = new bytes32[](_bound(_random(), 1, 128));
        for (uint256 i; i < t.leafs.length; ++i) {
            t.leafs[i] = bytes32(_random());
        }
        t.leafIndices = _generateUniqueLeafIndices(t.leafs);
        t.tree = MerkleTreeLib.build(t.leafs);
        (t.proof, t.flags) = t.tree.leafsMultiProof(t.leafIndices);
        t.gathered = _gatherLeafs(t.leafs, t.leafIndices);
        assertTrue(MerkleProofLib.verifyMultiProof(t.proof, t.tree.root(), t.gathered, t.flags));
    }

    function _generateUniqueLeafIndices(bytes32[] memory leafs)
        internal
        returns (uint256[] memory indices)
    {
        indices = new uint256[](leafs.length);
        for (uint256 i; i < leafs.length; ++i) {
            indices[i] = i;
        }
        LibPRNG.PRNG memory prng;
        prng.seed(_randomUniform());
        prng.shuffle(indices);
        uint256 n = _bound(_random(), 1, indices.length);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(indices, n)
        }
        LibSort.sort(indices);
    }

    function _gatherLeafs(bytes32[] memory leafs, uint256[] memory indices)
        internal
        pure
        returns (bytes32[] memory gathered)
    {
        gathered = new bytes32[](indices.length);
        for (uint256 i; i < indices.length; ++i) {
            gathered[i] = leafs[indices[i]];
        }
    }
}
