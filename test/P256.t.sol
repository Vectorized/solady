// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {LibString} from "../src/utils/LibString.sol";
import {P256} from "../src/utils/P256.sol";

contract P256Test is SoladyTest {
    bytes private constant _VERIFIER_BYTECODE =
        hex"7fffffffff00000001000000000000000000000000ffffffffffffffffffffffff604052610199565b60008060008561003f5750859150869050876100cc565b886100515750829150839050846100cc565b60405180878809818b8c098281880983838c0984858f85098b09925084858c86098e099350848286038208905084818209858183098685880387089550868788848709600209880388838a038a8a8b09080899508687828709880388898d8b038b878a09088909089850505084858f8d098209955050505050505b96509650969350505050565b8160071b915081513d8301516040840151604051808384098183840982838388096004098384858485093d510985868a8b09600309089650838482600209850385898a090891508384858586096008098503858685880385088a0908965050828385870960020960079790971b9081523d810195909552505050506040015250565b8160071b91508260071b925061018460408401513d850151855160408601513d8701518751610028565b60079390931b9182523d820152604001525050565b6020357fffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc6325516040357f7fffffff800000007fffffffffffffffde737d56d38bcf4279dce5617e3192a88111156101eb5781035b60206108005260206108205260206108405280610860526002820361088052816108a0526040518060031860205260603560803560203d60c061080060055afa60203d1416837f5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b8585873d5189898a09080908848384091486861086151087891089151016609f36111616166102815760206080f35b60808281523d01819052600160c05250507f6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c2966102009081527f4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f53d9091015250506001610240526102f3600160026100d8565b6102ff600460086100d8565b61030d60026001600361015a565b61031b60046001600561015a565b61032960046002600661015a565b61033760046003600761015a565b61034560086001600961015a565b61035360086002600a61015a565b61036160086003600b61015a565b61036f60086004600c61015a565b61037d600c6001600d61015a565b61038b600c6002600e61015a565b610399600c6003600f61015a565b6000816000516000350982600051850960008060006040515b821561046657808485098184850982838386096004098384858485093d51098586888909600309088485836002098603868384090885868787880960080987038788848a03870885090886878a8c09600209878283099650878182099550878888850960040994508788898889093d5109898a868709600309089350878886600209890389868709089850878882840960020999505050508485868687096008098603868789890386088409089750505050505b61018085881b60f71c1661060087891b60f51c1617801561051e57604081015180610491575061051e565b846104a85781513d8301519650909450925061051e565b82858609838283098481870985868584098a09915085818703878588510908868182098781830988858a038a8b8e8a093d8c01510908955088898a8487096002098a038a838c038c8a8b090808995088898287098a038a8b8d8d038d878a09088909089b5050508687868b098209985050505050505b5082156105d357808485098184850982838386096004098384858485093d51098586888909600309088485836002098603868384090885868787880960080987038788848a03870885090886878a8c09600209878283099650878182099550878888850960040994508788898889093d5109898a868709600309089350878886600209890389868709089850878882840960020999505050508485868687096008098603868789890386088409089750505050505b61018085881b60f51c1661060087891b60f31c1617801561068b576040810151806105fe575061068b565b846106155781513d8301519650909450925061068b565b82858609838283098481870985868584098a09915085818703878588510908868182098781830988858a038a8b8e8a093d8c01510908955088898a8487096002098a038a838c038c8a8b090808995088898287098a038a8b8d8d038d878a09088909089b5050508687868b098209985050505050505b50600487019660fb19016103b257826106a75788153d5260203df35b82610860526002810361088052806108a0523d3d60c061080060055afa898983843d513d510986090614163d525050505050505050503d3df3fea26469706673582212206775789f4c3ac0130b20d36cc627c1cec82b85082a6b23157dc1409168ae969264736f6c634300081a0033";

    // Public key x and y.
    uint256 private constant _X = 0x65a2fa44daad46eab0278703edb6c4dcf5e30b8a9aec09fdc71a56f52aa392e4;
    uint256 private constant _Y = 0x4a7a9e4604aa36898209997288e902ac544a555e4b5e0a9efef2b59233f3f437;
    uint256 private constant _R = 0x01655c1753db6b61a9717e4ccc5d6c4bf7681623dd54c2d6babc55125756661c;
    uint256 private constant _NON_MALLEABLE_S =
        0xf8cfdc3921ecf0f7aef50be09b0f98383392dd8079014df95fde2a04b79023a;
    uint256 private constant _MALLEABLE_S =
        0xf073023b6de130f18510af41f64f067c39adccd59f8789a55dbbe822b0ea2317;
    bytes32 private constant _HASH =
        0x267f9ea080b54bbea2443dff8aa543604564329783b6a515c6663a691c555490;
    uint256 private constant _N = 0xffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551;
    uint256 private constant _MALLEABILITY_THRESHOLD =
        0x7fffffff800000007fffffffffffffffde737d56d38bcf4279dce5617e3192a8;

    mapping(bytes32 => bool) internal _vectorTested;
    mapping(bytes32 => bool) internal _vectorResult;

    function setUp() public {
        _etchRIPPrecompile(true);
        _etchVerifier(true);
    }

    function _etchVerifierBytecode(address target, bool active) internal {
        if (active) {
            if (target.code.length == 0) vm.etch(target, _VERIFIER_BYTECODE);
        } else {
            if (target.code.length != 0) vm.etch(target, "");
        }
    }

    function _etchRIPPrecompile(bool active) internal {
        _etchVerifierBytecode(P256.RIP_PRECOMPILE, active);
    }

    function _etchVerifier(bool active) internal {
        _etchVerifierBytecode(P256.VERIFIER, active);
    }

    function testP256VerifyMalleableRIPPrecompile() public {
        _testP256VerifyMalleable();
    }

    function testP256VerifyMalleableVerifier() public {
        _testP256VerifyMalleable();
    }

    function _verifySignatureAllowMalleability(
        bytes32 hash,
        uint256 r,
        uint256 s,
        uint256 x,
        uint256 y
    ) internal view returns (bool) {
        return P256.verifySignatureAllowMalleability(
            hash, bytes32(r), bytes32(s), bytes32(x), bytes32(y)
        );
    }

    function _verifySignature(bytes32 hash, uint256 r, uint256 s, uint256 x, uint256 y)
        internal
        view
        returns (bool)
    {
        return P256.verifySignature(hash, bytes32(r), bytes32(s), bytes32(x), bytes32(y));
    }

    function _testP256VerifyMalleable() internal {
        assertTrue(_verifySignatureAllowMalleability(_HASH, _R, _MALLEABLE_S, _X, _Y));
        assertFalse(_verifySignature(_HASH, _R, _MALLEABLE_S, _X, _Y));
    }

    function testP256VerifyNonMalleableRIPPrecompile() public {
        _testP256VerifyNonMalleable();
    }

    function testP256VerifyNonMalleableVerifier() public {
        _testP256VerifyNonMalleable();
    }

    function testP256VerifyNotDeployedReverts(
        bytes32 hash,
        bytes32 r,
        bytes32 s,
        bytes32 x,
        bytes32 y,
        bool t
    ) public {
        _etchVerifier(false);
        _etchRIPPrecompile(false);
        if (t) {
            vm.expectRevert(P256.P256VerificationFailed.selector);
            this.verifySignatureAllowMalleability(hash, r, s, x, y);
        } else {
            vm.expectRevert(P256.P256VerificationFailed.selector);
            this.verifySignature(hash, r, s, x, y);
        }
    }

    function verifySignature(bytes32 hash, bytes32 r, bytes32 s, bytes32 x, bytes32 y)
        public
        view
        returns (bool)
    {
        return P256.verifySignature(hash, r, s, x, y);
    }

    function verifySignatureAllowMalleability(
        bytes32 hash,
        bytes32 r,
        bytes32 s,
        bytes32 x,
        bytes32 y
    ) public view returns (bool) {
        return P256.verifySignatureAllowMalleability(hash, r, s, x, y);
    }

    function _testP256VerifyNonMalleable() internal {
        assertTrue(_verifySignatureAllowMalleability(_HASH, _R, _NON_MALLEABLE_S, _X, _Y));
        assertTrue(_verifySignature(_HASH, _R, _NON_MALLEABLE_S, _X, _Y));
    }

    function testP256Verify(uint256 seed, bytes32 hash) public {
        uint256 privateKey = _bound(uint256(keccak256(abi.encode(seed))), 1, _N - 1);
        (bytes32 x, bytes32 y) = P256PublicKey.getPublicKey(privateKey);
        (bytes32 r, bytes32 s) = vm.signP256(privateKey, hash);
        assertTrue(_verifyViaVerifier(hash, r, s, x, y));
        assertFalse(_verifyViaVerifier(hash, r, s, x, bytes32(uint256(y) ^ 1)));
    }

    function testP256VerifyWycheproof() public {
        _testP256VerifyWycheproof("./test/data/wycheproof.jsonl");
    }

    function _testP256VerifyWycheproof(string memory file) internal {
        vm.pauseGasMetering();
        uint256 numParseFails;
        for (uint256 i = 1;; ++i) {
            string memory vector = vm.readLine(file);
            bool expected;
            try vm.parseJsonBool(vector, ".valid") returns (bool valid) {
                expected = valid;
            } catch {
                if (++numParseFails == 8) break;
                continue;
            }
            bool result = _verifyViaVerifier(
                vm.parseJsonBytes32(vector, ".hash"),
                vm.parseJsonBytes32(vector, ".r"),
                vm.parseJsonBytes32(vector, ".s"),
                vm.parseJsonBytes32(vector, ".x"),
                vm.parseJsonBytes32(vector, ".y")
            );
            if (result != expected) {
                bytes memory err = abi.encodePacked("Line: ", LibString.toString(i));
                err = abi.encodePacked(err, ", Expected: ", expected ? "1" : "0");
                err = abi.encodePacked(err, ", Returned: ", result ? "1" : "0");
                err = abi.encodePacked(err, ", Comment: ", vm.parseJsonString(vector, ".comment"));
                revert(string(err));
            }
        }
        vm.resumeGasMetering();
    }

    function _verifyViaVerifier(bytes32 hash, uint256 r, uint256 s, uint256 x, uint256 y)
        internal
        returns (bool)
    {
        return _verifyViaVerifier(hash, bytes32(r), bytes32(s), bytes32(x), bytes32(y));
    }

    function _verifyViaVerifier(bytes32 hash, bytes32 r, bytes32 s, bytes32 x, bytes32 y)
        internal
        returns (bool)
    {
        bytes memory payload = abi.encode(hash, r, s, x, y);
        if (uint256(y) & 0xff == 0) {
            bytes memory truncatedPayload = abi.encodePacked(hash, r, s, x, bytes31(y));
            assertEq(truncatedPayload.length, 0x9f);
            assertEq(abi.encodePacked(truncatedPayload, bytes1(0)), payload);
            assertFalse(_verifierCall(truncatedPayload));
        }
        if (_random() & 0x1f == 0) {
            payload = abi.encodePacked(payload, new bytes(_random() & 0xff));
        }
        bytes32 payloadHash = keccak256(payload);
        if (_vectorTested[payloadHash]) return _vectorResult[payloadHash];
        _vectorTested[payloadHash] = true;
        return (_vectorResult[payloadHash] = _verifierCall(payload));
    }

    function _verifierCall(bytes memory payload) internal returns (bool) {
        (bool success, bytes memory result) = P256.VERIFIER.call(payload);
        assertTrue(success);
        return abi.decode(result, (bool));
    }

    function testP256VerifyOutOfBounds() public {
        uint256 p = P256PublicKey.P;
        assertFalse(_verifyViaVerifier(bytes32(0), 1, 1, 1, 1));
        assertFalse(_verifyViaVerifier(bytes32(0), 1, 1, 0, 1));
        assertFalse(_verifyViaVerifier(bytes32(0), 1, 1, 1, 0));
        assertFalse(_verifyViaVerifier(bytes32(0), 1, 1, 1, p));
        assertFalse(_verifyViaVerifier(bytes32(0), 1, 1, p, 1));
        assertFalse(_verifyViaVerifier(bytes32(0), 1, 1, p - 1, 1));
    }
}

