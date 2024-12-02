// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {Timelock} from "../src/accounts/Timelock.sol";

contract TimelockTest is SoladyTest {
    struct Call {
        address target;
        int256 value;
        bytes data;
    }

    event Proposed(bytes32 indexed id, bytes executionData, uint256 readyTimestamp);
    event Executed(bytes32 indexed id, bytes executionData);
    event Cancelled(bytes32 indexed id);
    event MinDelaySet(uint256 newMinDelay);

    Timelock timelock;

    uint256 internal constant _DEFAULT_MIN_DELAY = 1000;
    address internal constant _ALICE = address(111);
    bytes32 internal constant _SUPPORTED_MODE = bytes10(0x01000000000078210001);

    uint256 internal constant _MAX_DELAY = 2 ** 253 - 1;

    function setUp() public {
        timelock = new Timelock();
    }

    function _initializeTimelock() internal {
        address[] memory a = new address[](2);
        a[0] = address(this);
        a[1] = _ALICE;
        timelock.initialize(_DEFAULT_MIN_DELAY, a, a, a);
    }

    function testSetAndGetMinDelay(uint256 newMinDelay) public {
        newMinDelay = _bound(newMinDelay, 0, _MAX_DELAY);
        Call[] memory calls = new Call[](1);
        calls[0].target = address(timelock);
        calls[0].data = abi.encodeWithSignature("setMinDelay(uint256)", newMinDelay);
        _initializeTimelock();

        bytes memory executionData = abi.encode(calls);

        if (_randomChance(16)) {
            uint256 delay = _random();
            uint256 t = timelock.minDelay();
            if (delay < t) {
                vm.expectRevert(
                    abi.encodeWithSignature("TimelockInsufficientDelay(uint256,uint256)", delay, t)
                );
                timelock.propose(executionData, delay);
                return;
            } else if (delay > _MAX_DELAY) {
                vm.expectRevert(Timelock.TimelockDelayOverflow.selector);
                timelock.propose(executionData, delay);
                return;
            }
        }

        vm.expectEmit(true, true, true, true);
        emit Proposed(keccak256(executionData), executionData, block.timestamp + _DEFAULT_MIN_DELAY);
        bytes32 id = timelock.propose(executionData, _DEFAULT_MIN_DELAY);

        if (_randomChance(32)) {
            vm.warp(block.timestamp + _DEFAULT_MIN_DELAY - 1);
            vm.expectRevert(
                abi.encodeWithSignature(
                    "TimelockInvalidOperation(bytes32,uint256)",
                    id,
                    _os(Timelock.OperationState.Ready)
                )
            );
            timelock.execute(_SUPPORTED_MODE, executionData);
            return;
        }

        vm.warp(block.timestamp + _DEFAULT_MIN_DELAY);
        vm.expectEmit(true, true, true, true);
        emit Executed(id, executionData);
        vm.expectEmit(true, true, true, true);
        emit MinDelaySet(newMinDelay);
        timelock.execute(_SUPPORTED_MODE, executionData);
        assertEq(timelock.minDelay(), newMinDelay);

        if (_randomChance(8)) {
            vm.expectRevert(
                abi.encodeWithSignature(
                    "TimelockInvalidOperation(bytes32,uint256)",
                    id,
                    _os(Timelock.OperationState.Ready)
                )
            );
            timelock.execute(_SUPPORTED_MODE, executionData);
        }
    }

    function _os(Timelock.OperationState s) internal pure returns (uint256) {
        return 1 << uint256(uint8(s));
    }

    function testOperationStateDifferentialTrick(uint256 packed, uint256 blockTimestamp)
        public
        pure
    {
        check_OperationStateDifferentialTrick(packed, blockTimestamp);
    }

    function check_OperationStateDifferentialTrick(uint256 packed, uint256 blockTimestamp)
        public
        pure
    {
        assert(
            _operationStateOptimized(packed, blockTimestamp)
                == uint8(_operationStateOriginal(packed, blockTimestamp))
        );
        assert(
            _isOperationPendingOptimized(packed)
                == _isOperationPendingOriginal(packed, blockTimestamp)
        );
        assert(
            _isOperationReadyOptimized(packed, blockTimestamp)
                == _isOperationReadyOriginal(packed, blockTimestamp)
        );
    }

    function _isOperationPendingOptimized(uint256 packed) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            let p := packed
            result := iszero(or(and(1, p), iszero(p)))
        }
    }

    function _isOperationReadyOptimized(uint256 packed, uint256 blockTimestamp)
        internal
        pure
        returns (bool result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let p := packed
            result := iszero(or(or(and(1, p), iszero(p)), lt(blockTimestamp, shr(1, packed))))
        }
    }

    function _operationStateOptimized(uint256 packed, uint256 blockTimestamp)
        internal
        pure
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let p := packed
            let t := blockTimestamp
            result := mul(iszero(iszero(p)), or(mul(3, and(p, 1)), sub(2, lt(t, shr(1, p)))))
        }
    }

    function _isOperationPendingOriginal(uint256 packed, uint256 blockTimestamp)
        internal
        pure
        returns (bool)
    {
        return _operationStateOriginal(packed, blockTimestamp) == Timelock.OperationState.Waiting
            || _operationStateOriginal(packed, blockTimestamp) == Timelock.OperationState.Ready;
    }

    function _isOperationReadyOriginal(uint256 packed, uint256 blockTimestamp)
        internal
        pure
        returns (bool)
    {
        return _operationStateOriginal(packed, blockTimestamp) == Timelock.OperationState.Ready;
    }

    function _operationStateOriginal(uint256 packed, uint256 blockTimestamp)
        internal
        pure
        returns (Timelock.OperationState)
    {
        if (packed == uint256(0)) return Timelock.OperationState.Unset;
        if (packed & 1 == 1) return Timelock.OperationState.Done;
        if (packed >> 1 > blockTimestamp) return Timelock.OperationState.Waiting;
        return Timelock.OperationState.Ready;
    }
}
