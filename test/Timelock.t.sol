// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {Timelock} from "../src/accounts/Timelock.sol";

contract TimelockTest is SoladyTest {
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
