// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for various array operations.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibVector.sol)
library LibArray {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     ARRAY OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the sum of an array with unsigned elements.
    function unsignedSum(uint256[] memory arr) internal pure returns (uint256 sum) {
        assembly {
            // arr length (first 32 bytes).
            let len := mload(arr)

            // first element is 32 bytes after len.
            let el := add(arr, 0x20)

            // last element is `el` + `len` * 32 bytes.
            for { let end := add(el, mul(len, 0x20)) } lt(el, end) { el := add(el, 0x20) } {
                // load element into mem and add it to `sum`
                sum := add(sum, mload(el))
            }
        }
    }

    /// @dev Returns the max element of an array with unsigned elements.
    function unsignedMax(uint256[] memory arr) internal pure returns (uint256 max) {
        assembly {
            // arr length (first 32 bytes).
            let len := mload(arr)

            // first element is 32 bytes after len.
            let el := add(arr, 0x20)

            // set first element as current max
            max := mload(el)

            // last element is `el` + `len` * 32 bytes.
            for { let end := add(el, mul(len, 0x20)) } lt(el, end) { el := add(el, 0x20) } {
                // load next element in array
                let ele := mload(el)

                // `max` ^ ((`max` ^ `el`) & -(`max` > `el`)).
                max := xor(max, and(xor(ele, max), sub(gt(max, ele), 1)))
            }
        }
    }

    /// @dev Returns the min element of an array with unsigned elements.
    function unsignedMin(uint256[] memory arr) internal pure returns (uint256 min) {
        assembly {
            // arr length (first 32 bytes).
            let len := mload(arr)

            // first element is 32 bytes after len.
            let el := add(arr, 0x20)

            // set first element as current min
            min := mload(el)

            // last element is `el` + `len` * 32 bytes.
            for { let end := add(el, mul(len, 0x20)) } lt(el, end) { el := add(el, 0x20) } {
                // load next element in array
                let ele := mload(el)

                // `min` ^ ((`min` ^ `el`) & -(`min` < `el`)).
                min := xor(min, and(xor(ele, min), sub(lt(min, ele), 1)))
            }
        }
    }
}
