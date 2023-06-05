from typing import List, Tuple

from woke.testing import keccak256


class MerkleTree:
    _is_ready: bool
    _leaves: List[bytes]
    _levels: List[List[bytes]]

    def __init__(self):
        self._is_ready = False
        self._leaves = []
        self._levels = []

    @property
    def root(self) -> bytes:
        if not self._is_ready:
            self._build_tree()
        return self._levels[-1][0]

    @property
    def values(self) -> Tuple[bytes, ...]:
        return tuple(self._leaves)

    def get_proof(self, index: int) -> List[bytes]:
        if not self._is_ready:
            self._build_tree()

        proof = []
        for level in self._levels[:-1]:
            if index % 2 == 0:
                proof.append(level[index + 1])
            else:
                proof.append(level[index - 1])
            index //= 2
        return proof

    def get_multiproof(self, indexes: List[int]) -> Tuple[List[bytes], List[bool]]:
        if not self._is_ready:
            self._build_tree()

        proof = []
        flags = []
        known = indexes
        assert known == sorted(known), "Leaves must be sorted"

        for level in self._levels[:-1]:
            new_known = []
            for i in known:
                if i % 2 == 0:
                    if i + 1 in known:
                        flags.append(True)
                    else:
                        flags.append(False)
                        if i + 1 < len(level):
                            proof.append(level[i + 1])
                        else:
                            proof.append(level[i])
                else:
                    if i - 1 in known:
                        pass  # already processed
                    else:
                        flags.append(False)
                        proof.append(level[i - 1])
                if len(new_known) == 0 or new_known[-1] != i // 2:
                    new_known.append(i // 2)
            known = new_known

        return proof, flags

    def add_leaf(self, leaf: bytes):
        self._leaves.append(leaf)
        self._is_ready = False

    def _build_tree(self) -> None:
        self._levels.append([keccak256(leaf) for leaf in self._leaves])
        while len(self._levels[-1]) > 1:
            self._levels.append(self._build_level(self._levels[-1]))
        self._is_ready = True

    def _build_level(self, level: List[bytes]) -> List[bytes]:
        if len(level) % 2 == 1:
            level.append(level[-1])
        return [
            keccak256(level[i] + level[i + 1]) if level[i] < level[i + 1]
            else keccak256(level[i + 1] + level[i])
            for i in range(0, len(level), 2)
        ]
