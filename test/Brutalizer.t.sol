// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";

contract BrutalizerTest is SoladyTest {
    function testBrutalized() public {
        bool isBrutalized;
        for (uint256 t; t != 8; ++t) {
            while (true) {
                bool x = _randomChance(2);
                bool brutalized = _brutalized(x);
                /// @solidity memory-safe-assembly
                assembly {
                    isBrutalized := gt(brutalized, 0)
                }
                assertEq(brutalized, x);
                if (isBrutalized) break;
            }

            while (true) {
                address x = _randomNonZeroAddress();
                x = address(uint160(x) & (2 ** 160 - 1));
                address brutalized = _brutalized(x);
                /// @solidity memory-safe-assembly
                assembly {
                    isBrutalized := gt(shr(160, brutalized), 0)
                }
                assertEq(brutalized, x);
                if (isBrutalized) break;
            }

            while (true) {
                uint8 x = uint8(_random() & (2 ** 8 - 1));
                uint8 brutalized = _brutalizedUint8(x);
                /// @solidity memory-safe-assembly
                assembly {
                    isBrutalized := gt(shr(8, brutalized), 0)
                }
                assertEq(brutalized, x);
                if (isBrutalized) break;
            }

            while (true) {
                uint248 x = uint248(_random() & (2 ** 248 - 1));
                uint248 brutalized = _brutalizedUint248(x);
                /// @solidity memory-safe-assembly
                assembly {
                    isBrutalized := gt(shr(248, brutalized), 0)
                }
                assertEq(brutalized, x);
                if (isBrutalized) break;
            }

            while (true) {
                bytes1 x = bytes1(uint8(_random() & (2 ** 8 - 1)));
                bytes1 brutalized = _brutalizedBytes1(x);
                /// @solidity memory-safe-assembly
                assembly {
                    isBrutalized := gt(shl(8, brutalized), 0)
                }
                assertEq(brutalized, x);
                if (isBrutalized) break;
            }

            while (true) {
                bytes31 x = bytes31(uint248(_random() & (2 ** 248 - 1)));
                bytes31 brutalized = _brutalizedBytes31(x);
                /// @solidity memory-safe-assembly
                assembly {
                    isBrutalized := gt(shl(248, brutalized), 0)
                }
                assertEq(brutalized, x);
                if (isBrutalized) break;
            }
        }
    }
}
