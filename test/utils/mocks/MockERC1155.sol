// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC1155} from "../../../src/tokens/ERC1155.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockERC1155 is ERC1155 {
    function uri(uint256) public pure virtual override returns (string memory) {}

    function mint(address to, uint256 id, uint256 amount, bytes memory data) public virtual {
        _mint(_brutalized(to), id, amount, data);
    }

    function batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        _batchMint(_brutalized(to), ids, amounts, data);
    }

    function burn(address from, uint256 id, uint256 amount) public virtual {
        _burn(_brutalized(msg.sender), _brutalized(from), id, amount);
    }

    function uncheckedBurn(address from, uint256 id, uint256 amount) public virtual {
        _burn(_brutalized(from), id, amount);
    }

    function batchBurn(address from, uint256[] memory ids, uint256[] memory amounts)
        public
        virtual
    {
        _batchBurn(_brutalized(msg.sender), _brutalized(from), ids, amounts);
    }

    function uncheckedBatchBurn(address from, uint256[] memory ids, uint256[] memory amounts)
        public
        virtual
    {
        _batchBurn(_brutalized(from), ids, amounts);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual override {
        super.safeTransferFrom(_brutalized(from), _brutalized(to), id, amount, data);
    }

    function directSafeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        _safeTransfer(_brutalized(msg.sender), _brutalized(from), _brutalized(to), id, amount, data);
    }

    function uncheckedSafeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        _safeTransfer(_brutalized(address(0)), _brutalized(from), _brutalized(to), id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual override {
        super.safeBatchTransferFrom(_brutalized(from), _brutalized(to), ids, amounts, data);
    }

    function directSafeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        _safeBatchTransfer(
            _brutalized(msg.sender), _brutalized(from), _brutalized(to), ids, amounts, data
        );
    }

    function uncheckedSafeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        _safeBatchTransfer(
            _brutalized(address(0)), _brutalized(from), _brutalized(to), ids, amounts, data
        );
    }

    function directSetApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(_brutalized(msg.sender), _brutalized(operator), approved);
    }

    function _brutalized(address a) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := or(a, shl(160, gas()))
        }
    }
}
