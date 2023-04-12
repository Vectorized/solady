// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract InvariantTest {
    address[] private _targets;

    function targetContracts() public view virtual returns (address[] memory) {
        require(_targets.length > 0, "NO_TARGET_CONTRACTS");
        return _targets;
    }

    function _addTargetContract(address newTargetContract) internal virtual {
        _targets.push(newTargetContract);
    }
}
