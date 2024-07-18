// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {MetadataReaderLib} from "../src/utils/MetadataReaderLib.sol";
import {LibString} from "../src/utils/LibString.sol";

contract MetadataReaderLibTest is SoladyTest {
    string internal _stringToReturn;

    uint256 internal _randomness;

    function returnsString() public view returns (string memory) {
        uint256 r = _randomness;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x40, add(0x100, mload(0x40)))
            mstore(0x00, r)
        }
        string memory s = _stringToReturn;
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(and(r, 1)) {
                if iszero(and(r, 2)) {
                    mstore(sub(s, 0x40), 0x40)
                    return(sub(s, 0x40), add(0x60, add(mload(s), byte(2, r))))
                }
                mstore(sub(s, 0x20), 0x20)
                return(sub(s, 0x20), add(0x40, add(mload(s), byte(2, r))))
            }
            mstore(0x00, gas())
            mstore(0x20, r)
            mstore(add(mload(s), add(s, 0x20)), shr(8, keccak256(0x00, 0x40)))
            return(add(s, 0x20), add(mload(s), byte(2, r)))
        }
    }

    function returnsEmptyString() public view returns (string memory) {
        uint256 r = _randomness;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x40, add(0x100, mload(0x40)))
            mstore(0x00, r)
        }
        string memory s = _stringToReturn;
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(and(r, 1)) {
                if iszero(and(r, 2)) {
                    mstore(sub(s, 0x40), 0x41)
                    return(sub(s, 0x40), add(0x60, mload(s)))
                }
                mstore(sub(s, 0x20), 0x21)
                return(sub(s, 0x20), add(0x40, mload(s)))
            }
            if iszero(and(r, 2)) {
                let n := mload(s)
                mstore(s, add(n, 1))
                if iszero(and(r, 2)) {
                    mstore(sub(s, 0x40), 0x40)
                    return(sub(s, 0x40), add(0x60, n))
                }
                mstore(sub(s, 0x20), 0x20)
                return(sub(s, 0x20), add(0x40, n))
            }
            let m := mload(0x40)
            codecopy(m, codesize(), 0x200)
            mstore(m, and(63, byte(3, r)))
            return(m, and(63, byte(2, r)))
        }
    }

    function returnsChoppedString(uint256 chop) public pure returns (string memory) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(add(m, 0x00), 0x20)
            mstore(add(m, 0x20), 0x20)
            mstore(add(m, 0x40), "112233445566778899aa112233445566")
            return(add(m, 0x00), add(0x40, chop))
        }
    }

    function returnsBytes32StringA() public pure returns (bytes32) {
        return bytes32(hex"4d696c616479");
    }

    function returnsBytes32StringB() public pure returns (bytes32) {
        return bytes32("This string has thirty two bytes");
    }

    function returnsNothing() public pure {}

    function reverts() public pure {
        revert("Lorem Ipsum");
    }

    function returnsChoppedUint(uint256 v, uint256 chop) public pure returns (uint256) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, v)
            return(0x00, chop)
        }
    }

    function name() public view returns (string memory) {
        return returnsString();
    }

    function symbol() public view returns (string memory) {
        return returnsString();
    }

    function returnsUint() public view returns (uint256) {
        return _randomness;
    }

    function decimals() public view returns (uint8) {
        return uint8(_randomness);
    }

    function testReadBytes32String() public brutalizeMemory {
        string memory result;
        result = _readString(abi.encodeWithSignature("returnsBytes32StringA()"));
        _checkMemory(result);
        assertEq(result, "Milady");
        result = _readString(abi.encodeWithSignature("returnsBytes32StringB()"));
        _checkMemory(result);
        assertEq(result, "This string has thirty two bytes");
        result = _readString(abi.encodeWithSignature("returnsNothing()"));
        _checkMemory(result);
        assertEq(result, "");
        result = _readString(abi.encodeWithSignature("reverts()"));
        _checkMemory(result);
        assertEq(result, "");
    }

    function testReadBytes32StringTruncated() public brutalizeMemory {
        bytes memory data;
        string memory result;
        unchecked {
            data = abi.encodeWithSignature("returnsBytes32StringB()");
            for (uint256 limit; limit < 39; ++limit) {
                result = _readString(data, limit);
                _checkMemory(result);
                assertEq(result, LibString.slice("This string has thirty two bytes", 0, limit));
            }
        }
    }

    function testReadStringChopped() public {
        bytes memory data;
        string memory result;
        data = abi.encodeWithSignature("returnsChoppedString(uint256)", uint256(32));
        result = _readString(data);
        _checkMemory(result);
        assertEq(result, "112233445566778899aa112233445566");

        for (uint256 limit; limit < 39; limit += 5) {
            for (uint256 chop; chop < 39; chop += 3) {
                data = abi.encodeWithSignature("returnsChoppedString(uint256)", uint256(chop));
                result = _readString(data, limit);
                _checkMemory(result);
                // As long as the returndatasize is insufficient, the `abi.decode` will fail,
                // and the resultant string will be empty.
                // Even if the `limit` is smaller than `chop`.
                string memory expected;
                if (chop >= 32) {
                    expected = LibString.slice("112233445566778899aa112233445566", 0, limit);
                }
                assertEq(result, expected);
            }
        }
    }

    function _readString(bytes memory data, uint256 limit) internal returns (string memory) {
        uint256 r = _random() % 2;
        if (r == 0) return MetadataReaderLib.readString(address(this), data, limit, gasleft());
        return MetadataReaderLib.readString(address(this), data, limit);
    }

    function _readString(bytes memory data) internal returns (string memory) {
        uint256 r = _random() % 3;
        if (r == 0) {
            return MetadataReaderLib.readString(address(this), data, type(uint256).max, gasleft());
        }
        if (r == 1) return MetadataReaderLib.readString(address(this), data, type(uint256).max);
        return MetadataReaderLib.readString(address(this), data);
    }

    function _readSymbol() internal returns (string memory) {
        uint256 r = _random() % 3;
        if (r == 0) {
            return MetadataReaderLib.readSymbol(address(this), type(uint256).max, gasleft());
        }
        if (r == 1) return MetadataReaderLib.readSymbol(address(this), type(uint256).max);
        return MetadataReaderLib.readSymbol(address(this));
    }

    function _readName() internal returns (string memory) {
        uint256 r = _random() % 3;
        if (r == 0) return MetadataReaderLib.readName(address(this), type(uint256).max, gasleft());
        if (r == 1) return MetadataReaderLib.readName(address(this), type(uint256).max);
        return MetadataReaderLib.readName(address(this));
    }

    function _readUint(bytes memory data) internal returns (uint256) {
        uint256 r = _random() % 2;
        if (r == 0) return MetadataReaderLib.readUint(address(this), data, gasleft());
        return MetadataReaderLib.readUint(address(this), data);
    }

    function _readDecimals() internal returns (uint256) {
        uint256 r = _random() % 2;
        if (r == 0) return MetadataReaderLib.readDecimals(address(this), gasleft());
        return MetadataReaderLib.readDecimals(address(this));
    }

    function testReadString(uint256 r) public brutalizeMemory {
        string memory result;
        string memory s = _generateString();
        _stringToReturn = s;
        _randomness = r;
        result = _readString(abi.encodeWithSignature("returnsString()"));
        _checkMemory(result);
        assertEq(result, s);
        result = _readName();
        _checkMemory(result);
        assertEq(result, s);
        result = _readSymbol();
        _checkMemory(result);
        assertEq(result, s);
        result = _readString(abi.encodeWithSignature("returnsEmptyString()"));
        _checkMemory(result);
        assertEq(result, "");
        result = _readString(abi.encodeWithSignature("reverts()"));
        _checkMemory(result);
        assertEq(result, "");
        result = _readString(abi.encodeWithSignature("returnsNothing()"));
        _checkMemory(result);
        assertEq(result, "");
    }

    function testReadStringTruncated(uint256 r) public brutalizeMemory {
        bytes memory data;
        string memory result;
        string memory s = _generateString();
        _stringToReturn = s;
        _randomness = r;
        unchecked {
            uint256 limit = _bound(_random(), 0, bytes(s).length * 2);
            data = abi.encodeWithSignature("returnsString()");
            result = MetadataReaderLib.readString(address(this), data, limit);
            _checkMemory(result);
            assertEq(result, LibString.slice(s, 0, limit));
        }
    }

    function testReadUint(uint256 r) public {
        _randomness = r;
        bytes memory data = abi.encodeWithSignature("returnsUint()");
        assertEq(_readUint(data), r);
        assertEq(_readDecimals(), uint8(r));
    }

    function testReadUint() public {
        bytes memory data;
        uint256 result;
        data = abi.encodeWithSignature("returnsNothing()");
        result = _readUint(data);
        assertEq(result, 0);
        data = abi.encodeWithSignature("reverts()");
        result = _readUint(data);
        assertEq(result, 0);

        for (uint256 j; j != 8; ++j) {
            for (uint256 i; i != 70; ++i) {
                uint256 k = _hash(i, j);
                data = abi.encodeWithSignature("returnsChoppedUint(uint256,uint256)", k, i);
                result = _readUint(data);
                assertEq(result, i < 32 ? 0 : k);
            }
        }
    }

    function testBoundsCheckDifferential(uint256) public {
        uint256 rds = _bound(_random(), 0, 128);
        uint256 l = _randomChance(2) ? type(uint248).max : 128;
        uint256 o = _bound(_random(), 0, l);
        uint256 n = _bound(_random(), 0, l);
        bool result;
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(lt(rds, 0x40)) {
                if iszero(gt(o, sub(rds, 0x20))) {
                    if iszero(gt(n, sub(rds, add(o, 0x20)))) { result := 1 }
                }
            }
        }
        bool expected = rds >= 0x40 && !(o + 0x20 > rds) && !(n + o + 0x20 > rds);
        assertEq(result, expected);
    }

    function _hash(uint256 i, uint256 j) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, i)
            mstore(0x20, j)
            result := keccak256(0x00, 0x20)
        }
    }

    function _generateString() internal returns (string memory result) {
        uint256 randomness = _random();
        uint256 resultLength = _randomStringLength();
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(0x00, randomness)
            mstore(0x40, and(add(add(result, 0x40), resultLength), not(31)))
            mstore(result, resultLength)

            // forgefmt: disable-next-item
            for { let i := 0 } lt(i, resultLength) { i := add(i, 1) } {
                mstore(0x20, gas())
                let c := byte(0, keccak256(0x00, 0x40))
                mstore8(add(add(result, 0x20), i), or(c, iszero(c)))
            }
        }
    }

    function _randomStringLength() internal returns (uint256 r) {
        r = _random() % 256;
        if (r < 64) return _random() % 128;
        if (r < 128) return _random() % 64;
        return _random() % 16;
    }
}
