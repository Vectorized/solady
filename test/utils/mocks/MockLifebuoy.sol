// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Ownable} from "../../../src/auth/Ownable.sol";
import {Lifebuoy} from "../../../src/utils/Lifebuoy.sol";
import {Brutalizer} from "../Brutalizer.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockLifebuoy is Lifebuoy, Brutalizer {
    constructor() payable {}

    function rescueETH(address to, uint256 amount) public payable virtual override {
        _brutalizeScratchSpace();
        super.rescueETH(_brutalized(to), amount);
        _checkMemory();
    }

    function rescueERC20(address token, address to, uint256 amount)
        public
        payable
        virtual
        override
    {
        _brutalizeScratchSpace();
        super.rescueERC20(_brutalized(token), _brutalized(to), amount);
        _checkMemory();
    }

    function rescueERC721(address token, address to, uint256 tokenId)
        public
        payable
        virtual
        override
    {
        _brutalizeScratchSpace();
        super.rescueERC721(_brutalized(token), _brutalized(to), tokenId);
        _checkMemory();
    }

    function rescueERC1155(
        address token,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) public payable virtual override {
        _brutalizeScratchSpace();
        super.rescueERC1155(_brutalized(token), _brutalized(to), tokenId, amount, data);
        _checkMemory();
    }

    function rescueERC6909(address token, address to, uint256 tokenId, uint256 amount)
        public
        payable
        virtual
        override
    {
        _brutalizeScratchSpace();
        super.rescueERC6909(_brutalized(token), _brutalized(to), tokenId, amount);
        _checkMemory();
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata)
        external
        virtual
        returns (bytes4)
    {
        return MockLifebuoy.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return MockLifebuoy.onERC1155BatchReceived.selector;
    }
}

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockLifebuoyOwned is MockLifebuoy, Ownable {
    constructor(address owner_) payable {
        _initializeOwner(owner_);
    }

    function initializeOwner(address owner_) external {
        _initializeOwner(owner_);
    }
}
