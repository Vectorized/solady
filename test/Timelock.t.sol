// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {Timelock} from "../src/accounts/Timelock.sol";
import {EnumerableRoles} from "../src/auth/EnumerableRoles.sol";

contract TimelockTest is SoladyTest {
    struct Call {
        address target;
        int256 value;
        bytes data;
    }

    event Proposed(bytes32 indexed id, bytes32 mode, bytes executionData, uint256 readyTimestamp);
    event Executed(bytes32 indexed id, bytes32 mode, bytes executionData);
    event Cancelled(bytes32 indexed id);
    event MinDelaySet(uint256 newMinDelay);

    Timelock timelock;

    uint256 internal constant _DEFAULT_MIN_DELAY = 1000;
    address internal constant _ALICE = address(111);
    address internal constant _BOB = address(222);
    address internal constant _CHARLIE = address(333);
    address internal constant _ADMIN = address(777);
    bytes32 internal constant _SUPPORTED_MODE = bytes10(0x01000000000078210001);

    uint256 internal constant _MAX_DELAY = 2 ** 254 - 1;

    function setUp() public {
        timelock = new Timelock();
        _initializeTimelock();
    }

    function _initializeTimelock() internal {
        address[] memory a = new address[](2);

        a[0] = address(this);
        a[1] = _ALICE;
        vm.expectEmit(true, true, true, true);
        emit MinDelaySet(_DEFAULT_MIN_DELAY);
        timelock.initialize(_DEFAULT_MIN_DELAY, _ADMIN, a, a, a);
    }

    function testInitialize() public {
        assertEq(timelock.hasRole(_ALICE, timelock.EXECUTOR_ROLE()), true);
        address[] memory a;
        vm.expectRevert(Timelock.TimelockAlreadyInitialized.selector);
        timelock.initialize(_MAX_DELAY, _ADMIN, a, a, a);
        vm.expectRevert(Timelock.TimelockDelayOverflow.selector);
        timelock.initialize(_MAX_DELAY + 1, _ADMIN, a, a, a);
    }

    struct _PredecessorTestTemps {
        Call[] calls0;
        Call[] calls1;
        bytes executionData0;
        bytes executionData1;
        bytes32 id0;
        bytes32 id1;
        uint256 delay;
        uint256 minDelay;
        uint256 readyTimestamp;
    }

    function testPredecessor() public {
        uint256 executorRole = timelock.EXECUTOR_ROLE();

        _PredecessorTestTemps memory t;
        t.calls0 = new Call[](1);
        t.calls0[0].target = address(timelock);
        t.calls0[0].data =
            abi.encodeWithSignature("setRole(address,uint256,bool)", _BOB, executorRole, true);
        t.executionData0 = abi.encode(t.calls0);
        t.id0 = _id(t.executionData0);

        t.calls1 = new Call[](1);
        t.calls1[0].target = address(timelock);
        t.calls1[0].data =
            abi.encodeWithSignature("setRole(address,uint256,bool)", _CHARLIE, executorRole, true);
        t.executionData1 = abi.encode(t.calls1, abi.encodePacked(t.id0));
        t.id1 = _id(t.executionData1);

        // Must revert if try to execute on an empty id.
        vm.expectRevert(
            abi.encodeWithSignature(
                "TimelockInvalidOperation(bytes32,uint256)",
                t.id0,
                _os(Timelock.OperationState.Ready)
            )
        );
        timelock.execute(_SUPPORTED_MODE, t.executionData0);

        assertEq(timelock.propose(_SUPPORTED_MODE, t.executionData0, _DEFAULT_MIN_DELAY), t.id0);
        assertEq(timelock.propose(_SUPPORTED_MODE, t.executionData1, _DEFAULT_MIN_DELAY), t.id1);

        t.readyTimestamp = block.timestamp + _DEFAULT_MIN_DELAY;
        vm.warp(t.readyTimestamp);
        vm.expectRevert(abi.encodeWithSignature("TimelockUnexecutedPredecessor(bytes32)", t.id0));
        timelock.execute(_SUPPORTED_MODE, t.executionData1);

        vm.prank(_BOB);
        vm.expectRevert(EnumerableRoles.EnumerableRolesUnauthorized.selector);
        timelock.execute(_SUPPORTED_MODE, t.executionData0);

        timelock.execute(_SUPPORTED_MODE, t.executionData0);
        assertEq(timelock.roleHolderCount(executorRole), 3);

        vm.prank(_BOB);
        timelock.execute(_SUPPORTED_MODE, t.executionData1);
        assertEq(timelock.roleHolderCount(executorRole), 4);

        vm.expectRevert(EnumerableRoles.EnumerableRolesUnauthorized.selector);
        timelock.setRole(_CHARLIE, executorRole, false);
    }

    function testOpenRoleHolder() public {
        uint256 executorRole = timelock.EXECUTOR_ROLE();

        _PredecessorTestTemps memory t;
        t.calls0 = new Call[](1);
        t.calls0[0].target = address(timelock);
        t.calls0[0].data = abi.encodeWithSignature(
            "setRole(address,uint256,bool)", timelock.OPEN_ROLE_HOLDER(), executorRole, true
        );
        t.executionData0 = abi.encode(t.calls0);
        t.id0 = _id(t.executionData0);

        t.calls1 = new Call[](1);
        t.calls1[0].target = address(timelock);
        t.calls1[0].data =
            abi.encodeWithSignature("setRole(address,uint256,bool)", _CHARLIE, executorRole, true);
        t.executionData1 = abi.encode(t.calls1, abi.encodePacked(t.id0));
        t.id1 = _id(t.executionData1);

        assertEq(timelock.propose(_SUPPORTED_MODE, t.executionData0, _DEFAULT_MIN_DELAY), t.id0);
        assertEq(timelock.propose(_SUPPORTED_MODE, t.executionData1, _DEFAULT_MIN_DELAY), t.id1);

        t.readyTimestamp = block.timestamp + _DEFAULT_MIN_DELAY;
        vm.warp(t.readyTimestamp);
        vm.expectRevert(abi.encodeWithSignature("TimelockUnexecutedPredecessor(bytes32)", t.id0));
        timelock.execute(_SUPPORTED_MODE, t.executionData1);

        timelock.execute(_SUPPORTED_MODE, t.executionData0);
        assertEq(timelock.roleHolderCount(executorRole), 3);

        vm.prank(_BOB);
        timelock.execute(_SUPPORTED_MODE, t.executionData1);
        assertEq(timelock.roleHolderCount(executorRole), 4);

        vm.expectRevert(EnumerableRoles.EnumerableRolesUnauthorized.selector);
        timelock.setRole(_CHARLIE, executorRole, false);
    }

    function testAdminRole() public {
        uint256 executorRole = timelock.EXECUTOR_ROLE();
        uint256 adminRole = timelock.ADMIN_ROLE();

        vm.expectRevert(EnumerableRoles.EnumerableRolesUnauthorized.selector);
        timelock.setRole(_CHARLIE, executorRole, false);

        vm.prank(_ADMIN);
        timelock.setRole(_CHARLIE, executorRole, true);

        vm.prank(_ADMIN);
        timelock.setRole(_ADMIN, adminRole, false);

        vm.expectRevert(EnumerableRoles.EnumerableRolesUnauthorized.selector);
        vm.prank(_ADMIN);
        timelock.setRole(_ADMIN, adminRole, false);
    }

    struct _TestTemps {
        Call[] calls;
        bytes executionData;
        bytes32 id;
        uint256 delay;
        uint256 minDelay;
        uint256 readyTimestamp;
    }

    function testSetAndGetMinDelay(uint256 newMinDelay) public {
        vm.warp(block.timestamp + _bound(_random(), 0, 0xffffffff));

        newMinDelay = _bound(newMinDelay, 0, _MAX_DELAY);
        _TestTemps memory t;
        t.calls = new Call[](1);
        t.calls[0].target = address(timelock);
        t.calls[0].data = abi.encodeWithSignature("setMinDelay(uint256)", newMinDelay);

        t.executionData = abi.encode(t.calls);
        t.id = _id(t.executionData);

        if (_randomChance(16)) {
            t.delay = _random();
            t.minDelay = timelock.minDelay();
            if (t.delay < t.minDelay) {
                vm.expectRevert(
                    abi.encodeWithSignature(
                        "TimelockInsufficientDelay(uint256,uint256)", t.delay, t.minDelay
                    )
                );
                timelock.propose(_SUPPORTED_MODE, t.executionData, t.delay);
                return;
            } else if (t.delay > _MAX_DELAY) {
                vm.expectRevert(Timelock.TimelockDelayOverflow.selector);
                timelock.propose(_SUPPORTED_MODE, t.executionData, t.delay);
                return;
            }
        }

        assertEq(uint8(timelock.operationState(t.id)), uint8(Timelock.OperationState.Unset));
        assertEq(timelock.readyTimestamp(t.id), 0);

        if (_randomChance(64)) {
            vm.expectRevert(
                abi.encodeWithSignature(
                    "TimelockInvalidOperation(bytes32,uint256)",
                    t.id,
                    _os(Timelock.OperationState.Ready) | _os(Timelock.OperationState.Waiting)
                )
            );
            timelock.cancel(t.id);
        }

        t.readyTimestamp = block.timestamp + _DEFAULT_MIN_DELAY;
        vm.expectEmit(true, true, true, true);
        emit Proposed(t.id, _SUPPORTED_MODE, t.executionData, t.readyTimestamp);
        assertEq(timelock.propose(_SUPPORTED_MODE, t.executionData, _DEFAULT_MIN_DELAY), t.id);

        assertEq(uint8(timelock.operationState(t.id)), uint8(Timelock.OperationState.Waiting));
        assertEq(timelock.readyTimestamp(t.id), t.readyTimestamp);

        if (_randomChance(16)) {
            vm.warp(block.timestamp + _bound(_random(), 0, _DEFAULT_MIN_DELAY * 2));
            vm.expectEmit(true, true, true, true);
            emit Cancelled(t.id);
            timelock.cancel(t.id);
            assertEq(uint8(timelock.operationState(t.id)), uint8(Timelock.OperationState.Unset));
            return;
        }

        if (_randomChance(32)) {
            vm.warp(t.readyTimestamp - 1);
            vm.expectRevert(
                abi.encodeWithSignature(
                    "TimelockInvalidOperation(bytes32,uint256)",
                    t.id,
                    _os(Timelock.OperationState.Ready)
                )
            );
            timelock.execute(_SUPPORTED_MODE, t.executionData);
            return;
        }

        vm.warp(t.readyTimestamp);
        assertEq(uint8(timelock.operationState(t.id)), uint8(Timelock.OperationState.Ready));
        vm.expectEmit(true, true, true, true);
        emit MinDelaySet(newMinDelay);
        vm.expectEmit(true, true, true, true);
        emit Executed(t.id, _SUPPORTED_MODE, t.executionData);
        timelock.execute(_SUPPORTED_MODE, t.executionData);
        assertEq(timelock.minDelay(), newMinDelay);
        assertEq(uint8(timelock.operationState(t.id)), uint8(Timelock.OperationState.Done));
        assertEq(timelock.readyTimestamp(t.id), t.readyTimestamp);

        if (_randomChance(8)) {
            vm.expectRevert(
                abi.encodeWithSignature(
                    "TimelockInvalidOperation(bytes32,uint256)",
                    t.id,
                    _os(Timelock.OperationState.Ready)
                )
            );
            timelock.execute(_SUPPORTED_MODE, t.executionData);
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
        if (!_isOperationReadyOriginal(packed ^ 1, blockTimestamp)) {
            if (_isOperationDoneOriginal(packed, blockTimestamp)) {
                packed ^= 1;
                assert(!_isOperationReadyOriginal(packed, blockTimestamp));
            }
        }
        assert(
            _operationStateOptimized(packed, blockTimestamp)
                == uint8(_operationStateOriginal(packed, blockTimestamp))
        );
        assert(
            _isOperationDoneOptimized(packed, blockTimestamp)
                == _isOperationDoneOriginal(packed, blockTimestamp)
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

    function _isOperationDoneOptimized(uint256 packed, uint256)
        internal
        pure
        returns (bool result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := and(1, packed)
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
            result := mul(iszero(iszero(p)), add(and(p, 1), sub(2, lt(t, shr(1, p)))))
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

    function _isOperationDoneOriginal(uint256 packed, uint256 blockTimestamp)
        internal
        pure
        returns (bool)
    {
        return _operationStateOriginal(packed, blockTimestamp) == Timelock.OperationState.Done;
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

    function testDelayRestriction(uint256 minDelay, uint256 delay, uint256 blockTimestamp)
        public
        pure
    {
        check_DelayRestriction(minDelay, delay, blockTimestamp);
    }

    function check_DelayRestriction(uint256 minDelay, uint256 delay, uint256 blockTimestamp)
        public
        pure
    {
        uint256 upper = 2 ** 254 - 1;
        minDelay = minDelay & upper;
        if (delay < minDelay) delay = minDelay;
        else delay = delay & upper;
        blockTimestamp = blockTimestamp & (2 ** 64 - 1);
        uint256 readyTimestamp = delay + blockTimestamp;
        assert(readyTimestamp <= 2 ** 255 - 1);
    }

    function _id(bytes memory executionData) internal pure returns (bytes32) {
        return keccak256(abi.encode(_SUPPORTED_MODE, keccak256(executionData)));
    }
}
