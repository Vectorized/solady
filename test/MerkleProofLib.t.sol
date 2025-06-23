// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {MerkleProofLib} from "../src/utils/MerkleProofLib.sol";
import {LibString} from "../src/utils/LibString.sol";

contract MerkleProofLibTest is SoladyTest {
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
        if (!(data.length > 1)) data = _randomData();
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

    function testVerifyMultiProofMalicious() public {
        bytes32[] memory realLeaves = new bytes32[](2);
        realLeaves[0] = bytes32("real leaf");
        realLeaves[1] = bytes32(0);
        bytes32 root = _hashPair(realLeaves[0], realLeaves[1]);

        bytes32[] memory maliciousLeaves = new bytes32[](2);
        maliciousLeaves[0] = bytes32("malicious");
        maliciousLeaves[1] = bytes32("leaves");
        bytes32[] memory maliciousProof = new bytes32[](2);
        maliciousProof[0] = realLeaves[0];
        maliciousProof[1] = realLeaves[0];
        bool[] memory maliciousFlags = new bool[](3);
        maliciousFlags[0] = true;
        maliciousFlags[1] = true;
        maliciousFlags[2] = false;

        assertFalse(this.verifyMultiProof(maliciousProof, root, maliciousLeaves, maliciousFlags));
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

        bytes32 root =
            _hashPair(_hashPair(bytes32("a"), bytes32("b")), _hashPair(bytes32("c"), bytes32(0)));

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

    function testVerifyMultiProofForSingleLeaf(bytes32[] memory data, uint256 randomness)
        public
        brutalizeMemory
    {
        if (!(data.length > 1)) data = _randomData();
        uint256 nodeIndex = randomness % data.length;
        bytes32 root = _getRoot(data);
        bytes32[] memory proof = _getProof(data, nodeIndex);
        bytes32[] memory leaves = new bytes32[](1);
        leaves[0] = data[nodeIndex];
        bool[] memory flags = new bool[](proof.length);

        assertTrue(this.verifyMultiProof(proof, root, leaves, flags));

        // Checks verify with corrupted root returns false.
        assertFalse(this.verifyMultiProof(proof, bytes32(uint256(root) ^ 1), leaves, flags));

        // Checks verify with corrupted proof returns false.
        proof[0] = bytes32(uint256(proof[0]) ^ 1);
        assertFalse(this.verifyMultiProof(proof, root, leaves, flags));

        // Checks verify with corrupted root and proof returns false.
        assertFalse(this.verifyMultiProof(proof, bytes32(uint256(root) ^ 1), leaves, flags));
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
        bytes32[] memory leaves;
        if (hasLeaf) {
            leaves = new bytes32[](1);
            leaves[0] = nonEmptyLeaf ? bytes32("a") : bytes32(0);
        }
        bool leafSameAsRoot = leaves.length == 1 && leaves[0] == root;
        bool proofSameAsRoot = proof.length == 1 && proof[0] == root;
        bool isValid = flags.length == 0 && (leafSameAsRoot || proofSameAsRoot)
            && (leaves.length + proof.length == 1);
        assertEq(this.verifyMultiProof(proof, root, leaves, flags), isValid);
    }

    function testVerifyMultiProofForHeightTwoTree(
        bool allLeaves,
        bool damageRoot,
        bool damageLeaves,
        bool damageProof,
        bool damageFlags,
        bytes32 randomness
    ) public {
        bool noDamage = true;
        uint256 ri; // Randomness index.

        bytes32 root = _hashPair(bytes32("a"), bytes32("b"));

        bytes32[] memory proof;
        bytes32[] memory leaves;
        bool[] memory flags = new bool[](1);
        flags[0] = allLeaves;

        if (allLeaves) {
            leaves = new bytes32[](2);
            leaves[0] = bytes32("a");
            leaves[1] = bytes32("b");
        } else {
            leaves = new bytes32[](1);
            leaves[0] = bytes32("a");
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

        if (damageLeaves) {
            noDamage = false;
            uint256 i = uint256(uint8(randomness[ri++])) % leaves.length;
            leaves[i] = bytes32(uint256(leaves[i]) ^ 1); // Flip a bit.
            if (uint256(uint8(randomness[ri++])) & 1 == 0) delete leaves;
        }

        if (damageProof && proof.length != 0) {
            noDamage = false;
            proof[0] = bytes32(uint256(proof[0]) ^ 1); // Flip a bit.
            if (uint256(uint8(randomness[ri++])) & 1 == 0) delete proof;
        }

        assertEq(this.verifyMultiProof(proof, root, leaves, flags), noDamage);
    }

    function testVerifyMultiProofIsValid() public {
        testVerifyMultiProof(false, false, false, false, 0x00);
    }

    function testVerifyMultiProofIsInvalid() public {
        testVerifyMultiProof(false, false, true, false, 0x00);
    }

    function testVerifyMultiProof(
        bool damageRoot,
        bool damageLeaves,
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

        bytes32[] memory leaves = new bytes32[](3);
        leaves[0] = bytes32("d");
        leaves[1] = bytes32("e");
        leaves[2] = bytes32("f");

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

        if (damageLeaves) {
            noDamage = false;
            uint256 i = uint256(uint8(randomness[ri++])) % leaves.length;
            leaves[i] = bytes32(uint256(leaves[i]) ^ 1); // Flip a bit.
            if (uint256(uint8(randomness[ri++])) & 1 == 0) delete leaves;
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

        assertEq(this.verifyMultiProof(proof, root, leaves, flags), noDamage);
    }

    function verify(bytes32[] calldata proof, bytes32 root, bytes32 leaf)
        external
        returns (bool result)
    {
        result = MerkleProofLib.verifyCalldata(proof, root, leaf);
        assertEq(MerkleProofLib.verify(proof, root, leaf), result);
    }

    function verifyMultiProof(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32[] calldata leaves,
        bool[] calldata flags
    ) external returns (bool result) {
        uint256[] memory offsetsAndLengths = new uint256[](12);

        // Basically, we want to demonstrate that the `verifyMultiProof` does not
        // change the offsets and lengths.

        /// @solidity memory-safe-assembly
        assembly {
            mstore(add(offsetsAndLengths, shl(5, add(1, 0))), proof.offset)
            mstore(add(offsetsAndLengths, shl(5, add(1, 1))), leaves.offset)
            mstore(add(offsetsAndLengths, shl(5, add(1, 2))), flags.offset)
            mstore(add(offsetsAndLengths, shl(5, add(1, 3))), proof.length)
            mstore(add(offsetsAndLengths, shl(5, add(1, 4))), leaves.length)
            mstore(add(offsetsAndLengths, shl(5, add(1, 5))), flags.length)
        }

        result = MerkleProofLib.verifyMultiProofCalldata(proof, root, leaves, flags);

        /// @solidity memory-safe-assembly
        assembly {
            mstore(add(offsetsAndLengths, shl(5, add(1, 6))), proof.offset)
            mstore(add(offsetsAndLengths, shl(5, add(1, 7))), leaves.offset)
            mstore(add(offsetsAndLengths, shl(5, add(1, 8))), flags.offset)
            mstore(add(offsetsAndLengths, shl(5, add(1, 9))), proof.length)
            mstore(add(offsetsAndLengths, shl(5, add(1, 10))), leaves.length)
            mstore(add(offsetsAndLengths, shl(5, add(1, 11))), flags.length)
        }

        assertEq(offsetsAndLengths[0], offsetsAndLengths[6]);
        assertEq(offsetsAndLengths[1], offsetsAndLengths[7]);
        assertEq(offsetsAndLengths[2], offsetsAndLengths[8]);
        assertEq(offsetsAndLengths[3], offsetsAndLengths[9]);
        assertEq(offsetsAndLengths[4], offsetsAndLengths[10]);
        assertEq(offsetsAndLengths[5], offsetsAndLengths[11]);

        assertEq(MerkleProofLib.verifyMultiProof(proof, root, leaves, flags), result);
    }

    // Following code is adapted from https://github.com/dmfxyz/murky/blob/main/src/common/MurkyBase.sol.

    function _getRoot(bytes32[] memory data) private pure returns (bytes32) {
        require(data.length > 1);
        while (data.length > 1) {
            data = _hashLevel(data);
        }
        return data[0];
    }

    function _getProof(bytes32[] memory data, uint256 nodeIndex)
        private
        pure
        returns (bytes32[] memory)
    {
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

    function testEmptyCalldataHelpers() public {
        assertFalse(
            MerkleProofLib.verifyMultiProofCalldata(
                MerkleProofLib.emptyProof(),
                bytes32(0),
                MerkleProofLib.emptyLeaves(),
                MerkleProofLib.emptyFlags()
            )
        );

        assertFalse(
            MerkleProofLib.verifyMultiProof(
                MerkleProofLib.emptyProof(),
                bytes32(0),
                MerkleProofLib.emptyLeaves(),
                MerkleProofLib.emptyFlags()
            )
        );
    }

    function _randomData() internal returns (bytes32[] memory result) {
        uint256 n = _bound(_random(), 2, 0xff);
        result = new bytes32[](n);
        unchecked {
            for (uint256 i; i != n; ++i) {
                result[i] = bytes32(_random());
            }
        }
    }
}
