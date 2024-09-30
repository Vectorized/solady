// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library to encode and decode strings in URI format.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/URIEncode.sol)
/// @author Johnny Shankman aka White Lights - <johnny@white-lights.net>
library URI {
  /**
   * @dev URI Encoding/Decoding Hex Table
   */
  bytes internal constant TABLE = "0123456789ABCDEF";

  /**
   * @dev Encodes the provided string so that it can be safely used in a URI
   * just like encodeURIComponent in JavaScript.
   * See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent
   * See: https://datatracker.ietf.org/doc/html/rfc2396
   * See: https://datatracker.ietf.org/doc/html/rfc3986
   * @param str The string to encode
   * @return The URI encoded string
   */
  function encodeComponent(string memory str) public pure returns (string memory) {
      bytes memory input = bytes(str);
      uint256 inputLength = input.length;
      uint256 outputLength = 0;

      for (uint256 i = 0; i < inputLength; i++) {
          bytes1 b = input[i];

          if (
              (b >= 0x30 && b <= 0x39) || // 0-9
              (b >= 0x41 && b <= 0x5a) || // A-Z
              (b >= 0x61 && b <= 0x7a) || // a-z
              b == 0x2D || // -
              b == 0x2E || // .
              b == 0x21 || // !
              b == 0x7E || // ~
              b == 0x2A || // *
              b == 0x27 || // '
              b == 0x28 || // (
              b == 0x29    // )
          ) {
              outputLength++;
          } else {
              outputLength += 3;
          }
      }

      bytes memory output = new bytes(outputLength);
      uint256 j = 0;

      for (uint256 i = 0; i < inputLength; i++) {
          bytes1 b = input[i];

          if (
              (b >= 0x30 && b <= 0x39) || // 0-9
              (b >= 0x41 && b <= 0x5a) || // A-Z
              (b >= 0x61 && b <= 0x7a) || // a-z
              b == 0x2D || // -
              b == 0x2E || // .
              b == 0x21 || // !
              b == 0x7E || // ~
              b == 0x2A || // *
              b == 0x27 || // '
              b == 0x28 || // (
              b == 0x29    // )
          ) {
              output[j++] = b;
          } else {
              bytes1 b1 = TABLE[uint8(b) / 16];
              bytes1 b2 = TABLE[uint8(b) % 16];
              output[j++] = 0x25; // '%'
              output[j++] = b1;
              output[j++] = b2;
          }
      }

      return string(output);
  }

  /**
   * @dev Decodes the provided URI-encoded string just like decodeURIComponent
   *      in JavsScript. Strings which are incorrectly encoded cannot be parsed
   *      and will typically revert.
   * See: https://datatracker.ietf.org/doc/html/rfc2396
   * See: https://datatracker.ietf.org/doc/html/rfc3986
   * @param str The string to decode
   * @return The decoded string
   */
  function decodeComponent(string memory str) public pure returns (string memory) {
    string memory result = "";
    uint256 bytelength = bytes(str).length;

    for (uint256 i = 0; i < bytelength; i++) {
      bytes1 b = bytes(str)[i];
      // check if that character (as a byte1) is the "%" sign delimiter
      if (b == bytes1("%")) {
        // parse the two characters following the % delimiter
        uint8 byteU8_1 = uint8(bytes(str)[++i]);
        uint8 byteU8_2 = uint8(bytes(str)[++i]);

        // ensure they are characters 0-9 or A-F or a-f and therefore hexadecimal
        require(
          ((byteU8_1 >= 48 && byteU8_1 <= 57) ||
              (byteU8_1 >= 65 && byteU8_1 <= 70) ||
              (byteU8_1 >= 97 && byteU8_1 <= 102)),
          "invalid encoded string"
        );
        require(
          ((byteU8_2 >= 48 && byteU8_2 <= 57) ||
              (byteU8_2 >= 65 && byteU8_2 <= 70) ||
              (byteU8_2 >= 97 && byteU8_2 <= 102)),
          "invalid encoded string"
        );

        // convert the 1st char representing a hexadecimal to decimal
        uint8 hexCharAsDecimal;
        if (byteU8_1 >= 48 && byteU8_1 <= 57) {
          // 0-9
          hexCharAsDecimal = byteU8_1 - 48;
        } else if (byteU8_1 >= 65 && byteU8_1 <= 70) {
          // A-F
          hexCharAsDecimal = byteU8_1 - 55;
        } else {
          // a-f
          hexCharAsDecimal = byteU8_1 - 87;
        }

        // convert the 2nd char representing a hexadecimal to decimal
        uint8 hexCharAsDecimal2;
        if (byteU8_2 >= 48 && byteU8_2 <= 57) {
          // 0-9
          hexCharAsDecimal2 = byteU8_2 - 48;
        } else if (byteU8_2 >= 65 && byteU8_2 <= 70) {
          // A-F
          hexCharAsDecimal2 = byteU8_2 - 55;
        } else {
          // a-f
          hexCharAsDecimal2 = byteU8_2 - 87;
        }

        // 1st hex-char is a number words to move over
        // 2nd hex-char is byte offset from there
        // ex: %3E or %3e we move (3 * 16) + 14 bytes over
        result = string(
          abi.encodePacked(
            result,
            bytes1((hexCharAsDecimal * 16) + hexCharAsDecimal2)
          )
        );
      } else {
        result = string(
          abi.encodePacked(result, string(abi.encodePacked(b)))
        );
      }
    }

    return result;
  }
}
