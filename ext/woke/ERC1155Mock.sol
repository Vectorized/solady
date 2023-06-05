// SPDX-License-Identifier: MIT
import "src/tokens/ERC1155.sol";

contract ERC1155Mock is ERC1155 {
    event BeforeTokenTransfer(address from, address to, uint256[] ids, uint256[] amounts, bytes data);

    event AfterTokenTransfer(address from, address to, uint256[] ids, uint256[] amounts, bytes data);

    bool immutable private _enableHooks;

    constructor(bool enableHooks_) {
        _enableHooks = enableHooks_;
    }

    function _useBeforeTokenTransfer() internal view override returns (bool) {
        return _enableHooks;
    }

    function _useAfterTokenTransfer() internal view override returns (bool) {
        return _enableHooks;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        emit BeforeTokenTransfer(from, to, ids, amounts, data);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        emit AfterTokenTransfer(from, to, ids, amounts, data);
    }

    function uri(uint256 id) public view override returns (string memory) {}

    function mint(address to, uint256 id, uint256 amount, bytes memory data) external {
        _mint(to, id, amount, data);
    }

    function batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external {
        _batchMint(to, ids, amounts, data);
    }

    function burnUnchecked(address by, address from, uint256 id, uint256 amount) external {
        _burn(by, from, id, amount);
    }

    function burn(address from, uint256 id, uint256 amount) external {
        _burn(msg.sender, from, id, amount);
    }

    function batchBurnUnchecked(address by, address from, uint256[] memory ids, uint256[] memory amounts) external {
        _batchBurn(by, from, ids, amounts);
    }

    function batchBurn(address from, uint256[] memory ids, uint256[] memory amounts) external {
        _batchBurn(msg.sender, from, ids, amounts);
    }

    function setApprovalForAllUnchecked(address by, address operator, bool approved) external {
        _setApprovalForAll(by, operator, approved);
    }

    function safeTransferUnchecked(
        address by,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external {
        _safeTransfer(by, from, to, id, amount, data);
    }

    function safeBatchTransferUnchecked(
        address by,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external {
        _safeBatchTransfer(by, from, to, ids, amounts, data);
    }
}

contract ERC1155ReceiverMock {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata data
    ) external pure returns(bytes4) {
        require(keccak256(data) == keccak256(hex"00112233"), "ERC1155ReceiverMock: invalid payload received");
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata data
    ) external pure returns(bytes4) {
        require(keccak256(data) == keccak256(hex"00112233"), "ERC1155ReceiverMock: invalid payload received");
        return this.onERC1155BatchReceived.selector;
    }
}

contract ERC1155ReentrancyAttacker {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata data
    ) external returns(bytes4) {
        if (data.length == 0)
            ERC1155Mock(msg.sender).mint(address(this), 1024, 1, hex"00112233");
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata data
    ) external returns(bytes4) {
        if (data.length == 0)
            ERC1155Mock(msg.sender).mint(address(this), 1024, 1, hex"00112233");
        return this.onERC1155BatchReceived.selector;
    }
}