// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for converting numbers into strings and other string operations.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibString.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibString.sol)
library LibString {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CUSTOM ERRORS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The `length` of the output is too small to contain all the hex digits.
    error HexLengthInsufficient();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The constant returned when the `search` is not found in the string.
    uint256 internal constant NOT_FOUND = uint256(int256(-1));

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     DECIMAL OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the base 10 decimal representation of `value`.
    function toString(uint256 value) internal pure returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   HEXADECIMAL OPERATIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the hexadecimal representation of `value`,
    /// left-padded to an input length of `length` bytes.
    /// The output is prefixed with "0x" encoded using 2 hexadecimal digits per byte,
    /// giving a total length of `length * 2 + 2` bytes.
    /// Reverts if `length` is too small for the output to contain all the digits.
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory str) {
        assembly {
            let start := mload(0x40)
            // We need 0x20 bytes for the trailing zeros padding, `length * 2` bytes
            // for the digits, 0x02 bytes for the prefix, and 0x20 bytes for the length.
            // We add 0x20 to the total and round down to a multiple of 0x20.
            // (0x20 + 0x20 + 0x02 + 0x20) = 0x62.
            let m := add(start, and(add(shl(1, length), 0x62), not(0x1f)))
            // Allocate the memory.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end to calculate the length later.
            let end := str
            // Store "0123456789abcdef" in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            let temp := value
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for {} 1 {} {
                str := sub(str, 2)
                mstore8(add(str, 1), mload(and(temp, 15)))
                mstore8(str, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                length := sub(length, 1)
                // prettier-ignore
                if iszero(length) { break }
            }

            if temp {
                // Store the function selector of `HexLengthInsufficient()`.
                mstore(0x00, 0x2194895a)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Compute the string's length.
            let strLength := add(sub(end, str), 2)
            // Move the pointer and write the "0x" prefix.
            str := sub(str, 0x20)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, strLength)
        }
    }

    /// @dev Returns the hexadecimal representation of `value`.
    /// The output is prefixed with "0x" and encoded using 2 hexadecimal digits per byte.
    /// As address are 20 bytes long, the output will left-padded to have
    /// a length of `20 * 2 + 2` bytes.
    function toHexString(uint256 value) internal pure returns (string memory str) {
        assembly {
            let start := mload(0x40)
            // We need 0x20 bytes for the trailing zeros padding, 0x20 bytes for the length,
            // 0x02 bytes for the prefix, and 0x40 bytes for the digits.
            // The next multiple of 0x20 above (0x20 + 0x20 + 0x02 + 0x40) is 0xa0.
            let m := add(start, 0xa0)
            // Allocate the memory.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end to calculate the length later.
            let end := str
            // Store "0123456789abcdef" in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 2)
                mstore8(add(str, 1), mload(and(temp, 15)))
                mstore8(str, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute the string's length.
            let strLength := add(sub(end, str), 2)
            // Move the pointer and write the "0x" prefix.
            str := sub(str, 0x20)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, strLength)
        }
    }

    /// @dev Returns the hexadecimal representation of `value`.
    /// The output is prefixed with "0x" and encoded using 2 hexadecimal digits per byte.
    function toHexString(address value) internal pure returns (string memory str) {
        assembly {
            let start := mload(0x40)
            // We need 0x20 bytes for the length, 0x02 bytes for the prefix,
            // and 0x28 bytes for the digits.
            // The next multiple of 0x20 above (0x20 + 0x02 + 0x28) is 0x60.
            str := add(start, 0x60)

            // Allocate the memory.
            mstore(0x40, str)
            // Store "0123456789abcdef" in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            let length := 20
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 2)
                mstore8(add(str, 1), mload(and(temp, 15)))
                mstore8(str, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                length := sub(length, 1)
                // prettier-ignore
                if iszero(length) { break }
            }

            // Move the pointer and write the "0x" prefix.
            str := sub(str, 32)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, 42)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   OTHER STRING OPERATIONS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns `subject` all occurances of `search` replaced with `replacement`.
    function replace(
        string memory subject,
        string memory search,
        string memory replacement
    ) internal pure returns (string memory result) {
        assembly {
            let subjectLength := mload(subject)
            let searchLength := mload(search)
            let replacementLength := mload(replacement)

            subject := add(subject, 0x20)
            search := add(search, 0x20)
            replacement := add(replacement, 0x20)
            result := add(mload(0x40), 0x20)

            let subjectEnd := add(subject, subjectLength)
            if iszero(gt(searchLength, subjectLength)) {
                let subjectSearchEnd := add(sub(subjectEnd, searchLength), 1)
                let h := 0
                if iszero(lt(searchLength, 32)) {
                    h := keccak256(search, searchLength)
                }
                let m := shl(3, sub(32, and(searchLength, 31)))
                let s := mload(search)
                // prettier-ignore
                for {} 1 {} {
                    let t := mload(subject)
                    // Whether the first `searchLength % 32` bytes of 
                    // `subject` and `search` matches.
                    if iszero(shr(m, xor(t, s))) {
                        if h {
                            if iszero(eq(keccak256(subject, searchLength), h)) {
                                mstore(result, t)
                                result := add(result, 1)
                                subject := add(subject, 1)
                                // prettier-ignore
                                if iszero(lt(subject, subjectSearchEnd)) { break }
                                continue
                            }
                        }
                        // Copy the `replacement` one word at a time.
                        // prettier-ignore
                        for { let o := 0 } 1 {} {
                            mstore(add(result, o), mload(add(replacement, o)))
                            o := add(o, 0x20)
                            // prettier-ignore
                            if iszero(lt(o, replacementLength)) { break }
                        }
                        result := add(result, replacementLength)
                        subject := add(subject, searchLength)
                        if searchLength {
                            // prettier-ignore
                            if iszero(lt(subject, subjectSearchEnd)) { break }
                            continue
                        }
                    }
                    mstore(result, t)
                    result := add(result, 1)
                    subject := add(subject, 1)
                    // prettier-ignore
                    if iszero(lt(subject, subjectSearchEnd)) { break }
                }
            }

            let resultRemainder := result
            result := add(mload(0x40), 0x20)
            let k := add(sub(resultRemainder, result), sub(subjectEnd, subject))
            // Copy the rest of the string one word at a time.
            // prettier-ignore
            for {} lt(subject, subjectEnd) {} {
                mstore(resultRemainder, mload(subject))
                resultRemainder := add(resultRemainder, 0x20)
                subject := add(subject, 0x20)
            }
            // Zeroize the slot after the string.
            mstore(resultRemainder, 0)
            // Allocate memory for the length and the bytes,
            // rounded up to a multiple of 32.
            mstore(0x40, add(result, and(add(k, 63), not(31))))
            result := sub(result, 0x20)
            mstore(result, k)
        }
    }

    /// @dev Returns the index of the first location of `search` in `subject`,
    /// searching from left to right, starting from `from`.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function indexOf(
        string memory subject,
        string memory search,
        uint256 from
    ) internal pure returns (uint256 result) {
        assembly {
            // prettier-ignore
            for { let subjectLength := mload(subject) } 1 {} {
                if iszero(mload(search)) {
                    // `result = min(from, subjectLength)`.
                    result := xor(from, mul(xor(from, subjectLength), lt(subjectLength, from)))
                    break
                }
                let searchLength := mload(search)
                let subjectStart := add(subject, 0x20)    
                
                result := not(0) // Initialize to `NOT_FOUND`.

                subject := add(subjectStart, from)
                let subjectSearchEnd := add(sub(add(subjectStart, subjectLength), searchLength), 1)

                let m := shl(3, sub(32, and(searchLength, 31)))
                let s := mload(add(search, 0x20))

                // prettier-ignore
                if iszero(lt(subject, subjectSearchEnd)) { break }

                if iszero(lt(searchLength, 32)) {
                    // prettier-ignore
                    for { let h := keccak256(add(search, 0x20), searchLength) } 1 {} {
                        if iszero(shr(m, xor(mload(subject), s))) {
                            if eq(keccak256(subject, searchLength), h) {
                                result := sub(subject, subjectStart)
                                break
                            }
                        }
                        subject := add(subject, 1)
                        // prettier-ignore
                        if iszero(lt(subject, subjectSearchEnd)) { break }
                    }
                    break
                }
                // prettier-ignore
                for {} 1 {} {
                    if iszero(shr(m, xor(mload(subject), s))) {
                        result := sub(subject, subjectStart)
                        break
                    }
                    subject := add(subject, 1)
                    // prettier-ignore
                    if iszero(lt(subject, subjectSearchEnd)) { break }
                }
                break
            }
        }
    }

    /// @dev Returns the index of the first location of `search` in `subject`,
    /// searching from left to right.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function indexOf(string memory subject, string memory search) internal pure returns (uint256 result) {
        result = indexOf(subject, search, 0);
    }

    /// @dev Returns the index of the first location of `search` in `subject`,
    /// searching from right to left, starting from `from`.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function lastIndexOf(
        string memory subject,
        string memory search,
        uint256 from
    ) internal pure returns (uint256 result) {
        assembly {
            // prettier-ignore
            for {} 1 {} {
                let searchLength := mload(search)
                let fromMax := sub(mload(subject), searchLength)
                // `from = min(from, fromMax)`.
                from := xor(from, mul(xor(from, fromMax), lt(fromMax, from)))
                if iszero(mload(search)) {
                    result := from
                    break
                }
                result := not(0) // Initialize to `NOT_FOUND`.

                let subjectSearchEnd := sub(add(subject, 0x20), 1)

                subject := add(add(subject, 0x20), from)
                // prettier-ignore
                if iszero(gt(subject, subjectSearchEnd)) { break }
                // As this function is not too often used,
                // we shall simply use keccak256 for smaller bytecode size.
                // prettier-ignore
                for { let h := keccak256(add(search, 0x20), searchLength) } 1 {} {
                    if eq(keccak256(subject, searchLength), h) {
                        result := sub(subject, add(subjectSearchEnd, 1))
                        break
                    }
                    subject := sub(subject, 1)
                    // prettier-ignore
                    if iszero(gt(subject, subjectSearchEnd)) { break }
                }
                break
            }
        }
    }

    /// @dev Returns the index of the first location of `search` in `subject`,
    /// searching from right to left.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function lastIndexOf(string memory subject, string memory search) internal pure returns (uint256 result) {
        result = lastIndexOf(subject, search, uint256(int256(-1)));
    }

    /// @dev Returns whether `subject` starts with `search`.
    function startsWith(string memory subject, string memory search) internal pure returns (bool result) {
        assembly {
            let searchLength := mload(search)
            // Just using keccak256 directly is actually cheaper.
            result := and(
                iszero(gt(searchLength, mload(subject))),
                eq(keccak256(add(subject, 0x20), searchLength), keccak256(add(search, 0x20), searchLength))
            )
        }
    }

    /// @dev Returns whether `subject` ends with `search`.
    function endsWith(string memory subject, string memory search) internal pure returns (bool result) {
        assembly {
            let searchLength := mload(search)
            let subjectLength := mload(subject)
            // Whether `search` is not longer than `subject`.
            let withinRange := iszero(gt(searchLength, subjectLength))
            // Just using keccak256 directly is actually cheaper.
            result := and(
                withinRange,
                eq(
                    keccak256(
                        // `subject + 0x20 + max(subjectLength - searchLength, 0)`.
                        add(add(subject, 0x20), mul(withinRange, sub(subjectLength, searchLength))),
                        searchLength
                    ),
                    keccak256(add(search, 0x20), searchLength)
                )
            )
        }
    }

    /// @dev Returns `subject` repeated `times`.
    function repeat(string memory subject, uint256 times) internal pure returns (string memory result) {
        assembly {
            let subjectLength := mload(subject)
            if iszero(or(iszero(times), iszero(subjectLength))) {
                subject := add(subject, 0x20)
                result := mload(0x40)
                let output := add(result, 0x20)
                // prettier-ignore
                for {} 1 {} {
                    // Copy the `subject` one word at a time.
                    // prettier-ignore
                    for { let o := 0 } 1 {} {
                        mstore(add(output, o), mload(add(subject, o)))
                        o := add(o, 0x20)
                        // prettier-ignore
                        if iszero(lt(o, subjectLength)) { break }
                    }
                    output := add(output, subjectLength)
                    times := sub(times, 1)
                    // prettier-ignore
                    if iszero(times) { break }
                }
                // Zeroize the slot after the string.
                mstore(output, 0)
                // Store the length.
                let resultLength := sub(output, add(result, 0x20))
                mstore(result, resultLength)
                // Allocate memory for the length and the bytes,
                // rounded up to a multiple of 32.
                mstore(0x40, add(result, and(add(resultLength, 63), not(31))))
            }
        }
    }

    /// @dev Returns a copy of `subject` sliced from `start` to `end` (exclusive).
    function slice(
        string memory subject,
        uint256 start,
        uint256 end
    ) internal pure returns (string memory result) {
        assembly {
            let subjectLength := mload(subject)
            // `end = min(end, subjectLength)`.
            end := xor(end, mul(xor(end, subjectLength), lt(subjectLength, end)))
            // `start = min(start, subjectLength)`.
            start := xor(start, mul(xor(start, subjectLength), lt(subjectLength, start)))
            if lt(start, end) {
                result := mload(0x40)
                let resultLength := sub(end, start)
                mstore(result, resultLength)
                subject := add(subject, start)
                // Copy the `subject` one word at a time, backwards.
                // prettier-ignore
                for { let o := and(add(resultLength, 31), not(31)) } 1 {} {
                    mstore(add(result, o), mload(add(subject, o)))
                    o := sub(o, 0x20)
                    // prettier-ignore
                    if iszero(o) { break }
                }
                // Zeroize the slot after the string.
                mstore(add(add(result, 0x20), resultLength), 0)
                // Allocate memory for the length and the bytes,
                // rounded up to a multiple of 32.
                mstore(0x40, add(result, and(add(resultLength, 63), not(31))))
            }
        }
    }

    /// @dev Returns a copy of `subject` sliced from `start` to the end of the string.
    function slice(string memory subject, uint256 start) internal pure returns (string memory result) {
        result = slice(subject, start, uint256(int256(-1)));
    }

    /// @dev Returns a concated string of `subject` and `concat`.
    /// @dev This function is cheaper than string.concat() and doesn't desalign the free memory pointer.
    function concatenate(string memory subject, string memory concat) internal pure returns (string memory result) {
        assembly {
            //Load length.
            let subjectLength := mload(subject)
            let concatenateLength := mload(concat)
            //Load Free memory pointer.
            result := mload(0x40)
            let output := add(result, 0x20)
            //Calculates the result length.
            let totalLength := add(subjectLength, concatenateLength)
            //Moves pointer.
            subject := add(subject, 0x20)
            concat := add(concat, 0x20)
            //Loops one word at a time.
            for {
                let w := 0
            } 1 {

            } {
                //Stores 32 bytes
                mstore(add(output, w), mload(add(subject, w)))
                w := add(w, 0x20)
                if iszero(lt(w, subjectLength)) {
                    break
                }
            }

            output := add(output, subjectLength)
            //Loops one word at a time.
            for {
                let o := 0
            } 1 {

            } {
                //Stores 32 bytes at the result pointer + subjectLength.
                mstore(add(output, o), mload(add(concat, o)))
                o := add(o, 0x20)
                // prettier-ignore
                if iszero(lt(o, concatenateLength)) { break }
            }

            output := add(output, concatenateLength)
            // Zeroize the slot after the string.
            mstore(output, 0)
            //Stores result length.
            mstore(result, totalLength)
            // Allocate memory for the length and the bytes,
            // rounded up to a multiple of 32.
            mstore(0x40, add(result, and(add(totalLength, 63), not(31))))
        }
    }

    /// @dev Returns a string from on a array of `subjects` based on the `search` string.
    function join(string[] memory subjects, string memory search) internal pure returns (string memory result) {
        assembly {
            //Loads string from array and join string.
            let searchLength := mload(search)
            let arrLength := mload(subjects)
            //Builds the total string length to use later.
            let stringLength := 0
            //Set start of pointer for string.
            search := add(search, 0x20)
            //Loads free memory pointer.
            result := mload(0x40)
            let output := add(result, 0x20)
            //Loops all array members.
            for {
                let i := 1
            } lt(i, arrLength) {
                i := add(i, 1)
            } {
                //Set start of pointer for string inside the array by 0x20 each loop,
                //In a array of string the array it self stores the pointers for the location of the string inside of memory,
                //So here we just need to go 32 bits at a time.
                subjects := add(subjects, 0x20)
                //Load the actual string.
                let currentString := mload(subjects)
                //Gets the length of the string in the loop.
                let currentStringLength := mload(currentString)
                //Sets the pointer to the start of the string.
                currentString := add(currentString, 0x20)
                //Loops one word at a time to store it in the result.
                for {
                    let w := 0
                } 1 {

                } {
                    mstore(add(add(output, stringLength), w), mload(add(currentString, w)))
                    w := add(w, 0x20)
                    if iszero(lt(w, currentStringLength)) {
                        break
                    }
                }
                //Builds the total string length to use later.
                stringLength := add(currentStringLength, stringLength)
                //Loops one word at a time for the string to join.
                for {
                    let s := 0
                } 1 {

                } {
                    mstore(add(add(output, stringLength), s), mload(add(search, s)))
                    s := add(s, 0x20)
                    if iszero(lt(s, searchLength)) {
                        break
                    }
                }
                //Adds the length to the total.
                stringLength := add(searchLength, stringLength)
            }
            //Do this one more time but without the string to join so it doesn't get added at the end.
            subjects := add(subjects, 0x20)
            //Load the actual string.
            let currentString := mload(subjects)
            //Gets the length of the string in the loop.
            let currentStringLength := mload(currentString)
            //Sets the pointer to the start of the string.
            currentString := add(currentString, 0x20)
            //Loops one word at a time to store it in the result.
            for {
                let w := 0
            } 1 {

            } {
                mstore(add(add(output, stringLength), w), mload(add(currentString, w)))
                w := add(w, 0x20)
                if iszero(lt(w, currentStringLength)) {
                    break
                }
            }
            stringLength := add(currentStringLength, stringLength)
            // Zeroize the slot after the string.
            output := add(output, stringLength)
            mstore(output, 0)
            //Stores the total string length in the resulting string.
            mstore(result, stringLength)
            // Allocate memory for the length and the bytes,
            // rounded up to a multiple of 32.
            mstore(0x40, add(result, and(add(stringLength, 63), not(31))))
        }
    }

    /// @dev Returns a arrays of strings based on the `delim` inside of the `subject` string.
    function split(string memory subject, string memory delim) internal pure returns (string[] memory result) {
        //Concatenates both subject and delim same as string.concat(subject, delim).
        string memory val = concatenate(subject, delim);
        assembly {
            let delimLength := mload(delim)
            let length := mload(val)
            //Create new pointer for substrings.
            let ptr := add(mload(0x40), 0x20)
            //Copies pointer to the stack so it can be used to calculate the pointer location of the strings.
            let copyPtr := ptr
            //Sets helper counter used to calculate string length and array length.
            //Counter for array length.
            let counter := 0
            //Counter for string length.
            let lengthCounter := 0
            //Grabs hex value of the `delim`.
            let pattern := shl(3, sub(32, and(delimLength, 31)))
            //Moves pointer to start of the string value.
            val := add(val, 0x20)
            delim := add(delim, 0x20)
            //Checks if the `delim` is bigger than 32 bits.
            let hash := 0
            if iszero(lt(delimLength, 32)) {
                hash := keccak256(delim, delimLength)
            }
            //If the `delim` is a empty string return the `subject` string as a array.
            if iszero(delimLength) {
                //Loops one word at a time.
                for {
                    let w := 0
                } 1 {

                } {
                    mstore(add(add(ptr, 0x20), w), mload(add(val, w)))
                    w := add(w, 0x20)
                    if iszero(lt(w, length)) {
                        break
                    }
                }
                //Stores length and allocates memory for length and bytes.
                mstore(ptr, length)
                ptr := add(ptr, and(add(length, 0x40), not(0x1f)))
                //Set the `result` to the pointer location
                result := ptr
                //It will always be one.
                mstore(result, 1)
                //Stores the initial pointer location on the `result` array.
                mstore(add(result, 0x20), copyPtr)
                // Allocate memory for the length and the bytes.
                mstore(0x40, add(add(result, 0x20), 0x20))
            }

            if delimLength {
                //Loops one char at a time.
                for {
                    let i := 0
                } or(eq(i, length), lt(i, length)) {

                } {
                    //Moves pointer by i value.
                    let start := add(val, i)
                    //If the hash is not 0 then we perform the string calcs from here.
                    if hash {
                        if iszero(eq(keccak256(start, delimLength), hash)) {
                            mstore(add(ptr, add(0x20, lengthCounter)), mload(start))
                            //Adds one to the word length.
                            lengthCounter := add(lengthCounter, 1)
                            //Skips to next char.
                            i := add(i, 1)
                            continue
                        }

                        if eq(keccak256(start, delimLength), hash) {
                            if iszero(eq(lengthCounter, 0)) {
                                //Stores 0s based on the pointer location with the length counter added so we can clean the bits that we don't care about.
                                mstore(add(ptr, add(0x20, lengthCounter)), 0)
                                //Stores length at the ptr current location.
                                mstore(ptr, lengthCounter)
                            }
                            //Calculates the new pointer to store the new word.
                            ptr := add(ptr, and(add(lengthCounter, 0x40), not(0x1f)))
                            //Reset the str length.
                            lengthCounter := 0
                            // counter++.
                            counter := add(counter, 1)
                            //skips the delim word in subject.
                            i := add(i, delimLength)
                            continue
                        }
                    }
                    //Grabs chars based on pattern.
                    let compare := shr(pattern, xor(mload(start), mload(delim)))
                    //If compare != 0 then store it to pointer current location.
                    if iszero(eq(compare, 0)) {
                        //Store the whole in the pointer at the current location.
                        mstore(add(ptr, add(0x20, lengthCounter)), mload(start))
                        //Adds one to word length.
                        lengthCounter := add(lengthCounter, 1)
                        //Skips to next char.
                        i := add(i, 1)
                        continue
                    }
                    //If compare == 0 the check if the length is not empty.
                    if iszero(compare) {
                        //if length != 0.
                        if iszero(eq(lengthCounter, 0)) {
                            //Stores 0s based on the pointer location with the length counter added so we can clean the bits that we don't care about.
                            mstore(add(ptr, add(0x20, lengthCounter)), 0)
                            //Stores length at the ptr current location.
                            mstore(ptr, lengthCounter)
                        }
                        //Calculates the new pointer to store the new word.
                        ptr := add(ptr, and(add(lengthCounter, 0x40), not(0x1f)))
                        //Reset the str length.
                        lengthCounter := 0
                        // counter++.
                        counter := add(counter, 1)
                        //skips the delim word in subject.
                        i := add(i, delimLength)
                    }
                }
                result := ptr
                //Stores the array length.
                mstore(result, counter)
                // Allocate memory for the length and the bytes of all strings.
                mstore(0x40, add(add(result, 0x20), mul(0x20, counter)))
                //Loop to fill the result array with the pointer location for the strings.
                for {
                    let i := 0
                } lt(i, counter) {
                    i := add(i, 1)
                } {
                    let lenPointer := mload(copyPtr)
                    //Calculates the pointer with the string location.
                    mstore(add(result, add(0x20, mul(0x20, i))), copyPtr)
                    //Calculates the pointer with the string location based on the len stored at the first pointer location.
                    copyPtr := add(copyPtr, and(add(lenPointer, 0x40), not(0x1f)))
                }
            }
        }
    }
}
