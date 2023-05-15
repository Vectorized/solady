// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibZip} from "../../../src/utils/LibZip.sol";

contract MockCd {
    error NumbersHash(bytes32 h);

    bytes32 public numbersHash;
    uint256 public lastCallvalue;

    function storeNumbersHash(uint256[] calldata numbers, bool success)
        external
        payable
        returns (bytes32 result)
    {
        result = keccak256(abi.encode(numbers));
        if (!success) {
            revert NumbersHash(result);
        }
        numbersHash = result;
        lastCallvalue = msg.value;
    }

    receive() external payable {
        LibZip.cdFallback();
    }

    fallback() external payable {
        LibZip.cdFallback();
    }
}
