// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Pausable} from "../../../src/utils/Pausable.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockPausable is Pausable {
    bool public drasticMeasureTaken;
    uint256 public count;

    constructor() {
        drasticMeasureTaken = false;
    }

    function normalProcess() external whenNotPaused {
        count++;
    }

    function drasticMeasure() external whenPaused {
        drasticMeasureTaken = true;
    }

    function pause() external {
        _pause();
    }

    function unpause() external {
        _unpause();
    }
}

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract PausableMockBytecodeSizer is Pausable {}