/// @dev Library to derive P256 public key from private key
/// Should be removed if Foundry adds this functionality
/// See: https://github.com/foundry-rs/foundry/issues/7908
/// From: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/P256.sol
library P256PublicKey {
    uint256 internal constant GX =
        0x6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296;
    uint256 internal constant GY =
        0x4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5;
    uint256 internal constant P = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF;
    uint256 internal constant N = 0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551;
    uint256 internal constant A = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC;
    uint256 internal constant B = 0x5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B;
    uint256 internal constant P1DIV4 =
        0x3fffffffc0000000400000000000000000000000400000000000000000000000;
    uint256 internal constant HALF_N =
        0x7fffffff800000007fffffffffffffffde737d56d38bcf4279dce5617e3192a8;

    function getPublicKey(uint256 privateKey) internal view returns (bytes32, bytes32) {
        (uint256 x, uint256 y, uint256 z) = _jMult(GX, GY, 1, privateKey);
        return _affineFromJacobian(x, y, z);
    }

    function _jMult(uint256 x, uint256 y, uint256 z, uint256 k)
        private
        pure
        returns (uint256 rx, uint256 ry, uint256 rz)
    {
        unchecked {
            for (uint256 i; i != 256; ++i) {
                if (rz > 0) {
                    (rx, ry, rz) = _jDouble(rx, ry, rz);
                }
                if (k >> 255 > 0) {
                    if (rz == 0) {
                        (rx, ry, rz) = (x, y, z);
                    } else {
                        (rx, ry, rz) = _jAdd(rx, ry, rz, x, y, z);
                    }
                }
                k <<= 1;
            }
        }
    }

    function _affineFromJacobian(uint256 jx, uint256 jy, uint256 jz)
        private
        view
        returns (bytes32 ax, bytes32 ay)
    {
        if (jz == uint256(0)) return (0, 0);
        uint256 zinv = invModPrime(jz, P);
        uint256 zzinv = mulmod(zinv, zinv, P);
        uint256 zzzinv = mulmod(zzinv, zinv, P);
        ax = bytes32(mulmod(jx, zzinv, P));
        ay = bytes32(mulmod(jy, zzzinv, P));
    }

    function _jDouble(uint256 x, uint256 y, uint256 z)
        private
        pure
        returns (uint256 rx, uint256 ry, uint256 rz)
    {
        uint256 p = P;
        /// @solidity memory-safe-assembly
        assembly {
            let yy := mulmod(y, y, p)
            let zz := mulmod(z, z, p)
            mstore(0x00, mulmod(4, mulmod(x, yy, p), p))
            mstore(0x20, addmod(mulmod(3, mulmod(x, x, p), p), mulmod(A, mulmod(zz, zz, p), p), p))
            rx := addmod(mulmod(mload(0x20), mload(0x20), p), sub(p, mulmod(2, mload(0x00), p)), p)
            ry :=
                addmod(
                    mulmod(mload(0x20), addmod(mload(0x00), sub(p, rx), p), p),
                    sub(p, mulmod(8, mulmod(yy, yy, p), p)),
                    p
                )
            rz := mulmod(2, mulmod(y, z, p), p)
        }
    }

    function _jAdd(uint256 x1, uint256 y1, uint256 z1, uint256 x2, uint256 y2, uint256 z2)
        private
        pure
        returns (uint256 rx, uint256 ry, uint256 rz)
    {
        uint256 p = P;
        /// @solidity memory-safe-assembly
        assembly {
            let zz1 := mulmod(z1, z1, p)
            mstore(0x60, mulmod(z2, z2, p))
            mstore(0x00, mulmod(x1, mload(0x60), p))
            mstore(0x20, mulmod(y1, mulmod(mload(0x60), z2, p), p))
            mstore(0x60, addmod(mulmod(x2, zz1, p), sub(p, mload(0x00)), p))
            let hh := mulmod(mload(0x60), mload(0x60), p)
            let hhh := mulmod(mload(0x60), hh, p)
            let r := addmod(mulmod(y2, mulmod(zz1, z1, p), p), sub(p, mload(0x20)), p)
            rx :=
                addmod(
                    addmod(mulmod(r, r, p), sub(p, hhh), p),
                    sub(p, mulmod(2, mulmod(mload(0x00), hh, p), p)),
                    p
                )
            ry :=
                addmod(
                    mulmod(r, addmod(mulmod(mload(0x00), hh, p), sub(p, rx), p), p),
                    sub(p, mulmod(mload(0x20), hhh, p)),
                    p
                )
            rz := mulmod(mload(0x60), mulmod(z1, z2, p), p)
            mstore(0x60, 0)
        }
    }

    function invModPrime(uint256 a, uint256 p) internal view returns (uint256) {
        unchecked {
            return modExp(a, p - 2, p);
        }
    }

    function modExp(uint256 b, uint256 e, uint256 m) internal view returns (uint256) {
        (bool success, uint256 result) = tryModExp(b, e, m);
        if (!success) revert();
        return result;
    }

    function tryModExp(uint256 b, uint256 e, uint256 m)
        internal
        view
        returns (bool success, uint256 result)
    {
        if (m == 0) return (false, 0);
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x20)
            mstore(add(ptr, 0x20), 0x20)
            mstore(add(ptr, 0x40), 0x20)
            mstore(add(ptr, 0x60), b)
            mstore(add(ptr, 0x80), e)
            mstore(add(ptr, 0xa0), m)
            success := staticcall(gas(), 0x05, ptr, 0xc0, 0x00, 0x20)
            result := mload(0x00)
        }
    }
}
