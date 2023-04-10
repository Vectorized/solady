// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC1155} from "../../../src/tokens/ERC1155.sol";

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
        _burn(_brutalized(from), id, amount);
    }

    function batchBurn(address from, uint256[] memory ids, uint256[] memory amounts)
        public
        virtual
    {
        _batchBurn(_brutalized(from), ids, amounts);
    }

    function directSafeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        _safeTransfer(_brutalizedMsgSender(), from, to, id, amount, data);
    }

    function directSafeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        _safeBatchTransfer(_brutalizedMsgSender(), from, to, ids, amounts, data);
    }

    function directSetApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(_brutalizedMsgSender(), _brutalized(operator), approved);
    }

    function _brutalized(address a) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := or(a, shl(160, gas()))
        }
    }

    function _brutalizedMsgSender() internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := or(caller(), shl(160, gas()))
        }
    }
}
