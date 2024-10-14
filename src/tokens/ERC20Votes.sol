// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC20} from "./ERC20.sol";

/// @notice ERC20 with votes based on ERC5805 and ERC6372.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/tokens/ERC20Votes.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC20Votes.sol)
abstract contract ERC20Votes is ERC20 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ETH transfer has failed.
    error ERC5805FutureLookup();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The delegate of `delegator` is changed from `from` to `to`.
    event DelegateChanged(address indexed delegator, address indexed from, address indexed to);

    /// @dev The votes balance of `delegate` is changed from `oldValue` to `newValue`.
    event DelegateVotesChanged(address indexed delegate, uint256 oldValue, uint256 newValue);

    /// @dev `keccak256(bytes("DelegateChanged(address,address,address)"))`.
    uint256 private constant _DELEGATE_CHANGED_EVENT_SIGNATURE =
        0x3134e8a2e6d97e929a7e54011ea5485d7d196dd5f0ba4d4ef95803e8e3fc257f;

    /// @dev `keccak256(bytes("DelegateVotesChanged(address,uint256,uint256)"))`.
    uint256 private constant _DELEGATE_VOTES_CHANGED_EVENT_SIGNATURE =
        0xdec2bacdd2f05b59de34da9b523dff8be42e5e38e818c82fdb0bae774387a724;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The slot of a delegate is given by:
    /// ```
    ///     mstore(0x04, _ERC20_VOTES_MASTER_SLOT_SEED)
    ///     mstore(0x00, account)
    ///     let delegateSlot := keccak256(0x0c, 0x18)
    /// ```
    /// The checkpoints slot of a delegate is given by:
    /// ```
    ///     mstore(0x04, _ERC20_VOTES_MASTER_SLOT_SEED)
    ///     mstore(0x00, delegate)
    ///     let delegateCheckpointsSlot := keccak256(0x0c, 0x17)
    /// ```
    /// The total checkpoints slot is `_ERC20_VOTES_MASTER_SLOT_SEED`.
    uint256 private constant _ERC20_VOTES_MASTER_SLOT_SEED = 0xff466c9f;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          ERC6372                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function CLOCK_MODE() public view virtual returns (string memory) {
        return "mode=blocknumber&from=default";
    }

    function clock() public view returns (uint48) {
        if (block.number >= 2 ** 48) revert();
        return uint48(block.number);
    }

    function delegates(address delegator) public view virtual returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x04, _ERC20_VOTES_MASTER_SLOT_SEED)
            mstore(0x00, delegator)
            result := sload(keccak256(0x0c, 0x18))
        }
    }

    function delegate(address to) public virtual {
        _delegate(msg.sender, to);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _getVotingUnits(address delegator) internal virtual returns (uint256) {
        return balanceOf(delegator);
    }

    function _delegate(address delegator, address to) internal virtual {
        address from;
        /// @solidity memory-safe-assembly
        assembly {
            to := shr(96, shl(96, to))
            mstore(0x04, _ERC20_VOTES_MASTER_SLOT_SEED)
            mstore(0x00, delegator)
            let delegateSlot := keccak256(0x0c, 0x18)
            from := sload(delegateSlot)
            sstore(delegateSlot, to)
            log4(0x00, 0x00, _DELEGATE_CHANGED_EVENT_SIGNATURE, shr(96, mload(0x0c)), from, to)
        }
        _transferVotingUnits(from, to, _getVotingUnits(delegator));
    }

    /// @dev Used in `_afterTokenTransfer(address from, address to, uint256 amount)`.
    function _transferVotingUnits(address from, address to, uint256 amount) internal virtual {
        if (from == address(0)) {
            _checkpointPushDiff(_ERC20_VOTES_MASTER_SLOT_SEED, clock(), amount, true);
        }
        if (to == address(0)) {
            _checkpointPushDiff(_ERC20_VOTES_MASTER_SLOT_SEED, clock(), amount, false);
        }
        _moveDelegateVotes(delegates(from), delegates(to), amount);
    }

    function _moveDelegateVotes(address from, address to, uint256 amount) internal virtual {
        if (amount == uint256(0)) return;
        (uint256 fromCleaned, uint256 toCleaned) = (uint256(uint160(from)), uint256(uint160(to)));
        if (fromCleaned == toCleaned) return;
        if (fromCleaned != 0) {
            (uint256 oldValue, uint256 newValue) =
                _checkpointPushDiff(_delegateCheckpointsSlot(from), clock(), amount, false);
            /// @solidity memory-safe-assembly
            assembly {
                mstore(0x00, oldValue)
                mstore(0x20, newValue)
                log2(0x00, 0x40, _DELEGATE_VOTES_CHANGED_EVENT_SIGNATURE, fromCleaned)
            }
        }
        if (toCleaned != 0) {
            (uint256 oldValue, uint256 newValue) =
                _checkpointPushDiff(_delegateCheckpointsSlot(to), clock(), amount, true);
            /// @solidity memory-safe-assembly
            assembly {
                mstore(0x00, oldValue)
                mstore(0x20, newValue)
                log2(0x00, 0x40, _DELEGATE_VOTES_CHANGED_EVENT_SIGNATURE, toCleaned)
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function _delegateCheckpointsSlot(address account) private pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x04, _ERC20_VOTES_MASTER_SLOT_SEED)
            mstore(0x00, account)
            result := keccak256(0x0c, 0x17)
        }
    }

    function _checkpointPushDiff(uint256 lengthSlot, uint256 key, uint256 amount, bool isAdd)
        private
        returns (uint256 oldValue, uint256 newValue)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let n := sload(lengthSlot) // Checkpoint length. Must always be less than 2 ** 48.
            let checkpointSlot := shl(96, lengthSlot) // `lengthSlot` must never be zero.
            for {} 1 {} {
                if iszero(n) {
                    if iszero(or(isAdd, iszero(amount))) {
                        mstore(0x00, 0xef529cb2) // `ERC5805VoteCheckpointUnderflow()`.
                        revert(0x1c, 0x04)
                    }
                    newValue := amount
                    sstore(lengthSlot, 1)
                    if iszero(or(eq(newValue, address()), shr(208, newValue))) {
                        sstore(checkpointSlot, or(key, shl(48, newValue)))
                        break
                    }
                    sstore(checkpointSlot, or(key, shl(48, address())))
                    sstore(not(checkpointSlot), newValue)
                    break
                }
                checkpointSlot := add(sub(n, 1), checkpointSlot)
                let lastPacked := sload(checkpointSlot)
                oldValue := shr(48, lastPacked)
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
                if gt(lastKey, key) {
                    mstore(0x00, 0xce3d39b5) // `ERC5805VoteCheckpointUnorderedInsertion()`.
                    revert(0x1c, 0x04)
                }
                if iszero(eq(lastKey, key)) {
                    sstore(lengthSlot, add(n, 1))
                    checkpointSlot := add(1, checkpointSlot)
                }
                if iszero(or(eq(newValue, address()), shr(208, newValue))) {
                    sstore(checkpointSlot, or(key, shl(48, newValue)))
                    break
                }
                sstore(checkpointSlot, or(key, shl(48, address())))
                sstore(not(checkpointSlot), newValue)
                break
            }
        }
    }

    function _checkpointLatest(uint256 lengthSlot) private view returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let n := sload(lengthSlot) // Checkpoint length.
            if n {
                let checkpointSlot := add(sub(n, 1), shl(96, lengthSlot))
                result := shr(48, sload(checkpointSlot))
                if eq(result, address()) { result := sload(not(checkpointSlot)) }
            }
        }
    }

    function _checkpointUpperLookupRecent(uint256 lengthSlot, uint256 key)
        private
        view
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let n := sload(lengthSlot)
            let checkpointSlot := shl(96, lengthSlot)
            let l := 0 // Low.
            let h := n // High.
            for {} iszero(lt(n, 6)) {} {
                let m := shl(4, lt(0xffff, n))
                m := shl(shr(1, or(m, shl(3, lt(0xff, shr(m, n))))), 16)
                m := shr(1, add(m, div(n, m)))
                m := shr(1, add(m, div(n, m)))
                m := shr(1, add(m, div(n, m)))
                m := shr(1, add(m, div(n, m)))
                m := shr(1, add(m, div(n, m)))
                m := sub(n, shr(1, add(m, div(n, m)))) // Approx `n - sqrt(n)`.
                if iszero(lt(key, and(sload(add(m, checkpointSlot)), 0xffffffffffff))) {
                    l := add(1, m)
                    break
                }
                h := m
                break
            }
            for {} lt(l, h) {} {
                let m := shr(1, add(l, h)) // Won't overflow in practice.
                if iszero(lt(key, and(sload(add(m, checkpointSlot)), 0xffffffffffff))) {
                    l := add(1, m)
                    continue
                }
                h := m
            }
            if h {
                checkpointSlot := add(sub(h, 1), checkpointSlot)
                result := shr(48, sload(checkpointSlot))
                if eq(result, address()) { result := sload(not(checkpointSlot)) }
            }
        }
    }
}
