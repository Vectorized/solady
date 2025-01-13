// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Contract that enables a single call to call multiple methods on itself.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Multicallable.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Multicallable.sol)
///
/// WARNING:
/// This implementation is NOT to be used with ERC2771 out-of-the-box.
/// https://blog.openzeppelin.com/arbitrary-address-spoofing-vulnerability-erc2771context-multicall-public-disclosure
/// This also applies to potentially other ERCs / patterns appending to the back of calldata.
///
/// We do NOT have a check for ERC2771, as we do not inherit from OpenZeppelin's context.
/// Moreover, it is infeasible and inefficient for us to add checks and mitigations
/// for all possible ERC / patterns appending to the back of calldata.
///
/// We would highly recommend using an alternative pattern such as
/// https://github.com/Vectorized/multicaller
/// which is more flexible, futureproof, and safer by default.
abstract contract Multicallable {
    /// @dev Apply `delegatecall` with the current contract to each calldata in `data`,
    /// and store the `abi.encode` formatted results of each `delegatecall` into `results`.
    /// If any of the `delegatecall`s reverts, the entire context is reverted,
    /// and the error is bubbled up.
    ///
    /// By default, this function directly returns the results and terminates the call context.
    /// If you need to add before and after actions to the multicall, please override this function.
    function multicall(bytes[] calldata data) public payable virtual returns (bytes[] memory) {
        // Revert if `msg.value` is non-zero by default to guard against double-spending.
        // (See: https://www.paradigm.xyz/2021/08/two-rights-might-make-a-wrong)
        //
        // If you really need to pass in a `msg.value`, then you will have to
        // override this function and add in any relevant before and after checks.
        if (msg.value != 0) revert();
        // `_multicallDirectReturn` returns the results directly and terminates the call context.
        _multicallDirectReturn(_multicall(data));
    }

    /// @dev The inner logic of `multicall`.
    /// This function is included so that you can override `multicall`
    /// to add before and after actions, and use the `_multicallDirectReturn` function.
    function _multicall(bytes[] calldata data) internal virtual returns (bytes32 results) {
        /// @solidity memory-safe-assembly
        assembly {
            results := mload(0x40)
            mstore(results, 0x20)
            mstore(add(0x20, results), data.length)
            let c := add(0x40, results)
            let s := c
            let end := shl(5, data.length)
            calldatacopy(c, data.offset, end)
            end := add(c, end)
            let m := end
            if data.length {
                for {} 1 {} {
                    let o := add(data.offset, mload(c))
                    calldatacopy(m, add(o, 0x20), calldataload(o))
                    // forgefmt: disable-next-item
                    if iszero(delegatecall(gas(), address(), m, calldataload(o), codesize(), 0x00)) {
                        // Bubble up the revert if the delegatecall reverts.
                        returndatacopy(results, 0x00, returndatasize())
                        revert(results, returndatasize())
                    }
                    mstore(c, sub(m, s))
                    c := add(0x20, c)
                    // Append the `returndatasize()`, and the return data.
                    mstore(m, returndatasize())
                    let b := add(m, 0x20)
                    returndatacopy(b, 0x00, returndatasize())
                    // Advance `m` by `returndatasize() + 0x20`,
                    // rounded up to the next multiple of 32.
                    m := and(add(add(b, returndatasize()), 0x1f), 0xffffffffffffffe0)
                    mstore(add(b, returndatasize()), 0) // Zeroize the slot after the returndata.
                    if iszero(lt(c, end)) { break }
                }
            }
            mstore(0x40, m) // Allocate memory.
            results := or(shl(64, sub(m, results)), results) // Pack the bytes length into `results`.
        }
    }

    /// @dev Decodes the `results` into an array of bytes.
    /// This can be useful if you need to access the results or re-encode it.
    function _multicallResultsToBytesArray(bytes32 results)
        internal
        pure
        virtual
        returns (bytes[] memory decoded)
    {
        /// @solidity memory-safe-assembly
        assembly {
            decoded := mload(0x40)
            let c := and(0xffffffffffffffff, results) // Extract the offset.
            mstore(decoded, mload(add(c, 0x20))) // Store the length.
            let o := add(decoded, 0x20) // Start of elements in `decoded`.
            let end := add(o, shl(5, mload(decoded)))
            mstore(0x40, end) // Allocate memory.
            let s := add(c, 0x40) // Start of elements in `results`.
            let d := sub(s, o) // Difference between input and output pointers.
            for {} iszero(eq(o, end)) { o := add(o, 0x20) } { mstore(o, add(mload(add(d, o)), s)) }
        }
    }

    /// @dev Directly returns the `results` and terminates the current call context.
    /// `results` must be from `_multicall`, else behavior is undefined.
    function _multicallDirectReturn(bytes32 results) internal pure virtual {
        /// @solidity memory-safe-assembly
        assembly {
            return(and(0xffffffffffffffff, results), shr(64, results))
        }
    }
}
