// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {GasBurnerLib} from "../src/utils/GasBurnerLib.sol";

contract GasBurnerLibTest is SoladyTest {
    event LogGasBurn(uint256 required, uint256 actual);

    function testBurnPure() public {
        _testBurnPure(0);
        _testBurnPure(1);
        _testBurnPure(110);
        _testBurnPure(119);
        _testBurnPure(120);
        _testBurnPure(121);
        _testBurnPure(300);
        for (uint256 x = 300; x < 9000; x += 32) {
            _testBurnPure(x);
        }
    }

    function testBurnView() public {
        _testBurnView(1 * 3000);
        _testBurnView(2 * 3000);
        _testBurnView(3 * 3000);
        _testBurnView(4 * 3000);
        _testBurnView(5 * 3000);
        _testBurnView(9 * 3000);
    }

    function testBurn() public {
        _testBurn(20000);
        _testBurn(30000);
        _testBurn(50000);
    }

    function testBurnPure(uint256 x) public {
        x = _bound(x, 0, _randomChance(512) ? 30000000 : 5000);
        GasBurnerLib.burnPure(x);
    }

    function testBurnView(uint256 x) public {
        x = _bound(x, 0, _randomChance(512) ? 30000000 : 15000);
        GasBurnerLib.burnView(x);
    }

    function testBurn(uint256 x) public {
        x = _bound(x, 0, _randomChance(512) ? 30000000 : 60000);
        GasBurnerLib.burn(x);
    }

    function testBurnPureTiming() public pure {
        GasBurnerLib.burnPure(300000);
    }

    function testBurnViewTiming() public view {
        GasBurnerLib.burnView(300000);
    }

    function testBurnTiming() public {
        GasBurnerLib.burn(300000);
    }

    function _testBurnPure(uint256 x) internal {
        unchecked {
            uint256 gasBefore = gasleft();
            GasBurnerLib.burnPure(x);
            uint256 gasAfter = gasleft();
            emit LogGasBurn(x, gasBefore - gasAfter);
        }
    }

    function _testBurnView(uint256 x) internal {
        unchecked {
            uint256 gasBefore = gasleft();
            GasBurnerLib.burnView(x);
            uint256 gasAfter = gasleft();
            emit LogGasBurn(x, gasBefore - gasAfter);
        }
    }

    function _testBurn(uint256 x) internal {
        unchecked {
            uint256 gasBefore = gasleft();
            GasBurnerLib.burn(x);
            uint256 gasAfter = gasleft();
            emit LogGasBurn(x, gasBefore - gasAfter);
        }
    }
}
