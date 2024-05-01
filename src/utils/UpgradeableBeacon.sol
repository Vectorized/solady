// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Beacon contract for beacon proxies.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/UpgradeableBeacon.sol)
interface IUpgradeableBeacon {
    function implementation() external view returns (address);
    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
    function renounceOwnership() external;
    function upgradeTo(address newImplementation) external;
}

contract UpgradeableBeacon {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    uint256 internal constant _UPGRADEABLE_BEACON_OWNER_SLOT = 0x4343a0dc92ed22dbfc;
    uint256 internal constant _UPGRADEABLE_BEACON_IMPLEMENTATION_SLOT = 0x911c5a209f08d5ec5e;

    constructor() payable {
        _upgradeableBeaconConstructor();
    }

    /// @dev Called in the constructor.
    /// Override if you want to initialize the owner and implementation differently.
    function _upgradeableBeaconConstructor() internal virtual {
        _setOwner(msg.sender);
    }

    function _setOwner(address newOwner) internal virtual {}

    function _setImplementation(address newImplementation) internal virtual {}

    function _owner() internal view virtual returns (address result) {
        assembly {
            result := sload(_UPGRADEABLE_BEACON_OWNER_SLOT)
        }
    }

    function _implementation() internal view virtual returns (address result) {
        assembly {
            result := sload(_UPGRADEABLE_BEACON_IMPLEMENTATION_SLOT)
        }
    }

    function _calldataload(uint256 offset) internal pure returns (uint256 result) {
        assembly {
            result := calldataload(offset)
        }
    }

    function _fnSelectorEquals(uint256 s) private pure returns (bool result) {
        assembly {
            result := iszero(xor(shr(224, calldataload(returndatasize())), s))
        }
    }

    fallback() external payable virtual {
        if (_fnSelectorEquals(0x5c60da1b)) {}
    }
}
