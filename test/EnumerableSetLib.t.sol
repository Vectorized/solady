// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./utils/SoladyTest.sol";
import {EnumerableSetLib} from "../src/utils/EnumerableSetLib.sol";

contract EnumerableSetLibTest is SoladyTest {
    using EnumerableSetLib for *;

    EnumerableSetLib.AddressSet addressSet;

    function testEnumerableAddressSetBasic() public {
        assertEq(addressSet.length(), 0);
        assertEq(addressSet.contains(address(1)), false);
        assertEq(addressSet.contains(address(2)), false);
        assertEq(addressSet.contains(address(3)), false);
        assertEq(addressSet.contains(address(4)), false);
        assertEq(addressSet.contains(address(5)), false);

        assertTrue(addressSet.add(address(1)));
        assertFalse(addressSet.add(address(1)));

        assertEq(addressSet.length(), 1);
        assertEq(addressSet.contains(address(1)), true);
        assertEq(addressSet.contains(address(2)), false);
        assertEq(addressSet.contains(address(3)), false);
        assertEq(addressSet.contains(address(4)), false);
        assertEq(addressSet.contains(address(5)), false);

        assertTrue(addressSet.add(address(2)));
        assertFalse(addressSet.add(address(2)));

        assertEq(addressSet.length(), 2);
        assertEq(addressSet.contains(address(1)), true);
        assertEq(addressSet.contains(address(2)), true);
        assertEq(addressSet.contains(address(3)), false);
        assertEq(addressSet.contains(address(4)), false);
        assertEq(addressSet.contains(address(5)), false);

        assertTrue(addressSet.add(address(3)));
        assertFalse(addressSet.add(address(3)));

        assertEq(addressSet.length(), 3);
        assertEq(addressSet.contains(address(1)), true);
        assertEq(addressSet.contains(address(2)), true);
        assertEq(addressSet.contains(address(3)), true);
        assertEq(addressSet.contains(address(4)), false);
        assertEq(addressSet.contains(address(5)), false);

        assertTrue(addressSet.add(address(4)));
        assertFalse(addressSet.add(address(4)));

        assertEq(addressSet.length(), 4);
        assertEq(addressSet.contains(address(1)), true);
        assertEq(addressSet.contains(address(2)), true);
        assertEq(addressSet.contains(address(3)), true);
        assertEq(addressSet.contains(address(4)), true);
        assertEq(addressSet.contains(address(5)), false);

        assertTrue(addressSet.add(address(5)));
        assertFalse(addressSet.add(address(5)));

        assertEq(addressSet.length(), 5);
        assertEq(addressSet.contains(address(1)), true);
        assertEq(addressSet.contains(address(2)), true);
        assertEq(addressSet.contains(address(3)), true);
        assertEq(addressSet.contains(address(4)), true);
        assertEq(addressSet.contains(address(5)), true);
    }

    function testEnumerableAddressSetBasic2() public {
        addressSet.add(address(1));
        addressSet.add(address(2));

        addressSet.remove(address(1));
        assertEq(addressSet.length(), 1);
        addressSet.remove(address(2));
        assertEq(addressSet.length(), 0);

        addressSet.add(address(1));
        addressSet.add(address(2));

        addressSet.remove(address(2));
        assertEq(addressSet.length(), 1);
        addressSet.remove(address(1));
        assertEq(addressSet.length(), 0);

        addressSet.add(address(1));
        addressSet.add(address(2));
        addressSet.add(address(3));

        addressSet.remove(address(3));
        assertEq(addressSet.length(), 2);
        addressSet.remove(address(2));
        assertEq(addressSet.length(), 1);
        addressSet.remove(address(1));
        assertEq(addressSet.length(), 0);

        addressSet.add(address(1));
        addressSet.add(address(2));
        addressSet.add(address(3));

        addressSet.remove(address(1));
        assertEq(addressSet.length(), 2);
        addressSet.remove(address(2));
        assertEq(addressSet.length(), 1);
        addressSet.remove(address(3));
        assertEq(addressSet.length(), 0);
    }
}
