// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../../src/utils/EIP712.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockEIP712Dynamic is EIP712 {
    string private _name;
    string private _version;

    constructor(string memory name, string memory version) {
        _name = name;
        _version = version;
    }

    function setDomainNameAndVersion(string memory name, string memory version) public {
        _name = name;
        _version = version;
    }

    function _domainNameAndVersion()
        internal
        view
        override
        returns (string memory name, string memory version)
    {
        name = _name;
        version = _version;
    }

    function _domainNameAndVersionMayChange() internal pure override returns (bool) {
        return true;
    }

    function hashTypedData(bytes32 structHash) external view returns (bytes32) {
        return _hashTypedData(structHash);
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparator();
    }
}
