// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Modern, minimalist, and gas efficient ERC721 implementation.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/tokens/ERC721.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokenss/ERC721.sol)
abstract contract ERC721 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The caller must own the token or be an approved operator.
    error CallerNotOwnerNorApproved();

    /// @dev The token does not exist.
    error TokenDoesNotExist();

    /// @dev The token already exists.
    error TokenAlreadyExists();

    /// @dev Cannot query the balance for the zero address.
    error BalanceQueryForZeroAddress();

    /// @dev Cannot transfer or mint to the zero address.
    error TransferToZeroAddress();

    /// @dev The token must be owned by `from`.
    error TransferFromIncorrectOwner();

    /// @dev Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
    error TransferToNonERC721ReceiverImplementer();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Emitted when `tokenId` token is transferred from `from` to `to`.
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /// @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /// @dev Emitted when `owner` enables or disables
    /// (`approved`) `operator` to manage all of its assets.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /// @dev `keccak256(bytes("Transfer(address,address,uint256)"))`.
    uint256 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    /// @dev `keccak256(bytes("Approval(address,address,uint256)"))`.
    uint256 private constant _APPROVAL_EVENT_SIGNATURE =
        0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925;

    /// @dev `keccak256(bytes("ApprovalForAll(address,address,bool)"))`.
    uint256 private constant _APPROVAL_FOR_ALL_EVENT_SIGNATURE =
        0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ownership data slot of (`tokenId`) is given by.
    /// ```
    ///     mstore(0x20, _OWNERSHIP_DATA_SLOT_SEED)
    ///     mstore(0x00, tokenId)
    ///     let ownershipDataSlot := keccak256(0x00, 0x40)
    /// ```
    /// Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `extraData`
    uint256 private constant _OWNERSHIP_DATA_SLOT_SEED = 0x1e498770;

    /// @dev The address data slot of `owner` is given by.
    /// ```
    ///     mstore(0x0c, _ADDRESS_DATA_SLOT_SEED)
    ///     mstore(0x00, owner)
    ///     let addressDataSlot := keccak256(0x0c, 0x20)
    /// ```
    /// Bits Layout:
    /// - [0..31]   `balance`
    /// - [32..225] `aux`
    uint256 private constant _ADDRESS_DATA_SLOT_SEED = 0xee1757ab;

    /// @dev The token approval slot of `owner` is given by.
    /// ```
    ///     mstore(0x0c, _TOKEN_APPROVAL_SLOT_SEED)
    ///     mstore(0x00, owner)
    ///     let tokenApprovalDataSlot := keccak256(0x0c, 0x20)
    /// ```
    uint256 private constant _TOKEN_APPROVAL_SLOT_SEED = 0x2f2069df;

    /// @dev The operator approval slot of `owner` is given by.
    /// ```
    ///     mstore(0x20, operator)
    ///     mstore(0x0c, _OPERATOR_APPROVAL_SLOT_SEED)
    ///     mstore(0x00, owner)
    ///     let operatorApprovalDataSlot := keccak256(0x0c, 0x34)
    /// ```
    uint256 private constant _OPERATOR_APPROVAL_SLOT_SEED = 0x7ee4befd;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC721 METADATA                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the token collection name.
    function name() public view virtual returns (string memory);

    /// @dev Returns the token collection symbol.
    function symbol() public view virtual returns (string memory);

    /// @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
    function tokenURI(uint256 tokenId) public view virtual returns (string memory);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           ERC721                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function ownerOf(uint256 tokenId) public view virtual returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, _OWNERSHIP_DATA_SLOT_SEED)
            mstore(0x00, tokenId)
            result := shr(96, shl(96, sload(keccak256(0x00, 0x40))))
        }
    }

    function balanceOf(address owner) public view virtual returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x0c, _ADDRESS_DATA_SLOT_SEED)
            mstore(0x00, owner)
            owner := shr(96, mload(0x0c))
            if iszero(owner) {
                mstore(0x00, 0x8f4eb604) // `BalanceQueryForZeroAddress()`.
                revert(0x1c, 0x04)
            }
            result := shr(96, shl(96, sload(keccak256(0x0c, 0x20))))
        }
    }
}
