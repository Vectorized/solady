import random

from woke.testing import *
from woke.testing.fuzzing import *
from pytypes.tests.MerkleProofMock import MerkleProofMock

from .utils import MerkleTree


class MerkleProofFuzzTest(FuzzTest):
    _merkle_proof: MerkleProofMock
    _tree: MerkleTree

    def __init__(self):
        self._merkle_proof = MerkleProofMock.deploy()

    def pre_sequence(self) -> None:
        self._tree = MerkleTree()
        for _ in range(random_int(1, 1_000)):
            self._tree.add_leaf(random_bytes(0, 100))

    @flow()
    def flow_verify(self) -> None:
        index = random_int(0, len(self._tree.values) - 1)
        proof = self._tree.get_proof(index)
        leaf = self._tree.values[index]

        assert self._merkle_proof.verify(proof, self._tree.root, keccak256(leaf))
        assert self._merkle_proof.verifyCalldata(proof, self._tree.root, keccak256(leaf))

    @flow(weight=40)
    def flow_verify_invalid_random(self, proof: List[bytes32], root: bytes32, leaf: bytes) -> None:
        try:
            index = self._tree.values.index(leaf)
            assert self._tree.root == root
            assert self._tree.get_proof(index) == proof
            return
        except Exception:
            pass

        leaf_hash = keccak256(leaf)
        assert not self._merkle_proof.verify(proof, root, leaf_hash)
        assert not self._merkle_proof.verifyCalldata(proof, root, leaf_hash)

    @flow(weight=60)
    def flow_verify_invalid_modified(self) -> None:
        index = random_int(0, len(self._tree.values) - 1)
        leaf = self._tree.values[index]
        proof = self._tree.get_proof(index)
        root = self._tree.root

        r = random_int(0, 2)
        if r == 0:
            leaf = random_bytes(32)
        elif r == 1:
            if len(proof) != 0:
                proof[random_int(0, len(proof) - 1)] = random_bytes(32)
            else:
                proof.append(random_bytes(32))
        else:
            root = random_bytes(32)

        assert not self._merkle_proof.verify(proof, root, keccak256(leaf))
        assert not self._merkle_proof.verifyCalldata(proof, root, keccak256(leaf))

    @flow()
    def flow_verify_multiproof(self) -> None:
        indexes = sorted(random.sample(range(len(self._tree.values)), random_int(1, len(self._tree.values))))
        leaves = [self._tree.values[i] for i in indexes]
        proof, flags = self._tree.get_multiproof(indexes)

        assert self._merkle_proof.verifyMultiProof(proof, self._tree.root, [keccak256(leaf) for leaf in leaves], flags)
        assert self._merkle_proof.verifyMultiProofCalldata(proof, self._tree.root, [keccak256(leaf) for leaf in leaves], flags)

    @flow(weight=40)
    def flow_verify_multiproof_invalid_random(self, proof: List[bytes32], root: bytes32, leaves: List[bytes], flags: List[bool]) -> None:
        try:
            indexes = sorted([self._tree.values.index(leaf) for leaf in leaves])
            assert self._tree.root == root
            assert self._tree.get_multiproof(indexes) == (proof, flags)
            return
        except Exception:
            pass

        leaf_hashes = [keccak256(leaf) for leaf in leaves]
        assert not self._merkle_proof.verifyMultiProof(proof, root, leaf_hashes, flags)
        assert not self._merkle_proof.verifyMultiProofCalldata(proof, root, leaf_hashes, flags)

    @flow(weight=60)
    def flow_verify_multiproof_invalid_modified(self) -> None:
        indexes = sorted(random.sample(range(len(self._tree.values)), random_int(1, len(self._tree.values))))
        leaves = [self._tree.values[i] for i in indexes]
        proof, flags = self._tree.get_multiproof(indexes)
        root = self._tree.root

        r = random_int(0, 3)
        if r == 0:
            if len(leaves) != 0:
                leaves[random_int(0, len(leaves) - 1)] = random_bytes(32)
            else:
                leaves.append(random_bytes(32))
        elif r == 1:
            if len(proof) != 0:
                proof[random_int(0, len(proof) - 1)] = random_bytes(32)
            else:
                proof.append(random_bytes(32))
        elif r == 2:
            if len(flags) != 0:
                pos = random_int(0, len(flags) - 1)
                flags[pos] = not flags[pos]
            else:
                flags.append(random.choice([True, False]))
        else:
            root = random_bytes(32)

        leaf_hashes = [keccak256(leaf) for leaf in leaves]
        assert not self._merkle_proof.verifyMultiProof(proof, root, leaf_hashes, flags)
        assert not self._merkle_proof.verifyMultiProofCalldata(proof, root, leaf_hashes, flags)


@default_chain.connect()
def test_merkle_proof_fuzz():
    default_chain.set_default_accounts(default_chain.accounts[0])
    MerkleProofFuzzTest().run(10, 100)
