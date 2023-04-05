// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/TestPlus.sol";

import {ERC20, MockERC20} from "./utils/mocks/MockERC20.sol";

contract ERC20Test is TestPlus {
    MockERC20 token;

    bytes32 constant PERMIT_TYPEHASH = keccak256(
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    struct _TestTemps {
        address owner;
        uint256 privateKey;
        address to;
        uint256 amount;
        uint256 nonce;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function _testTemps() internal returns (_TestTemps memory t) {
        (t.owner, t.privateKey) = _randomSigner();
        (t.to,) = _randomSigner();
        t.amount = _random();
        t.nonce = _random();
        t.deadline = _random();
    }

    function setUp() public {
        token = new MockERC20("Token", "TKN", 18);
    }

    function invariantMetadata() public {
        assertEq(token.name(), "Token");
        assertEq(token.symbol(), "TKN");
        assertEq(token.decimals(), 18);
    }

    function testMint() public {
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), address(0xBEEF), 1e18);
        token.mint(address(0xBEEF), 1e18);

        assertEq(token.totalSupply(), 1e18);
        assertEq(token.balanceOf(address(0xBEEF)), 1e18);
    }

    function testBurn() public {
        token.mint(address(0xBEEF), 1e18);

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0xBEEF), address(0), 0.9e18);
        token.burn(address(0xBEEF), 0.9e18);

        assertEq(token.totalSupply(), 1e18 - 0.9e18);
        assertEq(token.balanceOf(address(0xBEEF)), 0.1e18);
    }

    function testApprove() public {
        vm.expectEmit(true, true, true, true);
        emit Approval(address(this), address(0xBEEF), 1e18);
        assertTrue(token.approve(address(0xBEEF), 1e18));

        assertEq(token.allowance(address(this), address(0xBEEF)), 1e18);
    }

    function testTransfer() public {
        token.mint(address(this), 1e18);

        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), address(0xBEEF), 1e18);
        assertTrue(token.transfer(address(0xBEEF), 1e18));
        assertEq(token.totalSupply(), 1e18);

        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(address(0xBEEF)), 1e18);
    }

    function testTransferFrom() public {
        address from = address(0xABCD);

        token.mint(from, 1e18);

        vm.prank(from);
        token.approve(address(this), 1e18);

        vm.expectEmit(true, true, true, true);
        emit Transfer(from, address(0xBEEF), 1e18);
        assertTrue(token.transferFrom(from, address(0xBEEF), 1e18));
        assertEq(token.totalSupply(), 1e18);

        assertEq(token.allowance(from, address(this)), 0);

        assertEq(token.balanceOf(from), 0);
        assertEq(token.balanceOf(address(0xBEEF)), 1e18);
    }

    function testInfiniteApproveTransferFrom() public {
        address from = address(0xABCD);

        token.mint(from, 1e18);

        vm.prank(from);
        token.approve(address(this), type(uint256).max);

        assertTrue(token.transferFrom(from, address(0xBEEF), 1e18));
        assertEq(token.totalSupply(), 1e18);

        assertEq(token.allowance(from, address(this)), type(uint256).max);

        assertEq(token.balanceOf(from), 0);
        assertEq(token.balanceOf(address(0xBEEF)), 1e18);
    }

    function testPermit() public {
        (address owner, uint256 privateKey) = _randomSigner();

        (t.v, t.r, t.s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH, owner, address(0xCAFE), 1e18, 0, block.timestamp
                        )
                    )
                )
            )
        );

        token.permit(owner, address(0xCAFE), 1e18, block.timestamp, t.v, t.r, t.s);

        assertEq(token.allowance(owner, address(0xCAFE)), 1e18);
        assertEq(token.nonces(owner), 1);
    }

    function testMintOverMaxUintReverts() public {
        token.mint(address(this), type(uint256).max);
        vm.expectRevert(ERC20.TotalSupplyOverflow.selector);
        token.mint(address(this), 1);
    }

    function testIncreaseAllowance(uint256 difference0, uint256 difference1) public {
        uint256 expected;
        (address spender,) = _randomSigner();
        (address owner,) = _randomSigner();

        expected += difference0;
        vm.expectEmit(true, true, true, true);
        emit Approval(owner, spender, expected);
        vm.prank(owner);
        token.increaseAllowance(spender, difference0);
        assertEq(token.allowance(owner, spender), expected);

        if (type(uint256).max - difference1 < difference0) {
            vm.expectRevert(ERC20.AllowanceOverflow.selector);
            vm.prank(owner);
            token.increaseAllowance(spender, difference1);
        } else {
            expected += difference1;
            vm.prank(owner);
            vm.expectEmit(true, true, true, true);
            emit Approval(owner, spender, expected);
            token.increaseAllowance(spender, difference1);
            assertEq(token.allowance(owner, spender), expected);
        }
    }

    function testDecreaseAllowance(uint256 difference0, uint256 difference1) public {
        uint256 expected = type(uint256).max;
        (address spender,) = _randomSigner();
        (address owner,) = _randomSigner();
        vm.prank(owner);
        token.approve(spender, expected);

        expected -= difference0;
        vm.prank(owner);
        token.decreaseAllowance(spender, difference0);
        assertEq(token.allowance(owner, spender), expected);

        if (difference1 > expected) {
            vm.expectRevert(ERC20.AllowanceUnderflow.selector);
            vm.prank(owner);
            token.decreaseAllowance(spender, difference1);
        } else {
            expected -= difference1;
            vm.prank(owner);
            vm.expectEmit(true, true, true, true);
            emit Approval(owner, spender, expected);
            token.decreaseAllowance(spender, difference1);
            assertEq(token.allowance(owner, spender), expected);
        }
    }

    function testTransferInsufficientBalanceReverts() public {
        token.mint(address(this), 0.9e18);
        vm.expectRevert(ERC20.InsufficientBalance.selector);
        token.transfer(address(0xBEEF), 1e18);
    }

    function testTransferFromInsufficientAllowanceReverts() public {
        address from = address(0xABCD);

        token.mint(from, 1e18);

        vm.prank(from);
        token.approve(address(this), 0.9e18);

        vm.expectRevert(ERC20.InsufficientAllowance.selector);
        token.transferFrom(from, address(0xBEEF), 1e18);
    }

    function testTransferFromInsufficientBalanceReverts() public {
        address from = address(0xABCD);

        token.mint(from, 0.9e18);

        vm.prank(from);
        token.approve(address(this), 1e18);

        vm.expectRevert(ERC20.InsufficientBalance.selector);
        token.transferFrom(from, address(0xBEEF), 1e18);
    }

    function testPermitBadNonceReverts() public {
        (address owner, uint256 privateKey) = _randomSigner();

        (t.v, t.r, t.s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH, owner, address(0xCAFE), 1e18, 1, block.timestamp
                        )
                    )
                )
            )
        );

        vm.expectRevert(ERC20.InvalidPermit.selector);
        token.permit(owner, address(0xCAFE), 1e18, block.timestamp, t.v, t.r, t.s);
    }

    function testPermitBadDeadlineReverts() public {
        (address owner, uint256 privateKey) = _randomSigner();

        (t.v, t.r, t.s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH, owner, address(0xCAFE), 1e18, 0, block.timestamp
                        )
                    )
                )
            )
        );

        vm.expectRevert(ERC20.InvalidPermit.selector);
        token.permit(owner, address(0xCAFE), 1e18, block.timestamp + 1, t.v, t.r, t.s);
    }

    function testPermitPastDeadlineReverts() public {
        uint256 oldTimestamp = block.timestamp;
        (address owner, uint256 privateKey) = _randomSigner();

        (t.v, t.r, t.s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(PERMIT_TYPEHASH, owner, address(0xCAFE), 1e18, 0, oldTimestamp)
                    )
                )
            )
        );

        vm.warp(block.timestamp + 1);
        vm.expectRevert(ERC20.PermitExpired.selector);
        token.permit(owner, address(0xCAFE), 1e18, oldTimestamp, t.v, t.r, t.s);
    }

    function testPermitReplayReverts() public {
        (address owner, uint256 privateKey) = _randomSigner();

        (t.v, t.r, t.s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH, owner, address(0xCAFE), 1e18, 0, block.timestamp
                        )
                    )
                )
            )
        );

        token.permit(owner, address(0xCAFE), 1e18, block.timestamp, t.v, t.r, t.s);
        vm.expectRevert(ERC20.InvalidPermit.selector);
        token.permit(owner, address(0xCAFE), 1e18, block.timestamp, t.v, t.r, t.s);
    }

    function testMetadata(string calldata name, string calldata symbol, uint8 decimals) public {
        MockERC20 tkn = new MockERC20(name, symbol, decimals);
        assertEq(tkn.name(), name);
        assertEq(tkn.symbol(), symbol);
        assertEq(tkn.decimals(), decimals);
    }

    function testMint(address from, uint256 amount) public {
        token.mint(from, amount);

        assertEq(token.totalSupply(), amount);
        assertEq(token.balanceOf(from), amount);
    }

    function testBurn(address from, uint256 mintAmount, uint256 burnAmount) public {
        burnAmount = _bound(burnAmount, 0, mintAmount);

        token.mint(from, mintAmount);
        token.burn(from, burnAmount);

        assertEq(token.totalSupply(), mintAmount - burnAmount);
        assertEq(token.balanceOf(from), mintAmount - burnAmount);
    }

    function testApprove(address to, uint256 amount) public {
        assertTrue(token.approve(to, amount));

        assertEq(token.allowance(address(this), to), amount);
    }

    function testTransfer(address from, uint256 amount) public {
        token.mint(address(this), amount);

        assertTrue(token.transfer(from, amount));
        assertEq(token.totalSupply(), amount);

        if (address(this) == from) {
            assertEq(token.balanceOf(address(this)), amount);
        } else {
            assertEq(token.balanceOf(address(this)), 0);
            assertEq(token.balanceOf(from), amount);
        }
    }

    function testTransferFrom(address to, uint256 approval, uint256 amount) public {
        amount = _bound(amount, 0, approval);

        address from = address(0xABCD);

        token.mint(from, amount);

        vm.prank(from);
        token.approve(address(this), approval);

        assertTrue(token.transferFrom(from, to, amount));
        assertEq(token.totalSupply(), amount);

        uint256 app =
            from == address(this) || approval == type(uint256).max ? approval : approval - amount;
        assertEq(token.allowance(from, address(this)), app);

        if (from == to) {
            assertEq(token.balanceOf(from), amount);
        } else {
            assertEq(token.balanceOf(from), 0);
            assertEq(token.balanceOf(to), amount);
        }
    }

    function testPermit(uint256) public {
        _TestTemps memory t = _testTemps();
        if (t.deadline < block.timestamp) t.deadline = block.timestamp;

        (t.v, t.r, t.s) = vm.sign(
            t.privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, t.owner, t.to, t.amount, 0, t.deadline))
                )
            )
        );

        token.permit(t.owner, t.to, t.amount, t.deadline, t.v, t.r, t.s);

        assertEq(token.allowance(t.owner, t.to), t.amount);
        assertEq(token.nonces(t.owner), 1);
    }

    function testBurnInsufficientBalanceReverts(address to, uint256 mintAmount, uint256 burnAmount)
        public
    {
        if (mintAmount == type(uint256).max) mintAmount--;
        burnAmount = _bound(burnAmount, mintAmount + 1, type(uint256).max);

        token.mint(to, mintAmount);
        vm.expectRevert(ERC20.InsufficientBalance.selector);
        token.burn(to, burnAmount);
    }

    function testTransferInsufficientBalanceReverts(
        address to,
        uint256 mintAmount,
        uint256 sendAmount
    ) public {
        if (mintAmount == type(uint256).max) mintAmount--;
        sendAmount = _bound(sendAmount, mintAmount + 1, type(uint256).max);

        token.mint(address(this), mintAmount);
        vm.expectRevert(ERC20.InsufficientBalance.selector);
        token.transfer(to, sendAmount);
    }

    function testTransferFromInsufficientAllowanceReverts(
        address to,
        uint256 approval,
        uint256 amount
    ) public {
        if (approval == type(uint256).max) approval--;
        amount = _bound(amount, approval + 1, type(uint256).max);

        address from = address(0xABCD);

        token.mint(from, amount);

        vm.prank(from);
        token.approve(address(this), approval);

        vm.expectRevert(ERC20.InsufficientAllowance.selector);
        token.transferFrom(from, to, amount);
    }

    function testTransferFromInsufficientBalanceReverts(
        address to,
        uint256 mintAmount,
        uint256 sendAmount
    ) public {
        if (mintAmount == type(uint256).max) mintAmount--;
        sendAmount = _bound(sendAmount, mintAmount + 1, type(uint256).max);

        address from = address(0xABCD);

        token.mint(from, mintAmount);

        vm.prank(from);
        token.approve(address(this), sendAmount);

        vm.expectRevert(ERC20.InsufficientBalance.selector);
        token.transferFrom(from, to, sendAmount);
    }

    function testPermitBadNonceReverts(uint256) public {
        _TestTemps memory t = _testTemps();
        if (t.deadline < block.timestamp) t.deadline = block.timestamp;
        if (t.nonce == 0) t.nonce = 1;

        (t.v, t.r, t.s) = vm.sign(
            t.privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(PERMIT_TYPEHASH, t.owner, t.to, t.amount, t.nonce, t.deadline)
                    )
                )
            )
        );

        vm.expectRevert(ERC20.InvalidPermit.selector);
        token.permit(t.owner, t.to, t.amount, t.deadline, t.v, t.r, t.s);
    }

    function testPermitBadDeadlineReverts(uint256) public {
        _TestTemps memory t = _testTemps();
        if (t.deadline == type(uint256).max) t.deadline--;
        if (t.deadline < block.timestamp) t.deadline = block.timestamp;

        (t.v, t.r, t.s) = vm.sign(
            t.privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, t.owner, t.to, t.amount, 0, t.deadline))
                )
            )
        );

        vm.expectRevert(ERC20.InvalidPermit.selector);
        token.permit(t.owner, t.to, t.amount, t.deadline + 1, t.v, t.r, t.s);
    }

    function testPermitPastDeadlineReverts(uint256) public {
        _TestTemps memory t = _testTemps();
        t.deadline = _bound(t.deadline, 0, block.timestamp - 1);

        (t.v, t.r, t.s) = vm.sign(
            t.privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, t.owner, t.to, t.amount, 0, t.deadline))
                )
            )
        );

        vm.expectRevert(ERC20.PermitExpired.selector);
        token.permit(t.owner, t.to, t.amount, t.deadline, t.v, t.r, t.s);
    }

    function testPermitReplayReverts(uint256) public {
        _TestTemps memory t = _testTemps();
        if (t.deadline < block.timestamp) t.deadline = block.timestamp;

        (t.v, t.r, t.s) = vm.sign(
            t.privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, t.owner, t.to, t.amount, 0, t.deadline))
                )
            )
        );

        token.permit(t.owner, t.to, t.amount, t.deadline, t.v, t.r, t.s);
        vm.expectRevert(ERC20.InvalidPermit.selector);
        token.permit(t.owner, t.to, t.amount, t.deadline, t.v, t.r, t.s);
    }
}

