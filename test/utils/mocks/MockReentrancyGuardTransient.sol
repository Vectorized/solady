// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ReentrancyGuardTransient} from "../../../src/utils/ReentrancyGuardTransient.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockReentrancyGuardTransient is ReentrancyGuardTransient {
    /// @dev SEE: `ReentrancyGuardTransient`.
    uint256 public constant _REENTRANCY_GUARD_SLOT = 0x929eee149b4bd21268;

    uint256 public enterTimes;

    bool public transientOnlyOnMainnet;

    // Mocks

    function isReentrancyGuardLocked() public view returns (bool locked) {
        /// @solidity memory-safe-assembly
        assembly {
            if tload(_REENTRANCY_GUARD_SLOT) { locked := true }
        }
    }

    function callUnguardedToGuarded() public {
        callbackTargetGuarded();
    }

    function callUnguardedToUnguarded() public {
        callbackTargetUnguarded();
    }

    function callGuardedToGuarded() public nonReentrant {
        callbackTargetGuarded();
    }

    function callGuardedToUnguarded() public nonReentrant {
        callbackTargetUnguarded();
    }

    function callGuardedToReadGuarded() public nonReentrant {
        readCallbackTargetGuarded();
    }

    function callUnguardedToReadGuarded() public {
        readCallbackTargetGuarded();
    }

    function setTransientOnlyOnMainnet(bool value) public {
        transientOnlyOnMainnet = value;
    }

    function _useTransientReentrancyGuardOnlyOnMainnet() internal view override returns (bool) {
        return transientOnlyOnMainnet;
    }

    // Targets

    /// @dev Callback target without a reentrancy guard.
    function callbackTargetUnguarded() public {
        enterTimes++;
    }

    /// @dev Callback target with a reentrancy guard.
    function callbackTargetGuarded() public nonReentrant {
        enterTimes++;
    }

    /// @dev Callback target with a non-read reentrancy guard.
    function readCallbackTargetGuarded() public nonReadReentrant {
        enterTimes++;
    }

    // Recursion

    function countUnguardedDirectRecursive(uint256 recursion) public {
        _recurseDirect(false, recursion);
    }

    function countGuardedDirectRecursive(uint256 recursion) public nonReentrant {
        _recurseDirect(true, recursion);
    }

    function countUnguardedIndirectRecursive(uint256 recursion) public {
        _recurseIndirect(false, recursion);
    }

    function countGuardedIndirectRecursive(uint256 recursion) public nonReentrant {
        _recurseIndirect(true, recursion);
    }

    function countAndCall(ReentrancyAttack attacker) public nonReentrant {
        enterTimes++;
        attacker.callSender(bytes4(keccak256("callbackTargetGuarded()")));
    }

    // Helpers

    function _recurseDirect(bool guarded, uint256 recursion) private {
        if (recursion > 0) {
            enterTimes++;

            if (guarded) {
                countGuardedDirectRecursive(recursion - 1);
            } else {
                countUnguardedDirectRecursive(recursion - 1);
            }
        }
    }

    function _recurseIndirect(bool guarded, uint256 recursion) private {
        if (recursion > 0) {
            enterTimes++;

            (bool success, bytes memory data) = address(this).call(
                abi.encodeWithSignature(
                    guarded
                        ? "countGuardedIndirectRecursive(uint256)"
                        : "countUnguardedIndirectRecursive(uint256)",
                    recursion - 1
                )
            );

            if (!success) {
                /// @solidity memory-safe-assembly
                assembly {
                    revert(add(32, data), mload(data))
                }
            }
        }
    }
}

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract ReentrancyAttack {
    /// @dev Reverts on a failed reentrancy attack.
    error ReentrancyAttackFailed();

    /// @dev Call the msg.sender with the given data to perform a reentrancy attack.
    function callSender(bytes4 data) external {
        (bool success,) = msg.sender.call(abi.encodeWithSelector(data));

        if (!success) revert ReentrancyAttackFailed();
    }
}
