// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC7821} from "../../../src/accounts/ERC7821.sol";
import {Brutalizer} from "../Brutalizer.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockERC7821 is ERC7821, Brutalizer {
    bytes public lastOpData;

    mapping(address => bool) public isAuthorizedCaller;

    error Unauthorized();

    function _execute(bytes32, bytes calldata, Call[] calldata calls, bytes calldata opData)
        internal
        virtual
        override
    {
        lastOpData = opData;
        _execute(calls, bytes32(0));
    }

    function execute(bytes32 mode, bytes calldata executionData) public payable virtual override {
        if (!isAuthorizedCaller[msg.sender]) revert Unauthorized();
        super.execute(mode, executionData);
    }

    function executeDirect(Call[] calldata calls) public payable virtual {
        _misalignFreeMemoryPointer();
        _brutalizeMemory();
        _execute(calls, bytes32(0));
        _checkMemory();
    }

    function setAuthorizedCaller(address target, bool status) public {
        isAuthorizedCaller[target] = status;
    }
}
