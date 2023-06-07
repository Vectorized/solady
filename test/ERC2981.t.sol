// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";

import {ERC2981, MockERC2981} from "./utils/mocks/MockERC2981.sol";

contract ERC2981Test is SoladyTest {
    MockERC2981 token;

    function setUp() public {
        token = new MockERC2981();
    }

    struct _TestTemps {
        uint256 feeDenominator;
        address[2] receivers;
        uint256[2] tokenIds;
        uint256[2] salePrices;
        uint256[2] royaltyFractions;
        address defaultReceiver;
        uint256 defaultRoyaltyFraction;
    }

    function _testTemps() internal returns (_TestTemps memory t) {
        t.feeDenominator = token.feeDenominator();
        t.tokenIds[0] = _random();
        do {
            t.tokenIds[1] = _random();
        } while (t.tokenIds[0] == t.tokenIds[1]);
        t.receivers[0] = _randomNonZeroAddress();
        do {
            t.receivers[1] = _randomNonZeroAddress();
        } while (t.receivers[0] == t.receivers[1]);
        t.salePrices[0] = _bound(_random(), 0, type(uint160).max);
        t.salePrices[1] = _bound(_random(), 0, type(uint160).max);
        t.defaultReceiver = _randomNonZeroAddress();
        t.defaultRoyaltyFraction = _bound(_random(), 0, t.feeDenominator);
        t.royaltyFractions[0] = _bound(_random(), 0, t.feeDenominator);
        t.royaltyFractions[1] = _bound(_random(), 0, t.feeDenominator);
    }

    function testRoyaltyOverflowCheckDifferential(uint256 x, uint256 y) public {
        unchecked {
            bool expected = x != 0 && (x * y) / x != y;
            bool computed;
            /// @solidity memory-safe-assembly
            assembly {
                computed := mul(y, gt(x, div(not(0), y)))
            }
            assertEq(computed, expected);
        }
    }

    function testSetAndGetRoyaltyInfo(uint256) public {
        _TestTemps memory t = _testTemps();

        if (_random() % 16 == 0) _checkReverts(t);

        _checkRoyaltyInfoIsZero(t);

        token.setDefaultRoyalty(t.defaultReceiver, uint96(t.defaultRoyaltyFraction));
        _checkRoyaltyInfoIsDefault(t, 0);
        _checkRoyaltyInfoIsDefault(t, 1);

        token.setTokenRoyalty(t.tokenIds[0], t.receivers[0], uint96(t.royaltyFractions[0]));
        _checkRoyaltyInfo(t, 0);
        _checkRoyaltyInfoIsDefault(t, 1);
        token.setTokenRoyalty(t.tokenIds[1], t.receivers[1], uint96(t.royaltyFractions[1]));
        _checkRoyaltyInfo(t, 0);
        _checkRoyaltyInfo(t, 1);

        if (_random() % 16 == 0) _checkReverts(t);

        token.resetTokenRoyalty(t.tokenIds[0]);
        _checkRoyaltyInfoIsDefault(t, 0);
        _checkRoyaltyInfo(t, 1);
        token.resetTokenRoyalty(t.tokenIds[1]);
        _checkRoyaltyInfoIsDefault(t, 0);
        _checkRoyaltyInfoIsDefault(t, 1);

        if (_random() % 16 == 0) _checkReverts(t);

        token.deleteDefaultRoyalty();

        _checkRoyaltyInfoIsZero(t);

        if (_random() % 16 == 0) _checkReverts(t);
    }

    function _getInvalidFeeNumerator(_TestTemps memory t) internal returns (uint96 r) {
        while (true) {
            r = uint96(_random());
            if (r > t.feeDenominator) break;
        }
    }

    function _checkReverts(_TestTemps memory t) internal {
        vm.expectRevert(ERC2981.RoyaltyReceiverIsZeroAddress.selector);
        token.setDefaultRoyalty(address(0), 1);
        vm.expectRevert(ERC2981.RoyaltyOverflow.selector);
        token.setDefaultRoyalty(t.defaultReceiver, _getInvalidFeeNumerator(t));

        vm.expectRevert(ERC2981.RoyaltyReceiverIsZeroAddress.selector);
        token.setTokenRoyalty(t.tokenIds[0], address(0), 1);
        vm.expectRevert(ERC2981.RoyaltyOverflow.selector);
        token.setTokenRoyalty(t.tokenIds[0], t.receivers[0], _getInvalidFeeNumerator(t));

        vm.expectRevert(ERC2981.RoyaltyReceiverIsZeroAddress.selector);
        token.setTokenRoyalty(t.tokenIds[1], address(0), 1);
        vm.expectRevert(ERC2981.RoyaltyOverflow.selector);
        token.setTokenRoyalty(t.tokenIds[1], t.receivers[1], _getInvalidFeeNumerator(t));
    }

    function _checkRoyaltyInfoIsZero(_TestTemps memory t) internal {
        _checkRoyaltyInfo(t, 0, address(0), 0);
        _checkRoyaltyInfo(t, 1, address(0), 0);
    }

    function _checkRoyaltyInfoIsDefault(_TestTemps memory t, uint256 i) internal {
        uint256 expected = t.salePrices[i] * t.defaultRoyaltyFraction / t.feeDenominator;
        _checkRoyaltyInfo(t, i, t.defaultReceiver, expected);
    }

    function _checkRoyaltyInfo(_TestTemps memory t, uint256 i) internal {
        uint256 expected = t.salePrices[i] * t.royaltyFractions[i] / t.feeDenominator;
        _checkRoyaltyInfo(t, i, t.receivers[i], expected);
    }

    function _checkRoyaltyInfo(
        _TestTemps memory t,
        uint256 i,
        address expectedReceiver,
        uint256 expectedAmount
    ) internal {
        (address receiver, uint256 amount) = token.royaltyInfo(t.tokenIds[i], t.salePrices[i]);
        assertEq(receiver, expectedReceiver);
        assertEq(amount, expectedAmount);
    }
}
