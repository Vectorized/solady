// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/TestPlus.sol";
import {MerkleProofLib} from "../src/utils/MerkleProofLib.sol";

contract MerkleProofLibTest is TestPlus {
    function testVerifyProofForHeightOneTree(
        bool hasProof,
        bool nonEmptyProof,
        bool nonEmptyRoot,
        bool nonEmptyLeaf
    ) public {
        bytes32 root;
        if (nonEmptyRoot) {
            root = bytes32("a");
        }
        bytes32 leaf;
        if (nonEmptyLeaf) {
            leaf = bytes32("a");
        }
        bytes32[] memory proof;
        if (hasProof) {
            proof = new bytes32[](1);
            proof[0] = nonEmptyProof ? bytes32("a") : bytes32(0);
        }
        bool isValid = leaf == root && proof.length == 0;
        assertEq(this.verify(proof, root, leaf), isValid);
    }

    function testVerifyProof(bytes32[] memory data, uint256 randomness) public brutalizeMemory {
        vm.assume(data.length > 1);
        uint256 nodeIndex = randomness % data.length;
        bytes32 root = _getRoot(data);
        bytes32[] memory proof = _getProof(data, nodeIndex);
        bytes32 leaf = data[nodeIndex];

        assertTrue(this.verify(proof, root, leaf));

        // Checks verify with corrupted root returns false.
        assertFalse(this.verify(proof, bytes32(uint256(root) ^ 1), leaf));

        // Checks verify with corrupted proof returns false.
        proof[0] = bytes32(uint256(proof[0]) ^ 1);
        assertFalse(this.verify(proof, root, leaf));

        // Checks verify with corrupted root and proof returns false.
        assertFalse(this.verify(proof, bytes32(uint256(root) ^ 1), leaf));
    }

    function testVerifyProofBasicCaseIsValid() public {
        testVerifyProofBasicCase(false, false, false, 0x00);
    }

    function testVerifyProofBasicCaseIsInvalid() public {
        testVerifyProofBasicCase(false, false, true, 0x00);
    }

    function testVerifyProofBasicCase(
        bool damageProof,
        bool damageRoot,
        bool damageLeaf,
        bytes32 randomness
    ) public {
        bool noDamage = true;
        uint256 ri; // Randomness index.

        bytes32[] memory proof = new bytes32[](2);
        proof[0] = bytes32("b");
        proof[1] = _hashPair(bytes32("c"), bytes32(0));
        if (damageProof) {
            noDamage = false;
            uint256 i = uint256(uint8(randomness[ri++])) % proof.length;
            proof[i] = bytes32(uint256(proof[i]) ^ 1); // Flip a bit.
        }

        bytes32 root = _hashPair(_hashPair(bytes32("a"), bytes32("b")), _hashPair(bytes32("c"), bytes32(0)));

        if (damageRoot) {
            noDamage = false;
            root = bytes32(uint256(root) ^ 1); // Flip a bit.
        }

        bytes32 leaf = bytes32("a");
        if (damageLeaf) {
            noDamage = false;
            leaf = bytes32(uint256(leaf) ^ 1); // Flip a bit.
        }

        assertEq(this.verify(proof, root, leaf), noDamage);
    }

    function testVerifyMultiProofForSingleLeaf(bytes32[] memory data, uint256 randomness) public brutalizeMemory {
        vm.assume(data.length > 1);
        uint256 nodeIndex = randomness % data.length;
        bytes32 root = _getRoot(data);
        bytes32[] memory proof = _getProof(data, nodeIndex);
        bytes32[] memory leafs = new bytes32[](1);
        leafs[0] = data[nodeIndex];
        bool[] memory flags = new bool[](proof.length);

        assertTrue(this.verifyMultiProof(proof, root, leafs, flags));

        // Checks verify with corrupted root returns false.
        assertFalse(this.verifyMultiProof(proof, bytes32(uint256(root) ^ 1), leafs, flags));

        // Checks verify with corrupted proof returns false.
        proof[0] = bytes32(uint256(proof[0]) ^ 1);
        assertFalse(this.verifyMultiProof(proof, root, leafs, flags));

        // Checks verify with corrupted root and proof returns false.
        assertFalse(this.verifyMultiProof(proof, bytes32(uint256(root) ^ 1), leafs, flags));
    }

    function testVerifyMultiProofForHeightOneTree(
        bool hasProof,
        bool nonEmptyProof,
        bool nonEmptyRoot,
        bool hasLeaf,
        bool nonEmptyLeaf,
        bool[] memory flags
    ) public {
        bytes32 root;
        if (nonEmptyRoot) {
            root = bytes32("a");
        }
        bytes32[] memory proof;
        if (hasProof) {
            proof = new bytes32[](1);
            proof[0] = nonEmptyProof ? bytes32("a") : bytes32(0);
        }
        bytes32[] memory leafs;
        if (hasLeaf) {
            leafs = new bytes32[](1);
            leafs[0] = nonEmptyLeaf ? bytes32("a") : bytes32(0);
        }
        bool leafSameAsRoot = leafs.length == 1 && leafs[0] == root;
        bool proofSameAsRoot = proof.length == 1 && proof[0] == root;
        bool isValid = flags.length == 0 && (leafSameAsRoot || proofSameAsRoot) && (leafs.length + proof.length == 1);
        assertEq(this.verifyMultiProof(proof, root, leafs, flags), isValid);
    }

    function testVerifyMultiProofForHeightTwoTree(
        bool allLeafs,
        bool damageRoot,
        bool damageLeafs,
        bool damageProof,
        bool damageFlags,
        bytes32 randomness
    ) public {
        bool noDamage = true;
        uint256 ri; // Randomness index.

        bytes32 root = _hashPair(bytes32("a"), bytes32("b"));

        bytes32[] memory proof;
        bytes32[] memory leafs;
        bool[] memory flags = new bool[](1);
        flags[0] = allLeafs;

        if (allLeafs) {
            leafs = new bytes32[](2);
            leafs[0] = bytes32("a");
            leafs[1] = bytes32("b");
        } else {
            leafs = new bytes32[](1);
            leafs[0] = bytes32("a");
            proof = new bytes32[](1);
            proof[0] = bytes32("b");
        }

        if (damageRoot) {
            noDamage = false;
            root = bytes32(uint256(root) ^ 1); // Flip a bit.
        }

        if (damageFlags) {
            noDamage = false;
            flags[0] = !flags[0]; // Flip a bool.
            if (uint256(uint8(randomness[ri++])) & 1 == 0) delete flags;
        }

        if (damageLeafs) {
            noDamage = false;
            uint256 i = uint256(uint8(randomness[ri++])) % leafs.length;
            leafs[i] = bytes32(uint256(leafs[i]) ^ 1); // Flip a bit.
            if (uint256(uint8(randomness[ri++])) & 1 == 0) delete leafs;
        }

        if (damageProof && proof.length != 0) {
            noDamage = false;
            proof[0] = bytes32(uint256(proof[0]) ^ 1); // Flip a bit.
            if (uint256(uint8(randomness[ri++])) & 1 == 0) delete proof;
        }

        assertEq(this.verifyMultiProof(proof, root, leafs, flags), noDamage);
    }

    function testVerifyMultiProofIsValid() public {
        testVerifyMultiProof(false, false, false, false, 0x00);
    }

    function testVerifyMultiProofIsInvalid() public {
        testVerifyMultiProof(false, false, true, false, 0x00);
    }

    function testVerifyMultiProof(
        bool damageRoot,
        bool damageLeafs,
        bool damageProof,
        bool damageFlags,
        bytes32 randomness
    ) public brutalizeMemory {
        bool noDamage = true;
        uint256 ri; // Randomness index.

        bytes32 root = _hashPair(
            _hashPair(_hashPair(bytes32("a"), bytes32("b")), _hashPair(bytes32("c"), bytes32("d"))),
            _hashPair(bytes32("e"), bytes32("f"))
        );

        bytes32[] memory leafs = new bytes32[](3);
        leafs[0] = bytes32("d");
        leafs[1] = bytes32("e");
        leafs[2] = bytes32("f");

        bytes32[] memory proof = new bytes32[](2);
        proof[0] = bytes32("c");
        proof[1] = _hashPair(bytes32("b"), bytes32("a"));

        bool[] memory flags = new bool[](4);
        flags[0] = false;
        flags[1] = true;
        flags[2] = false;
        flags[3] = true;

        if (damageRoot) {
            noDamage = false;
            root = bytes32(uint256(root) ^ 1); // Flip a bit.
        }

        if (damageLeafs) {
            noDamage = false;
            uint256 i = uint256(uint8(randomness[ri++])) % leafs.length;
            leafs[i] = bytes32(uint256(leafs[i]) ^ 1); // Flip a bit.
            if (uint256(uint8(randomness[ri++])) & 1 == 0) delete leafs;
        }

        if (damageProof) {
            noDamage = false;
            uint256 i = uint256(uint8(randomness[ri++])) % proof.length;
            proof[i] = bytes32(uint256(proof[i]) ^ 1); // Flip a bit.
            if (uint256(uint8(randomness[ri++])) & 1 == 0) delete proof;
        }

        if (damageFlags) {
            noDamage = false;
            uint256 i = uint256(uint8(randomness[ri++])) % flags.length;
            flags[i] = !flags[i]; // Flip a bool.
            if (uint256(uint8(randomness[ri++])) & 1 == 0) delete flags;
        }

        assertEq(this.verifyMultiProof(proof, root, leafs, flags), noDamage);
    }

    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) external pure returns (bool) {
        return MerkleProofLib.verify(proof, root, leaf);
    }

    function verifyMultiProof(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32[] calldata leafs,
        bool[] calldata flags
    ) external returns (bool result) {
        uint256[] memory offsetsAndLengths = new uint256[](12);

        // Basically, we want to demonstrate that the `verifyMultiProof` does not
        // change the offsets and lengths.

        /// @solidity memory-safe-assembly
        assembly {
            mstore(add(offsetsAndLengths, shl(5, add(1, 0))), proof.offset)
            mstore(add(offsetsAndLengths, shl(5, add(1, 1))), leafs.offset)
            mstore(add(offsetsAndLengths, shl(5, add(1, 2))), flags.offset)
            mstore(add(offsetsAndLengths, shl(5, add(1, 3))), proof.length)
            mstore(add(offsetsAndLengths, shl(5, add(1, 4))), leafs.length)
            mstore(add(offsetsAndLengths, shl(5, add(1, 5))), flags.length)
        }

        result = MerkleProofLib.verifyMultiProof(proof, root, leafs, flags);

        /// @solidity memory-safe-assembly
        assembly {
            mstore(add(offsetsAndLengths, shl(5, add(1, 6))), proof.offset)
            mstore(add(offsetsAndLengths, shl(5, add(1, 7))), leafs.offset)
            mstore(add(offsetsAndLengths, shl(5, add(1, 8))), flags.offset)
            mstore(add(offsetsAndLengths, shl(5, add(1, 9))), proof.length)
            mstore(add(offsetsAndLengths, shl(5, add(1, 10))), leafs.length)
            mstore(add(offsetsAndLengths, shl(5, add(1, 11))), flags.length)
        }

        assertEq(offsetsAndLengths[0], offsetsAndLengths[6]);
        assertEq(offsetsAndLengths[1], offsetsAndLengths[7]);
        assertEq(offsetsAndLengths[2], offsetsAndLengths[8]);
        assertEq(offsetsAndLengths[3], offsetsAndLengths[9]);
        assertEq(offsetsAndLengths[4], offsetsAndLengths[10]);
        assertEq(offsetsAndLengths[5], offsetsAndLengths[11]);
    }

    // Following code is adapted from https://github.com/dmfxyz/murky/blob/main/src/common/MurkyBase.sol.

    function _getRoot(bytes32[] memory data) private pure returns (bytes32) {
        require(data.length > 1);
        while (data.length > 1) {
            data = _hashLevel(data);
        }
        return data[0];
    }

    function _getProof(bytes32[] memory data, uint256 nodeIndex) private pure returns (bytes32[] memory) {
        require(data.length > 1);

        bytes32[] memory result = new bytes32[](64);
        uint256 pos;

        while (data.length > 1) {
            unchecked {
                if (nodeIndex & 0x1 == 1) {
                    result[pos] = data[nodeIndex - 1];
                } else if (nodeIndex + 1 == data.length) {
                    result[pos] = bytes32(0);
                } else {
                    result[pos] = data[nodeIndex + 1];
                }
                ++pos;
                nodeIndex /= 2;
            }
            data = _hashLevel(data);
        }
        // Resize the length of the array to fit.
        /// @solidity memory-safe-assembly
        assembly {
            mstore(result, pos)
        }

        return result;
    }

    function _hashLevel(bytes32[] memory data) private pure returns (bytes32[] memory) {
        bytes32[] memory result;
        unchecked {
            uint256 length = data.length;
            if (length & 0x1 == 1) {
                result = new bytes32[](length / 2 + 1);
                result[result.length - 1] = _hashPair(data[length - 1], bytes32(0));
            } else {
                result = new bytes32[](length / 2);
            }
            uint256 pos = 0;
            for (uint256 i = 0; i < length - 1; i += 2) {
                result[pos] = _hashPair(data[i], data[i + 1]);
                ++pos;
            }
        }
        return result;
    }

    function _hashPair(bytes32 left, bytes32 right) private pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            switch lt(left, right)
            case 0 {
                mstore(0x0, right)
                mstore(0x20, left)
            }
            default {
                mstore(0x0, left)
                mstore(0x20, right)
            }
            result := keccak256(0x0, 0x40)
        }
    }
}
