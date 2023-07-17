// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibZip} from "../../../src/utils/LibZip.sol";

contract MockCd {
    error Hash(bytes32 h);

    bytes32 public dataHash;
    bytes32 public numbersHash;
    uint256 public lastCallvalue;
    address public lastCaller;

    function storeDataHash(bytes calldata data, bool success)
        external
        payable
        returns (bytes32 result)
    {
        result = keccak256(data);
        if (!success) {
            revert Hash(result);
        }
        dataHash = result;
        lastCallvalue = msg.value;
        lastCaller = msg.sender;
    }

    function storeNumbersHash(uint256[] calldata numbers, bool success)
        external
        payable
        returns (bytes32 result)
    {
        result = keccak256(abi.encode(numbers));
        if (!success) {
            revert Hash(result);
        }
        numbersHash = result;
        lastCallvalue = msg.value;
        lastCaller = msg.sender;
    }

    receive() external payable {
        LibZip.cdFallback();
    }

    fallback() external payable {
        LibZip.cdFallback();
    }
}

contract MockCdFallbackDecompressor {
    receive() external payable {
        _interceptCdFallback();
        LibZip.cdFallback();
    }

    fallback() external payable {
        _interceptCdFallback();
        LibZip.cdFallback();
    }

    function _interceptCdFallback() internal {
        assembly {
            if iszero(calldatasize()) {
                mstore(0x00, keccak256(0x00, 0x00))
                return(0x00, 0x20)
            }
            if sload(0) {
                calldatacopy(0x00, 0x00, calldatasize())
                mstore(0x00, keccak256(0x00, calldatasize()))
                return(0x00, 0x20)
            }
            sstore(0, 1)
        }
    }
}
