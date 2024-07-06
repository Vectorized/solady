// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {LibString} from "../src/utils/LibString.sol";
import {P256} from "../src/utils/P256.sol";

contract P256Test is SoladyTest {
    bytes private constant _VERIFIER_BYTECODE =
        hex"7fffffffff00000001000000000000000000000000ffffffffffffffffffffffff604052610523565b60008060008561003f5750859150869050876100cc565b886100515750829150839050846100cc565b60405180878809818b8c098281880983838c0984858f85098b09925084858c86098e099350848286038208905084818209858183098685880387089550868788848709600209880388838a038a8a8b09080899508687828709880388898d8b038b878a09088909089850505084858f8d098209955050505050505b96509650969350505050565b6000604051807f5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b8285843d5186898a0908090880828687091495945050505050565b8160071b915081513d8301516040840151604051808384098183840982838388096004098384858485093d510985868a8b09600309089650838482600209850385898a090891508384858586096008098503858685880385088a0908965050828385870960020960079790971b9081523d810195909552505050506040015250565b8160071b91508260071b92506101c660408401513d850151855160408601513d8701518751610028565b60079390931b9182523d820152604001525050565b60006040516000806000805b811561029b57848384098583840986878388096004098788898485093d5109898a8a8b09600309088889836002098a038a83840908898a8b8788096008098b038b8c848e0387088509088a8b898b096002098b82830996508b81820995508b8c88850960040994508b8c8d8889093d51098d8e8687096003090893508b8c866002098d038d868709089a508b8c828409600209985050505088898a8687096008098a038a8b8b8d0386088409089650505050505b61018088821b60f71c1661060088831b60f51c16178015610356576040810151806102c65750610356565b836102dd5781513d83015190965094509250610356565b86808586098183840982818a0983848684098a0991508381850385858951090884818209858183098685880388898e8a093d8d015109089550868788848709600209880388838a038a8a8b09080887888388098903898a848c038c888b09088a09089c5087888a8e098509909d509a5050505050505050505b50811561040b57848384098583840986878388096004098788898485093d5109898a8a8b09600309088889836002098a038a83840908898a8b8788096008098b038b8c848e0387088509088a8b898b096002098b82830996508b81820995508b8c88850960040994508b8c8d8889093d51098d8e8687096003090893508b8c866002098d038d868709089a508b8c828409600209985050505088898a8687096008098a038a8b8b8d0386088409089650505050505b61018088821b60f51c1661060088831b60f31c161780156104c65760408101518061043657506104c6565b8361044d5781513d830151909650945092506104c6565b86808586098183840982818a0983848684098a0991508381850385858951090884818209858183098685880388898e8a093d8d015109089550868788848709600209880388838a038a8a8b09080887888388098903898a848c038c888b09088a09089c5087888a8e098509909d509a5050505050505050505b50600481019060fb19016101e75750806104e3575050505061051d565b80610860526002840361088052836108a0523d3d60c061080060055afa61050d5760003d5260203df35b505081823d513d51098209925050505b92915050565b7fffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc6325516040357f7fffffff800000007fffffffffffffffde737d56d38bcf4279dce5617e3192a88111156105725781035b60206108005260206108205260206108405280610860526002820361088052816108a05260203d60c061080060055afa60203d14166105b45760003d5260203df35b6003604051183d523d356060356080356105ce81836100d8565b85851085151086851085151016166105e95760003d5260203df35b60808281523d01819052600160c05250507f6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c2966102009081527f4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f53d909101526001610240526106596001600261011a565b6106656004600861011a565b61067360026001600361019c565b61068160046001600561019c565b61068f60046002600661019c565b61069d60046003600761019c565b6106ab60086001600961019c565b6106b960086002600a61019c565b6106c760086003600b61019c565b6106d560086004600c61019c565b6106e3600c6001600d61019c565b6106f1600c6002600e61019c565b6106ff600c6003600f61019c565b808361071785600051850986600051600035096101db565b06143d525050503d3df3fea26469706673582212200a642bbac6980dc09f95e3ba2c0c7a066ea241650330dd87926d43c3f0d39c8464736f6c634300081a0033";

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

    function _etchRIPPrecompile() internal {
        vm.etch(P256.RIP_PRECOMPILE, _VERIFIER_BYTECODE);
    }

    function _etchVerifier() internal {
        vm.etch(P256.VERIFIER, _VERIFIER_BYTECODE);
    }

    function testP256VerifyMalleableRIPPrecompile() public {
        _etchRIPPrecompile();
        _testP256VerifyMalleable();
    }

    function testP256VerifyMalleableVerifier() public {
        _etchVerifier();
        _testP256VerifyMalleable();
    }

    function _testP256VerifyMalleable() internal {
        assertEq(P256.verifySignatureAllowMalleability(_HASH, _R, _MALLEABLE_S, _X, _Y), true);
        assertEq(P256.verifySignature(_HASH, _R, _MALLEABLE_S, _X, _Y), false);
    }

    function testP256VerifyNonMalleableRIPPrecompile() public {
        _etchRIPPrecompile();
        _testP256VerifyNonMalleable();
    }

    function testP256VerifyNonMalleableVerifier() public {
        _etchVerifier();
        _testP256VerifyNonMalleable();
    }

    function testP256VerifyNotDeployedReverts(
        bytes32 hash,
        uint256 r,
        uint256 s,
        uint256 x,
        uint256 y,
        bool t
    ) public {
        if (t) {
            vm.expectRevert(P256.P256VerificationFailed.selector);
            this.verifySignatureAllowMalleability(hash, r, s, x, y);
        } else {
            vm.expectRevert(P256.P256VerificationFailed.selector);
            this.verifySignature(hash, r, s, x, y);
        }
    }

    function verifySignature(bytes32 hash, uint256 r, uint256 s, uint256 x, uint256 y)
        public
        view
        returns (bool)
    {
        return P256.verifySignature(hash, r, s, x, y);
    }

    function verifySignatureAllowMalleability(
        bytes32 hash,
        uint256 r,
        uint256 s,
        uint256 x,
        uint256 y
    ) public view returns (bool) {
        return P256.verifySignatureAllowMalleability(hash, r, s, x, y);
    }

    function _testP256VerifyNonMalleable() internal {
        assertEq(P256.verifySignatureAllowMalleability(_HASH, _R, _NON_MALLEABLE_S, _X, _Y), true);
        assertEq(P256.verifySignature(_HASH, _R, _NON_MALLEABLE_S, _X, _Y), true);
    }

    function testP256Wycheproof() public {
        _testP256Wycheproof("./test/data/wycheproof.jsonl");
    }

    function _testP256Wycheproof(string memory file) internal {
        vm.pauseGasMetering();
        _etchVerifier();
        for (uint256 i = 1;; ++i) {
            string memory vector = vm.readLine(file);
            if (bytes(vector).length == 0) break;
            bool expected = vm.parseJsonBool(vector, ".valid");
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

    function _verifyViaVerifier(bytes32 hash, bytes32 r, bytes32 s, bytes32 x, bytes32 y)
        internal
        returns (bool)
    {
        bytes memory payload = abi.encode(hash, r, s, x, y);
        bytes32 payloadHash = keccak256(payload);
        if (_vectorTested[payloadHash]) return _vectorResult[payloadHash];
        (bool success, bytes memory result) = P256.VERIFIER.call(payload);
        assertTrue(success);
        _vectorTested[payloadHash] = true;
        return (_vectorResult[payloadHash] = abi.decode(result, (bool)));
    }
}
