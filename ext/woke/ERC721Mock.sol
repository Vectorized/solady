// SPDX-License-Identifier: MIT
import "src/tokens/ERC721.sol";
contract ERC721Mock is ERC721 {

    event BeforeTokenTransfer(address from, address to, uint256 id);

    event AfterTokenTransfer(address from, address to, uint256 id);

    uint256 private constant _ERC721_MASTER_SLOT_SEED = 0x7d8825530a5a2e7a << 192;
    /// @dev Returns the token collection name.
    function name() public view override returns (string memory) {
        return "Mock ERC721";
    }
    /// @dev Returns the token collection symbol.
    function symbol() public view override returns (string memory) {
        return "MERC721";
    }
    /// @dev Returns the Uniform Resource Identifier (URI) for token `id`.
    function tokenURI(uint256 id) public view override returns (string memory) {
        return "aaa";
    }
    function getAux(address owner) public view returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x1c, _ERC721_MASTER_SLOT_SEED)
            mstore(0x00, owner)
            result := shr(32, sload(keccak256(0x0c, 0x1c)))
        }
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 id
    ) internal override {
        emit BeforeTokenTransfer(from, to, id);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 id
    ) internal override {
        emit AfterTokenTransfer(from, to, id);
    }

    function mint(address to, uint256 id) public {
        _mint(to, id);
    }

    function burnZero(uint256 id) public {
        _burn(id);
    }

    function burn(uint256 id) public {
        _burn(msg.sender, id);
    }

    function transfer(address from, address to, uint256 id) public {
        _transfer(msg.sender, from, to, id);
    }


    function balanceOf(address owner) public view virtual override returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Revert if the `owner` is the zero address.
            if iszero(owner) {
                mstore(0x00, 0x8f4eb604) // `BalanceQueryForZeroAddress()`.
                revert(0x1c, 0x04)
            }
            mstore(0x1c, _ERC721_MASTER_SLOT_SEED)
            mstore(0x00, owner)
            result := and(sload(keccak256(0x0c, 0x1c)), _MAX_ACCOUNT_BALANCE)
        }
    }
    function ownerOf(uint256 id) public view virtual override returns (address result) {
        result = _ownerOf(id);
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(result) {
                mstore(0x00, 0xceea21b6) // `TokenDoesNotExist()`.
                revert(0x1c, 0x04)
            }
        }
    }
}