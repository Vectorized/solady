// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC721} from "../../../src/tokens/ERC721.sol";
import {LibString} from "../../../src/utils/LibString.sol";

contract MockERC721 is ERC721 {
    string internal _name;
    string internal _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        if (!_exists(id)) revert TokenDoesNotExist();
        return string(abi.encodePacked("https://example.com/", LibString.toString(id)));
    }

    function mint(address to, uint256 id) public virtual {
        _mint(to, id);
    }

    function burn(uint256 id) public virtual {
        _burn(id);
    }

    function safeMint(address to, uint256 id) public virtual {
        _safeMint(to, id);
    }

    function safeMint(address to, uint256 id, bytes memory data) public virtual {
        _safeMint(to, id, data);
    }

    function getExtraData(uint256 id) public virtual returns (uint96) {
        return _getExtraData(id);
    }

    function setExtraData(uint256 id, uint96 value) public virtual {
        _setExtraData(id, value);
    }

    function getAux(address owner) public virtual returns (uint224) {
        return _getAux(owner);
    }

    function setAux(address owner, uint224 value) public virtual {
        _setAux(owner, value);
    }
}
