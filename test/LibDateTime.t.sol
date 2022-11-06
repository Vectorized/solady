// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../test/utils/TestPlus.sol";
import {LibDateTime} from "../src/utils/LibDateTime.sol";

contract LibDateTimeTest is TestPlus {
    function testDaysFromDate() public {
        assertEq(LibDateTime.daysFromDate(1970, 1, 1), 0);
        assertEq(LibDateTime.daysFromDate(1970, 1, 2), 1);
        assertEq(LibDateTime.daysFromDate(1970, 2, 1), 31);
        assertEq(LibDateTime.daysFromDate(1970, 3, 1), 59);
        assertEq(LibDateTime.daysFromDate(1970, 4, 1), 90);
        assertEq(LibDateTime.daysFromDate(1970, 5, 1), 120);
        assertEq(LibDateTime.daysFromDate(1970, 6, 1), 151);
        assertEq(LibDateTime.daysFromDate(1970, 7, 1), 181);
        assertEq(LibDateTime.daysFromDate(1970, 8, 1), 212);
        assertEq(LibDateTime.daysFromDate(1970, 9, 1), 243);
        assertEq(LibDateTime.daysFromDate(1970, 10, 1), 273);
        assertEq(LibDateTime.daysFromDate(1970, 11, 1), 304);
        assertEq(LibDateTime.daysFromDate(1970, 12, 1), 334);
        assertEq(LibDateTime.daysFromDate(1970, 12, 31), 364);
        assertEq(LibDateTime.daysFromDate(1971, 1, 1), 365);
        assertEq(LibDateTime.daysFromDate(1980, 11, 3), 3959);
        assertEq(LibDateTime.daysFromDate(2000, 3, 1), 11017);
        assertEq(LibDateTime.daysFromDate(2355, 12, 31), 140982);
        assertEq(LibDateTime.daysFromDate(99999, 12, 31), 35804721);
        assertEq(LibDateTime.daysFromDate(100000, 12, 31), 35805087);
        assertEq(LibDateTime.daysFromDate(604800, 2, 29), 220179195);
        assertEq(LibDateTime.daysFromDate(1667347200, 2, 29), 608985340227);
        assertEq(LibDateTime.daysFromDate(1667952000, 2, 29), 609206238891);
    }

    function testDaysToDate() public {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = LibDateTime.daysToDate(0);
        assertTrue(year == 1970 && month == 1 && day == 1);
        (year, month, day) = LibDateTime.daysToDate(31);
        assertTrue(year == 1970 && month == 2 && day == 1);
        (year, month, day) = LibDateTime.daysToDate(59);
        assertTrue(year == 1970 && month == 3 && day == 1);
        (year, month, day) = LibDateTime.daysToDate(90);
        assertTrue(year == 1970 && month == 4 && day == 1);
        (year, month, day) = LibDateTime.daysToDate(120);
        assertTrue(year == 1970 && month == 5 && day == 1);
        (year, month, day) = LibDateTime.daysToDate(151);
        assertTrue(year == 1970 && month == 6 && day == 1);
        (year, month, day) = LibDateTime.daysToDate(181);
        assertTrue(year == 1970 && month == 7 && day == 1);
        (year, month, day) = LibDateTime.daysToDate(212);
        assertTrue(year == 1970 && month == 8 && day == 1);
        (year, month, day) = LibDateTime.daysToDate(243);
        assertTrue(year == 1970 && month == 9 && day == 1);
        (year, month, day) = LibDateTime.daysToDate(273);
        assertTrue(year == 1970 && month == 10 && day == 1);
        (year, month, day) = LibDateTime.daysToDate(304);
        assertTrue(year == 1970 && month == 11 && day == 1);
        (year, month, day) = LibDateTime.daysToDate(334);
        assertTrue(year == 1970 && month == 12 && day == 1);
        (year, month, day) = LibDateTime.daysToDate(365);
        assertTrue(year == 1971 && month == 1 && day == 1);
        (year, month, day) = LibDateTime.daysToDate(10987);
        assertTrue(year == 2000 && month == 1 && day == 31);
        (year, month, day) = LibDateTime.daysToDate(18321);
        assertTrue(year == 2020 && month == 2 && day == 29);
        (year, month, day) = LibDateTime.daysToDate(156468);
        assertTrue(year == 2398 && month == 5 && day == 25);
        (year, month, day) = LibDateTime.daysToDate(35805087);
        assertTrue(year == 100000 && month == 12 && day == 31);
    }

    function testFuzzDaysToDate(uint256 z) public {
        (uint256 y, uint256 m, uint256 d) = LibDateTime.daysToDate(z);
        uint256 day = LibDateTime.daysFromDate(y, m, d);
        assertEq(z, day);
    }

    function testFuzzDaysFromDate(
        uint256 _y,
        uint256 _m,
        uint256 _d
    ) public {
        // MAX POSSIBLE DAY = 115792089237316195423570985008687907853269984665640564039457584007913128920467
        // MAX DATE = 317027972476686572410305440929486321699336700043506886628630523577932824465 - 12 - 03
        _y = _bound(_y,1970,3669305236998687180674831492239425019668248843096144521164705134005821);
        _m = _bound(_m,1,12);
        uint256 md = LibDateTime.getDaysInMonth(_y,_m);
        _d = _bound(_d,1,md);
        uint256 day = LibDateTime.daysFromDate(_y, _m, _d);
        (uint256 y, uint256 m, uint256 d) = LibDateTime.daysToDate(day);
        assertTrue(_y == y && _m == m && _d == d);
    }

    function testIsLeapYear() public {
        assertTrue(LibDateTime.isLeapYear(2000));
        assertTrue(LibDateTime.isLeapYear(2024));
        assertTrue(LibDateTime.isLeapYear(2048));
        assertTrue(LibDateTime.isLeapYear(2072));
        assertTrue(LibDateTime.isLeapYear(2104));
        assertTrue(LibDateTime.isLeapYear(2128));
        assertTrue(LibDateTime.isLeapYear(10032));
        assertTrue(LibDateTime.isLeapYear(10124));
        assertTrue(LibDateTime.isLeapYear(10296));
        assertTrue(LibDateTime.isLeapYear(10400));
        assertTrue(LibDateTime.isLeapYear(10916));
    }

    function testFuzzIsLeapYear(uint256 y) public {
        if ((y % 4 == 0) && (y % 100 != 0 || y % 400 == 0)) {
            assertTrue(LibDateTime.isLeapYear(y));
        } else {
            assertFalse(LibDateTime.isLeapYear(y));
        }
    }

    function testgetDaysInMonth() public {
        assertEq(LibDateTime.getDaysInMonth(2022, 1), 31);
        assertEq(LibDateTime.getDaysInMonth(2022, 2), 28);
        assertEq(LibDateTime.getDaysInMonth(2022, 3), 31);
        assertEq(LibDateTime.getDaysInMonth(2022, 4), 30);
        assertEq(LibDateTime.getDaysInMonth(2022, 5), 31);
        assertEq(LibDateTime.getDaysInMonth(2022, 6), 30);
        assertEq(LibDateTime.getDaysInMonth(2022, 7), 31);
        assertEq(LibDateTime.getDaysInMonth(2022, 8), 31);
        assertEq(LibDateTime.getDaysInMonth(2022, 9), 30);
        assertEq(LibDateTime.getDaysInMonth(2022, 10), 31);
        assertEq(LibDateTime.getDaysInMonth(2022, 11), 30);
        assertEq(LibDateTime.getDaysInMonth(2022, 12), 31);
        assertEq(LibDateTime.getDaysInMonth(2024, 1), 31);
        assertEq(LibDateTime.getDaysInMonth(2024, 2), 29);
        assertEq(LibDateTime.getDaysInMonth(1900, 2), 28);
    }

    function testFuzzgetDaysInMonth(uint256 y, uint256 m) public {
        m = _bound(m, 1, 12);
        if (LibDateTime.isLeapYear(y) && m == 2) {
            assertEq(LibDateTime.getDaysInMonth(y, m), 29);
        } else if (m == 1 || m == 3 || m == 5 || m == 7 || m == 8 || m == 10 || m == 12) {
            assertEq(LibDateTime.getDaysInMonth(y, m), 31);
        } else if (m == 2) {
            assertEq(LibDateTime.getDaysInMonth(y, m), 28);
        } else {
            assertEq(LibDateTime.getDaysInMonth(y, m), 30);
        }
    }

    function testgetDayOfWeek() public {
        assertEq(LibDateTime.getDayOfWeek(1), 3);
        assertEq(LibDateTime.getDayOfWeek(86400), 4);
        assertEq(LibDateTime.getDayOfWeek(86401), 4);
        assertEq(LibDateTime.getDayOfWeek(172800), 5);
        assertEq(LibDateTime.getDayOfWeek(259200), 6);
        assertEq(LibDateTime.getDayOfWeek(345600), 0);
        assertEq(LibDateTime.getDayOfWeek(432000), 1);
        assertEq(LibDateTime.getDayOfWeek(518400), 2);
    }

    function testFuzzgetDayOfWeek() public {
        uint256 t = 0;
        uint256 wd = 3;
        unchecked {
            for (uint256 i = 0; i < 1000; ++i) {
                assertEq(LibDateTime.getDayOfWeek(t), wd);
                t += 86400;
                wd = (wd + 1) % 7;
            }
        }
    }

    function testIsValidDateTrue() public {
        assertTrue(LibDateTime.isValidDate(1970, 1, 1));
        assertTrue(LibDateTime.isValidDate(1971, 5, 31));
        assertTrue(LibDateTime.isValidDate(1971, 6, 30));
        assertTrue(LibDateTime.isValidDate(1971, 12, 31));
        assertTrue(LibDateTime.isValidDate(1972, 2, 28));
        assertTrue(LibDateTime.isValidDate(1972, 4, 30));
        assertTrue(LibDateTime.isValidDate(1972, 5, 31));
        assertTrue(LibDateTime.isValidDate(2000, 2, 29));
    }

    function testIsValidDateFalse() public {
        assertFalse(LibDateTime.isValidDate(0, 0, 0));
        assertFalse(LibDateTime.isValidDate(1970, 0, 0));
        assertFalse(LibDateTime.isValidDate(1970, 1, 0));
        assertFalse(LibDateTime.isValidDate(1969, 1, 1));
        assertFalse(LibDateTime.isValidDate(1800, 1, 1));
        assertFalse(
            LibDateTime.isValidDate(317027972476686572410305440929486321699336700043506886628630523577932824465, 1, 1)
        );
        assertFalse(LibDateTime.isValidDate(1970, 13, 1));
        assertFalse(LibDateTime.isValidDate(1700, 13, 1));
        assertFalse(LibDateTime.isValidDate(1970, 15, 32));
        assertFalse(LibDateTime.isValidDate(1970, 1, 32));
        assertFalse(LibDateTime.isValidDate(1970, 13, 1));
        assertFalse(LibDateTime.isValidDate(1879, 1, 1));
        assertFalse(LibDateTime.isValidDate(1970, 4, 31));
        assertFalse(LibDateTime.isValidDate(1970, 6, 31));
        assertFalse(LibDateTime.isValidDate(1970, 7, 32));
        assertFalse(LibDateTime.isValidDate(2000, 2, 30));
    }

    function testFuzzIsValidDate(
        uint256 y,
        uint256 m,
        uint256 d
    ) public {
        if (y > 1969 && y < 317027972476686572410305440929486321699336700043506886628630523577932824464) {
            if (m > 0 && m < 13 && d > 0 && d < LibDateTime.getDaysInMonth(y, m)) {
                assertTrue(LibDateTime.isValidDate(y, m, d));
            }
        } else {
            assertFalse(LibDateTime.isValidDate(y, m, d));
        }
    }

    function testgetNthDayOfWeekInMonthOfYear() public {
        // get 1st 2nd 3rd 4th monday in Novermber 2022
        assertEq(LibDateTime.getNthDayOfWeekInMonthOfYear(2022, 11, 1, 0), 1667779200);
        assertEq(LibDateTime.getNthDayOfWeekInMonthOfYear(2022, 11, 2, 0), 1668384000);
        assertEq(LibDateTime.getNthDayOfWeekInMonthOfYear(2022, 11, 3, 0), 1668988800);
        assertEq(LibDateTime.getNthDayOfWeekInMonthOfYear(2022, 11, 4, 0), 1669593600);
        assertEq(LibDateTime.getNthDayOfWeekInMonthOfYear(2022, 11, 5, 0), 0);

        // get 1st... 5th Wednesday in Novermber 2022
        assertEq(LibDateTime.getNthDayOfWeekInMonthOfYear(2022, 11, 1, 2), 1667347200);
        assertEq(LibDateTime.getNthDayOfWeekInMonthOfYear(2022, 11, 2, 2), 1667952000);
        assertEq(LibDateTime.getNthDayOfWeekInMonthOfYear(2022, 11, 3, 2), 1668556800);
        assertEq(LibDateTime.getNthDayOfWeekInMonthOfYear(2022, 11, 4, 2), 1669161600);
        assertEq(LibDateTime.getNthDayOfWeekInMonthOfYear(2022, 11, 5, 2), 1669766400);
        assertEq(LibDateTime.getNthDayOfWeekInMonthOfYear(2022, 11, 6, 2), 0);

        // get 1st... 5th Friday in December 2022
        assertEq(LibDateTime.getNthDayOfWeekInMonthOfYear(2022, 12, 1, 4), 1669939200);
        assertEq(LibDateTime.getNthDayOfWeekInMonthOfYear(2022, 12, 2, 4), 1670544000);
        assertEq(LibDateTime.getNthDayOfWeekInMonthOfYear(2022, 12, 3, 4), 1671148800);
        assertEq(LibDateTime.getNthDayOfWeekInMonthOfYear(2022, 12, 4, 4), 1671753600);
        assertEq(LibDateTime.getNthDayOfWeekInMonthOfYear(2022, 12, 5, 4), 1672358400);
        assertEq(LibDateTime.getNthDayOfWeekInMonthOfYear(2022, 12, 6, 4), 0);

        // get 1st... 5th Sunday in January 2023
        assertEq(LibDateTime.getNthDayOfWeekInMonthOfYear(2023, 1, 1, 6), 1672531200);
        assertEq(LibDateTime.getNthDayOfWeekInMonthOfYear(2023, 1, 2, 6), 1673136000);
        assertEq(LibDateTime.getNthDayOfWeekInMonthOfYear(2023, 1, 3, 6), 1673740800);
        assertEq(LibDateTime.getNthDayOfWeekInMonthOfYear(2023, 1, 4, 6), 1674345600);
        assertEq(LibDateTime.getNthDayOfWeekInMonthOfYear(2023, 1, 5, 6), 1674950400);
        assertEq(LibDateTime.getNthDayOfWeekInMonthOfYear(2023, 1, 6, 6), 0);
    }

    function testFuzzgetNthDayOfWeekInMonthOfYear(
        uint256 year,
        uint256 month,
        uint256 n,
        uint256 wd
    ) public {
        wd = _bound(wd, 0, 6);
        month = _bound(month, 1, 12);

        year = _bound(year, 1970, 3669305236998687180674831492239425019668248843096144521164705134005821);
        console.log(month, year);
        uint256 t = LibDateTime.getNthDayOfWeekInMonthOfYear(year, month, n, wd);
        uint256 day = LibDateTime.daysFromDate(year, month, 1);
        uint256 wd1 = (day + 3) % 7;
        uint256 diff;
        unchecked {
            diff = wd - wd1;
            diff = diff > 6 ? diff + 7 : diff;
        }
        console.log(wd1, diff, t);
        // console.log(LibDateTime.getDaysInMonth(year,month));
        if (n == 0 || n > 5) {
            assertEq(t, 0);
        } else {
            uint256 date = diff + (n - 1) * 7 + 1;
            uint256 md = LibDateTime.getDaysInMonth(year, month);
            if (date > md) {
                assertEq(t, 0);
            } else {
                assertEq(t, LibDateTime.timestampFromDate(year, month, date));
            }
        }
    }

    function getNextWeekDay() public {
        // 6 Novermber 2022 (1667692800) to next monday,Tuesday...,sunday
        assertEq(LibDateTime.getNextWeekDay(1667692800, 0), 1667779200);
        assertEq(LibDateTime.getNextWeekDay(1667692855, 1), 1667865600);
        assertEq(LibDateTime.getNextWeekDay(1667693000, 2), 1667952000);
        assertEq(LibDateTime.getNextWeekDay(1667693100, 3), 1668038400);
        assertEq(LibDateTime.getNextWeekDay(1667693186, 4), 1668124800);
        assertEq(LibDateTime.getNextWeekDay(1667693201, 5), 1668211200);
        assertEq(LibDateTime.getNextWeekDay(1667693264, 6), 1668297600);

        // 30 January 2023 (1675036800) to next monday,Tuesday...,sunday
        assertEq(LibDateTime.getNextWeekDay(1675036800, 0), 1675641600);
        assertEq(LibDateTime.getNextWeekDay(1675036800, 1), 1675123200);
        assertEq(LibDateTime.getNextWeekDay(1675036800, 2), 1675209600);
        assertEq(LibDateTime.getNextWeekDay(1675036800, 3), 1675296000);
        assertEq(LibDateTime.getNextWeekDay(1675036800, 4), 1675382400);
        assertEq(LibDateTime.getNextWeekDay(1675036800, 5), 1675468800);
        assertEq(LibDateTime.getNextWeekDay(1675036800, 6), 1675555200);
    }

    function testFuzzGetNextWeekDay(uint256 t, uint256 wd) public {
        if (t < 115792089237316195423570985008687907853269984665640564039457584007913129084800 && wd < 7) {
            uint256 currentweekday = (t / 86400 + 3) % 7;
            uint256 difference;
            unchecked {
                difference = wd - currentweekday;
                difference = (difference == 0 || difference > 6) ? difference + 7 : difference;
            }
            assertEq(LibDateTime.getNextWeekDay(t, wd), ((t / 86400) + difference) * 86400);
        } else {
            assertEq(LibDateTime.getNextWeekDay(t, wd), 0);
        }
    }
}
