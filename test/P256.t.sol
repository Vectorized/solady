// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {LibString} from "../src/utils/LibString.sol";
import {P256} from "../src/utils/P256.sol";

contract P256VerifierEtcher is SoladyTest {
    bytes internal constant _VERIFIER_BYTECODE =
        hex"3d604052610216565b60008060006ffffffffeffffffffffffffffffffffff60601b19808687098188890982838389096004098384858485093d510985868b8c096003090891508384828308850385848509089650838485858609600809850385868a880385088509089550505050808188880960020991505093509350939050565b81513d83015160408401516ffffffffeffffffffffffffffffffffff60601b19808384098183840982838388096004098384858485093d510985868a8b096003090896508384828308850385898a09089150610102848587890960020985868787880960080987038788878a0387088c0908848b523d8b015260408a0152565b505050505050505050565b81513d830151604084015185513d87015160408801518361013d578287523d870182905260408701819052610102565b80610157578587523d870185905260408701849052610102565b6ffffffffeffffffffffffffffffffffff60601b19808586098183840982818a099850828385830989099750508188830383838809089450818783038384898509870908935050826101be57836101be576101b28a89610082565b50505050505050505050565b808485098181860982828a09985082838a8b0884038483860386898a09080891506102088384868a0988098485848c09860386878789038f088a0908848d523d8d015260408c0152565b505050505050505050505050565b6020357fffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc6325513d6040357f7fffffff800000007fffffffffffffffde737d56d38bcf4279dce5617e3192a88111156102695782035b60206108005260206108205260206108405280610860526002830361088052826108a0526ffffffffeffffffffffffffffffffffff60601b198060031860205260603560803560203d60c061080060055afa60203d1416837f5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b8585873d5189898a09080908848384091484831085851016888710871510898b108b151016609f3611161616166103195760206080f35b60809182523d820152600160c08190527f6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c2966102009081527f4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f53d909101526102405261038992509050610100610082565b610397610200610400610082565b6103a7610100608061018061010d565b6103b7610200608061028061010d565b6103c861020061010061030061010d565b6103d961020061018061038061010d565b6103e9610400608061048061010d565b6103fa61040061010061050061010d565b61040b61040061018061058061010d565b61041c61040061020061060061010d565b61042c610600608061068061010d565b61043d61060061010061070061010d565b61044e61060061018061078061010d565b81815182350982825185098283846ffffffffeffffffffffffffffffffffff60601b193d515b82156105245781858609828485098384838809600409848586848509860986878a8b096003090885868384088703878384090886878887880960080988038889848b03870885090887888a8d096002098882830996508881820995508889888509600409945088898a8889098a098a8b86870960030908935088898687088a038a868709089a5088898284096002099950505050858687868709600809870387888b8a0386088409089850505050505b61018086891b60f71c16610600888a1b60f51c16176040810151801585151715610564578061055357506105fe565b81513d8301519750955093506105fe565b83858609848283098581890986878584098b0991508681880388858851090887838903898a8c88093d8a015109089350836105b957806105b9576105a9898c8c610008565b9a509b50995050505050506105fe565b8781820988818309898285099350898a8586088b038b838d038d8a8b0908089b50898a8287098b038b8c8f8e0388088909089c5050508788868b098209985050505050505b5082156106af5781858609828485098384838809600409848586848509860986878a8b096003090885868384088703878384090886878887880960080988038889848b03870885090887888a8d096002098882830996508881820995508889888509600409945088898a8889098a098a8b86870960030908935088898687088a038a868709089a5088898284096002099950505050858687868709600809870387888b8a0386088409089850505050505b61018086891b60f51c16610600888a1b60f31c161760408101518015851517156106ef57806106de5750610789565b81513d830151975095509350610789565b83858609848283098581890986878584098b0991508681880388858851090887838903898a8c88093d8a01510908935083610744578061074457610734898c8c610008565b9a509b5099505050505050610789565b8781820988818309898285099350898a8586088b038b838d038d8a8b0908089b50898a8287098b038b8c8f8e0388088909089c5050508788868b098209985050505050505b50600488019760fb19016104745750816107a2573d6040f35b81610860526002810361088052806108a0523d3d60c061080060055afa898983843d513d510987090614163d525050505050505050503d3df3fea264697066735822122063ce32ec0e56e7893a1f6101795ce2e38aca14dd12adb703c71fe3bee27da71e64736f6c634300081a0033";

    bytes internal constant _PASSTHROUGH_BYTECODE = hex"600160005260206000f3";

    function _etchBytecode(address target, bytes memory bytecode, bool active) internal {
        if (target == P256.RIP_PRECOMPILE) {
            if (active && _hasNativeRIPPrecompile()) return;
            if (!active && _hasNativeRIPPrecompile()) {
                /// @solidity memory-safe-assembly
                assembly {
                    return(0x00, 0x00)
                }
            }
        }

        if (active) {
            if (target.code.length == 0) vm.etch(target, bytecode);
        } else {
            if (target.code.length != 0) vm.etch(target, "");
        }
    }

    function _hasNativeRIPPrecompile() internal view returns (bool) {
        return P256.hasPrecompile() && P256.RIP_PRECOMPILE.code.length == 0;
    }

    function _etchPassthroughBytecode(address target, bool active) internal {
        _etchBytecode(target, _PASSTHROUGH_BYTECODE, active);
    }

    function _etchVerifierBytecode(address target, bool active) internal {
        _etchBytecode(target, _VERIFIER_BYTECODE, active);
    }

    function _etchRIPPrecompilePassthrough(bool active) internal {
        _etchPassthroughBytecode(P256.RIP_PRECOMPILE, active);
    }

    function _etchVerifierPassthrough(bool active) internal {
        _etchPassthroughBytecode(P256.VERIFIER, active);
    }

    function _etchRIPPrecompile(bool active) internal {
        _etchVerifierBytecode(P256.RIP_PRECOMPILE, active);
    }

    function _etchVerifier(bool active) internal {
        _etchVerifierBytecode(P256.VERIFIER, active);
    }
}

