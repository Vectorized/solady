// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";

contract BrutalizerTest is SoladyTest {
    function testBrutalizedBool() public {
        for (uint256 i; i < 8; ++i) {
            _testBrutalizedBool(i & 1 == uint256(0));
        }
    }

    function _testBrutalizedBool(bool b) internal {
        bool brutalized = _brutalized(b);
        assertEq(brutalized, b);
        for (bool isBrutalized; b && !isBrutalized;) {
            brutalized = _brutalized(b);
            /// @solidity memory-safe-assembly
            assembly {
                isBrutalized := gt(brutalized, 1)
            }
        }
    }
}
