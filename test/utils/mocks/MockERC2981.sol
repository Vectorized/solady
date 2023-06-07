// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC2981} from "../../../src/tokens/ERC2981.sol";

contract MockERC2981 is ERC2981 {
    function feeDenominator() external pure returns (uint256) {
        return _feeDenominator();
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external {
        _setDefaultRoyalty(_brutalized(receiver), _brutalized(feeNumerator));
    }

    function deleteDefaultRoyalty() external {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external {
        _setTokenRoyalty(tokenId, _brutalized(receiver), _brutalized(feeNumerator));
    }

    function resetTokenRoyalty(uint256 tokenId) external {
        _resetTokenRoyalty(tokenId);
    }

    function _brutalized(uint96 x) internal view returns (uint96 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := or(x, shl(96, gas()))
        }
    }

    function _brutalized(address a) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := or(a, shl(160, gas()))
        }
    }
}
