// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";

contract BrutalizerTest is SoladyTest {
    function testBrutalizedBool(bytes32, bool x) public {
        bool brutalized = _brutalized(x);
        assertEq(brutalized, x);
        if (x) {
            for (bool isBrutalized; !isBrutalized;) {
                brutalized = _brutalized(x);
                assertEq(brutalized, x);
                /// @solidity memory-safe-assembly
                assembly {
                    isBrutalized := gt(brutalized, 1)
                }
            }
        }
    }

    function testBrutalizedAddress(bytes32, address x) public {
        address brutalized = _brutalized(x);
        assertEq(brutalized, x);
        for (bool isBrutalized; !isBrutalized;) {
            brutalized = _brutalized(x);
            assertEq(brutalized, x);
            /// @solidity memory-safe-assembly
            assembly {
                isBrutalized := shr(160, brutalized)
            }
        }
    }

    function testBrutalizedUint8(bytes32, uint8 x) public {
        uint8 brutalized = _brutalizedUint8(x);
        assertEq(brutalized, x);
        for (bool isBrutalized; !isBrutalized;) {
            brutalized = _brutalizedUint8(x);
            assertEq(brutalized, x);
            /// @solidity memory-safe-assembly
            assembly {
                isBrutalized := shr(8, brutalized)
            }
        }
    }

    function testBrutalizedUint248(bytes32, uint248 x) public {
        uint248 brutalized = _brutalizedUint248(x);
        assertEq(brutalized, x);
        for (bool isBrutalized; !isBrutalized;) {
            brutalized = _brutalizedUint248(x);
            assertEq(brutalized, x);
            /// @solidity memory-safe-assembly
            assembly {
                isBrutalized := shr(248, brutalized)
            }
        }
    }

    function testBrutalizedBytes1(bytes32, bytes1 x) public {
        bytes1 brutalized = _brutalizedBytes1(x);
        assertEq(brutalized, x);
        for (bool isBrutalized; !isBrutalized;) {
            brutalized = _brutalizedBytes1(x);
            assertEq(brutalized, x);
            /// @solidity memory-safe-assembly
            assembly {
                isBrutalized := shl(8, brutalized)
            }
        }
    }

    function testBrutalizedBytes31(bytes32, bytes31 x) public {
        bytes31 brutalized = _brutalizedBytes31(x);
        assertEq(brutalized, x);
        for (bool isBrutalized; !isBrutalized;) {
            brutalized = _brutalizedBytes31(x);
            assertEq(brutalized, x);
            /// @solidity memory-safe-assembly
            assembly {
                isBrutalized := shl(248, brutalized)
            }
        }
    }
}
