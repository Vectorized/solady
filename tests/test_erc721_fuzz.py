import random

from woke.testing.fuzzing import *
from woke.testing import *

from pytypes.tests.ERC721Mock import ERC721Mock


###################################################################
####################### PYTHON ERC721 MODEL #######################
###################################################################
class ERC721:
    # mapping owner -> token id
    owners: dict[int, Address]
    # mapping owner -> token count
    balances: dict[Address, int]
    # mapping token id -> approved address
    approvals: dict[int, Address]
    # mapping operator approval owner -> operator
    operators: dict[Address, Address]
    def __init__(self):
        self.owners = {}
        self.balances = {}
        self.approvals = {}
        self.operators = {}

    def balance_of(self, _owner: Address):
        return self.balances[_owner]

    def owner_of(self, _token_id: uint):
        return self.owners[_token_id]

    def safe_transfer_from(_from: Address, _to: Address, _token_id: uint, _data: bytes):
        return

    def safe_transfer_from(_from: Address, _to: Address, _token_id: uint):
        return

    def transfer_from(self,_by: Address, _from: Address, _to: Address, _token_id: uint):
        self.transfer(_by, _from, _to, _token_id)

    def transfer(self, _by: Address, _from: Address, _to: Address, _token_id: uint):
        if self.owners[_token_id] != _by and self.approvals[_token_id] != _by and self.operators[_from] != _by:
            return
        self.balances[_from] -= 1
        if _to in self.balances.keys():
            self.balances[_to] += 1
        else:
            self.balances[_to] = 1

        self.owners[_token_id] = _to
        if _token_id in self.approvals.keys():
            del self.approvals[_token_id]

    def approve(self, _approved: Address, _token_id: uint):
        if _approved == Address(0):
            del self.approvals[_token_id]
        self.approvals[_token_id] = _approved

    def set_approval_for_all(self, _operator: Address, _owner: Address):
        self.operators[_owner] = _operator

    def get_approved(self, _token_id: uint):
        return self.approvals[_token_id]

    def is_approve_for_all(self, _owner: Address, _operator: Address):
        if self.operators[_owner]:
            return True
        return False

    def mint(self, _to: Address, _token_id: int):
        self.owners[_token_id] = _to
        if _to in self.balances.keys():
            self.balances[_to] += 1
        else:
            self.balances[_to] = 1

    def burn(self,_token_id: int):
        if _token_id in self.owners.keys():
            self.balances[self.owner_of(_token_id)] -= 1
            del self.owners[_token_id]
            if _token_id in self.approvals.keys():
                del self.approvals[_token_id]


###################################################################
########################### Fuzz Test #############################
###################################################################

