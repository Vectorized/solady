// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC6909} from "../../../src/tokens/ERC6909.sol";
import {LibString} from "../../../src/utils/LibString.sol";
import {Brutalizer} from "../Brutalizer.sol";

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockERC6909 is ERC6909, Brutalizer {
    error TokenDoesNotExist();

    function name(uint256) public view virtual override returns (string memory) {
        return "Solady Token";
    }

    function symbol(uint256) public view virtual override returns (string memory) {
        return "ST";
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        return string(abi.encodePacked("http://solady.org/", LibString.toString(id)));
    }

    function mint(address to, uint256 id, uint256 amount) public payable virtual {
        _mint(_brutalized(to), id, amount);
    }

    function burn(address from, uint256 id, uint256 amount) public payable virtual {
        _burn(_brutalized(from), id, amount);
    }

    function approve(address spender, uint256 id, uint256 amount)
        public
        payable
        virtual
        override
        returns (bool)
    {
        return super.approve(_brutalized(spender), id, amount);
    }

    function setOperator(address owner, bool approved)
        public
        payable
        virtual
        override
        returns (bool)
    {
        /// @solidity memory-safe-assembly
        assembly {
            approved := mul(gas(), approved)
        }
        return super.setOperator(_brutalized(owner), approved);
    }

    function transfer(address to, uint256 id, uint256 amount)
        public
        payable
        virtual
        override
        returns (bool)
    {
        return super.transfer(_brutalized(to), id, amount);
    }

    function transferFrom(address from, address to, uint256 id, uint256 amount)
        public
        payable
        virtual
        override
        returns (bool)
    {
        return super.transferFrom(_brutalized(from), _brutalized(to), id, amount);
    }

    function directTransferFrom(address by, address from, address to, uint256 id, uint256 amount)
        public
        payable
        virtual
    {
        _transfer(_brutalized(by), _brutalized(from), _brutalized(to), id, amount);
    }

    function directSetOperator(address owner, address operator, bool approved)
        public
        payable
        virtual
    {
        /// @solidity memory-safe-assembly
        assembly {
            approved := mul(gas(), approved)
        }
        _setOperator(owner, operator, approved);
    }

    function directApprove(address owner, address spender, uint256 id, uint256 amount)
        public
        payable
        virtual
    {
        _approve(owner, spender, id, amount);
    }
}
