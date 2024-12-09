// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC7821} from "../../../src/accounts/ERC7821.sol";
import {Brutalizer} from "../Brutalizer.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockERC7821 is ERC7821, Brutalizer {
    bytes public lastOpData;

    function _execute(bytes32, bytes calldata, Call[] calldata calls, bytes calldata opData)
        internal
        virtual
        override
    {
        lastOpData = opData;
        _execute(calls, bytes32(0));
    }

    function executeDirect(Call[] calldata calls) public payable virtual {
        _misalignFreeMemoryPointer();
        _brutalizeMemory();
        _execute(calls, bytes32(0));
        _checkMemory();
    }
}
