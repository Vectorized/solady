// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Ownable} from "../../../src/auth/Ownable.sol";
import {Lifebouy} from "../../../src/auth/Lifebouy.sol";
// import {Brutalizer} from "../Brutalizer.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockLifebouy is Lifebouy {
    constructor() payable {}

    function payMe() external payable {}
}

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockLifebouyOwned is MockLifebouy, Ownable {
    constructor(address owner_) payable {
        _initializeOwner(owner_);
    }
}

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockLifebouyDeployerFallback {
    address public mock;

    constructor() payable {
        mock = address(new MockLifebouy{value: msg.value}());
    }

    fallback() external payable {}

    receive() external payable {}
}

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockLifebouyDeployerNoFallback {
    address public mock;

    constructor() {}

    function deployMock() external payable {
        mock = address(new MockLifebouy{value: msg.value}());
    }
}
