from wake.testing import *
from wake.testing.fuzzing import *
from pytypes.tests.SignatureCheckerMock import SignatureCheckerMock, ERC1217SignatureChecker

class SignatureCheckerFuzzTest(FuzzTest):
    _signature_checker: SignatureCheckerMock
    _erc1271_signature_checker: ERC1217SignatureChecker
    _signer: Account

    def pre_sequence(self) -> None:
        self._signature_checker = SignatureCheckerMock.deploy()
        self._erc1271_signature_checker = ERC1217SignatureChecker.deploy()
        self._signer = Account.new()

    @flow()
    def flow_check_signature(self) -> None:
        data = random_bytes(0, 1000)
        hash = keccak256(data)
        signature = self._signer.sign_hash(hash)
        r = signature[:32]
        s = signature[32:64]
        v = signature[64]

        assert self._signature_checker.isValidSignatureNow(self._signer, hash, signature)
        assert self._signature_checker.isValidSignatureNow_(
            self._signer,
            hash,
            r,
            s if v == 27 else (s[0] | 0x80).to_bytes(1, "big") + s[1:],
        )
        assert self._signature_checker.isValidSignatureNow__(self._signer, hash, v, r, s)
        assert self._signature_checker.isValidSignatureNowCalldata(self._signer, hash, signature)

        # erc1271
        assert self._signature_checker.isValidSignatureNow(self._erc1271_signature_checker, hash, signature, from_=self._signer)
        assert self._signature_checker.isValidSignatureNow_(
            self._erc1271_signature_checker,
            hash,
            r,
            s if v == 27 else (s[0] | 0x80).to_bytes(1, "big") + s[1:],
            from_=self._signer,
        )
        assert self._signature_checker.isValidSignatureNow__(self._erc1271_signature_checker, hash, v, r, s, from_=self._signer)
        assert self._signature_checker.isValidSignatureNowCalldata(self._erc1271_signature_checker, hash, signature, from_=self._signer)

        assert not self._signature_checker.isValidSignatureNow(self._erc1271_signature_checker, hash, signature)
        assert not self._signature_checker.isValidSignatureNow_(
            self._erc1271_signature_checker,
            hash,
            r,
            s if v == 27 else (s[0] | 0x80).to_bytes(1, "big") + s[1:],
        )
        assert not self._signature_checker.isValidSignatureNow__(self._erc1271_signature_checker, hash, v, r, s)
        assert not self._signature_checker.isValidSignatureNowCalldata(self._erc1271_signature_checker, hash, signature)

    @flow(weight=40)
    def flow_check_signature_invalid_random(self, signer: Address, hash: bytes32) -> None:
        signature = random_bytes(65)
        r = signature[:32]
        s = signature[32:64]
        v = signature[64]

        assert not self._signature_checker.isValidSignatureNow(signer, hash, signature)
        assert not self._signature_checker.isValidSignatureNow_(
            self._signer,
            hash,
            r,
            s if v == 27 else (s[0] | 0x80).to_bytes(1, "big") + s[1:],
        )
        assert not self._signature_checker.isValidSignatureNow__(signer, hash, v, r, s)
        assert not self._signature_checker.isValidSignatureNowCalldata(signer, hash, signature)

        assert not self._signature_checker.isValidSignatureNow(self._erc1271_signature_checker, hash, signature, from_=signer)
        assert not self._signature_checker.isValidSignatureNow_(
            self._erc1271_signature_checker,
            hash,
            r,
            s if v == 27 else (s[0] | 0x80).to_bytes(1, "big") + s[1:],
            from_=signer,
        )
        assert not self._signature_checker.isValidSignatureNow__(self._erc1271_signature_checker, hash, v, r, s, from_=signer)
        assert not self._signature_checker.isValidSignatureNowCalldata(self._erc1271_signature_checker, hash, signature, from_=signer)

        assert not self._signature_checker.isValidERC1271SignatureNow(self._erc1271_signature_checker, hash, signature, from_=signer)
        assert not self._signature_checker.isValidERC1271SignatureNow_(
            self._erc1271_signature_checker,
            hash,
            r,
            s if v == 27 else (s[0] | 0x80).to_bytes(1, "big") + s[1:],
            from_=signer,
        )
        assert not self._signature_checker.isValidERC1271SignatureNow__(self._erc1271_signature_checker, hash, v, r, s, from_=signer)
        assert not self._signature_checker.isValidERC1271SignatureNowCalldata(self._erc1271_signature_checker, hash, signature, from_=signer)

    @flow(weight=60)
    def flow_check_signature_invalid_modified(self) -> None:
        signer = self._signer.address
        data = random_bytes(0, 1000)
        hash = bytearray(keccak256(data))
        signature = bytearray(self._signer.sign_hash(hash))
        original_v = None

        x = random_int(0, 2)
        if x == 0:
            signer_bytes = bytearray(bytes(signer))
            pos = random_int(0, 19)
            new_byte = random_bytes(1)[0]
            while signer_bytes[pos] == new_byte:
                new_byte = random_bytes(1)[0]
            signer_bytes[pos] = new_byte
            signer = Address(signer_bytes.hex())
        elif x == 1:
            pos = random_int(0, 31)
            new_byte = random_bytes(1)[0]
            while hash[pos] == new_byte:
                new_byte = random_bytes(1)[0]
            hash[pos] = new_byte
        elif x == 2:
            pos = random_int(0, 64)
            if pos == 64:
                original_v = signature[64]

            new_byte = random_bytes(1)[0]
            while signature[pos] == new_byte:
                new_byte = random_bytes(1)[0]
            signature[pos] = new_byte
        else:
            assert False

        r = signature[:32]
        s = signature[32:64]
        v = signature[64]

        if original_v is None:
            # v was not modified
            vs = s if v == 27 else (s[0] | 0x80).to_bytes(1, "big") + s[1:]
        else:
            # v was modified
            vs = s if original_v == 28 else (s[0] | 0x80).to_bytes(1, "big") + s[1:]

        assert not self._signature_checker.isValidSignatureNow(signer, hash, signature)
        assert not self._signature_checker.isValidSignatureNow_(
            signer,
            hash,
            r,
            vs,
        )
        assert not self._signature_checker.isValidSignatureNow__(signer, hash, v, r, s)
        assert not self._signature_checker.isValidSignatureNowCalldata(signer, hash, signature)

        # erc1271
        assert not self._signature_checker.isValidSignatureNow(self._erc1271_signature_checker, hash, signature, from_=signer)
        assert not self._signature_checker.isValidSignatureNow_(
            self._erc1271_signature_checker,
            hash,
            r,
            vs,
            from_=signer,
        )
        assert not self._signature_checker.isValidSignatureNow__(self._erc1271_signature_checker, hash, v, r, s, from_=signer)
        assert not self._signature_checker.isValidSignatureNowCalldata(self._erc1271_signature_checker, hash, signature, from_=signer)

        assert not self._signature_checker.isValidERC1271SignatureNow(self._erc1271_signature_checker, hash, signature, from_=signer)
        assert not self._signature_checker.isValidERC1271SignatureNow_(
            self._erc1271_signature_checker,
            hash,
            r,
            vs,
            from_=signer,
        )
        assert not self._signature_checker.isValidERC1271SignatureNow__(self._erc1271_signature_checker, hash, v, r, s, from_=signer)
        assert not self._signature_checker.isValidERC1271SignatureNowCalldata(self._erc1271_signature_checker, hash, signature, from_=signer)


@default_chain.connect()
def test_signature_checker():
    SignatureCheckerFuzzTest().run(10, 20)
