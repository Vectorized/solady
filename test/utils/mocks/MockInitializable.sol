// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Initializable} from "../../../src/utils/Initializable.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockInitializableParent is Initializable {
    uint256 public x;

    event Yo();

    function _initialize(uint256 x_) internal onlyInitializing {
        x = x_;
        if (x_ & 8 == 0) onlyDuringInitializing();
    }

    function getVersion() external view returns (uint64) {
        return _getInitializedVersion();
    }

    function isInitializing() external view returns (bool) {
        return _isInitializing();
    }

    function onlyDuringInitializing() public onlyInitializing {
        emit Yo();
    }
}

contract MockInitializable is MockInitializableParent {
    function init(uint256 x_) public initializer {
        _initialize(x_);
    }

    function reinit(uint256 x_, uint64 version) public reinitializer(version) {
        _initialize(x_);
    }
}

contract MockInitializableRevert is MockInitializableParent {
    function init1(uint256 x_, uint64 version) public initializer {
        _initialize(x_);
        reinit(version);
    }

    function reinit(uint64 version) public reinitializer(version) {}
}

contract MockInitializableDisabled is MockInitializableParent {
    constructor() {
        _disableInitializers();
    }

    function init(uint256 x_) public initializer {
        _initialize(x_);
    }
}

contract MockInitializableRevert2 is MockInitializableParent {
    function init(uint256 x_) public {
        _initialize(x_);
    }
}
