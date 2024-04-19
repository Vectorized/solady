// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC2981} from "../../../src/tokens/ERC2981.sol";
import {Brutalizer} from "../Brutalizer.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockERC2981 is ERC2981, Brutalizer {
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
}
