// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {ERC6551, SignatureCheckerLib} from "../src/accounts/ERC6551.sol";

contract ERC6551Test is SoladyTest {
    function testDeployERC6551() public {
        new ERC6551();
    }

    function testSelfOwnBooleanTrick(uint256 x) public {
        bool t0;
        assembly {
            t0 :=
                iszero(
                    or(
                        eq(byte(0, x), byte(1, x)),
                        and(
                            eq(byte(2, x), byte(3, x)),
                            and(eq(byte(4, x), byte(5, x)), eq(byte(6, x), byte(7, x)))
                        )
                    )
                )
        }
        bool t1 =
            b(0, x) != b(1, x) && (b(2, x) != b(3, x) || b(4, x) != b(5, x) || b(6, x) != b(7, x));
        assertEq(t0, t1);
    }

    function b(uint256 n, uint256 x) internal pure returns (uint256 c) {
        assembly {
            c := byte(n, x)
        }
    }
}