class ERC721FuzzTest(FuzzTest):
    _erc721: ERC721Mock
    _py_erc721: ERC721
    _id_counter: int
    _ids: List[int]
    # We dont want to use random addresses in flows
    # We want more interaction by addresses that are already managing something
    _addresses: List[Address]

    def pre_sequence(self) -> None:
        self._erc721 = ERC721Mock.deploy()
        self._py_erc721 = ERC721()
        self._addresses = []
        for i in range(20):
            self._addresses.append(random_address())

    ######################## MINT ########################
    @flow(weight=100)
    def mint(self) -> None:
        # Random data
        to = random.choice(self._addresses)
        token_id = random_int(0,(2**256)-1)
        # Mint in contract
        tx = self._erc721.mint(to, token_id)
        # Check events
        assert tx.events == [
            ERC721Mock.BeforeTokenTransfer(Address(0), to, token_id),
            ERC721Mock.Transfer(Address(0), to, token_id),
            ERC721Mock.AfterTokenTransfer(Address(0), to, token_id)
        ]
        # Mint in Py model
        self._py_erc721.mint(to, token_id)

    ######################## BURNS ########################
    @flow(weight=50)
    def burn_owner(self) -> None:
        if self._py_erc721.owners:
            # Random token with owner
            token_id, owner = random.choice(list(self._py_erc721.owners.items()))
            # Burn in contract, msg.sender == owner
            tx = self._erc721.burn(token_id, from_=owner)
            # Check events
            assert tx.events == [
            ERC721Mock.BeforeTokenTransfer(owner, Address(0), token_id),
            ERC721Mock.Transfer(owner, Address(0), token_id),
            ERC721Mock.AfterTokenTransfer(owner, Address(0), token_id)
            ]
            # Burn in Py model
            self._py_erc721.burn(token_id)

    @flow(weight=40)
    def burn_approved(self) -> None:
        if self._py_erc721.approvals:
            # Random token with owner
            token_id, approved = random.choice(list(self._py_erc721.approvals.items()))
            if token_id in self._py_erc721.owners.keys():
                owner = self._py_erc721.owners[token_id]
                # Burn in contract, msg.sender == approved
                tx = self._erc721.burn(token_id, from_=approved)
                # Check events
                assert tx.events == [
                ERC721Mock.BeforeTokenTransfer(owner, Address(0), token_id),
                ERC721Mock.Transfer(owner, Address(0), token_id),
                ERC721Mock.AfterTokenTransfer(owner, Address(0), token_id)
                ]
                # Burn in Py model
                self._py_erc721.burn(token_id)

    @flow(weight=40)
    def burn_operator(self) -> None:
        if self._py_erc721.operators:
            owner, operator = random.choice(list(self._py_erc721.operators.items()))
            if owner in self._py_erc721.owners.keys():
                token_id = self._py_erc721.owners[owner]
                # Burn in contract, msg.sender == operator
                tx = self._erc721.burn(token_id, from_=operator)
                # Check events
                assert tx.events == [
                ERC721Mock.BeforeTokenTransfer(owner, Address(0), token_id),
                ERC721Mock.Transfer(owner, Address(0), token_id),
                ERC721Mock.AfterTokenTransfer(owner, Address(0), token_id)
                ]
                # Burn in Py model
                self._py_erc721.burn(token_id)

    ######################## TRANSFER ########################
    @flow(weight=80)
    def transfer_owner(self) -> None:
        # from == by == owner
        if self._py_erc721.owners:
            token_id, owner = random.choice(list(self._py_erc721.owners.items()))
            to = random.choice(self._addresses)
            # Transfer in contract, msg.sender == owner
            tx = self._erc721.transfer(owner, to, token_id, from_ = owner)
            assert tx.events == [
                ERC721Mock.BeforeTokenTransfer(owner, to, token_id),
                ERC721Mock.Transfer(owner, to, token_id),
                ERC721Mock.AfterTokenTransfer(owner, to, token_id)
                ]
            # Transfer in Py model
            self._py_erc721.transfer(owner, owner, to, token_id)

    @flow(weight=60)
    def transfer_approved(self) -> None:
        # by == approved, from == owner
        if self._py_erc721.approvals:
            token_id, approved = random.choice(list(self._py_erc721.approvals.items()))
            if token_id in self._py_erc721.owners.keys():
                owner = self._py_erc721.owners[token_id]
                to = random.choice(self._addresses)
                # Transfer in contract, msg.sender == approved
                tx = self._erc721.transfer(owner, to, token_id, from_ = approved)
                assert tx.events == [
                    ERC721Mock.BeforeTokenTransfer(owner, to, token_id),
                    ERC721Mock.Transfer(owner, to, token_id),
                    ERC721Mock.AfterTokenTransfer(owner, to, token_id)
                ]
                # Transfer in Py model
                self._py_erc721.transfer(approved, owner, to, token_id)

    @flow(weight=60)
    def transfer_operator(self) -> None:
        # by == operator, from == owner
        if self._py_erc721.operators:
            owner, operator = random.choice(list(self._py_erc721.operators.items()))
            if owner in self._py_erc721.owners.keys():
                token_id = self._py_erc721.owners[owner]
                to = random.choice(self._addresses)
                # Transfer in contract, msg.sender == operator
                tx = self._erc721.transfer(owner, to, token_id, from_ = operator)
                assert tx.events == [
                    ERC721Mock.BeforeTokenTransfer(owner, to, token_id),
                    ERC721Mock.Transfer(owner, to, token_id),
                    ERC721Mock.AfterTokenTransfer(owner, to, token_id)
                ]
                # Transfer in Py model
                self._py_erc721.transfer(operator, owner, to, token_id)

    ###################### TRANSFERS FROM ######################
    @flow(weight=80)
    def transfer_from_owner(self) -> None:
        # from == by == owner
        if self._py_erc721.owners:
            token_id, owner = random.choice(list(self._py_erc721.owners.items()))
            to = random.choice(self._addresses)
            # Transfer in contract, msg.sender == owner
            tx = self._erc721.transferFrom(owner, to, token_id, from_ = owner)
            assert tx.events == [
                ERC721Mock.BeforeTokenTransfer(owner, to, token_id),
                ERC721Mock.Transfer(owner, to, token_id),
                ERC721Mock.AfterTokenTransfer(owner, to, token_id)
                ]
            # Transfer in Py model
            self._py_erc721.transfer_from(owner, owner, to, token_id)

    @flow(weight=60)
    def transfer_from_approved(self) -> None:
        # by == approved, from == owner
        if self._py_erc721.approvals:
            token_id, approved = random.choice(list(self._py_erc721.approvals.items()))
            if token_id in self._py_erc721.owners.keys():
                owner = self._py_erc721.owners[token_id]
                to = random.choice(self._addresses)
                # Transfer in contract, msg.sender == approved
                tx = self._erc721.transferFrom(owner, to, token_id, from_ = approved)
                assert tx.events == [
                    ERC721Mock.BeforeTokenTransfer(owner, to, token_id),
                    ERC721Mock.Transfer(owner, to, token_id),
                    ERC721Mock.AfterTokenTransfer(owner, to, token_id)
                ]
                # Transfer in Py model
                self._py_erc721.transfer_from(approved, owner, to, token_id)

    @flow(weight=60)
    def transfer_from_operator(self) -> None:
        # by == operator, from == owner
        if self._py_erc721.operators:
            owner, operator = random.choice(list(self._py_erc721.operators.items()))
            if owner in self._py_erc721.owners.keys():
                token_id = self._py_erc721.owners[owner]
                to = random.choice(self._addresses)
                # Transfer in contract, msg.sender == operator
                tx = self._erc721.transferFrom(owner, to, token_id, from_ = operator)
                assert tx.events == [
                    ERC721Mock.BeforeTokenTransfer(owner, to, token_id),
                    ERC721Mock.Transfer(owner, to, token_id),
                    ERC721Mock.AfterTokenTransfer(owner, to, token_id)
                ]
                # Transfer in Py model
                self._py_erc721.transfer_from(operator, owner, to, token_id)

    ######################## APPROVALS ########################
    @flow(weight=50)
    def approve_owner(self) -> None:
        if self._py_erc721.owners:
            token_id, owner = random.choice(list(self._py_erc721.owners.items()))
            account = random.choice(self._addresses)
            # Approve in contract
            tx = self._erc721.approve(account, token_id, from_=owner)
            # Check events
            assert tx.events == [
                    ERC721Mock.Approval(owner, account, token_id),

                ]
            # Approve in Py model
            self._py_erc721.approve(account, token_id)

    @flow(weight=40)
    def dis_approve_owner(self) -> None:
        if self._py_erc721.owners:
            token_id, owner = random.choice(list(self._py_erc721.owners.items()))
            if token_id in self._py_erc721.approvals.keys():
                # Delete approval in contract
                tx = self._erc721.approve(Address(0), token_id, from_=owner)
                # Check events
                assert tx.events == [
                    ERC721Mock.Approval(owner, Address(0), token_id),
                ]
                # Delete approval in Py model
                self._py_erc721.approve(Address(0), token_id)

    @flow(weight=40)
    def approve_operator(self) -> None:
        if self._py_erc721.operators:
            owner, operator = random.choice(list(self._py_erc721.operators.items()))
            if owner in self._py_erc721.owners.keys():
                token_id = self._py_erc721.owners[owner]
                account = random.choice(self._addresses)
                # Approve in contract
                tx = self._erc721.approve(account, token_id, from_=operator)
                # Check events
                assert tx.events == [
                    ERC721Mock.Approval(owner, account, token_id),
                ]
                # Approve in Py model
                self._py_erc721.approve(account, token_id)

    #################### APPROVE FOR ALL ########################
    @flow(weight=40)
    def approve_for_all(self) -> None:
        if self._py_erc721.owners:
            _, owner = random.choice(list(self._py_erc721.owners.items()))
            operator = random.choice(self._addresses)
            # Set approve for all in contract
            tx = self._erc721.setApprovalForAll(operator, True, from_=owner)
            assert tx.events == [
                ERC721Mock.ApprovalForAll(owner, operator, True),
            ]
            # Set approve for all in Py model
            self._py_erc721.set_approval_for_all(operator, owner)


    @invariant(period=20)
    def invariant_owners(self) -> None:
        owners = self._py_erc721.owners.items()
        for token_id, owner in owners:
            assert self._erc721.ownerOf(token_id) == owner

    @invariant(period=20)
    def invariant_balances(self) -> None:
        balances = self._py_erc721.balances.items()
        for owner, count in balances:
            assert self._erc721.balanceOf(owner) == count

    @invariant(period=20)
    def invariant_approvals(self) -> None:
        approvals = self._py_erc721.approvals.items()
        for token_id, approved in approvals:
            assert self._erc721.getApproved(token_id) == approved


@default_chain.connect()
def test_eip712_fuzz():
    default_chain.set_default_accounts(default_chain.accounts[0])
    ERC721FuzzTest().run(30, 600)

