// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {P256VerifierEtcher} from "./P256.t.sol";
import {LibString} from "../src/utils/LibString.sol";
import {Base64} from "../src/utils/Base64.sol";
import {WebAuthn} from "../src/utils/WebAuthn.sol";

contract WebAuthnTest is P256VerifierEtcher {
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

    function verify(
        bytes memory challenge,
        bool requireUserVerification,
        WebAuthn.WebAuthnAuth memory webAuthnAuth,
        bytes32 x,
        bytes32 y
    ) public virtual returns (bool) {
        return WebAuthn.verify(challenge, requireUserVerification, webAuthnAuth, x, y);
    }

    struct _TestTemps {
        bytes32 x;
        bytes32 y;
        bytes challenge;
    }

    function _testTemps() internal virtual returns (_TestTemps memory t) {
        t.x = 0x3f2be075ef57d6c8374ef412fe54fdd980050f70f4f3a00b5b1b32d2def7d28d;
        t.y = 0x57095a365acc2590ade3583fabfe8fbd64a9ed3ec07520da00636fb21f0176c1;
        t.challenge = abi.encode(0xf631058a3ba1116acce12396fad0a125b5041c43f8e15723709f81aa8d5f4ccf);
    }

    function testSafari() public {
        _etchRIPPrecompile(true);
        _etchVerifier(true);
        _TestTemps memory t = _testTemps();
        WebAuthn.WebAuthnAuth memory auth;
        auth.authenticatorData =
            hex"49960de5880e8c687434170f6476605b8fe4aeb9a28632c7995cf3ba831d97630500000101";
        auth.clientDataJSON = string(
            abi.encodePacked(
                '{"type":"webauthn.get","challenge":"',
                Base64.encode(t.challenge, true, true),
                '","origin":"http://localhost:3005"}'
            )
        );
        auth.challengeIndex = 23;
        auth.typeIndex = 1;
        auth.r = 0x60946081650523acad13c8eff94996a409b1ed60e923c90f9e366aad619adffa;
        auth.s = 0x3216a237b73765d01b839e0832d73474bc7e63f4c86ef05fbbbfbeb34b35602b;
        assertTrue(WebAuthn.verify(t.challenge, false, auth, t.x, t.y));
    }

    function testChrome() public {
        _etchRIPPrecompile(true);
        _etchVerifier(true);
        _TestTemps memory t = _testTemps();
        WebAuthn.WebAuthnAuth memory auth;
        auth.authenticatorData =
            hex"49960de5880e8c687434170f6476605b8fe4aeb9a28632c7995cf3ba831d9763050000010a";
        auth.clientDataJSON = string(
            abi.encodePacked(
                '{"type":"webauthn.get","challenge":"',
                Base64.encode(t.challenge, true, true),
                '","origin":"http://localhost:3005","crossOrigin":false}'
            )
        );
        auth.challengeIndex = 23;
        auth.typeIndex = 1;
        auth.r = 0x41c01ca5ecdfeb23ef70d6cc216fd491ac3aa3d40c480751f3618a3a9ef67b41;
        auth.s = 0x6595569abf76c2777e832a9252bae14efdb77febd0fa3b919aa16f6208469e86;
        assertTrue(WebAuthn.verify(t.challenge, false, auth, t.x, t.y));
    }

    function testPassthroughDifferential(bytes32) public {
        _etchVerifierPassthrough(true);
        _etchRIPPrecompilePassthrough(true);

        bytes memory challenge = _sampleRandomUniformShortBytes();
        WebAuthn.WebAuthnAuth memory auth;
        auth.authenticatorData = _sampleRandomUniformShortBytes();
        auth.clientDataJSON = _sampleClientDataJSON(challenge);
        auth.challengeIndex = _sampleChallengeIndex(auth.clientDataJSON);
        auth.typeIndex = _sampleTypeIndex(auth.clientDataJSON);
        bool requireUserVerification = _randomChance(2);
        assertEq(
            WebAuthn.verify(challenge, requireUserVerification, auth, 0, 0),
            _verifyPassthroughOriginal(challenge, requireUserVerification, auth)
        );
    }

    bytes1 private constant _AUTH_DATA_FLAGS_UP = 0x01;
    bytes1 private constant _AUTH_DATA_FLAGS_UV = 0x04;
    bytes32 private constant _EXPECTED_TYPE_HASH = keccak256('"type":"webauthn.get"');

    function _verifyPassthroughOriginal(
        bytes memory challenge,
        bool requireUserVerification,
        WebAuthn.WebAuthnAuth memory webAuthnAuth
    ) internal pure returns (bool) {
        string memory t = LibString.slice(
            webAuthnAuth.clientDataJSON, webAuthnAuth.typeIndex, webAuthnAuth.typeIndex + 21
        );
        if (keccak256(bytes(t)) != _EXPECTED_TYPE_HASH) {
            return false;
        }
        bytes memory expectedChallenge =
            abi.encodePacked('"challenge":"', Base64.encode(challenge, true, true), '"');
        string memory actualChallenge = LibString.slice(
            webAuthnAuth.clientDataJSON,
            webAuthnAuth.challengeIndex,
            webAuthnAuth.challengeIndex + expectedChallenge.length
        );
        if (keccak256(bytes(actualChallenge)) != keccak256(expectedChallenge)) {
            return false;
        }

        if (webAuthnAuth.authenticatorData.length <= 32) return false;

        if (webAuthnAuth.authenticatorData[32] & _AUTH_DATA_FLAGS_UP != _AUTH_DATA_FLAGS_UP) {
            return false;
        }
        if (
            requireUserVerification
                && (webAuthnAuth.authenticatorData[32] & _AUTH_DATA_FLAGS_UV) != _AUTH_DATA_FLAGS_UV
        ) {
            return false;
        }
        return true;
    }

    function _sampleClientDataJSON(bytes memory challenge) internal returns (string memory) {
        return string(
            abi.encodePacked(
                "{",
                _sampleRandomUniformShortBytes(),
                _maybeReturnEmpty('"type":"webauthn.get"'),
                _sampleRandomUniformShortBytes(),
                _maybeReturnEmpty(',"challenge":"'),
                Base64.encode(challenge, true, true),
                _maybeReturnEmpty(abi.encodePacked('"', _sampleRandomUniformShortBytes(), "}"))
            )
        );
    }

    function _maybeReturnEmpty(bytes memory s) internal returns (bytes memory result) {
        if (!_randomChance(4)) result = s;
    }

    function _sampleChallengeIndex(string memory clientDataJSON)
        internal
        returns (uint256 result)
    {
        if (!_randomChance(4)) {
            result = LibString.indexOf(clientDataJSON, '"challenge":"');
            if (result <= 0xffffffff) return result;
        }
        unchecked {
            result = _bound(_randomUniform(), 0, bytes(clientDataJSON).length + 35);
        }
    }

    function _sampleTypeIndex(string memory clientDataJSON) internal returns (uint256 result) {
        if (!_randomChance(4)) {
            result = LibString.indexOf(clientDataJSON, '"type":"webauthn.get"');
            if (result <= 0xffffffff) return result;
        }
        unchecked {
            result = _bound(_randomUniform(), 0, bytes(clientDataJSON).length + 35);
        }
    }

    function _sampleRandomUniformShortBytes() internal returns (bytes memory result) {
        uint256 n = _randomUniform();
        uint256 r = _randomUniform();
        /// @solidity memory-safe-assembly
        assembly {
            switch and(0xf, byte(0, n))
            case 0 { n := and(n, 0x3f) }
            default { n := and(n, 0x3) }
            result := mload(0x40)
            mstore(result, n)
            mstore(add(0x20, result), r)
            mstore(add(0x40, result), keccak256(result, 0x40))
            mstore(0x40, add(result, 0x80))
        }
    }
}
