// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {ERC20, ERC20Votes, MockERC20Votes} from "./utils/mocks/MockERC20Votes.sol";
import {FixedPointMathLib} from "../src/utils/FixedPointMathLib.sol";

contract ERC20VotesTest is SoladyTest {
    MockERC20Votes erc20Votes;

    event DelegateChanged(address indexed delegator, address indexed from, address indexed to);
    event DelegateVotesChanged(address indexed delegate, uint256 oldValue, uint256 newValue);

    address internal constant _ALICE = address(111);
    address internal constant _BOB = address(222);
    address internal constant _CHARLIE = address(333);
    address internal constant _DAVID = address(444);

    function setUp() public {
        erc20Votes = new MockERC20Votes();
    }

    function testSetAndGetDelegate(address delegator, address delegatee) public {
        erc20Votes.directDelegate(delegator, delegatee);
        assertEq(erc20Votes.delegates(delegator), delegatee);
    }

    function testMintTransferBurnDelegate() public {
        uint256 amount = 1 ether;
        erc20Votes.mint(_ALICE, amount);

        // Minting does not automatically give one votes.
        assertEq(erc20Votes.getVotes(_ALICE), 0);
        assertEq(erc20Votes.getVotes(_BOB), 0);
        assertEq(erc20Votes.getTotalVotesSupply(), 1 ether);

        vm.expectEmit(true, true, true, true);
        emit DelegateChanged(_ALICE, address(0), _BOB);
        vm.prank(_ALICE);
        erc20Votes.delegate(_BOB);

        assertEq(erc20Votes.getVotes(_BOB), 1 ether);
        assertEq(erc20Votes.getVotes(_DAVID), 0 ether);

        vm.expectEmit(true, true, true, true);
        emit DelegateChanged(_CHARLIE, address(0), _DAVID);
        vm.prank(_CHARLIE);
        erc20Votes.delegate(_DAVID);

        vm.prank(_ALICE);
        erc20Votes.transfer(_CHARLIE, 0.3 ether);

        assertEq(erc20Votes.getVotes(_BOB), 0.7 ether);
        assertEq(erc20Votes.getVotes(_DAVID), 0.3 ether);

        erc20Votes.burn(_ALICE, 0.1 ether);
        assertEq(erc20Votes.getVotes(_BOB), 0.6 ether);
        assertEq(erc20Votes.getVotes(_DAVID), 0.3 ether);

        vm.expectEmit(true, true, true, true);
        emit DelegateChanged(_CHARLIE, _DAVID, _BOB);
        vm.expectEmit(true, true, true, true);
        emit DelegateVotesChanged(_DAVID, 0.3 ether, 0 ether);
        vm.expectEmit(true, true, true, true);
        emit DelegateVotesChanged(_BOB, 0.6 ether, 0.9 ether);
        vm.prank(_CHARLIE);
        erc20Votes.delegate(_BOB);
        assertEq(erc20Votes.getVotes(_BOB), 0.9 ether);
        assertEq(erc20Votes.getVotes(_DAVID), 0 ether);
    }

    function _advanceBlockNumber() internal {
        vm.roll(vm.getBlockNumber() + (_randomUniform() & 3));
    }

    struct _TestVoteInvariantsTemps {
        address[] accounts;
        address[] delegates;
        address account;
        uint256 amount;
        address delegator;
        address delegate;
        address from;
        address to;
        uint256 checkpointCount;
        uint256 totalBalanceForDelegate;
        uint256 totalVotes;
        uint256 n;
    }

    function testVoteInvariants(bytes32) public {
        unchecked {
            _TestVoteInvariantsTemps memory t;
            t.n = 1 + (_randomUniform() & 3);
            t.accounts = new address[](t.n);
            t.delegates = new address[](t.n + 1);
            for (uint256 i; i != t.accounts.length; ++i) {
                t.account = _randomUniqueHashedAddress();
                t.accounts[i] = t.account;
                t.delegates[i + 1] = t.account;
                if (!_randomChance(4)) {
                    erc20Votes.mint(t.account, _bound(_random(), 0, 2 ** 161 - 1));
                }
            }
            do {
                if (_randomChance(2)) {
                    t.delegator = t.accounts[_randomUniform() % t.accounts.length];
                    t.delegate = t.delegates[_randomUniform() % t.delegates.length];
                    vm.prank(t.delegator);
                    erc20Votes.delegate(t.delegate);
                }
                if (_randomChance(4)) _advanceBlockNumber();
                if (_randomChance(2)) {
                    t.from = t.accounts[_randomUniform() % t.accounts.length];
                    t.to = t.accounts[_randomUniform() % t.accounts.length];
                    t.amount = _bound(_random(), 0, erc20Votes.balanceOf(t.from));
                    vm.prank(t.from);
                    erc20Votes.transfer(t.to, t.amount);
                }
                if (_randomChance(4)) _advanceBlockNumber();
                if (_randomChance(4)) {
                    t.account = t.accounts[_randomUniform() % t.accounts.length];
                    t.amount = _bound(_random(), 0, erc20Votes.balanceOf(t.account));
                    erc20Votes.burn(t.account, t.amount);
                }
                if (_randomChance(4)) _advanceBlockNumber();
                if (_randomChance(4)) {
                    t.account = t.accounts[_randomUniform() % t.accounts.length];
                    t.amount = _bound(_random(), 0, 2 ** 161 - 1);
                    erc20Votes.mint(t.account, t.amount);
                }
                if (_randomChance(4)) _advanceBlockNumber();
                if (_randomChance(8)) _checkVoteInvariants(t);
            } while (!_randomChance(4));
            _checkVoteInvariants(t);
        }
    }

    function _checkVoteInvariants(_TestVoteInvariantsTemps memory t) internal {
        unchecked {
            t.totalVotes = 0;
            for (uint256 j; j != t.delegates.length; ++j) {
                t.totalVotes += erc20Votes.getVotes(t.delegates[j]);
            }
            for (uint256 j; j != t.delegates.length; ++j) {
                t.totalBalanceForDelegate = 0;
                for (uint256 i; i != t.accounts.length; ++i) {
                    if (erc20Votes.delegates(t.accounts[i]) == t.delegates[j]) {
                        t.totalBalanceForDelegate += erc20Votes.balanceOf(t.accounts[i]);
                    }
                }
                assertLe(erc20Votes.getVotes(t.delegates[j]), t.totalBalanceForDelegate);
            }
            assertLe(t.totalVotes, erc20Votes.getTotalVotesSupply());
            assertEq(erc20Votes.getTotalVotesSupply(), erc20Votes.totalSupply());
        }
        unchecked {
            for (uint256 j; j != t.delegates.length; ++j) {
                t.checkpointCount = erc20Votes.checkpointCount(t.delegates[j]);
                if (_randomChance(2) && t.checkpointCount != 0) {
                    uint256 i = _bound(_random(), 0, t.checkpointCount - 1);
                    erc20Votes.checkpointAt(t.delegates[j], i);
                } else if (t.checkpointCount != 0) {
                    uint256 i = _bound(_random(), t.checkpointCount, t.checkpointCount + 10);
                    vm.expectRevert(ERC20Votes.ERC5805VoteCheckpointIndexOutOfBounds.selector);
                    erc20Votes.checkpointAt(t.delegates[j], i);
                }
            }
        }
    }

    struct _TestDelegateBySigTemps {
        address signer;
        uint256 privateKey;
        uint256 nonce;
        uint256 expiry;
        address delegatee;
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes32 innerHash;
        bytes32 outerHash;
        bytes32 domainSeparator;
    }

    bytes32 internal constant _ERC5805_DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    function _signDelegate(_TestDelegateBySigTemps memory t) internal view {
        t.innerHash =
            keccak256(abi.encode(_ERC5805_DELEGATION_TYPEHASH, t.delegatee, t.nonce, t.expiry));
        t.domainSeparator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(erc20Votes.name())),
                keccak256("1"),
                block.chainid,
                address(erc20Votes)
            )
        );
        t.outerHash = keccak256(abi.encodePacked("\x19\x01", t.domainSeparator, t.innerHash));
        (t.v, t.r, t.s) = vm.sign(t.privateKey, t.outerHash);
    }

    function testClockTrick(uint48 x) public pure {
        /// @solidity memory-safe-assembly
        assembly {
            returndatacopy(returndatasize(), returndatasize(), sub(0, shr(48, x)))
        }
    }

    function testDelegateBySig(bytes32) public {
        _TestDelegateBySigTemps memory t;
        t.delegatee = _randomHashedAddress();
        (t.signer, t.privateKey) = _randomSigner();
        t.nonce = _randomUniform() & 7;
        t.expiry = _bound(_randomUniform(), 10, 2 ** 32 - 1);
        if (!_randomChance(32)) {
            unchecked {
                for (uint256 i; i != t.nonce; ++i) {
                    erc20Votes.directIncrementNonce(t.signer);
                }
                assertEq(t.nonce, erc20Votes.nonces(t.signer));
            }
        }
        _signDelegate(t);
        uint256 timestamp = _bound(_randomUniform(), 10, 2 ** 32 - 1);
        vm.warp(timestamp);
        if (timestamp > t.expiry) {
            vm.expectRevert(ERC20Votes.ERC5805VoteSignatureExpired.selector);
            erc20Votes.delegateBySig(t.delegatee, t.nonce, t.expiry, t.v, t.r, t.s);
        } else if (t.nonce != erc20Votes.nonces(t.signer)) {
            vm.expectRevert(ERC20Votes.ERC5805VoteInvalidSignature.selector);
            erc20Votes.delegateBySig(t.delegatee, t.nonce, t.expiry, t.v, t.r, t.s);
        } else {
            erc20Votes.delegateBySig(t.delegatee, t.nonce, t.expiry, t.v, t.r, t.s);
            assertEq(t.nonce + 1, erc20Votes.nonces(t.signer));
            assertEq(erc20Votes.delegates(t.signer), t.delegatee);
        }
    }

    struct Checkpoint {
        uint256 key;
        uint256 value;
    }

    Checkpoint[] internal _trace;

    function testSmallSqrtApprox(uint32 n) public {
        uint256 approx = _smallSqrtApprox(n);
        uint256 groundTruth = FixedPointMathLib.sqrt(n);
        assertGe(approx, groundTruth);
        assertLe(FixedPointMathLib.dist(approx, groundTruth), 3);
    }

    function _smallSqrtApprox(uint256 n) internal pure returns (uint256 m) {
        /// @solidity memory-safe-assembly
        assembly {
            m := shl(4, lt(0xffff, n))
            m := shl(shr(1, or(shl(3, lt(0xff, shr(m, n))), m)), 16)
            m := shr(1, add(m, div(n, m)))
            m := shr(1, add(m, div(n, m)))
            m := shr(1, add(m, div(n, m)))
            m := shr(1, add(m, div(n, m)))
            m := shr(1, add(m, div(n, m)))
            m := shr(1, add(m, div(n, m)))
        }
    }

    struct _TestCheckpointTemps {
        uint256 key;
        uint256 amount;
        bool isAdd;
        uint256 oldValueOriginal;
        uint256 oldValue;
        uint256 newValueOriginal;
        uint256 newValue;
    }

    function testCheckpointDifferential(uint256 lengthSlot, uint256 n) public {
        lengthSlot = uint256(keccak256(abi.encode(lengthSlot, "hehe")));
        unchecked {
            n = _randomChance(32) ? _bound(n, 1, 70) : _bound(n, 1, 8);
            _TestCheckpointTemps memory t;
            for (uint256 i; i != n; ++i) {
                uint256 lastKey = _checkpointLatestKeyOriginal();
                while (true) {
                    t.key = lastKey + _randomUniform() & 0xf;
                    t.amount = _random();
                    t.isAdd = _randomChance(2);
                    if (!_checkpointPushDiffOriginalReverts(t.key, t.amount, t.isAdd)) break;
                }

                (t.oldValueOriginal, t.newValueOriginal) =
                    _checkpointPushDiffOriginal(t.key, t.amount, t.isAdd);

                (t.oldValue, t.newValue) = _checkpointPushDiff(lengthSlot, t.key, t.amount, t.isAdd);

                assertEq(t.oldValue, t.oldValueOriginal);
                assertEq(t.newValue, t.newValueOriginal);

                assertEq(_checkpointLatestOriginal(), _checkpointLatest(lengthSlot));

                if (_randomChance(8)) _checkCheckpoints(lengthSlot);
                if (_randomChance(8)) _checkCheckpointUpperLookupRecent(lengthSlot);
            }
            _checkCheckpoints(lengthSlot);
            _checkCheckpointUpperLookupRecent(lengthSlot);
        }
    }

    function _checkCheckpoints(uint256 lengthSlot) internal tempMemory {
        unchecked {
            uint256 n = _trace.length;
            for (uint256 i; i != n; ++i) {
                (uint256 key, uint256 value) = _checkpointAt(lengthSlot, i);
                Checkpoint storage c = _trace[i];
                assertEq(key, c.key);
                assertEq(value, c.value);
            }
        }
    }

    function _checkCheckpointUpperLookupRecent(uint256 lengthSlot) internal tempMemory {
        uint256 key = _bound(_randomUniform(), 0, _checkpointLatestKeyOriginal() + 3);
        assertEq(
            _checkpointUpperLookupRecent(lengthSlot, key), _checkpointUpperLookupRecentOriginal(key)
        );
    }

    function _checkpointPushDiffOriginalReverts(uint256 key, uint256 amount, bool isAdd)
        internal
        tempMemory
        returns (bool)
    {
        (bool success,) = address(this).call(
            abi.encodeWithSignature(
                "checkpointPushDiffOriginalCheck(uint256,uint256,bool)", key, amount, isAdd
            )
        );
        return !success;
    }

    function checkpointPushDiffOriginalCheck(uint256 key, uint256 amount, bool isAdd)
        external
        view
    {
        uint256 oldValue;
        uint256 newValue;
        if (_trace.length == 0) {
            newValue = isAdd ? oldValue + amount : oldValue - amount;
        } else {
            Checkpoint storage last = _trace[_trace.length - 1];
            oldValue = last.value;
            newValue = isAdd ? oldValue + amount : oldValue - amount;
            if (last.key > key) revert("Unordered insertion");
        }
    }

    function _checkpointUpperLookupRecentOriginal(uint256 key)
        private
        view
        tempMemory
        returns (uint256 result)
    {
        unchecked {
            uint256 n = _trace.length;
            for (uint256 i; i != n; ++i) {
                Checkpoint storage c = _trace[i];
                if (c.key > key) break;
                result = c.value;
            }
        }
    }

    function _checkpointPushDiffOriginal(uint256 key, uint256 amount, bool isAdd)
        private
        tempMemory
        returns (uint256 oldValue, uint256 newValue)
    {
        if (_trace.length == 0) {
            newValue = isAdd ? oldValue + amount : oldValue - amount;
            _trace.push(Checkpoint(key, newValue));
        } else {
            Checkpoint storage last = _trace[_trace.length - 1];
            oldValue = last.value;
            newValue = isAdd ? oldValue + amount : oldValue - amount;
            if (last.key > key) revert("Unordered insertion");
            if (last.key == key) {
                last.value = newValue;
            } else {
                _trace.push(Checkpoint(key, newValue));
            }
        }
    }

    function _checkpointLatestKeyOriginal() private view returns (uint256) {
        return _trace.length == 0 ? 0 : _trace[_trace.length - 1].key;
    }

    function _checkpointLatestOriginal() private view returns (uint256) {
        return _trace.length == 0 ? 0 : _trace[_trace.length - 1].value;
    }

    function _checkpointAt(uint256 lengthSlot, uint256 i)
        private
        view
        returns (uint48 checkpointClock, uint256 checkpointValue)
    {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(lt(i, shr(208, shl(160, sload(lengthSlot))))) {
                mstore(0x00, 0x30607f04) // `ERC5805VoteCheckpointIndexOutOfBounds()`.
                revert(0x1c, 0x04)
            }
            let checkpointSlot := add(i, lengthSlot)
            let checkpointPacked := sload(checkpointSlot)
            checkpointClock := and(0xffffffffffff, checkpointPacked)
            checkpointValue := shr(96, checkpointPacked)
            if eq(checkpointValue, address()) { checkpointValue := sload(not(checkpointSlot)) }
        }
    }

    /// @dev Pushes a checkpoint.
    function _checkpointPushDiff(uint256 lengthSlot, uint256 key, uint256 amount, bool isAdd)
        private
        returns (uint256 oldValue, uint256 newValue)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let lengthSlotPacked := sload(lengthSlot)
            for { let n := shr(208, shl(160, lengthSlotPacked)) } 1 {} {
                if iszero(n) {
                    if iszero(or(isAdd, iszero(amount))) {
                        mstore(0x00, 0xef529cb2) // `ERC5805VoteCheckpointUnderflow()`.
                        revert(0x1c, 0x04)
                    }
                    newValue := amount
                    if iszero(or(eq(newValue, address()), shr(160, newValue))) {
                        sstore(lengthSlot, or(or(key, shl(48, 1)), shl(96, newValue)))
                        break
                    }
                    sstore(lengthSlot, or(or(key, shl(48, 1)), shl(96, address())))
                    sstore(not(lengthSlot), newValue)
                    break
                }
                let checkpointSlot := add(sub(n, 1), lengthSlot)
                let lastPacked := sload(checkpointSlot)
                oldValue := shr(96, lastPacked)
                if eq(oldValue, address()) { oldValue := sload(not(checkpointSlot)) }
                for {} 1 {} {
                    if iszero(isAdd) {
                        if gt(amount, oldValue) {
                            mstore(0x00, 0xef529cb2) // `ERC5805VoteCheckpointUnderflow()`.
                            revert(0x1c, 0x04)
                        }
                        newValue := sub(oldValue, amount)
                        break
                    }
                    newValue := add(oldValue, amount)
                    if lt(newValue, oldValue) {
                        mstore(0x00, 0x4a15589d) // `ERC5805VoteCheckpointOverflow()`.
                        revert(0x1c, 0x04)
                    }
                    break
                }
                let lastKey := and(0xffffffffffff, lastPacked)
                if iszero(eq(lastKey, key)) {
                    n := add(1, n)
                    checkpointSlot := add(1, checkpointSlot)
                    sstore(lengthSlot, add(shl(48, 1), lengthSlotPacked))
                }
                if or(gt(lastKey, key), shr(48, n)) { invalid() }
                if iszero(or(eq(newValue, address()), shr(160, newValue))) {
                    sstore(checkpointSlot, or(or(key, shl(48, n)), shl(96, newValue)))
                    break
                }
                sstore(checkpointSlot, or(or(key, shl(48, n)), shl(96, address())))
                sstore(not(checkpointSlot), newValue)
                break
            }
        }
    }

    /// @dev Returns the latest value in the checkpoints.
    function _checkpointLatest(uint256 lengthSlot) private view returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := shr(208, shl(160, sload(lengthSlot)))
            if result {
                let checkpointSlot := add(sub(result, 1), lengthSlot)
                result := shr(96, sload(checkpointSlot))
                if eq(result, address()) { result := sload(not(checkpointSlot)) }
            }
        }
    }

    /// @dev Returns the value in the checkpoints with the largest key that is less than `key`.
    function _checkpointUpperLookupRecent(uint256 lengthSlot, uint256 key)
        private
        view
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let l := 0 // Low.
            let h := shr(208, shl(160, sload(lengthSlot))) // High.
            // Start the binary search nearer to the right to optimize for recent checkpoints.
            for { let n := h } iszero(lt(n, 6)) {} {
                let m := shl(4, lt(0xffff, n))
                m := shl(shr(1, or(m, shl(3, lt(0xff, shr(m, n))))), 16)
                m := shr(1, add(m, div(n, m)))
                m := shr(1, add(m, div(n, m)))
                m := shr(1, add(m, div(n, m)))
                m := shr(1, add(m, div(n, m)))
                m := shr(1, add(m, div(n, m)))
                m := sub(n, shr(1, add(m, div(n, m)))) // Approx `n - sqrt(n)`.
                if iszero(lt(key, and(sload(add(m, lengthSlot)), 0xffffffffffff))) {
                    l := add(1, m)
                    break
                }
                h := m
                break
            }
            // Binary search.
            for {} lt(l, h) {} {
                let m := shr(1, add(l, h)) // Won't overflow in practice.
                if iszero(lt(key, and(sload(add(m, lengthSlot)), 0xffffffffffff))) {
                    l := add(1, m)
                    continue
                }
                h := m
            }
            if h {
                let checkpointSlot := add(sub(h, 1), lengthSlot)
                result := shr(96, sload(checkpointSlot))
                if eq(result, address()) { result := sload(not(checkpointSlot)) }
            }
        }
    }
}
