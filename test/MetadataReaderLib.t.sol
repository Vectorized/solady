// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {MetadataReaderLib} from "../src/utils/MetadataReaderLib.sol";

contract MetadataReaderLibTest is SoladyTest {
    string internal _stringToReturn;
    
    uint256 internal _randomness;

    function returnsString() public view returns (string memory) {
        uint256 r = _randomness;
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
            mstore(add(mload(s), add(s, 0x20)), 0)
            return(add(s, 0x20), add(mload(s), byte(2, r)))        
        }
    }

    function returnsEmptyString() public view returns (string memory) {
        uint256 r = _randomness;
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
            mstore(0x00, 0)
            mstore(0x20, 0)
            return(0x00, and(63, byte(2, r)))
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

    function testReadString(uint256 r) public {
        string memory s = _generateString("ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        _stringToReturn = s;
        _randomness = r;
        bytes memory data = abi.encodeWithSignature("returnsString()");
        string memory result = MetadataReaderLib.readString(address(this), data);
        _checkMemory(result);
        assertEq(result, s);
        result = MetadataReaderLib.readName(address(this));
        _checkMemory(result);
        assertEq(result, s);
        result = MetadataReaderLib.readSymbol(address(this));
        _checkMemory(result);
        assertEq(result, s);
    }

    function testReadEmptyString(uint256 r) public {
        string memory s = _generateString("ABCDEFGHIJKLMNOPQRSTUVWXYZ");
        _stringToReturn = s;
        _randomness = r;
        bytes memory data = abi.encodeWithSignature("returnsEmptyString()");
        string memory result = MetadataReaderLib.readString(address(this), data);
        _checkMemory(result);
        assertEq(result, "");
    }

    function testReadUint(uint256 r) public {
        _randomness = r;
        bytes memory data = abi.encodeWithSignature("returnsUint()");
        assertEq(MetadataReaderLib.readUint(address(this), data), r);
        assertEq(MetadataReaderLib.readDecimals(address(this)), uint8(r));
    }

    function _generateString(string memory byteChoices) internal returns (string memory result) {
        uint256 randomness = _random();
        uint256 resultLength = _randomStringLength();
        /// @solidity memory-safe-assembly
        assembly {
            if mload(byteChoices) {
                result := mload(0x40)
                mstore(0x00, randomness)
                mstore(0x40, and(add(add(result, 0x40), resultLength), not(31)))
                mstore(result, resultLength)

                // forgefmt: disable-next-item
                for { let i := 0 } lt(i, resultLength) { i := add(i, 1) } {
                    mstore(0x20, gas())
                    mstore8(
                        add(add(result, 0x20), i), 
                        mload(add(add(byteChoices, 1), mod(keccak256(0x00, 0x40), mload(byteChoices))))
                    )
                }
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
