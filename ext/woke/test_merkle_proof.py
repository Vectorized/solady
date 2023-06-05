import random

from woke.testing import *
from woke.testing.fuzzing import random_bytes, random_int
from pytypes.tests.MerkleProofMock import MerkleProofMock

from .utils import MerkleTree


@default_chain.connect()
def test_merkle_proof():
    default_chain.set_default_accounts(default_chain.accounts[0])

    tree = MerkleTree()
    for _ in range(100):
        tree.add_leaf(random_bytes(0, 1_000))

    merkle_proof_mock = MerkleProofMock.deploy()

    for i in range(100):
        assert merkle_proof_mock.verify(tree.get_proof(i), tree.root, keccak256(tree.values[i]))
        assert merkle_proof_mock.verifyCalldata(tree.get_proof(i), tree.root, keccak256(tree.values[i]))


@default_chain.connect()
def test_merkle_multiproof_single():
    default_chain.set_default_accounts(default_chain.accounts[0])

    tree = MerkleTree()
    tree.add_leaf(random_bytes(0, 1_000))

    merkle_proof_mock = MerkleProofMock.deploy()
    assert merkle_proof_mock.verifyMultiProof([], tree.root, [keccak256(tree.values[0])], [])
    assert merkle_proof_mock.verifyMultiProofCalldata([], tree.root, [keccak256(tree.values[0])], [])

    assert merkle_proof_mock.verifyMultiProof([keccak256(tree.values[0])], tree.root, [], [])
    assert merkle_proof_mock.verifyMultiProofCalldata([keccak256(tree.values[0])], tree.root, [], [])


@default_chain.connect()
def test_merkle_multiproof():
    default_chain.set_default_accounts(default_chain.accounts[0])

    tree = MerkleTree()
    for _ in range(1_000):
        tree.add_leaf(random_bytes(0, 1_000))

    merkle_proof_mock = MerkleProofMock.deploy()

    for _ in range(100):
        indexes = sorted(random.sample(range(len(tree.values)), random_int(1, 100)))
        leaves = [tree.values[i] for i in indexes]
        proof, flags = tree.get_multiproof(indexes)
        assert merkle_proof_mock.verifyMultiProof(proof, tree.root, [keccak256(leaf) for leaf in leaves], flags)
        assert merkle_proof_mock.verifyMultiProofCalldata(proof, tree.root, [keccak256(leaf) for leaf in leaves], flags)
