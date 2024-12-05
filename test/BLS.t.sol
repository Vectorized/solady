// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {BLS} from "../src/utils/ext/ithaca/BLS.sol";

contract BLSTest is SoladyTest {
    function G1_GENERATOR() internal pure returns (BLS.G1Point memory) {
        return BLS.G1Point(
            _u(31827880280837800241567138048534752271),
            _u(88385725958748408079899006800036250932223001591707578097800747617502997169851),
            _u(11568204302792691131076548377920244452),
            _u(114417265404584670498511149331300188430316142484413708742216858159411894806497)
        );
    }

    function NEGATED_G1_GENERATOR() internal pure returns (BLS.G1Point memory) {
        return BLS.G1Point(
            _u(31827880280837800241567138048534752271),
            _u(88385725958748408079899006800036250932223001591707578097800747617502997169851),
            _u(22997279242622214937712647648895181298),
            _u(46816884707101390882112958134453447585552332943769894357249934112654335001290)
        );
    }

    function _u(uint256 x) internal pure returns (bytes32) {
        return bytes32(x);
    }

    // We need to figure out a way to run with Odyssey features.
    // Ideally, it should be `forge test --some-odyssey-flag`.

    // function test() public {
    //     // Obtain the private key as a random scalar.
    //     bytes32 privateKey = bytes32(_randomUniform());

    //     // Public key is the generator point multiplied by the private key.
    //     BLS.G1Point memory publicKey = BLS.mul(G1_GENERATOR(), privateKey);

    //     // Compute the message point by mapping message's keccak256 hash to a point in G2.
    //     bytes memory message = "hello world";
    //     BLS.G2Point memory messagePoint = BLS.toG2(BLS.Fp2(0, 0, 0, keccak256(message)));

    //     // Obtain the signature by multiplying the message point by the private key.
    //     BLS.G2Point memory signature = BLS.mul(messagePoint, privateKey);

    //     // Invoke the pairing check to verify the signature.
    //     BLS.G1Point[] memory g1Points = new BLS.G1Point[](2);
    //     g1Points[0] = NEGATED_G1_GENERATOR();
    //     g1Points[1] = publicKey;

    //     BLS.G2Point[] memory g2Points = new BLS.G2Point[](2);
    //     g2Points[0] = signature;
    //     g2Points[1] = messagePoint;

    //     assertTrue(BLS.pairing(g1Points, g2Points));
    // }
}