contract P256Test is P256VerifierEtcher {
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

    function testTryDecodePoint(bytes32 x, bytes32 y) public {
        bytes memory encoded = abi.encodePacked(x, y);
        (bytes32 xDecoded, bytes32 yDecoded) = P256.tryDecodePoint(encoded);
        assertEq(xDecoded, x);
        assertEq(yDecoded, y);
        this.tryDecodePointCalldata(encoded, x, y);
    }

    function tryDecodePointCalldata(bytes calldata encoded, bytes32 x, bytes32 y) public {
        (bytes32 xDecoded, bytes32 yDecoded) = P256.tryDecodePointCalldata(encoded);
        assertEq(xDecoded, x);
        assertEq(yDecoded, y);
    }

    function check_P256Normalized(uint256 s) public pure {
        uint256 n = uint256(P256.N);
        unchecked {
            uint256 expected = s > (n / 2) ? n - s : s;
            assert(uint256(P256.normalized(bytes32(s))) == expected);
        }
    }

    function testP256Normalized(uint256 privateKey, bytes32 hash) public {
        while (privateKey == 0 || privateKey >= P256.N) {
            privateKey = uint256(keccak256(abi.encode(privateKey)));
        }
        (uint256 x, uint256 y) = vm.publicKeyP256(privateKey);

        // Note that `vm.signP256` can produce `s` above `N / 2`.
        (bytes32 r, bytes32 s) = vm.signP256(privateKey, hash);

        if (uint256(s) > P256.N / 2) {
            assertFalse(P256.verifySignature(hash, r, s, bytes32(x), bytes32(y)));
            assertTrue(P256.verifySignature(hash, r, P256.normalized(s), bytes32(x), bytes32(y)));
        } else {
            assertTrue(P256.verifySignature(hash, r, s, bytes32(x), bytes32(y)));
        }
        assertTrue(P256.verifySignatureAllowMalleability(hash, r, s, bytes32(x), bytes32(y)));
    }

    function testHasPrecompileOrVerifier(bytes32) public {
        bool etchPrecompile = _randomChance(2);
        bool etchVerifier = _randomChance(2);
        _etchRIPPrecompile(etchPrecompile);
        _etchVerifier(etchVerifier);
        assertEq(P256.hasPrecompileOrVerifier(), etchPrecompile || etchVerifier);
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
