import logging
from collections import defaultdict
import random
from typing import DefaultDict, Set

from woke.testing import *
from woke.testing.fuzzing import *
from pytypes.tests.ERC1155Mock import ERC1155Mock


logger = logging.getLogger(__name__)
#logger.setLevel(logging.DEBUG)


class ERC1155FuzzTest(FuzzTest):
    _erc1155: ERC1155Mock
    _balances: DefaultDict[Account, DefaultDict[uint256, uint256]]
    _approvals: DefaultDict[Account, Set[Account]]
    _token_ids: List[uint256]

    def pre_sequence(self) -> None:
        self._erc1155 = ERC1155Mock.deploy(True)
        self._balances = defaultdict(lambda: defaultdict(lambda: 0))
        self._approvals = defaultdict(set)
        self._token_ids = [random_int(0, 2 ** 256 - 1, edge_values_prob=0.25) for _ in range(10)]

    @flow()
    def flow_mint(self, payload: bytearray) -> None:
        a = random_account()
        id = random.choice(self._token_ids)
        amount = random_int(0, 2 ** 256 - 1, edge_values_prob=0.05)

        try:
            tx = self._erc1155.mint(a, id, amount, payload)
            assert self._balances[a][id] + amount < 2 ** 256
            assert tx.events == [
                ERC1155Mock.BeforeTokenTransfer(Address.ZERO, a.address, [id], [amount], payload),
                ERC1155Mock.TransferSingle(tx.from_.address, Address.ZERO, a.address, id, amount),
                ERC1155Mock.AfterTokenTransfer(Address.ZERO, a.address, [id], [amount], payload),
            ]
            self._balances[a][id] += amount

            logger.debug(f"Minted {amount} of {id} to {a}")
        except UnknownTransactionRevertedError as e:
            assert e.data == ERC1155Mock.AccountBalanceOverflow.selector
            assert self._balances[a][id] + amount >= 2 ** 256

            logger.debug(f"Failed to mint {amount} of {id} to {a}")

    @flow()
    def flow_batch_mint(self, payload: bytearray) -> None:
        a = random_account()
        ids = [random.choice(self._token_ids) for _ in range(random_int(0, 10, edge_values_prob=0.05))]
        amounts = [random_int(0, 2 ** 256 - 1, edge_values_prob=0.05) for _ in range(len(ids))]

        try:
            tx = self._erc1155.batchMint(a, ids, amounts, payload)
            for id, amount in zip(ids, amounts):
                assert self._balances[a][id] + amount < 2 ** 256
                self._balances[a][id] += amount
            assert tx.events == [
                ERC1155Mock.BeforeTokenTransfer(Address.ZERO, a.address, ids, amounts, payload),
                ERC1155Mock.TransferBatch(tx.from_.address, Address.ZERO, a.address, ids, amounts),
                ERC1155Mock.AfterTokenTransfer(Address.ZERO, a.address, ids, amounts, payload),
            ]

            logger.debug(f"Minted {amounts} of {ids} to {a}")
        except UnknownTransactionRevertedError as e:
            assert e.data == ERC1155Mock.AccountBalanceOverflow.selector
            amounts_by_ids = defaultdict(int)
            for id, amount in zip(ids, amounts):
                amounts_by_ids[id] += amount
            assert any(self._balances[a][id] + amount >= 2 ** 256 for id, amount in amounts_by_ids.items())

            logger.debug(f"Failed to mint {amounts} of {ids} to {a}")

    @flow()
    def flow_burn(self) -> None:
        owner = random_account()

        if random.random() < 0.8 and sum(self._balances[owner].values()) > 0:
            id = random.choice([k for k in self._balances[owner].keys() if self._balances[owner][k] > 0])
        else:
            id = random.choice(self._token_ids)

        if self._balances[owner][id] == 0:
            amount = random.choice([0, 1])
        else:
            amount = random_int(0, min(self._balances[owner][id] + 1, 2 ** 256 - 1), min_prob=0.05, max_prob=0.01)

        operator = random.choices(
            default_chain.accounts,
            [0.5 if a == owner else 0.5 / (len(default_chain.accounts) - 1) for a in default_chain.accounts]
        )[0]

        try:
            tx = self._erc1155.burn(owner, id, amount, from_=operator)
            assert tx.events == [
                ERC1155Mock.BeforeTokenTransfer(owner.address, Address.ZERO, [id], [amount], bytearray()),
                ERC1155Mock.TransferSingle(operator.address, owner.address, Address.ZERO, id, amount),
                ERC1155Mock.AfterTokenTransfer(owner.address, Address.ZERO, [id], [amount], bytearray()),
            ]
            assert self._balances[owner][id] - amount >= 0
            self._balances[owner][id] -= amount

            assert operator == owner or operator in self._approvals[owner]

            logger.debug(f"Burned {amount} of {id} from {owner}")
        except UnknownTransactionRevertedError as e:
            if e.data == ERC1155Mock.InsufficientBalance.selector:
                assert self._balances[owner][id] - amount < 0
            elif e.data == ERC1155Mock.NotOwnerNorApproved.selector:
                assert operator != owner and operator not in self._approvals[owner]
            else:
                raise

            logger.debug(f"Failed to burn {amount} of {id} from {owner}")

    @flow()
    def flow_burn_batch(self) -> None:
        owner = random_account()

        ids = []
        amounts = []
        for _ in range(random_int(0, 10, edge_values_prob=0.05)):
            if random.random() < 0.98 and sum(self._balances[owner].values()) > 0:
                id = random.choice([k for k in self._balances[owner].keys() if self._balances[owner][k] > 0])
                ids.append(id)
                if self._balances[owner][id] == 0:
                    amount = random.choice([0, 1])
                else:
                    amount = random_int(0, min(self._balances[owner][id] + 1, 2 ** 256 - 1), edge_values_prob=0.05)
                amounts.append(amount)
            else:
                id = random.choice(self._token_ids)
                ids.append(id)
                amount = random_int(0, 2 ** 256 - 1, edge_values_prob=0.05)
                amounts.append(amount)

        operator = random.choices(
            default_chain.accounts,
            [0.5 if a == owner else 0.5 / (len(default_chain.accounts) - 1) for a in default_chain.accounts]
        )[0]

        try:
            tx = self._erc1155.batchBurn(owner, ids, amounts, from_=operator)
            assert tx.events == [
                ERC1155Mock.BeforeTokenTransfer(owner.address, Address.ZERO, ids, amounts, bytearray()),
                ERC1155Mock.TransferBatch(operator.address, owner.address, Address.ZERO, ids, amounts),
                ERC1155Mock.AfterTokenTransfer(owner.address, Address.ZERO, ids, amounts, bytearray()),
            ]
            for id, amount in zip(ids, amounts):
                assert self._balances[owner][id] - amount >= 0
                self._balances[owner][id] -= amount

            assert operator == owner or operator in self._approvals[owner]

            logger.debug(f"Burned {amounts} of {ids} from {owner}")
        except UnknownTransactionRevertedError as e:
            if e.data == ERC1155Mock.InsufficientBalance.selector:
                amounts_by_ids = defaultdict(int)
                for id, amount in zip(ids, amounts):
                    amounts_by_ids[id] += amount
                assert any(self._balances[owner][id] - amount < 0 for id, amount in amounts_by_ids.items())
            elif e.data == ERC1155Mock.NotOwnerNorApproved.selector:
                assert operator != owner and operator not in self._approvals[owner]
            else:
                raise

            logger.debug(f"Failed to burn {amounts} of {ids} from {owner}")

    @flow()
    def flow_burn_unchecked(self) -> None:
        owner = random_account()

        if random.random() < 0.8 and sum(self._balances[owner].values()) > 0:
            id = random.choice([k for k in self._balances[owner].keys() if self._balances[owner][k] > 0])
        else:
            id = random.choice(self._token_ids)

        if self._balances[owner][id] == 0:
            amount = random.choice([0, 1])
        else:
            amount = random_int(0, min(self._balances[owner][id] + 1, 2 ** 256 - 1), min_prob=0.05, max_prob=0.01)

        operator = random.choices(
            default_chain.accounts + (Account(0), ),
            [0.25 if a == owner else 0.5 / (len(default_chain.accounts) - 1) for a in default_chain.accounts] + [0.25]
        )[0]
        executor = random_account()

        try:
            tx = self._erc1155.burnUnchecked(operator, owner, id, amount, from_=executor)
            assert tx.events == [
                ERC1155Mock.BeforeTokenTransfer(owner.address, Address.ZERO, [id], [amount], bytearray()),
                ERC1155Mock.TransferSingle(executor.address, owner.address, Address.ZERO, id, amount),
                ERC1155Mock.AfterTokenTransfer(owner.address, Address.ZERO, [id], [amount], bytearray()),
            ]
            assert self._balances[owner][id] - amount >= 0
            self._balances[owner][id] -= amount

            assert operator == owner or operator == Account(0) or operator in self._approvals[owner]

            logger.debug(f"Burned {amount} of {id} from {owner}")
        except UnknownTransactionRevertedError as e:
            if e.data == ERC1155Mock.InsufficientBalance.selector:
                assert self._balances[owner][id] - amount < 0
            elif e.data == ERC1155Mock.NotOwnerNorApproved.selector:
                assert operator != owner and operator != Account(0) and operator not in self._approvals[owner]
            else:
                raise

            logger.debug(f"Failed to burn {amount} of {id} from {owner}")

    @flow()
    def flow_burn_batch_unchecked(self):
        owner = random_account()

        ids = []
        amounts = []
        for _ in range(random_int(0, 10, edge_values_prob=0.05)):
            if random.random() < 0.98 and sum(self._balances[owner].values()) > 0:
                id = random.choice([k for k in self._balances[owner].keys() if self._balances[owner][k] > 0])
                ids.append(id)
                if self._balances[owner][id] == 0:
                    amount = random.choice([0, 1])
                else:
                    amount = random_int(0, min(self._balances[owner][id] + 1, 2 ** 256 - 1), edge_values_prob=0.05)
                amounts.append(amount)
            else:
                id = random.choice(self._token_ids)
                ids.append(id)
                amount = random_int(0, 2 ** 256 - 1, edge_values_prob=0.05)
                amounts.append(amount)

        operator = random.choices(
            default_chain.accounts + (Account(0), ),
            [0.25 if a == owner else 0.5 / (len(default_chain.accounts) - 1) for a in default_chain.accounts] + [0.25]
        )[0]
        executor = random_account()

        try:
            tx = self._erc1155.batchBurnUnchecked(operator, owner, ids, amounts, from_=executor)
            assert tx.events == [
                ERC1155Mock.BeforeTokenTransfer(owner.address, Address.ZERO, ids, amounts, bytearray()),
                ERC1155Mock.TransferBatch(executor.address, owner.address, Address.ZERO, ids, amounts),
                ERC1155Mock.AfterTokenTransfer(owner.address, Address.ZERO, ids, amounts, bytearray()),
            ]
            for id, amount in zip(ids, amounts):
                assert self._balances[owner][id] - amount >= 0
                self._balances[owner][id] -= amount

            assert operator == owner or operator == Account(0) or operator in self._approvals[owner]

            logger.debug(f"Burned {amounts} of {ids} from {owner}")
        except UnknownTransactionRevertedError as e:
            if e.data == ERC1155Mock.InsufficientBalance.selector:
                amounts_by_ids = defaultdict(int)
                for id, amount in zip(ids, amounts):
                    amounts_by_ids[id] += amount
                assert any(self._balances[owner][id] - amount < 0 for id, amount in amounts_by_ids.items())
            elif e.data == ERC1155Mock.NotOwnerNorApproved.selector:
                assert operator != owner and operator != Account(0) and operator not in self._approvals[owner]
            else:
                raise

            logger.debug(f"Failed to burn {amounts} of {ids} from {owner}")

    @flow()
    def flow_change_approval(self) -> None:
        a = random_account()
        operator = random_account()
        approval = operator in self._approvals[a]

        tx = self._erc1155.setApprovalForAll(operator, not approval, from_=a)
        assert tx.events == [
            ERC1155Mock.ApprovalForAll(a.address, operator.address, not approval),
        ]

        if approval:
            self._approvals[a].remove(operator)
        else:
            self._approvals[a].add(operator)

        logger.debug(f"Changed approval of {operator} for {a} to {not approval}")

    @flow()
    def flow_change_approval_unchecked(self) -> None:
        owner = random_account()
        operator = random_account()
        executor = random_account()
        approval = operator in self._approvals[owner]

        tx = self._erc1155.setApprovalForAllUnchecked(owner, operator, not approval, from_=executor)
        assert tx.events == [
            ERC1155Mock.ApprovalForAll(owner.address, operator.address, not approval),
        ]

        if approval:
            self._approvals[owner].remove(operator)
        else:
            self._approvals[owner].add(operator)

        logger.debug(f"Changed approval of {operator} for {owner} to {not approval}")

    @flow()
    def flow_safe_transfer(self, payload: bytearray):
        owner = random_account()
        recipient = random_account()

        if random.random() < 0.8 and sum(self._balances[owner].values()) > 0:
            id = random.choice([k for k in self._balances[owner].keys() if self._balances[owner][k] > 0])
        else:
            id = random.choice(self._token_ids)

        if self._balances[owner][id] == 0:
            amount = random.choice([0, 1])
        else:
            amount = random_int(0, min(self._balances[owner][id] + 1, 2 ** 256 - 1), min_prob=0.05, max_prob=0.01)

        operator = random.choices(
            default_chain.accounts,
            [0.5 if a == owner else 0.5 / (len(default_chain.accounts) - 1) for a in default_chain.accounts]
        )[0]

        try:
            tx = self._erc1155.safeTransferFrom(owner, recipient, id, amount, payload, from_=operator)
            assert tx.events == [
                ERC1155Mock.BeforeTokenTransfer(owner.address, recipient.address, [id], [amount], payload),
                ERC1155Mock.TransferSingle(operator.address, owner.address, recipient.address, id, amount),
                ERC1155Mock.AfterTokenTransfer(owner.address, recipient.address, [id], [amount], payload),
            ]
            assert self._balances[owner][id] - amount >= 0
            self._balances[owner][id] -= amount
            assert self._balances[recipient][id] + amount <= 2 ** 256 - 1
            self._balances[recipient][id] += amount

            assert operator == owner or operator in self._approvals[owner]

            logger.debug(f"Transferred {amount} of {id} from {owner} to {recipient}")
        except UnknownTransactionRevertedError as e:
            if e.data == ERC1155Mock.InsufficientBalance.selector:
                assert self._balances[owner][id] - amount < 0
            elif e.data == ERC1155Mock.AccountBalanceOverflow.selector:
                assert self._balances[recipient][id] + amount > 2 ** 256 - 1
            elif e.data == ERC1155Mock.NotOwnerNorApproved.selector:
                assert operator != owner and operator not in self._approvals[owner]
            else:
                raise

            logger.debug(f"Failed to transfer {amount} of {id} from {owner} to {recipient}")

    @flow()
    def flow_safe_batch_transfer(self, payload: bytearray) -> None:
        owner = random_account()
        ids = []
        amounts = []
        for _ in range(random_int(0, 10, edge_values_prob=0.05)):
            if random.random() < 0.98 and sum(self._balances[owner].values()) > 0:
                id = random.choice([k for k in self._balances[owner].keys() if self._balances[owner][k] > 0])
                ids.append(id)
                if self._balances[owner][id] == 0:
                    amount = random.choice([0, 1])
                else:
                    amount = random_int(0, min(self._balances[owner][id] + 1, 2 ** 256 - 1), edge_values_prob=0.05)
                amounts.append(amount)
            else:
                id = random.choice(self._token_ids)
                ids.append(id)
                amount = random_int(0, 2 ** 256 - 1, edge_values_prob=0.05)
                amounts.append(amount)

        operator = random.choices(
            default_chain.accounts,
            [0.5 if a == owner else 0.5 / (len(default_chain.accounts) - 1) for a in default_chain.accounts]
        )[0]

        try:
            tx = self._erc1155.safeBatchTransferFrom(owner, owner, ids, amounts, payload, from_=operator)
            assert tx.events == [
                ERC1155Mock.BeforeTokenTransfer(owner.address, owner.address, ids, amounts, payload),
                ERC1155Mock.TransferBatch(operator.address, owner.address, owner.address, ids, amounts),
                ERC1155Mock.AfterTokenTransfer(owner.address, owner.address, ids, amounts, payload),
            ]
            for id, amount in zip(ids, amounts):
                assert self._balances[owner][id] - amount >= 0
                self._balances[owner][id] -= amount
                assert self._balances[owner][id] + amount <= 2 ** 256 - 1
                self._balances[owner][id] += amount

            assert operator == owner or operator in self._approvals[owner]

            logger.debug(f"Transferred {amounts} of {ids} from {owner} to {owner}")
        except UnknownTransactionRevertedError as e:
            if e.data == ERC1155Mock.InsufficientBalance.selector:
                amounts_by_ids = defaultdict(int)
                for id, amount in zip(ids, amounts):
                    amounts_by_ids[id] += amount
                assert any(self._balances[owner][id] - amount < 0 for id, amount in amounts_by_ids.items())
            elif e.data == ERC1155Mock.AccountBalanceOverflow.selector:
                amounts_by_ids = defaultdict(int)
                for id, amount in zip(ids, amounts):
                    amounts_by_ids[id] += amount
                assert any(self._balances[owner][id] + amount > 2 ** 256 - 1 for id, amount in amounts_by_ids.items())
            elif e.data == ERC1155Mock.NotOwnerNorApproved.selector:
                assert operator != owner and operator not in self._approvals[owner]
            else:
                raise

            logger.debug(f"Failed to transfer {amounts} of {ids} from {owner} to {owner}")

    @flow()
    def flow_safe_transfer_unchecked(self, payload: bytearray) -> None:
        owner = random_account()
        recipient = random_account()

        if random.random() < 0.8 and sum(self._balances[owner].values()) > 0:
            id = random.choice([k for k in self._balances[owner].keys() if self._balances[owner][k] > 0])
        else:
            id = random.choice(self._token_ids)

        if self._balances[owner][id] == 0:
            amount = random.choice([0, 1])
        else:
            amount = random_int(0, min(self._balances[owner][id] + 1, 2 ** 256 - 1), min_prob=0.05, max_prob=0.01)

        operator = random.choices(
            default_chain.accounts + (Account(0), ),
            [0.25 if a == owner else 0.5 / (len(default_chain.accounts) - 1) for a in default_chain.accounts] + [0.25]
        )[0]
        executor = random_account()

        try:
            tx = self._erc1155.safeTransferUnchecked(operator, owner, recipient, id, amount, payload, from_=executor)
            assert tx.events == [
                ERC1155Mock.BeforeTokenTransfer(owner.address, recipient.address, [id], [amount], payload),
                ERC1155Mock.TransferSingle(executor.address, owner.address, recipient.address, id, amount),
                ERC1155Mock.AfterTokenTransfer(owner.address, recipient.address, [id], [amount], payload),
            ]
            assert self._balances[owner][id] - amount >= 0
            self._balances[owner][id] -= amount
            assert self._balances[recipient][id] + amount <= 2 ** 256 - 1
            self._balances[recipient][id] += amount

            assert operator == owner or operator == Account(0) or operator in self._approvals[owner]

            logger.debug(f"Transferred {amount} of {id} from {owner} to {recipient}")
        except UnknownTransactionRevertedError as e:
            if e.data == ERC1155Mock.InsufficientBalance.selector:
                assert self._balances[owner][id] - amount < 0
            elif e.data == ERC1155Mock.AccountBalanceOverflow.selector:
                assert self._balances[recipient][id] + amount > 2 ** 256 - 1
            elif e.data == ERC1155Mock.NotOwnerNorApproved.selector:
                assert operator != owner and operator != Account(0) and operator not in self._approvals[owner]
            else:
                raise

            logger.debug(f"Failed to transfer {amount} of {id} from {owner} to {recipient}")

    @flow()
    def flow_safe_batch_transfer_unchecked(self, payload: bytearray) -> None:
        owner = random_account()
        ids = []
        amounts = []
        for _ in range(random_int(0, 10, edge_values_prob=0.05)):
            if random.random() < 0.98 and sum(self._balances[owner].values()) > 0:
                id = random.choice([k for k in self._balances[owner].keys() if self._balances[owner][k] > 0])
                ids.append(id)
                if self._balances[owner][id] == 0:
                    amount = random.choice([0, 1])
                else:
                    amount = random_int(0, min(self._balances[owner][id] + 1, 2 ** 256 - 1), edge_values_prob=0.05)
                amounts.append(amount)
            else:
                id = random.choice(self._token_ids)
                ids.append(id)
                amount = random_int(0, 2 ** 256 - 1, edge_values_prob=0.05)
                amounts.append(amount)

        operator = random.choices(
            default_chain.accounts + (Account(0), ),
            [0.25 if a == owner else 0.5 / (len(default_chain.accounts) - 1) for a in default_chain.accounts] + [0.25]
        )[0]
        executor = random_account()

        try:
            tx = self._erc1155.safeBatchTransferUnchecked(operator, owner, owner, ids, amounts, payload, from_=executor)
            assert tx.events == [
                ERC1155Mock.BeforeTokenTransfer(owner.address, owner.address, ids, amounts, payload),
                ERC1155Mock.TransferBatch(executor.address, owner.address, owner.address, ids, amounts),
                ERC1155Mock.AfterTokenTransfer(owner.address, owner.address, ids, amounts, payload),
            ]
            for id, amount in zip(ids, amounts):
                assert self._balances[owner][id] - amount >= 0
                self._balances[owner][id] -= amount
                assert self._balances[owner][id] + amount <= 2 ** 256 - 1
                self._balances[owner][id] += amount

            assert operator == owner or operator == Account(0) or operator in self._approvals[owner]

            logger.debug(f"Transferred {amounts} of {ids} from {owner} to {owner}")
        except UnknownTransactionRevertedError as e:
            if e.data == ERC1155Mock.InsufficientBalance.selector:
                amounts_by_ids = defaultdict(int)
                for id, amount in zip(ids, amounts):
                    amounts_by_ids[id] += amount
                assert any(self._balances[owner][id] - amount < 0 for id, amount in amounts_by_ids.items())
            elif e.data == ERC1155Mock.AccountBalanceOverflow.selector:
                amounts_by_ids = defaultdict(int)
                for id, amount in zip(ids, amounts):
                    amounts_by_ids[id] += amount
                assert any(self._balances[owner][id] + amount > 2 ** 256 - 1 for id, amount in amounts_by_ids.items())
            elif e.data == ERC1155Mock.NotOwnerNorApproved.selector:
                assert operator != owner and operator != Account(0) and operator not in self._approvals[owner]
            else:
                raise

            logger.debug(f"Failed to transfer {amounts} of {ids} from {owner} to {owner}")

    @invariant(period=20)
    def invariant_balances(self) -> None:
        for a, balances in self._balances.items():
            assert self._erc1155.balanceOfBatch([a] * len(balances), list(balances.keys())) == list(balances.values())
            for id, balance in balances.items():
                assert self._erc1155.balanceOf(a, id) == balance

    @invariant(period=20)
    def invariant_approvals(self) -> None:
        for a in default_chain.accounts:
            for b in default_chain.accounts:
                assert self._erc1155.isApprovedForAll(a, b) == (b in self._approvals[a])


@default_chain.connect(accounts=20)
def test_erc1155_fuzz():
    default_chain.set_default_accounts(default_chain.accounts[0])
    ERC1155FuzzTest().run(1, 100)
