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

    /// @dev The timepoint is in the future.
    error ERC5805FutureLookup();

    /// @dev The ERC5805 signature to set a delegate has expired.
    error ERC5805DelegateSignatureExpired();

    /// @dev The ERC5805 signature to set a delegate is invalid.
    error ERC5805DelegateInvalidSignature();

    /// @dev Out-of-bounds access for the checkpoints.
    error ERC5805CheckpointIndexOutOfBounds();

    /// @dev Arithmetic overflow when pushing a new checkpoint.
    error ERC5805CheckpointValueOverflow();

    /// @dev Arithmetic underflow when pushing a new checkpoint.
    error ERC5805CheckpointValueUnderflow();

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
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev `keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")`.
    bytes32 private constant _DOMAIN_TYPEHASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    /// @dev `keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)")`.
    bytes32 private constant _ERC5805_DELEGATION_TYPEHASH =
        0xe48329057bfd03d55e49b547132e39cffd9c1820ad7b9d4c5307691425d15adf;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The slot of a delegate is given by:
    /// ```
    ///     mstore(0x04, _ERC20_VOTES_MASTER_SLOT_SEED)
    ///     mstore(0x00, account)
    ///     let delegateSlot := keccak256(0x0c, 0x18)
    /// ```
    /// The checkpoints length slot of a delegate is given by:
    /// ```
    ///     mstore(0x04, _ERC20_VOTES_MASTER_SLOT_SEED)
    ///     mstore(0x00, delegate)
    ///     let lengthSlot := keccak256(0x0c, 0x17)
    ///     let length := and(0xffffffffffff, shr(48, sload(lengthSlot)))
    /// ```
    /// The total checkpoints length slot is `_ERC20_VOTES_MASTER_SLOT_SEED << 96`.
    ///
    /// The `i`-th checkpoint slot is given by:
    /// ```
    ///     let checkpointSlot := add(i, lengthSlot)
    ///     let key := and(sload(checkpointSlot), 0xffffffffffff)
    ///     let value := shr(96, sload(checkpointSlot))
    ///     if eq(value, address()) { value := sload(not(checkpointSlot)) }
    /// ```
    uint256 private constant _ERC20_VOTES_MASTER_SLOT_SEED = 0xff466c9f;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          ERC6372                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the clock mode.
    function CLOCK_MODE() public view virtual returns (string memory) {
        return "mode=blocknumber&from=default";
    }

    /// @dev Returns the current clock.
    function clock() public view virtual returns (uint48 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := number()
            // Branch-less out-of-gas revert if `block.number >= 2 ** 48`.
            returndatacopy(returndatasize(), returndatasize(), sub(0, shr(48, number())))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          ERC5805                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the latest amount of voting units for `account`.
    function getVotes(address account) public view virtual returns (uint256) {
        return _checkpointLatest(_delegateCheckpointsSlot(account));
    }

    /// @dev Returns the latest amount of voting units `account` has before or during `timepoint`.
    function getPastVotes(address account, uint256 timepoint)
        public
        view
        virtual
        returns (uint256)
    {
        if (timepoint >= clock()) _revertERC5805FutureLookup();
        return _checkpointUpperLookupRecent(_delegateCheckpointsSlot(account), timepoint);
    }

    /// @dev Returns the current voting delegate of `delegator`.
    function delegates(address delegator) public view virtual returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x04, _ERC20_VOTES_MASTER_SLOT_SEED)
            mstore(0x00, delegator)
            result := sload(keccak256(0x0c, 0x18))
        }
    }

    /// @dev Set the voting delegate of the caller to `delegatee`.
    function delegate(address delegatee) public virtual {
        _delegate(msg.sender, delegatee);
    }

    /// @dev Sets the voting delegate of the signature signer to `delegatee`.
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        address signer;
        bytes32 nameHash = _constantNameHash();
        //  We simply calculate it on-the-fly to allow for cases where the `name` may change.
        if (nameHash == bytes32(0)) nameHash = keccak256(bytes(name()));
        bytes32 versionHash = _versionHash();
        /// @solidity memory-safe-assembly
        assembly {
            if gt(timestamp(), expiry) {
                mstore(0x00, 0x3480e9e1) // `ERC5805DelegateSignatureExpired()`.
                revert(0x1c, 0x04)
            }
            let m := mload(0x40)
            // Prepare the struct hash.
            mstore(0x00, _ERC5805_DELEGATION_TYPEHASH)
            mstore(0x20, shr(96, shl(96, delegatee)))
            mstore(0x40, nonce)
            mstore(0x60, expiry)
            mstore(0x40, keccak256(0x00, 0x80))
            mstore(0x00, 0x1901) // Store "\x19\x01".
            // Prepare the domain separator.
            mstore(m, _DOMAIN_TYPEHASH)
            mstore(add(m, 0x20), nameHash)
            mstore(add(m, 0x40), versionHash)
            mstore(add(m, 0x60), chainid())
            mstore(add(m, 0x80), address())
            mstore(0x20, keccak256(m, 0xa0))
            // Prepare the ecrecover calldata.
            mstore(0x00, keccak256(0x1e, 0x42))
            mstore(0x20, and(0xff, v))
            mstore(0x40, r)
            mstore(0x60, s)
            signer := mload(staticcall(gas(), 1, 0x00, 0x80, 0x01, 0x20))
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero pointer.
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            expiry := iszero(returndatasize()) // Reuse `expiry` to denote `ecrecover` failure.
        }
        if ((nonces(signer) ^ nonce) | expiry != 0) {
            /// @solidity memory-safe-assembly
            assembly {
                mstore(0x00, 0x1838d95c) // `ERC5805DelegateInvalidSignature()`.
                revert(0x1c, 0x04)
            }
        }
        _incrementNonce(signer);
        _delegate(signer, delegatee);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              OTHER VOTE PUBLIC VIEW FUNCTIONS              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the number of checkpoints for `account`.
    function checkpointCount(address account) public view virtual returns (uint256 result) {
        result = _delegateCheckpointsSlot(account);
        /// @solidity memory-safe-assembly
        assembly {
            result := shr(208, shl(160, sload(result)))
        }
    }

    /// @dev Returns the voting checkpoint for `account` at index `i`.
    function checkpointAt(address account, uint256 i)
        public
        view
        virtual
        returns (uint48 checkpointClock, uint256 checkpointValue)
    {
        uint256 lengthSlot = _delegateCheckpointsSlot(account);
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(lt(i, shr(208, shl(160, sload(lengthSlot))))) {
                mstore(0x00, 0x86df9d10) // `ERC5805CheckpointIndexOutOfBounds()`.
                revert(0x1c, 0x04)
            }
            let checkpointPacked := sload(add(i, lengthSlot))
            checkpointClock := and(0xffffffffffff, checkpointPacked)
            checkpointValue := shr(96, checkpointPacked)
            if eq(checkpointValue, address()) { checkpointValue := sload(not(add(i, lengthSlot))) }
        }
    }

    /// @dev Returns the latest amount of total voting units.
    function getVotesTotalSupply() public view virtual returns (uint256) {
        return _checkpointLatest(_ERC20_VOTES_MASTER_SLOT_SEED << 96);
    }

    /// @dev Returns the latest amount of total voting units before or during `timepoint`.
    function getPastVotesTotalSupply(uint256 timepoint) public view virtual returns (uint256) {
        if (timepoint >= clock()) _revertERC5805FutureLookup();
        return _checkpointUpperLookupRecent(_ERC20_VOTES_MASTER_SLOT_SEED << 96, timepoint);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the amount of voting units `delegator` has control over.
    /// Override if you need a different formula.
    function _getVotingUnits(address delegator) internal view virtual returns (uint256) {
        return balanceOf(delegator);
    }

    /// @dev ERC20 after token transfer internal hook.
    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        virtual
        override
    {
        _transferVotingUnits(from, to, amount);
    }

    /// @dev Used in `_afterTokenTransfer(address from, address to, uint256 amount)`.
    function _transferVotingUnits(address from, address to, uint256 amount) internal virtual {
        if (from == address(0)) {
            _checkpointPushDiff(_ERC20_VOTES_MASTER_SLOT_SEED << 96, clock(), amount, true);
        }
        if (to == address(0)) {
            _checkpointPushDiff(_ERC20_VOTES_MASTER_SLOT_SEED << 96, clock(), amount, false);
        }
        _moveDelegateVotes(delegates(from), delegates(to), amount);
    }

    /// @dev Transfer `amount` of delegated votes from `from` to `to`.
    /// Emits a {DelegateVotesChanged} event for each change of delegated votes.
    function _moveDelegateVotes(address from, address to, uint256 amount) internal virtual {
        if (amount == uint256(0)) return;
        (uint256 fromCleaned, uint256 toCleaned) = (uint256(uint160(from)), uint256(uint160(to)));
        if (fromCleaned == toCleaned) return;
        if (fromCleaned != 0) {
            (uint256 oldValue, uint256 newValue) =
                _checkpointPushDiff(_delegateCheckpointsSlot(from), clock(), amount, false);
            /// @solidity memory-safe-assembly
            assembly {
                // Emit the {DelegateVotesChanged} event.
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
                // Emit the {DelegateVotesChanged} event.
                mstore(0x00, oldValue)
                mstore(0x20, newValue)
                log2(0x00, 0x40, _DELEGATE_VOTES_CHANGED_EVENT_SIGNATURE, toCleaned)
            }
        }
    }

    /// @dev Delegates all of `account`'s voting units to `delegatee`.
    /// Emits the {DelegateChanged} and {DelegateVotesChanged} events.
    function _delegate(address account, address delegatee) internal virtual {
        address from;
        /// @solidity memory-safe-assembly
        assembly {
            let to := shr(96, shl(96, delegatee))
            mstore(0x04, _ERC20_VOTES_MASTER_SLOT_SEED)
            mstore(0x00, account)
            let delegateSlot := keccak256(0x0c, 0x18)
            from := sload(delegateSlot)
            sstore(delegateSlot, to)
            // Emit the {DelegateChanged} event.
            log4(0x00, 0x00, _DELEGATE_CHANGED_EVENT_SIGNATURE, shr(96, mload(0x0c)), from, to)
        }
        _moveDelegateVotes(from, delegatee, _getVotingUnits(account));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the delegate checkpoints slot for `account`.
    function _delegateCheckpointsSlot(address account) private pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x04, _ERC20_VOTES_MASTER_SLOT_SEED)
            mstore(0x00, account)
            result := keccak256(0x0c, 0x17)
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
                        mstore(0x00, 0x5915f686) // `ERC5805CheckpointValueUnderflow()`.
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
                        newValue := sub(oldValue, amount)
                        if iszero(gt(newValue, oldValue)) { break }
                        mstore(0x00, 0x5915f686) // `ERC5805CheckpointValueUnderflow()`.
                        revert(0x1c, 0x04)
                    }
                    newValue := add(oldValue, amount)
                    if iszero(lt(newValue, oldValue)) { break }
                    mstore(0x00, 0x9dbbeb75) // `ERC5805CheckpointValueOverflow()`.
                    revert(0x1c, 0x04)
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
                lengthSlot := add(sub(result, 1), lengthSlot) // Reuse for `checkpointSlot`.
                result := shr(96, sload(lengthSlot))
                if eq(result, address()) { result := sload(not(lengthSlot)) }
            }
        }
    }

    /// @dev Returns checkpoint value with the largest key that is less than or equal to `key`.
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
            for {} iszero(lt(h, 6)) {} {
                let m := shl(4, lt(0xffff, h))
                m := shl(shr(1, or(m, shl(3, lt(0xff, shr(m, h))))), 16)
                m := shr(1, add(m, div(h, m)))
                m := shr(1, add(m, div(h, m)))
                m := shr(1, add(m, div(h, m)))
                m := shr(1, add(m, div(h, m)))
                m := shr(1, add(m, div(h, m)))
                m := sub(h, shr(1, add(m, div(h, m)))) // Approx `h - sqrt(h)`.
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
            let checkpointSlot := add(sub(h, 1), lengthSlot)
            result := mul(iszero(iszero(h)), shr(96, sload(checkpointSlot)))
            if eq(result, address()) { result := sload(not(checkpointSlot)) }
        }
    }

    /// @dev Reverts with `ERC5805FutureLookup()`.
    function _revertERC5805FutureLookup() private pure {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0xf9874464) // `ERC5805FutureLookup()`.
            revert(0x1c, 0x04)
        }
    }
}
