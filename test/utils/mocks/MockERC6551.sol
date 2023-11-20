// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC6551} from "../../../src/accounts/ERC6551.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockERC6551 is ERC6551 {
    function _brutalized(address a) private pure returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := or(a, shl(160, 0x0123456789abcdeffedcba98))
        }
    }

    function executeBatch(uint256 filler, Call[] calldata calls, uint8 operation)
        public
        payable
        virtual
        returns (bytes[] memory results)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x40, add(mload(0x40), mod(filler, 0x40)))
        }
        return super.executeBatch(calls, operation);
    }

    function _domainNameAndVersion()
        internal
        pure
        override
        returns (string memory, string memory)
    {
        return ("Milady", "1");
    }

    function hashTypedData(bytes32 structHash) external view returns (bytes32) {
        return _hashTypedData(structHash);
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparator();
    }

    function mockId() public pure virtual returns (string memory) {
        return "1";
    }
}

contract MockERC6551V2 is MockERC6551 {
    function mockId() public pure virtual override(MockERC6551) returns (string memory) {
        return "2";
    }
}
