// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../../src/utils/EIP712.sol";

contract MockEIP712 is EIP712 {
    function _domainNameAndVersion()
        internal
        pure
        override
        returns (string memory name, string memory version)
    {
        name = "Milady";
        version = "1";
    }

    function hashTypedData(bytes32 structHash) external view returns (bytes32) {
        return _hashTypedData(structHash);
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparator();
    }
}
