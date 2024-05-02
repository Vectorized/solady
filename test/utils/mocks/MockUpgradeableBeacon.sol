// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../../src/utils/UpgradeableBeacon.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockUpgradeableBeacon is UpgradeableBeacon {
    constructor(address initialOwner, address initialImplementation) {
        _initializeUpgradeableBeacon(initialOwner, initialImplementation);
    }
}
