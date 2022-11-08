// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../test/utils/TestPlus.sol";
import {DateTimeLib} from "../src/utils/DateTimeLib.sol";

contract DateTimeLibTest is TestPlus {
    function testDaysFromDate() public {
        assertEq(DateTimeLib.dateToDays(1970, 1, 1), 0);
        assertEq(DateTimeLib.dateToDays(1970, 1, 2), 1);
        assertEq(DateTimeLib.dateToDays(1970, 2, 1), 31);
        assertEq(DateTimeLib.dateToDays(1970, 3, 1), 59);
        assertEq(DateTimeLib.dateToDays(1970, 4, 1), 90);
        assertEq(DateTimeLib.dateToDays(1970, 5, 1), 120);
        assertEq(DateTimeLib.dateToDays(1970, 6, 1), 151);
        assertEq(DateTimeLib.dateToDays(1970, 7, 1), 181);
        assertEq(DateTimeLib.dateToDays(1970, 8, 1), 212);
        assertEq(DateTimeLib.dateToDays(1970, 9, 1), 243);
        assertEq(DateTimeLib.dateToDays(1970, 10, 1), 273);
        assertEq(DateTimeLib.dateToDays(1970, 11, 1), 304);
        assertEq(DateTimeLib.dateToDays(1970, 12, 1), 334);
        assertEq(DateTimeLib.dateToDays(1970, 12, 31), 364);
        assertEq(DateTimeLib.dateToDays(1971, 1, 1), 365);
        assertEq(DateTimeLib.dateToDays(1980, 11, 3), 3959);
        assertEq(DateTimeLib.dateToDays(2000, 3, 1), 11017);
        assertEq(DateTimeLib.dateToDays(2355, 12, 31), 140982);
        assertEq(DateTimeLib.dateToDays(99999, 12, 31), 35804721);
        assertEq(DateTimeLib.dateToDays(100000, 12, 31), 35805087);
        assertEq(DateTimeLib.dateToDays(604800, 2, 29), 220179195);
        assertEq(DateTimeLib.dateToDays(1667347200, 2, 29), 608985340227);
        assertEq(DateTimeLib.dateToDays(1667952000, 2, 29), 609206238891);
    }

    function testDaysToDate() public {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = DateTimeLib.daysToDate(0);
        assertTrue(year == 1970 && month == 1 && day == 1);
        (year, month, day) = DateTimeLib.daysToDate(31);
        assertTrue(year == 1970 && month == 2 && day == 1);
        (year, month, day) = DateTimeLib.daysToDate(59);
        assertTrue(year == 1970 && month == 3 && day == 1);
        (year, month, day) = DateTimeLib.daysToDate(90);
        assertTrue(year == 1970 && month == 4 && day == 1);
        (year, month, day) = DateTimeLib.daysToDate(120);
        assertTrue(year == 1970 && month == 5 && day == 1);
        (year, month, day) = DateTimeLib.daysToDate(151);
        assertTrue(year == 1970 && month == 6 && day == 1);
        (year, month, day) = DateTimeLib.daysToDate(181);
        assertTrue(year == 1970 && month == 7 && day == 1);
        (year, month, day) = DateTimeLib.daysToDate(212);
        assertTrue(year == 1970 && month == 8 && day == 1);
        (year, month, day) = DateTimeLib.daysToDate(243);
        assertTrue(year == 1970 && month == 9 && day == 1);
        (year, month, day) = DateTimeLib.daysToDate(273);
        assertTrue(year == 1970 && month == 10 && day == 1);
        (year, month, day) = DateTimeLib.daysToDate(304);
        assertTrue(year == 1970 && month == 11 && day == 1);
        (year, month, day) = DateTimeLib.daysToDate(334);
        assertTrue(year == 1970 && month == 12 && day == 1);
        (year, month, day) = DateTimeLib.daysToDate(365);
        assertTrue(year == 1971 && month == 1 && day == 1);
        (year, month, day) = DateTimeLib.daysToDate(10987);
        assertTrue(year == 2000 && month == 1 && day == 31);
        (year, month, day) = DateTimeLib.daysToDate(18321);
        assertTrue(year == 2020 && month == 2 && day == 29);
        (year, month, day) = DateTimeLib.daysToDate(156468);
        assertTrue(year == 2398 && month == 5 && day == 25);
        (year, month, day) = DateTimeLib.daysToDate(35805087);
        assertTrue(year == 100000 && month == 12 && day == 31);
    }

    function testFuzzDaysToDate(uint256 z) public {
        (uint256 y, uint256 m, uint256 d) = DateTimeLib.daysToDate(z);
        uint256 day = DateTimeLib.dateToDays(y, m, d);
        assertEq(z, day);
    }

    function testFuzzDaysFromDate(
        uint256 _y,
        uint256 _m,
        uint256 _d
    ) public {
        _y = _bound(_y, 1970, DateTimeLib.MAX_SUPPORTED_YEAR);
        _m = _bound(_m, 1, 12);
        uint256 md = DateTimeLib.daysInMonth(_y, _m);
        _d = _bound(_d, 1, md);
        uint256 day = DateTimeLib.dateToDays(_y, _m, _d);
        (uint256 y, uint256 m, uint256 d) = DateTimeLib.daysToDate(day);
        assertTrue(_y == y && _m == m && _d == d);
    }

    function testIsLeapYear() public {
        assertTrue(DateTimeLib.isLeapYear(2000));
        assertTrue(DateTimeLib.isLeapYear(2024));
        assertTrue(DateTimeLib.isLeapYear(2048));
        assertTrue(DateTimeLib.isLeapYear(2072));
        assertTrue(DateTimeLib.isLeapYear(2104));
        assertTrue(DateTimeLib.isLeapYear(2128));
        assertTrue(DateTimeLib.isLeapYear(10032));
        assertTrue(DateTimeLib.isLeapYear(10124));
        assertTrue(DateTimeLib.isLeapYear(10296));
        assertTrue(DateTimeLib.isLeapYear(10400));
        assertTrue(DateTimeLib.isLeapYear(10916));
    }

    function testFuzzIsLeapYear(uint256 y) public {
        if ((y % 4 == 0) && (y % 100 != 0 || y % 400 == 0)) {
            assertTrue(DateTimeLib.isLeapYear(y));
        } else {
            assertFalse(DateTimeLib.isLeapYear(y));
        }
    }

    function testGetDaysInMonth() public {
        assertEq(DateTimeLib.daysInMonth(2022, 1), 31);
        assertEq(DateTimeLib.daysInMonth(2022, 2), 28);
        assertEq(DateTimeLib.daysInMonth(2022, 3), 31);
        assertEq(DateTimeLib.daysInMonth(2022, 4), 30);
        assertEq(DateTimeLib.daysInMonth(2022, 5), 31);
        assertEq(DateTimeLib.daysInMonth(2022, 6), 30);
        assertEq(DateTimeLib.daysInMonth(2022, 7), 31);
        assertEq(DateTimeLib.daysInMonth(2022, 8), 31);
        assertEq(DateTimeLib.daysInMonth(2022, 9), 30);
        assertEq(DateTimeLib.daysInMonth(2022, 10), 31);
        assertEq(DateTimeLib.daysInMonth(2022, 11), 30);
        assertEq(DateTimeLib.daysInMonth(2022, 12), 31);
        assertEq(DateTimeLib.daysInMonth(2024, 1), 31);
        assertEq(DateTimeLib.daysInMonth(2024, 2), 29);
        assertEq(DateTimeLib.daysInMonth(1900, 2), 28);
    }

    function testFuzzGetDaysInMonth(uint256 y, uint256 m) public {
        m = _bound(m, 1, 12);
        if (DateTimeLib.isLeapYear(y) && m == 2) {
            assertEq(DateTimeLib.daysInMonth(y, m), 29);
        } else if (m == 1 || m == 3 || m == 5 || m == 7 || m == 8 || m == 10 || m == 12) {
            assertEq(DateTimeLib.daysInMonth(y, m), 31);
        } else if (m == 2) {
            assertEq(DateTimeLib.daysInMonth(y, m), 28);
        } else {
            assertEq(DateTimeLib.daysInMonth(y, m), 30);
        }
    }

    function testDayOfWeek() public {
        assertEq(DateTimeLib.dayOfWeek(1), 3);
        assertEq(DateTimeLib.dayOfWeek(86400), 4);
        assertEq(DateTimeLib.dayOfWeek(86401), 4);
        assertEq(DateTimeLib.dayOfWeek(172800), 5);
        assertEq(DateTimeLib.dayOfWeek(259200), 6);
        assertEq(DateTimeLib.dayOfWeek(345600), 0);
        assertEq(DateTimeLib.dayOfWeek(432000), 1);
        assertEq(DateTimeLib.dayOfWeek(518400), 2);
    }

    function testFuzzGetDayOfWeek() public {
        uint256 t = 0;
        uint256 wd = 3;
        unchecked {
            for (uint256 i = 0; i < 1000; ++i) {
                assertEq(DateTimeLib.dayOfWeek(t), wd);
                t += 86400;
                wd = (wd + 1) % 7;
            }
        }
    }

    function testIsSupportedDateTrue() public {
        assertTrue(DateTimeLib.isSupportedDate(1970, 1, 1));
        assertTrue(DateTimeLib.isSupportedDate(1971, 5, 31));
        assertTrue(DateTimeLib.isSupportedDate(1971, 6, 30));
        assertTrue(DateTimeLib.isSupportedDate(1971, 12, 31));
        assertTrue(DateTimeLib.isSupportedDate(1972, 2, 28));
        assertTrue(DateTimeLib.isSupportedDate(1972, 4, 30));
        assertTrue(DateTimeLib.isSupportedDate(1972, 5, 31));
        assertTrue(DateTimeLib.isSupportedDate(2000, 2, 29));
    }

    function testIsSupportedDateFalse() public {
        assertFalse(DateTimeLib.isSupportedDate(0, 0, 0));
        assertFalse(DateTimeLib.isSupportedDate(1970, 0, 0));
        assertFalse(DateTimeLib.isSupportedDate(1970, 1, 0));
        assertFalse(DateTimeLib.isSupportedDate(1969, 1, 1));
        assertFalse(DateTimeLib.isSupportedDate(1800, 1, 1));
        assertFalse(DateTimeLib.isSupportedDate(1970, 13, 1));
        assertFalse(DateTimeLib.isSupportedDate(1700, 13, 1));
        assertFalse(DateTimeLib.isSupportedDate(1970, 15, 32));
        assertFalse(DateTimeLib.isSupportedDate(1970, 1, 32));
        assertFalse(DateTimeLib.isSupportedDate(1970, 13, 1));
        assertFalse(DateTimeLib.isSupportedDate(1879, 1, 1));
        assertFalse(DateTimeLib.isSupportedDate(1970, 4, 31));
        assertFalse(DateTimeLib.isSupportedDate(1970, 6, 31));
        assertFalse(DateTimeLib.isSupportedDate(1970, 7, 32));
        assertFalse(DateTimeLib.isSupportedDate(2000, 2, 30));
    }

    function testFuzzIsSupportedDate(
        uint256 y,
        uint256 m,
        uint256 d
    ) public {
        assertEq(
            DateTimeLib.isSupportedDate(y, m, d),
            1970 <= y &&
                y <= DateTimeLib.MAX_SUPPORTED_YEAR &&
                1 <= m &&
                m < 12 &&
                1 <= d &&
                d < DateTimeLib.daysInMonth(y, m)
        );
    }

    function testNthWeekdayInMonthOfYearTimestamp() public {
        // get 1st 2nd 3rd 4th monday in Novermber 2022
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 11, 1, 0), 1667779200);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 11, 2, 0), 1668384000);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 11, 3, 0), 1668988800);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 11, 4, 0), 1669593600);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 11, 5, 0), 0);

        // get 1st... 5th Wednesday in Novermber 2022
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 11, 1, 2), 1667347200);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 11, 2, 2), 1667952000);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 11, 3, 2), 1668556800);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 11, 4, 2), 1669161600);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 11, 5, 2), 1669766400);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 11, 6, 2), 0);

        // get 1st... 5th Friday in December 2022
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 12, 1, 4), 1669939200);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 12, 2, 4), 1670544000);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 12, 3, 4), 1671148800);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 12, 4, 4), 1671753600);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 12, 5, 4), 1672358400);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 12, 6, 4), 0);

        // get 1st... 5th Sunday in January 2023
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2023, 1, 1, 6), 1672531200);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2023, 1, 2, 6), 1673136000);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2023, 1, 3, 6), 1673740800);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2023, 1, 4, 6), 1674345600);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2023, 1, 5, 6), 1674950400);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2023, 1, 6, 6), 0);
    }

    function testFuzzGetNthDayOfWeekInMonthOfYear(
        uint256 year,
        uint256 month,
        uint256 n,
        uint256 wd
    ) public {
        wd = _bound(wd, 0, 6);
        month = _bound(month, 1, 12);
        year = _bound(year, 1970, 1 << 128);
        uint256 t = DateTimeLib.nthWeekdayInMonthOfYearTimestamp(year, month, n, wd);
        uint256 day = DateTimeLib.dateToDays(year, month, 1);
        uint256 wd1 = (day + 3) % 7;
        uint256 diff;
        unchecked {
            diff = wd - wd1;
            diff = diff > 6 ? diff + 7 : diff;
        }
        if (n == 0 || n > 5) {
            assertEq(t, 0);
        } else {
            uint256 date = diff + (n - 1) * 7 + 1;
            uint256 md = DateTimeLib.daysInMonth(year, month);
            if (date > md) {
                assertEq(t, 0);
            } else {
                assertEq(t, DateTimeLib.dateToTimestamp(year, month, date));
            }
        }
    }

    function testMondayTimestamp() public {
        // Thursday 01 January 1970 -> 0
        assertEq(DateTimeLib.mondayTimestamp(0), 0);
        // Friday 02 January 1970 -> 86400
        assertEq(DateTimeLib.mondayTimestamp(86400), 0);
        // Saturday 03 January 1970 -> 172800
        assertEq(DateTimeLib.mondayTimestamp(172800), 0);
        // Sunday 04 January 1970 -> 259200
        assertEq(DateTimeLib.mondayTimestamp(259200), 0);
        // Monday 05 January 19700 -> 345600
        assertEq(DateTimeLib.mondayTimestamp(345600), 345600);
        // Monday 07 Novermber 2022 -> 1667779200
        assertEq(DateTimeLib.mondayTimestamp(1667779200), 1667779200);
        // Sunday 06 Novermber 2022 -> 1667692800
        assertEq(DateTimeLib.mondayTimestamp(1667692800), 1667174400);
        // Saturday 05 Novermber 2022 -> 1667606400
        assertEq(DateTimeLib.mondayTimestamp(1667606400), 1667174400);
        // Friday 04 Novermber 2022 -> 1667520000
        assertEq(DateTimeLib.mondayTimestamp(1667520000), 1667174400);
        // Thursday 03 Novermber 2022 -> 1667433600
        assertEq(DateTimeLib.mondayTimestamp(1667433600), 1667174400);
        // Wednesday 02 Novermber 2022 -> 1667347200
        assertEq(DateTimeLib.mondayTimestamp(1667347200), 1667174400);
        // Tuesday 01 Novermber 2022 -> 1667260800
        assertEq(DateTimeLib.mondayTimestamp(1667260800), 1667174400);
        // Monday 01 Novermber 2022 -> 1667260800
        assertEq(DateTimeLib.mondayTimestamp(1667174400), 1667174400);
    }

    function testFuzzMondayTimestamp(uint256 t) public {
        uint256 day = t / 86400;
        uint256 weekday = (day + 3) % 7;
        uint256 nt = DateTimeLib.mondayTimestamp(t);
        if (t > 345599) {
            assertEq(nt, (day - weekday) * 86400);
        } else {
            assertEq(nt, 0);
        }
    }
}
