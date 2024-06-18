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
