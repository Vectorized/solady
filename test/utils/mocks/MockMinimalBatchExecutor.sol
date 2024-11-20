// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {MinimalBatchExecutor} from "../../../src/accounts/MinimalBatchExecutor.sol";
import {Brutalizer} from "../Brutalizer.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockMinimalBatchExecutor is MinimalBatchExecutor, Brutalizer {
    function _authorizeExecute(Call[] calldata calls, bytes calldata authData)
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
