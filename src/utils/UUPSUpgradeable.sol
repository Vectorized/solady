// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice An upgradeability mechanism designed for UUPS pattern.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/UUPSUpgradeable.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/utils/UUPSUpgradeable.sol)
abstract contract UUPSUpgradeable {
    /// @dev The upgrade failed.
    error UpgradeFailed();

    /// @dev The ERC-1967 storage slot for the implementation in the proxy.
    /// `uint256(keccak256("eip1967.proxy.implementation")) - 1`.
    bytes32 internal constant ERC1967_IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @dev Function must be authorized msg.sender for upgrade contract.
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /// @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the implementation.
    function proxiableUUID() external pure returns (bytes32) {
        return ERC1967_IMPLEMENTATION_SLOT;
    }

    /// @dev Upgrades the implementation of th proxy to `newImplementation`.
    /// Then, delegate calls to newImplementation with abi encoded `data`.
    /// The caller of this function must be `_authorizeUpgrade`.
    function upgradeToAndCall(address newImplementation, bytes calldata data)
        external
        payable
        virtual
    {
        _authorizeUpgrade(newImplementation);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x52d1902d) // bytes4(keccak256("proxiableUUID()"))

            if iszero(
                eq(
                    mload(staticcall(gas(), newImplementation, 0x1c, 0x04, 0x01, 0x20)),
                    ERC1967_IMPLEMENTATION_SLOT
                )
            ) {
                mstore(0x00, 0x55299b49) // error selector of UpgradeFailed()
                revert(0x1c, 0x04)
            }

            sstore(ERC1967_IMPLEMENTATION_SLOT, newImplementation)

            let len := data.length

            if len {
                calldatacopy(0x00, data.offset, len)
                if iszero(delegatecall(gas(), newImplementation, 0x00, len, codesize(), 0x00)) {
                    returndatacopy(0x00, 0x00, returndatasize())
                    revert(0x00, returndatasize())
                }

                returndatacopy(0x00, 0x00, returndatasize())
                return(0x00, returndatasize())
            }
        }
    }

    /// @dev Upgrades the implementation of th proxy to `newImplementation`.
    /// The caller of this function must be `_authorizeUpgrade`.
    function _upgradeTo(address newImplementation) internal virtual{
        _authorizeUpgrade(newImplementation);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x52d1902d) // bytes4(keccak256("proxiableUUID()"))
            if iszero(
                eq(
                    mload(staticcall(gas(), newImplementation, 0x1c, 0x04, 0x01, 0x20)),
                    ERC1967_IMPLEMENTATION_SLOT
                )
            ) {
                mstore(0x00, 0x55299b49) // error selector of UpgradeFailed()
                revert(0x1c, 0x04)
            }

            sstore(ERC1967_IMPLEMENTATION_SLOT, newImplementation)
        }
    }
}
