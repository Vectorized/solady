from dataclasses import dataclass, field

from eth_account._utils.structured_data.hashing import hash_message
from wake.testing import *
from pytypes.src.utils.ERC1967Factory import ERC1967Factory
from pytypes.tests.EIP712Mock import EIP712Mock


@dataclass
class Person:
    name: str
    wallet: Address


@dataclass
class Mail:
    from_: Person = field(metadata={"original_name": "from"})
    to: Person
    contents: str


mail = Mail(
    from_=Person("Cow", Address("0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826")),
    to=Person("Bob", Address("0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB")),
    contents="Hello, Bob!",
)


@default_chain.connect()
def test_eip712():
    signer = Account.new()

    eip712 = EIP712Mock.deploy()
    assert eip712.eip712Domain() == (
        0b01111.to_bytes(1, "big"),
        eip712.NAME(),
        eip712.VERSION(),
        default_chain.chain_id,
        eip712.address,
        b"\x00" * 32,
        [],
    )

    mail_hash = hash_message(signer._prepare_eip712_dict(mail, Eip712Domain(), False))

    sign1 = signer.sign_hash(eip712.hashTypedData(mail_hash))
    sign2 = signer.sign_structured(mail, Eip712Domain(
        name=eip712.NAME(),
        version=eip712.VERSION(),
        chainId=default_chain.chain_id,
        verifyingContract=eip712.address,
    ))
    assert sign1 == sign2


@default_chain.connect()
def test_eip712_proxy():
    signer = Account.new()

    proxy_factory = ERC1967Factory.deploy()
    impl = EIP712Mock.deploy()
    eip712 = EIP712Mock(proxy_factory.deploy_(impl, signer).return_value)
    assert eip712.eip712Domain() == (
        0b01111.to_bytes(1, "big"),
        eip712.NAME(),
        eip712.VERSION(),
        default_chain.chain_id,
        eip712.address,
        b"\x00" * 32,
        [],
    )

    mail_hash = hash_message(signer._prepare_eip712_dict(mail, Eip712Domain(), False))

    sign1 = signer.sign_hash(eip712.hashTypedData(mail_hash))
    sign2 = signer.sign_structured(mail, Eip712Domain(
        name=eip712.NAME(),
        version=eip712.VERSION(),
        chainId=default_chain.chain_id,
        verifyingContract=eip712.address,
    ))
    assert sign1 == sign2
