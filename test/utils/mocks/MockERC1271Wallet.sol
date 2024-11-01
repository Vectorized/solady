// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../../src/utils/ECDSA.sol";

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata)
        external
        virtual
        returns (bytes4)
    {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(address, address, uint256, uint256, bytes calldata)
        external
        virtual
        returns (bytes4)
    {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

/// @dev WARNING! This mock is strictly intended for testing purposes only.
/// Do NOT copy anything here into production code unless you really know what you are doing.
contract MockERC1271Wallet is ERC721TokenReceiver, ERC1155TokenReceiver {
    address public signer;
    bool public useSignaturePassthrough;

    constructor(address signer_) {
        signer = signer_;
    }

    function setSigner(address signer_) external {
        signer = signer_;
    }

    function isValidSignature(bytes32 hash, bytes calldata signature)
        external
        view
        returns (bytes4)
    {
        if (useSignaturePassthrough) {
            return keccak256(signature) == hash ? bytes4(0x1626ba7e) : bytes4(0);
        }
        return ECDSA.recover(hash, signature) == signer ? bytes4(0x1626ba7e) : bytes4(0);
    }

    function setUseSignaturePassthrough(bool value) public {
        useSignaturePassthrough = value;
    }
}