contract InvariantTest {
    address[] private _targets;

    function targetContracts() public view virtual returns (address[] memory) {
        require(_targets.length > 0, "NO_TARGET_CONTRACTS");
        return _targets;
    }

    function _addTargetContract(address newTargetContract) internal virtual {
        _targets.push(newTargetContract);
    }
}

contract ERC20Invariants is TestPlus, InvariantTest {
    BalanceSum balanceSum;
    MockERC20 token;

    function setUp() public {
        token = new MockERC20("Token", "TKN", 18);
        balanceSum = new BalanceSum(token);
        _addTargetContract(address(balanceSum));
    }

    function invariantBalanceSum() public {
        assertEq(token.totalSupply(), balanceSum.sum());
    }
}

contract BalanceSum {
    MockERC20 token;
    uint256 public sum;

    constructor(MockERC20 _token) {
        token = _token;
    }

    function mint(address from, uint256 amount) public {
        token.mint(from, amount);
        sum += amount;
    }

    function burn(address from, uint256 amount) public {
        token.burn(from, amount);
        sum -= amount;
    }

    function approve(address to, uint256 amount) public {
        token.approve(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public {
        token.transferFrom(from, to, amount);
    }

    function transfer(address to, uint256 amount) public {
        token.transfer(to, amount);
    }
}
