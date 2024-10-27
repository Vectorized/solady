// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {LibString} from "../src/utils/LibString.sol";
import {P256} from "../src/utils/P256.sol";
import {Base64} from "../src/utils/Base64.sol";
import {WebAuthn} from "../src/utils/WebAuthn.sol";

contract WebAuthnTest is SoladyTest {
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

    function testHasExpectedTypeDifferential(bytes32) public {
        string memory clientDataJSON;
        if (_randomChance(2)) {
            clientDataJSON = string(
                abi.encodePacked(_randomSmallBytes(), '"type":"webauthn.get"', _randomSmallBytes())
            );
        } else {
            clientDataJSON = string(_randomSmallBytes());
        }

        uint256 typeIndex = _bound(_random(), 0, bytes(clientDataJSON).length + 50);

        bool hasExpectedType;
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(clientDataJSON)
            hasExpectedType :=
                and(
                    eq(
                        shr(88, mload(add(add(clientDataJSON, 0x20), typeIndex))),
                        shr(88, '"type":"webauthn.get"')
                    ),
                    and(lt(typeIndex, n), lt(add(20, typeIndex), n))
                )
        }

        assertEq(hasExpectedType, _hasExpectedTypeOriginal(clientDataJSON, typeIndex));
    }

    function _hasExpectedTypeOriginal(string memory clientDataJSON, uint256 typeIndex)
        internal
        pure
        returns (bool)
    {
        return keccak256(bytes(LibString.slice(clientDataJSON, typeIndex, typeIndex + 21)))
            == keccak256('"type":"webauthn.get"');
    }

    function testHasExpectedChallengeDifferential(bytes32) public {
        string memory clientDataJSON;
        bytes memory challenge = _randomSmallBytes();
        if (_randomChance(2)) {
            clientDataJSON = string(
                abi.encodePacked(
                    _randomSmallBytes(), '"challenge":"', challenge, '"', _randomSmallBytes()
                )
            );
        } else {
            clientDataJSON = string(_randomSmallBytes());
        }
        uint256 challengeIndex = _bound(_random(), 0, bytes(clientDataJSON).length + 50);

        bool hasExpectedChallenge;
        string memory encodedURL = Base64.encode(challenge, true, true);
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(clientDataJSON)
            let l := mload(encodedURL)
            mstore(encodedURL, shr(152, '"challenge":"'))
            let q := add(l, 13)
            hasExpectedChallenge :=
                and(
                    eq(
                        keccak256(add(add(clientDataJSON, 0x20), challengeIndex), q),
                        keccak256(add(encodedURL, 19), q)
                    ),
                    and(
                        eq(and(0xff, mload(add(add(clientDataJSON, challengeIndex), q))), 34),
                        and(lt(challengeIndex, n), lt(add(q, challengeIndex), n))
                    )
                )
            mstore(encodedURL, l)
        }

        assertEq(
            hasExpectedChallenge,
            _hasExpectedChallengeOriginal(challenge, clientDataJSON, challengeIndex)
        );
    }

    function _hasExpectedChallengeOriginal(
        bytes memory challenge,
        string memory clientDataJSON,
        uint256 challengeIndex
    ) private pure returns (bool) {
        bytes memory expectedChallenge =
            abi.encodePacked('"challenge":"', Base64.encode(challenge, true, true), '"');
        string memory actualChallenge = LibString.slice(
            clientDataJSON, challengeIndex, challengeIndex + expectedChallenge.length
        );
        return keccak256(bytes(actualChallenge)) == keccak256(expectedChallenge);
    }

    function _randomSmallBytes() private returns (bytes memory) {
        return _truncateBytes(_randomBytes(), 0x1ff);
    }

    function verify(
        bytes memory challenge,
        bool requireUserVerification,
        WebAuthn.WebAuthnAuth memory webAuthnAuth,
        bytes32 x,
        bytes32 y
    ) public view returns (bool) {
        return WebAuthn.verify(challenge, requireUserVerification, webAuthnAuth, x, y);
    }
}
