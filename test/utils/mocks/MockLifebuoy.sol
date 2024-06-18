// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Ownable} from "../../../src/auth/Ownable.sol";
import {Lifebuoy} from "../../../src/utils/Lifebuoy.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockLifebuoy is Lifebuoy {
    constructor() payable {}

    function payMe() external payable {}
}

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockLifebuoyOwned is MockLifebuoy, Ownable {
    constructor(address owner_) payable {
        _initializeOwner(owner_);
    }

    function initializeOwner(address owner_) external {
        _initializeOwner(owner_);
    }
}
