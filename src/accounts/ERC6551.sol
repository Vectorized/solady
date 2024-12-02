// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Receiver} from "./Receiver.sol";
import {ERC1271} from "./ERC1271.sol";
import {LibZip} from "../utils/LibZip.sol";
import {UUPSUpgradeable} from "../utils/UUPSUpgradeable.sol";

/// @notice Simple ERC6551 account implementation.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/accounts/ERC6551.sol)
/// @author ERC6551 team (https://github.com/erc6551/reference/blob/main/src/examples/upgradeable/ERC6551AccountUpgradeable.sol)
///
/// @dev Recommended usage (regular):
/// 1. Deploy the ERC6551 as an implementation contract, and verify it on Etherscan.
/// 2. Use the canonical ERC6551Registry to deploy a clone to the ERC6551 implementation.
///    The UUPSUpgradeable functions will simply become no-ops.
///
/// Recommended usage (upgradeable):
/// 1. Deploy the ERC6551 as an implementation contract, and verify it on Etherscan.
/// 2. Deploy the ERC6551Proxy pointing to the implementation.
///    This relay proxy is required, but Etherscan verification of it is optional.
/// 3. Use the canonical ERC6551Registry to deploy a clone to the ERC6551Proxy.
///    If you want to reveal the "Read as Proxy" and "Write as Proxy" tabs on Etherscan,
///    send 0 ETH to the clone to initialize its ERC1967 implementation slot,
///    the click on "Is this a proxy?" on the clone's page on Etherscan.
///
/// Note:
/// - This implementation does NOT include ERC4337 functionality.
///   This is intentional, because the canonical ERC4337 entry point may still change and we
///   don't want to encourage upgradeability by default for ERC6551 accounts just to handle this.
///   We may include ERC4337 functionality once ERC4337 has been finalized.
///   Recent updates to the account abstraction validation scope rules
///   [ERC7562](https://eips.ethereum.org/EIPS/eip-7562) has made ERC6551 compatible with ERC4337.
///   For an opinionated implementation, see https://github.com/tokenbound/contracts.
///   If you want to add it yourself, you'll just need to add in the
///   user operation validation functionality (and use ERC6551's execution functionality).
/// - Please refer to the official [ERC6551](https://github.com/erc6551/reference) reference
///   for latest updates on the ERC6551 standard, as well as canonical registry information.
abstract contract ERC6551 is UUPSUpgradeable, Receiver, ERC1271 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Call struct for the `executeBatch` function.
    struct Call {
        address target;
        uint256 value;
        bytes data;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The caller is not authorized to call the function.
    error Unauthorized();

    /// @dev The operation is not supported.
    error OperationNotSupported();

    /// @dev Self ownership detected.
    error SelfOwnDetected();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  CONSTANTS AND IMMUTABLES                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ERC6551 state slot is given by:
    /// `bytes32(~uint256(uint32(bytes4(keccak256("_ERC6551_STATE_SLOT_NOT")))))`.
    /// It is intentionally chosen to be a high value
    /// to avoid collision with lower slots.
    /// The choice of manual storage layout is to enable compatibility
    /// with both regular and upgradeable contracts.
    uint256 internal constant _ERC6551_STATE_SLOT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffb919c7a5;

    /// @dev Caches the chain ID in the deployed bytecode,
    /// so that in the rare case of a hard fork, `owner` will still work.
    uint256 private immutable _cachedChainId = block.chainid;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              TOKEN-BOUND OWNERSHIP OPERATIONS              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the token-bound information.
    function token()
        public
        view
        virtual
        returns (uint256 chainId, address tokenContract, uint256 tokenId)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            extcodecopy(address(), 0x00, 0x4d, 0x60)
            chainId := mload(0x00)
            tokenContract := mload(0x20) // Upper 96 bits will be clean.
            tokenId := mload(0x40)
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Returns the owner of the contract.
    function owner() public view virtual returns (address result) {
        uint256 cachedChainId = _cachedChainId;
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            extcodecopy(address(), 0x00, 0x4d, 0x60)
            if eq(mload(0x00), cachedChainId) {
                let tokenContract := mload(0x20)
                // `tokenId` is already at 0x40.
                mstore(0x20, 0x6352211e) // `ownerOf(uint256)`.
                result :=
                    mul( // Returns `address(0)` on failure or if contract does not exist.
                        mload(0x20),
                        and(
                            gt(returndatasize(), 0x1f),
                            staticcall(gas(), tokenContract, 0x3c, 0x24, 0x20, 0x20)
                        )
                    )
            }
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Returns if `signer` is an authorized signer.
    /// `extraData` can be anything (e.g. an address, a pointer to a struct / string in memory).
    function _isValidSigner(address signer, bytes32 extraData, bytes calldata context)
        internal
        view
        virtual
        returns (bool)
    {
        extraData = extraData; // Silence unused variable warning.
        context = context; // Silence unused variable warning.
        return signer == owner();
    }

    /// @dev Returns if `signer` is an authorized signer, with an optional `context`.
    /// MUST return the bytes4 magic value `0x523e3260` if the given signer is valid.
    /// By default, the holder of the non-fungible token the account is bound to
    /// MUST be considered a valid signer.
    function isValidSigner(address signer, bytes calldata context)
        public
        view
        virtual
        returns (bytes4 result)
    {
        bool isValid = _isValidSigner(signer, bytes32(0), context);
        /// @solidity memory-safe-assembly
        assembly {
            // `isValid ? bytes4(keccak256("isValidSigner(address,bytes)")) : 0x00000000`.
            // We use `0x00000000` for invalid, in convention with the reference implementation.
            result := shl(224, mul(0x523e3260, iszero(iszero(isValid))))
        }
    }

    /// @dev Returns empty calldata bytes.
    function _emptyContext() internal pure returns (bytes calldata context) {
        /// @solidity memory-safe-assembly
        assembly {
            context.length := 0
        }
    }

    /// @dev Requires that the caller is a valid signer (i.e. the owner).
    modifier onlyValidSigner() virtual {
        if (!_isValidSigner(msg.sender, bytes32(0), _emptyContext())) revert Unauthorized();
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      STATE OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the current value of the state.
    function state() public view virtual returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(_ERC6551_STATE_SLOT)
        }
    }

    /// @dev Mutates the state. This function is required to be called in every
    /// public / external function that may modify storage or emit events.
    function _updateState() internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            let s := _ERC6551_STATE_SLOT
            let m := mload(0x40)
            mstore(m, sload(s))
            mstore(add(0x20, m), 0x40)
            mstore(add(0x40, m), calldatasize())
            calldatacopy(add(0x60, m), 0x00, add(0x20, calldatasize()))
            sstore(s, keccak256(m, and(add(0x7f, calldatasize()), not(0x1f))))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    EXECUTION OPERATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Execute a call from this account.
    /// Reverts and bubbles up error if operation fails.
    /// Returns the result of the operation.
    ///
    /// Accounts MUST accept the following operation parameter values:
    /// - 0 = CALL
    /// - 1 = DELEGATECALL
    /// - 2 = CREATE
    /// - 3 = CREATE2
    ///
    /// Accounts MAY support additional operations or restrict a signer's
    /// ability to execute certain operations.
    function execute(address target, uint256 value, bytes calldata data, uint8 operation)
        public
        payable
        virtual
        onlyValidSigner
        returns (bytes memory result)
    {
        if (operation != 0) revert OperationNotSupported();
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            calldatacopy(result, data.offset, data.length)
            if iszero(call(gas(), target, value, result, data.length, codesize(), 0x00)) {
                // Bubble up the revert if the call reverts.
                returndatacopy(result, 0x00, returndatasize())
                revert(result, returndatasize())
            }
            mstore(result, returndatasize()) // Store the length.
            let o := add(result, 0x20)
            returndatacopy(o, 0x00, returndatasize()) // Copy the returndata.
            mstore(0x40, add(o, returndatasize())) // Allocate the memory.
        }
        _updateState();
    }

    /// @dev Execute a sequence of calls from this account.
    /// Reverts and bubbles up error if an operation fails.
    /// Returns the results of the operations.
    ///
    /// This is a batch variant of `execute` and is not required for `IERC6551Executable`.
    function executeBatch(Call[] calldata calls, uint8 operation)
        public
        payable
        virtual
        onlyValidSigner
        returns (bytes[] memory results)
    {
        if (operation != 0) revert OperationNotSupported();
        /// @solidity memory-safe-assembly
        assembly {
            results := mload(0x40)
            mstore(results, calls.length)
            let r := add(0x20, results)
            let m := add(r, shl(5, calls.length))
            calldatacopy(r, calls.offset, shl(5, calls.length))
            for { let end := m } iszero(eq(r, end)) { r := add(r, 0x20) } {
                let e := add(calls.offset, mload(r))
                let o := add(e, calldataload(add(e, 0x40)))
                calldatacopy(m, add(o, 0x20), calldataload(o))
                // forgefmt: disable-next-item
                if iszero(call(gas(), calldataload(e), calldataload(add(e, 0x20)),
                    m, calldataload(o), codesize(), 0x00)) {
                    // Bubble up the revert if the call reverts.
                    returndatacopy(m, 0x00, returndatasize())
                    revert(m, returndatasize())
                }
                mstore(r, m) // Append `m` into `results`.
                mstore(m, returndatasize()) // Store the length,
                let p := add(m, 0x20)
                returndatacopy(p, 0x00, returndatasize()) // and copy the returndata.
                m := add(p, returndatasize()) // Advance `m`.
            }
            mstore(0x40, m) // Allocate the memory.
        }
        _updateState();
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           ERC165                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns true if this contract implements the interface defined by `interfaceId`.
    /// See: https://eips.ethereum.org/EIPS/eip-165
    /// This function call must use less than 30000 gas.
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            let s := shr(224, interfaceId)
            // ERC165: 0x01ffc9a7, ERC6551: 0x6faff5f1, ERC6551Executable: 0x51945447.
            result := or(or(eq(s, 0x01ffc9a7), eq(s, 0x6faff5f1)), eq(s, 0x51945447))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      INTERNAL HELPERS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns whether there is an ownership cycle.
    function _hasOwnershipCycle() internal view virtual returns (bool result) {
        uint256 cachedChainId = _cachedChainId;
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            extcodecopy(address(), 0x00, 0x4d, 0x60) // `(chainId, tokenContract, tokenId)`.
            mstore(0x60, 0xfc0c546a) // `token()`.
            for {} 1 {} {
                let tokenContract := mload(0x20)
                mstore(0x20, 0x6352211e) // `ownerOf(uint256)`.
                let currentOwner :=
                    mul( // `chainId == cachedChainId ? tokenContract.ownerOf(tokenId) : address(0)`.
                        mload(0x20),
                        and(
                            and(gt(returndatasize(), 0x1f), eq(mload(0x00), cachedChainId)),
                            staticcall(gas(), tokenContract, 0x3c, 0x24, 0x20, 0x20)
                        )
                    )
                if iszero(eq(currentOwner, address())) {
                    if iszero(
                        and( // `(chainId, tokenContract, tokenId) = currentOwner.token()`.
                            gt(returndatasize(), 0x5f),
                            staticcall(gas(), currentOwner, 0x7c, 0x04, 0x00, 0x60)
                        )
                    ) { break }
                    continue
                }
                result := 1
                break
            }
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero pointer.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OVERRIDES                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev To ensure that only the owner or the account itself can upgrade the implementation.
    /// If you don't need upgradeability, override this function to return false.
    function _authorizeUpgrade(address)
        internal
        virtual
        override(UUPSUpgradeable)
        onlyValidSigner
    {
        _updateState();
    }

    /// @dev Uses the `owner` as the ERC1271 signer.
    function _erc1271Signer() internal view virtual override(ERC1271) returns (address) {
        return owner();
    }

    /// @dev For handling token callbacks.
    /// Safe-transferred ERC721 tokens will trigger a ownership cycle check.
    modifier receiverFallback() override(Receiver) {
        uint256 s = uint256(bytes32(msg.sig)) >> 224;
        // 0x150b7a02: `onERC721Received(address,address,uint256,bytes)`.
        if (s == 0x150b7a02) {
            if (!_hasOwnershipCycle()) {
                /// @solidity memory-safe-assembly
                assembly {
                    mstore(0x20, s) // Store `msg.sig`.
                    return(0x3c, 0x20) // Return `msg.sig`.
                }
            }
            /// @solidity memory-safe-assembly
            assembly {
                mstore(0x00, 0xaed146d3) // `SelfOwnDetected()`.
                revert(0x1c, 0x04)
            }
        }
        /// @solidity memory-safe-assembly
        assembly {
            // 0xf23a6e61: `onERC1155Received(address,address,uint256,uint256,bytes)`.
            // 0xbc197c81: `onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)`.
            if or(eq(s, 0xf23a6e61), eq(s, 0xbc197c81)) {
                mstore(0x20, s) // Store `msg.sig`.
                return(0x3c, 0x20) // Return `msg.sig`.
            }
        }
        _;
    }

    /// @dev If you don't need to use `LibZip.cdFallback`, override this function to return false.
    function _useLibZipCdFallback() internal view virtual returns (bool) {
        return true;
    }

    /// @dev Handle token callbacks. If no token callback is triggered,
    /// use `LibZip.cdFallback` for generalized calldata decompression.
    fallback() external payable virtual override(Receiver) receiverFallback {
        if (_useLibZipCdFallback()) {
            // Reverts with out-of-gas by recursing infinitely if the first 4 bytes
            // of the decompressed `msg.data` doesn't match any function selector.
            LibZip.cdFallback();
        } else {
            revert FnSelectorNotRecognized();
        }
    }
}
