// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "../../../src/utils/Multicallable.sol";

contract MockMulticallable is Multicallable {
    function functionThatRevertsWithError(string memory error) external pure {
        revert(error);
    }

    struct Tuple {
        uint256 a;
        uint256 b;
    }

    function functionThatReturnsTuple(uint256 a, uint256 b) external pure returns (Tuple memory tuple) {
        tuple = Tuple({a: a, b: b});
    }

    function functionThatReturnsString(string calldata s) external pure returns (string memory) {
        return s;
    }

    uint256 public paid;

    function pays() external payable {
        paid += msg.value;
    }

    function returnSender() external view returns (address) {
        return msg.sender;
    }
}
