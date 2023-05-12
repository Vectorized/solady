// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC721} from "../../../src/tokens/ERC721.sol";
import {LibString} from "../../../src/utils/LibString.sol";

contract MockERC721 is ERC721 {
    function name() public view virtual override returns (string memory) {
        return "TEST NFT";
    }

    function symbol() public view virtual override returns (string memory) {
        return "TEST";
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        if (!_exists(id)) revert TokenDoesNotExist();
        return string(abi.encodePacked("https://remilio.org/remilio/json/", LibString.toString(id)));
    }

    function exists(uint256 id) public view virtual returns (bool) {
        return _exists(id);
    }

    function mint(address to, uint256 id) public virtual {
        _mint(_brutalized(to), id);
    }

    function burn(uint256 id) public virtual {
        _burn(msg.sender, id);
    }

    function uncheckedBurn(uint256 id) public virtual {
        _burn(id);
    }

    function safeMint(address to, uint256 id) public virtual {
        _safeMint(_brutalized(to), id);
    }

    function safeMint(address to, uint256 id, bytes calldata data) public virtual {
        _safeMint(_brutalized(to), id, data);
    }

    function getExtraData(uint256 id) public view virtual returns (uint96) {
        return _getExtraData(id);
    }

    function setExtraData(uint256 id, uint96 value) public virtual {
        _setExtraData(id, value);
    }

    function getAux(address owner) public view virtual returns (uint224) {
        return _getAux(_brutalized(owner));
    }

    function setAux(address owner, uint224 value) public virtual {
        _setAux(_brutalized(owner), value);
    }

    function approve(address account, uint256 id) public payable virtual override {
        super.approve(_brutalized(account), id);
    }

    function directApprove(address account, uint256 id) public virtual {
        if (!_isApprovedOrOwner(_brutalized(msg.sender), id)) revert NotOwnerNorApproved();
        _approve(_brutalized(account), id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        super.setApprovalForAll(_brutalized(operator), approved);
    }

    function directSetApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(_brutalized(msg.sender), _brutalized(operator), approved);
    }

    function transferFrom(address from, address to, uint256 id) public payable virtual override {
        super.transferFrom(_brutalized(from), _brutalized(to), id);
    }

    function uncheckedTransferFrom(address from, address to, uint256 id) public payable virtual {
        _transfer(_brutalized(address(0)), _brutalized(from), _brutalized(to), id);
    }

    function directTransferFrom(address from, address to, uint256 id) public virtual {
        _transfer(_brutalized(msg.sender), _brutalized(from), _brutalized(to), id);
    }

    function safeTransferFrom(address from, address to, uint256 id)
        public
        payable
        virtual
        override
    {
        super.safeTransferFrom(_brutalized(from), _brutalized(to), id);
    }

    function directSafeTransferFrom(address from, address to, uint256 id) public virtual {
        _safeTransfer(_brutalized(msg.sender), _brutalized(from), _brutalized(to), id);
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data)
        public
        payable
        virtual
        override
    {
        super.safeTransferFrom(_brutalized(from), _brutalized(to), id, data);
    }

    function directSafeTransferFrom(address from, address to, uint256 id, bytes calldata data)
        public
        virtual
    {
        _safeTransfer(_brutalized(msg.sender), _brutalized(from), _brutalized(to), id, data);
    }

    function isApprovedOrOwner(address account, uint256 id) public view virtual returns (bool) {
        return _isApprovedOrOwner(_brutalized(account), id);
    }

    function directOwnerOf(uint256 id) public view virtual returns (address) {
        if (!_exists(id)) revert TokenDoesNotExist();
        return _ownerOf(id);
    }

    function directGetApproved(uint256 id) public view virtual returns (address) {
        if (!_exists(id)) revert TokenDoesNotExist();
        return _getApproved(id);
    }

    function _brutalized(address a) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := or(a, shl(160, gas()))
        }
    }
}
