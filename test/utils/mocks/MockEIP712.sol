// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../../src/utils/EIP712.sol";

contract MockEIP712 is EIP712 {
    function _domainNameHash() internal pure override returns (bytes32) {
        return keccak256("Milady");
    }

    function _domainVersionHash() internal pure override returns (bytes32) {
        return keccak256("1");
    }

    function hashTypedData(bytes32 structHash) external view returns (bytes32) {
        return _hashTypedData(structHash);
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparator();
    }
}
