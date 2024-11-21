// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC7821} from "../../../src/accounts/ERC7821.sol";
import {Brutalizer} from "../Brutalizer.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockERC7821 is ERC7821, Brutalizer {
    function _authorizeExecute(Call[] calldata calls, bytes calldata opData)
        internal
        virtual
        override
    {}

    function executeDirect(Call[] calldata calls)
        public
        payable
        virtual
        returns (bytes[] memory results)
    {
        _misalignFreeMemoryPointer();
        _brutalizeMemory();
        results = _execute(calls);
        _checkMemory();
    }
}
