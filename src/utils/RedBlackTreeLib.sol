// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for managing a red-black-tree in storage.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/RedBlackTreeLib.sol)
/// @author Modified from BokkyPooBahsRedBlackTreeLibrary (https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary)
library RedBlackTreeLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The value cannot be zero.
    error ValueIsEmpty();

    /// @dev Cannot insert a value that already exists.
    error ValueAlreadyExists();

    /// @dev Cannot remove a value that does not exist.
    error ValueDoesNotExist();

    /// @dev The pointer is out of bounds.
    error PointerOutOfBounds();

    /// @dev The tree is full.
    error TreeIsFull();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev A red-black-tree in storage.
    struct Tree {
        uint256 _spacer;
    }

    // Custom storage:
    // ```
    // mstore(0x20, _NODES_SLOT_SEED)
    // mstore(0x00, tree.slot)
    // let nodes := shl(_NODES_SLOT_SHIFT, keccak256(0x00, 0x40))
    //
    // let treePacked := sload(not(nodes))
    // let root := and(treePacked, _BITMASK_KEY)
    // let totalNodes := and(shr(_BITPOS_TOTAL_NODES, treePacked), _BITMASK_KEY)
    //
    // let nodePointer := or(nodes, nodeIndex)
    //
    // let nodePacked := sload(nodePointer)
    // let nodeLeft   := and(nodePacked, _BITMASK_KEY)
    // let nodeRight  := and(shr(_BITPOS_RIGHT, nodePacked), _BITMASK_KEY)
    // let nodeParent := and(shr(_BITPOS_PARENT, nodePacked), _BITMASK_KEY)
    // let nodeRed    := and(shr(_BITPOS_RED, nodePacked), 1)
    //
    // let nodeValue := shr(_BITPOS_PACKED_VALUE, nodePacked)
    // if iszero(nodeValue) {
    //     nodeValue := sload(or(_BIT_FULL_VALUE_SLOT, nodePointer))
    // }
    // ```

    uint256 private constant _NODES_SLOT_SEED = 0x846f2876cd72bffd;
    uint256 private constant _NODES_SLOT_SHIFT = 32;
    uint256 private constant _BITMASK_KEY = (1 << 31) - 1;
    uint256 private constant _BITPOS_ROOT = 0;
    uint256 private constant _BITPOS_TOTAL_NODES = 31;
    uint256 private constant _BITPOS_LEFT = 0;
    uint256 private constant _BITPOS_RIGHT = 31;
    uint256 private constant _BITPOS_PARENT = 31 * 2;
    uint256 private constant _BITPOS_RED = 31 * 3;
    uint256 private constant _BITWIDTH_PACKED_VALUE = 160;
    uint256 private constant _BITPOS_PACKED_VALUE = 96;
    uint256 private constant _BITMASK_PACKED_VALUE = (1 << 160) - 1;
    uint256 private constant _BIT_FULL_VALUE_SLOT = 1 << 31;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OPERATIONS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the number of values in the tree.
    function size(Tree storage tree) internal view returns (uint256 result) {
        uint256 nodes = _nodes(tree);
        /// @solidity memory-safe-assembly
        assembly {
            let treePacked := sload(not(nodes))
            result := and(shr(_BITPOS_TOTAL_NODES, treePacked), _BITMASK_KEY)
        }
    }

    /// @dev Returns a pointer to the value `v`.
    /// If the value is not in the tree, the returned pointer will be empty.
    function find(Tree storage tree, uint256 v) internal view returns (bytes32 result) {
        (uint256 nodes,, uint256 found) = _find(tree, v);
        /// @solidity memory-safe-assembly
        assembly {
            result := mul(or(nodes, found), iszero(iszero(found)))
        }
    }

    /// @dev Returns whether the value `v` exists.
    function exists(Tree storage tree, uint256 v) internal view returns (bool result) {
        (,, uint256 found) = _find(tree, v);
        result = found != 0;
    }

    /// @dev Inserts the value `v` into the tree.
    /// Reverts if the value already exists.
    function insert(Tree storage tree, uint256 v) internal {
        (uint256 nodes, uint256 cursor, uint256 found) = _find(tree, v);
        tree._spacer = cursor;
        _update(nodes, cursor, found, v, 0);
    }

    /// @dev Removes the value `v` from the tree.
    /// Reverts if the value does not exist.
    function remove(Tree storage tree, uint256 v) internal {
        (uint256 nodes, uint256 cursor, uint256 found) = _find(tree, v);
        _update(nodes, cursor, found, v, 1);
    }

    /// @dev Removes the pointer's value from the tree.
    /// Reverts if the value does not exist.
    /// An empty or invalid pointer is equivalent to a non-existent value.
    function remove(bytes32 pointer) internal {
        (uint256 nodes, uint256 key) = _unpack(pointer);
        _update(nodes, 0, key, 0, 1);
    }

    /// @dev Returns the value at `pointer`.
    function value(bytes32 pointer) internal view returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            if pointer {
                let packed := sload(pointer)
                result := shr(_BITPOS_PACKED_VALUE, packed)
                if iszero(result) { result := sload(or(pointer, _BIT_FULL_VALUE_SLOT)) }
            }
        }
    }

    /// @dev Returns a pointer to the smallest value in the tree.
    /// If the tree is empty, the returned pointer will be empty.
    function first(Tree storage tree) internal view returns (bytes32 result) {
        result = _end(tree, _BITPOS_LEFT);
    }

    /// @dev Returns a pointer to the largest value in the tree.
    /// If the tree is empty, the returned pointer will be empty.
    function last(Tree storage tree) internal view returns (bytes32 result) {
        result = _end(tree, _BITPOS_RIGHT);
    }

    /// @dev Returns the pointer to the next largest value.
    /// If there is no next value, the returned pointer will be empty.
    function next(bytes32 pointer) internal view returns (bytes32 result) {
        result = _step(pointer, _BITPOS_LEFT, _BITPOS_RIGHT);
    }

    /// @dev Returns the pointer to the next smallest value.
    /// If there is no previous value, the returned pointer will be empty.
    function prev(bytes32 pointer) internal view returns (bytes32 result) {
        result = _step(pointer, _BITPOS_RIGHT, _BITPOS_LEFT);
    }

    /// @dev Returns whether the `pointer` is empty.
    function isEmpty(bytes32 pointer) internal pure returns (bool result) {
        result = pointer == bytes32(0);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unpacks the `pointer` to its components.
    function _unpack(bytes32 pointer) private pure returns (uint256 nodes, uint256 key) {
        /// @solidity memory-safe-assembly
        assembly {
            nodes := shl(_NODES_SLOT_SHIFT, shr(_NODES_SLOT_SHIFT, pointer))
            key := and(_BITMASK_KEY, pointer)
        }
    }

    /// @dev Returns the pointer to either end of the `tree`.
    function _end(Tree storage tree, uint256 L) private view returns (bytes32 result) {
        uint256 nodes = _nodes(tree);
        /// @solidity memory-safe-assembly
        assembly {
            let key := and(shr(_BITPOS_ROOT, sload(not(nodes))), _BITMASK_KEY)
            if key {
                for {} 1 {} {
                    let packed := sload(or(nodes, key))
                    let left := and(shr(L, packed), _BITMASK_KEY)
                    if iszero(left) { break }
                    key := left
                }
            }
            result := mul(or(nodes, key), iszero(iszero(key)))
        }
    }

    /// @dev Step the `pointer` forwards or backwards.
    function _step(bytes32 pointer, uint256 L, uint256 R) private view returns (bytes32 result) {
        (uint256 nodes, uint256 target) = _unpack(pointer);
        /// @solidity memory-safe-assembly
        assembly {
            let packed := sload(pointer)
            let cursor := and(shr(R, packed), _BITMASK_KEY)
            for {} 1 {} {
                if cursor {
                    for {} 1 {} {
                        packed := sload(or(nodes, cursor))
                        let left := and(shr(L, packed), _BITMASK_KEY)
                        if iszero(left) { break }
                        cursor := left
                    }
                    break
                }
                cursor := and(shr(_BITPOS_PARENT, packed), _BITMASK_KEY)
                for {} 1 {} {
                    if iszero(cursor) { break }
                    packed := sload(or(nodes, cursor))
                    let right := and(shr(R, packed), _BITMASK_KEY)
                    if iszero(eq(target, right)) { break }
                    target := cursor
                    cursor := and(shr(_BITPOS_PARENT, packed), _BITMASK_KEY)
                }
                break
            }
            result := mul(or(nodes, cursor), iszero(iszero(cursor)))
        }
    }

    /// @dev Inserts or delete.
    function _update(uint256 nodes, uint256 cursor, uint256 key, uint256 v, uint256 mode) private {
        /// @solidity memory-safe-assembly
        assembly {
            function getKey(packed_, bitpos_) -> index_ {
                index_ := and(shr(bitpos_, packed_), _BITMASK_KEY)
            }

            function setKey(packed_, bitpos_, value_) -> result_ {
                result_ := or(and(not(shl(bitpos_, _BITMASK_KEY)), packed_), shl(bitpos_, value_))
            }

            function setRed(packed_, value_) -> result_ {
                result_ := or(and(not(shl(_BITPOS_RED, 1)), packed_), shl(_BITPOS_RED, value_))
            }

            function isRed(packed_) -> red_ {
                red_ := and(shl(_BITPOS_RED, 1), packed_)
            }

            function copyRed(packed_, fromPacked_) -> result_ {
                let mask_ := shl(_BITPOS_RED, 1)
                result_ := or(and(not(mask_), packed_), and(mask_, fromPacked_))
            }

            function rotate(nodes_, key_, L, R) {
                let packed_ := sload(or(nodes_, key_))
                let cursor_ := getKey(packed_, R)
                let parent_ := getKey(packed_, _BITPOS_PARENT)
                let cursorPacked_ := sload(or(nodes_, cursor_))
                let cursorLeft_ := getKey(cursorPacked_, L)

                if cursorLeft_ {
                    let s_ := or(nodes_, cursorLeft_)
                    sstore(s_, setKey(sload(s_), _BITPOS_PARENT, key_))
                }

                for {} 1 {} {
                    if iszero(parent_) {
                        mstore(0x00, setKey(mload(0x00), _BITPOS_ROOT, cursor_))
                        break
                    }
                    let s_ := or(nodes_, parent_)
                    let parentPacked_ := sload(s_)
                    if eq(key_, getKey(parentPacked_, L)) {
                        sstore(s_, setKey(parentPacked_, L, cursor_))
                        break
                    }
                    sstore(s_, setKey(parentPacked_, R, cursor_))
                    break
                }
                cursorPacked_ := setKey(cursorPacked_, _BITPOS_PARENT, parent_)
                sstore(or(nodes_, cursor_), setKey(cursorPacked_, L, key_))
                packed_ := setKey(packed_, R, cursorLeft_)
                sstore(or(nodes_, key_), setKey(packed_, _BITPOS_PARENT, cursor_))
            }

            function insertFixupUp(nodes_, key_) -> grandParent_ {
                let parent_ := getKey(sload(or(nodes_, key_)), _BITPOS_PARENT)
                let parentPacked_ := sload(or(nodes_, parent_))
                sstore(or(nodes_, parent_), setRed(parentPacked_, 0))
                grandParent_ := getKey(parentPacked_, _BITPOS_PARENT)
                sstore(or(nodes_, grandParent_), setRed(sload(or(nodes_, grandParent_)), 1))
            }

            function insertFixup(nodes_, key_) {
                for {} 1 {} {
                    if eq(key_, getKey(mload(0x00), _BITPOS_ROOT)) { break }
                    let packed_ := sload(or(nodes_, key_))
                    let parent_ := getKey(packed_, _BITPOS_PARENT)
                    let parentPacked_ := sload(or(nodes_, parent_))
                    if iszero(isRed(parentPacked_)) { break }

                    let grandParent_ := getKey(parentPacked_, _BITPOS_PARENT)
                    let grandParentPacked_ := sload(or(nodes_, grandParent_))

                    if eq(parent_, getKey(grandParentPacked_, _BITPOS_LEFT)) {
                        let cursor_ := getKey(grandParentPacked_, _BITPOS_RIGHT)
                        let cursorPacked_ := sload(or(nodes_, cursor_))
                        if iszero(isRed(cursorPacked_)) {
                            if eq(key_, getKey(parentPacked_, _BITPOS_RIGHT)) {
                                key_ := parent_
                                rotate(nodes_, key_, _BITPOS_LEFT, _BITPOS_RIGHT)
                            }
                            rotate(nodes_, insertFixupUp(nodes_, key_), _BITPOS_RIGHT, _BITPOS_LEFT)
                            continue
                        }
                        sstore(or(nodes_, parent_), setRed(parentPacked_, 0))
                        sstore(or(nodes_, cursor_), setRed(cursorPacked_, 0))
                        sstore(or(nodes_, grandParent_), setRed(grandParentPacked_, 1))
                        key_ := grandParent_
                        continue
                    }
                    let cursor_ := getKey(grandParentPacked_, _BITPOS_LEFT)
                    let cursorPacked_ := sload(or(nodes_, cursor_))
                    if iszero(isRed(cursorPacked_)) {
                        if eq(key_, getKey(parentPacked_, _BITPOS_LEFT)) {
                            key_ := parent_
                            rotate(nodes_, key_, _BITPOS_RIGHT, _BITPOS_LEFT)
                        }
                        rotate(nodes_, insertFixupUp(nodes_, key_), _BITPOS_LEFT, _BITPOS_RIGHT)
                        continue
                    }
                    sstore(or(nodes_, parent_), setRed(parentPacked_, 0))
                    sstore(or(nodes_, cursor_), setRed(cursorPacked_, 0))
                    sstore(or(nodes_, grandParent_), setRed(grandParentPacked_, 1))
                    key_ := grandParent_
                }
                let root_ := getKey(mload(0x00), _BITPOS_ROOT)
                sstore(or(nodes_, root_), setRed(sload(or(nodes_, root_)), 0))
            }

            function insert(nodes_, cursor_, key_, value_) {
                if key_ {
                    mstore(0x00, 0xbb33e6ac) // `ValueAlreadyExists()`.
                    revert(0x1c, 0x04) // Revert with (offset, size).
                }

                let treePacked_ := mload(0x00)
                let totalNodes_ := add(getKey(treePacked_, _BITPOS_TOTAL_NODES), 1)

                if gt(totalNodes_, _BITMASK_KEY) {
                    mstore(0x00, 0xed732d0c) // `TreeIsFull()`.
                    revert(0x1c, 0x04) // Revert with (offset, size).
                }

                treePacked_ := setKey(treePacked_, _BITPOS_TOTAL_NODES, totalNodes_)

                let packed_ := or(shl(_BITPOS_RED, 1), shl(_BITPOS_PARENT, cursor_))
                let nodePointer_ := or(nodes_, totalNodes_)

                for {} 1 {} {
                    if iszero(gt(value_, _BITMASK_PACKED_VALUE)) {
                        packed_ := or(shl(_BITPOS_PACKED_VALUE, value_), packed_)
                        break
                    }
                    sstore(or(nodePointer_, _BIT_FULL_VALUE_SLOT), value_)
                    break
                }
                sstore(nodePointer_, packed_)

                for {} 1 {} {
                    if iszero(cursor_) {
                        treePacked_ := setKey(treePacked_, _BITPOS_ROOT, totalNodes_)
                        break
                    }
                    let s_ := or(nodes_, cursor_)
                    let cursorPacked_ := sload(s_)
                    let cursorValue_ := shr(_BITPOS_PACKED_VALUE, cursorPacked_)
                    if iszero(cursorValue_) { cursorValue_ := sload(or(s_, _BIT_FULL_VALUE_SLOT)) }
                    if iszero(lt(value_, cursorValue_)) {
                        sstore(s_, setKey(cursorPacked_, _BITPOS_RIGHT, totalNodes_))
                        break
                    }
                    sstore(s_, setKey(cursorPacked_, _BITPOS_LEFT, totalNodes_))
                    break
                }
                mstore(0x00, treePacked_)
                insertFixup(nodes_, totalNodes_)
            }

            function removeFixupUp(nodes_, key_, L, R) -> o_ {
                let packed_ := sload(or(nodes_, key_))
                let parent_ := getKey(packed_, _BITPOS_PARENT)
                let parentPacked_ := sload(or(nodes_, parent_))
                let cursor_ := getKey(parentPacked_, R)
                let cursorPacked_ := sload(or(nodes_, cursor_))

                if isRed(cursorPacked_) {
                    sstore(or(nodes_, cursor_), setRed(cursorPacked_, 0))
                    sstore(or(nodes_, parent_), setRed(parentPacked_, 1))
                    rotate(nodes_, parent_, L, R)
                    cursor_ := getKey(sload(or(nodes_, parent_)), R)
                    cursorPacked_ := sload(or(nodes_, cursor_))
                }

                let cursorLeft_ := getKey(cursorPacked_, L)
                let cursorLeftPacked_ := sload(or(nodes_, cursorLeft_))
                let cursorRight_ := getKey(cursorPacked_, R)
                let cursorRightPacked_ := sload(or(nodes_, cursorRight_))

                if iszero(or(isRed(cursorLeftPacked_), isRed(cursorRightPacked_))) {
                    sstore(or(nodes_, cursor_), setRed(cursorPacked_, 1))
                    o_ := parent_
                    leave
                }

                if iszero(isRed(cursorRightPacked_)) {
                    sstore(or(nodes_, cursorLeft_), setRed(cursorLeftPacked_, 0))
                    sstore(or(nodes_, cursor_), setRed(cursorPacked_, 1))
                    rotate(nodes_, cursor_, R, L)
                    cursor_ := getKey(sload(or(nodes_, parent_)), R)
                    cursorPacked_ := sload(or(nodes_, cursor_))
                    cursorRight_ := getKey(cursorPacked_, R)
                    cursorRightPacked_ := sload(or(nodes_, cursorRight_))
                }

                parentPacked_ := sload(or(nodes_, parent_))
                sstore(or(nodes_, cursor_), copyRed(cursorPacked_, parentPacked_))
                sstore(or(nodes_, parent_), setRed(parentPacked_, 0))
                sstore(or(nodes_, cursorRight_), setRed(cursorRightPacked_, 0))
                rotate(nodes_, parent_, L, R)
                o_ := getKey(mload(0x00), _BITPOS_ROOT)
            }

            function removeFixup(nodes_, key_) {
                for {} 1 {} {
                    if eq(key_, getKey(mload(0x00), _BITPOS_ROOT)) { break }
                    let packed_ := sload(or(nodes_, key_))
                    if isRed(packed_) { break }

                    let parent_ := getKey(packed_, _BITPOS_PARENT)
                    let parentPacked_ := sload(or(nodes_, parent_))

                    if eq(key_, getKey(parentPacked_, _BITPOS_LEFT)) {
                        key_ := removeFixupUp(nodes_, key_, _BITPOS_LEFT, _BITPOS_RIGHT)
                        continue
                    }
                    key_ := removeFixupUp(nodes_, key_, _BITPOS_RIGHT, _BITPOS_LEFT)
                }
                sstore(or(nodes_, key_), setRed(sload(or(nodes_, key_)), 0))
            }

            function removeLast(nodes_, cursor_) {
                let treePacked_ := mload(0x00)

                let last_ := getKey(treePacked_, _BITPOS_TOTAL_NODES)
                let lastPacked_ := sload(or(nodes_, last_))
                let lastValue_ := shr(_BITPOS_PACKED_VALUE, lastPacked_)
                let lastFullValue_ := 0
                if iszero(lastValue_) {
                    lastValue_ := sload(or(_BIT_FULL_VALUE_SLOT, or(nodes_, last_)))
                    lastFullValue_ := lastValue_
                }

                let cursorPacked_ := sload(or(nodes_, cursor_))
                let cursorValue_ := shr(_BITPOS_PACKED_VALUE, cursorPacked_)
                let cursorFullValue_ := 0
                if iszero(cursorValue_) {
                    cursorValue_ := sload(or(_BIT_FULL_VALUE_SLOT, or(nodes_, cursor_)))
                    cursorFullValue_ := cursorValue_
                }

                if iszero(eq(lastValue_, cursorValue_)) {
                    sstore(or(nodes_, cursor_), lastPacked_)
                    if lastFullValue_ {
                        sstore(or(_BIT_FULL_VALUE_SLOT, or(nodes_, cursor_)), lastFullValue_)
                    }
                    for { let lastParent_ := getKey(lastPacked_, _BITPOS_PARENT) } 1 {} {
                        if iszero(lastParent_) {
                            treePacked_ := setKey(treePacked_, _BITPOS_ROOT, cursor_)
                            break
                        }
                        let s_ := or(nodes_, lastParent_)
                        let lastParentPacked_ := sload(s_)
                        if eq(last_, getKey(lastParentPacked_, _BITPOS_LEFT)) {
                            sstore(s_, setKey(lastParentPacked_, _BITPOS_LEFT, cursor_))
                            break
                        }
                        sstore(s_, setKey(lastParentPacked_, _BITPOS_RIGHT, cursor_))
                        break
                    }
                    let lastRight_ := getKey(lastPacked_, _BITPOS_RIGHT)
                    if lastRight_ {
                        let s_ := or(nodes_, lastRight_)
                        sstore(s_, setKey(sload(s_), _BITPOS_PARENT, cursor_))
                    }
                    let lastLeft_ := getKey(lastPacked_, _BITPOS_LEFT)
                    if lastLeft_ {
                        let s_ := or(nodes_, lastLeft_)
                        sstore(s_, setKey(sload(s_), _BITPOS_PARENT, cursor_))
                    }
                }
                sstore(or(nodes_, last_), 0)
                if lastFullValue_ { sstore(or(_BIT_FULL_VALUE_SLOT, or(nodes_, last_)), 0) }

                mstore(0x00, setKey(treePacked_, _BITPOS_TOTAL_NODES, sub(last_, 1)))
            }

            function remove(nodes_, key_) {
                let last_ := getKey(mload(0x00), _BITPOS_TOTAL_NODES)

                if gt(key_, last_) {
                    mstore(0x00, 0xccd52fbc) // `PointerOutOfBounds()`.
                    revert(0x1c, 0x04) // Revert with (offset, size).
                }
                if iszero(key_) {
                    mstore(0x00, 0xb113638a) // `ValueDoesNotExist()`.
                    revert(0x1c, 0x04) // Revert with (offset, size).
                }

                let cursor_ := 0

                for {} 1 {} {
                    let packed_ := sload(or(nodes_, key_))
                    let left_ := getKey(packed_, _BITPOS_LEFT)
                    let right_ := getKey(packed_, _BITPOS_RIGHT)
                    if iszero(mul(left_, right_)) {
                        cursor_ := key_
                        break
                    }
                    cursor_ := right_
                    for {} 1 {} {
                        let cursorLeft_ := getKey(sload(or(nodes_, cursor_)), _BITPOS_LEFT)
                        if iszero(cursorLeft_) { break }
                        cursor_ := cursorLeft_
                    }
                    break
                }

                let cursorPacked_ := sload(or(nodes_, cursor_))
                let probe_ := getKey(cursorPacked_, _BITPOS_LEFT)
                if iszero(probe_) { probe_ := getKey(cursorPacked_, _BITPOS_RIGHT) }

                for { let yParent_ := getKey(cursorPacked_, _BITPOS_PARENT) } 1 {} {
                    let probeSlot_ := or(nodes_, probe_)
                    sstore(probeSlot_, setKey(sload(probeSlot_), _BITPOS_PARENT, yParent_))

                    if iszero(yParent_) {
                        mstore(0x00, setKey(mload(0x00), _BITPOS_ROOT, probe_))
                        break
                    }
                    let yParentSlot_ := or(nodes_, yParent_)
                    let yParentPacked_ := sload(yParentSlot_)
                    let yParentLeft_ := getKey(yParentPacked_, _BITPOS_LEFT)
                    if eq(cursor_, yParentLeft_) {
                        sstore(yParentSlot_, setKey(yParentPacked_, _BITPOS_LEFT, probe_))
                        break
                    }
                    sstore(yParentSlot_, setKey(yParentPacked_, _BITPOS_RIGHT, probe_))
                    break
                }

                let skipFixup_ := isRed(cursorPacked_)

                if iszero(eq(cursor_, key_)) {
                    let packed_ := sload(or(nodes_, key_))
                    let parent_ := getKey(packed_, _BITPOS_PARENT)
                    cursorPacked_ := setKey(cursorPacked_, _BITPOS_PARENT, parent_)
                    for {} 1 {} {
                        if iszero(parent_) {
                            mstore(0x00, setKey(mload(0x00), _BITPOS_ROOT, cursor_))
                            break
                        }
                        let s_ := or(nodes_, parent_)
                        let parentPacked_ := sload(s_)
                        if eq(key_, getKey(parentPacked_, _BITPOS_LEFT)) {
                            sstore(s_, setKey(parentPacked_, _BITPOS_LEFT, cursor_))
                            break
                        }
                        sstore(s_, setKey(parentPacked_, _BITPOS_RIGHT, cursor_))
                        break
                    }

                    let left_ := getKey(packed_, _BITPOS_LEFT)
                    cursorPacked_ := setKey(cursorPacked_, _BITPOS_LEFT, left_)
                    sstore(
                        or(nodes_, left_), setKey(sload(or(nodes_, left_)), _BITPOS_PARENT, cursor_)
                    )

                    let right_ := getKey(packed_, _BITPOS_RIGHT)
                    cursorPacked_ := setKey(cursorPacked_, _BITPOS_RIGHT, right_)
                    sstore(
                        or(nodes_, right_),
                        setKey(sload(or(nodes_, right_)), _BITPOS_PARENT, cursor_)
                    )

                    cursorPacked_ := copyRed(cursorPacked_, packed_)
                    sstore(or(nodes_, cursor_), cursorPacked_)

                    let t_ := cursor_
                    cursor_ := key_
                    key_ := t_
                }
                if iszero(skipFixup_) { removeFixup(nodes_, probe_) }

                removeLast(nodes_, cursor_)
            }

            let treePacked := sload(not(nodes))
            mstore(0x00, treePacked)

            for {} 1 {} {
                if iszero(mode) {
                    insert(nodes, cursor, key, v)
                    break
                }
                remove(nodes, key)
                break
            }

            if iszero(eq(mload(0x00), treePacked)) { sstore(not(nodes), mload(0x00)) }
        }
    }

    /// @dev Returns the `nodes` pointer for `tree`.
    function _nodes(Tree storage tree) private pure returns (uint256 nodes) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, _NODES_SLOT_SEED)
            mstore(0x00, tree.slot)
            nodes := shl(_NODES_SLOT_SHIFT, keccak256(0x00, 0x40))
        }
    }

    /// @dev Finds `v` in `tree`.
    /// `key` will be zero if `v` is not found.
    function _find(Tree storage tree, uint256 v)
        private
        view
        returns (uint256 nodes, uint256 cursor, uint256 key)
    {
        nodes = _nodes(tree);
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(v) {
                mstore(0x00, 0xc94f1877) // `ValueIsEmpty()`.
                revert(0x1c, 0x04) // Revert with (offset, size).
            }

            let probe := and(shr(_BITPOS_ROOT, sload(not(nodes))), _BITMASK_KEY)
            for {} probe {} {
                cursor := probe
                let nodePointer := or(nodes, probe)
                let nodePacked := sload(nodePointer)
                let nodeValue := shr(_BITPOS_PACKED_VALUE, nodePacked)
                if iszero(nodeValue) { nodeValue := sload(or(nodePointer, _BIT_FULL_VALUE_SLOT)) }
                if eq(nodeValue, v) {
                    key := cursor
                    break
                }
                if iszero(lt(v, nodeValue)) {
                    probe := and(shr(_BITPOS_RIGHT, nodePacked), _BITMASK_KEY)
                    continue
                }
                probe := and(shr(_BITPOS_LEFT, nodePacked), _BITMASK_KEY)
            }
        }
    }
}
