// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../../src/utils/EIP712.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
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

    function hashTypedDataSansChainId(bytes32 structHash) external view returns (bytes32) {
        return _hashTypedDataSansChainId(structHash);
    }

    function hashTypedDataSansChainIdAndVerifyingContract(bytes32 structHash)
        external
        view
        returns (bytes32)
    {
        return _hashTypedDataSansChainIdAndVerifyingContract(structHash);
    }

    function hashTypedDataSansVerifyingContract(bytes32 structHash)
        external
        view
        returns (bytes32)
    {
        return _hashTypedDataSansVerifyingContract(structHash);
    }
}
