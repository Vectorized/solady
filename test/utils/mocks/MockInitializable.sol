// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Initializable} from "../../../src/utils/Initializable.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockInitializable is Initializable {
    uint256 public x;
    uint256 public y;

    struct Args {
        uint256 x;
        uint64 version;
        bool disableInitializers;
        bool initializeMulti;
        bool checkOnlyDuringInitializing;
        bool recurse;
    }

    constructor(Args memory a) {
        if (a.initializeMulti) {
            initialize(a);
            initialize(a);
        }
        if (a.disableInitializers) {
            _disableInitializers();
        }
    }

    function initialize(Args memory a) public initializer {
        x = a.x;
        if (a.checkOnlyDuringInitializing) {
            onlyDuringInitializing();
        }
        if (a.recurse) {
            a.recurse = false;
            if (a.x & 1 == 0) initialize(a);
            else reinitialize(a);
        }
    }

    function reinitialize(Args memory a) public reinitializer(a.version) {
        x = a.x;
        if (a.checkOnlyDuringInitializing) {
            onlyDuringInitializing();
        }
        if (a.recurse) {
            a.recurse = false;
            if (a.x & 1 == 0) initialize(a);
            else reinitialize(a);
        }
    }

    function getVersion() external view returns (uint64) {
        return _getInitializedVersion();
    }

    function isInitializing() external view returns (bool) {
        return _isInitializing();
    }

    function onlyDuringInitializing() public onlyInitializing {
        unchecked {
            ++y;
        }
    }

    function disableInitializers() public {
        _disableInitializers();
    }
}
