// SPDX-License-Identifier: MIT
import "src/utils/SignatureCheckerLib.sol";

contract SignatureCheckerMock {
    function isValidSignatureNow(address signer, bytes32 hash, bytes memory signature) external view returns (bool) {
        return SignatureCheckerLib.isValidSignatureNow(signer, hash, signature);
    }

    function isValidSignatureNowCalldata(address signer, bytes32 hash, bytes calldata signature) external view returns (bool) {
        return SignatureCheckerLib.isValidSignatureNowCalldata(signer, hash, signature);
    }

    function isValidSignatureNow(address signer, bytes32 hash, bytes32 r, bytes32 vs) external view returns(bool) {
        return SignatureCheckerLib.isValidSignatureNow(signer, hash, r, vs);
    }

    function isValidSignatureNow(address signer, bytes32 hash, uint8 v, bytes32 r, bytes32 s) external view returns(bool) {
        return SignatureCheckerLib.isValidSignatureNow(signer, hash, v, r, s);
    }

    function isValidERC1271SignatureNow(address signer, bytes32 hash, bytes memory signature) external view returns (bool) {
        return SignatureCheckerLib.isValidERC1271SignatureNow(signer, hash, signature);
    }

    function isValidERC1271SignatureNowCalldata(address signer, bytes32 hash, bytes calldata signature) external view returns (bool) {
        return SignatureCheckerLib.isValidERC1271SignatureNowCalldata(signer, hash, signature);
    }

    function isValidERC1271SignatureNow(address signer, bytes32 hash, bytes32 r, bytes32 vs) external view returns(bool) {
        return SignatureCheckerLib.isValidERC1271SignatureNow(signer, hash, r, vs);
    }

    function isValidERC1271SignatureNow(address signer, bytes32 hash, uint8 v, bytes32 r, bytes32 s) external view returns(bool) {
        return SignatureCheckerLib.isValidERC1271SignatureNow(signer, hash, v, r, s);
    }
}

contract ERC1271SignatureChecker {
    bytes4 constant internal MAGICVALUE = 0x1626ba7e;

    function isValidSignature(bytes32 _hash, bytes memory _signature) public view returns (bytes4) {
        uint8 v;
        bytes32 r;
        bytes32 s;

        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        if (tx.origin == ecrecover(_hash, v, r, s)) {
            return MAGICVALUE;
        } else {
            return 0x0;
        }
    }
}