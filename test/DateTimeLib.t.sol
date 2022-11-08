// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../test/utils/TestPlus.sol";
import {DateTimeLib} from "../src/utils/DateTimeLib.sol";

contract DateTimeLibTest is TestPlus {
    function testDateToEpochDay() public {
        assertEq(DateTimeLib.dateToEpochDay(1970, 1, 1), 0);
        assertEq(DateTimeLib.dateToEpochDay(1970, 1, 2), 1);
        assertEq(DateTimeLib.dateToEpochDay(1970, 2, 1), 31);
        assertEq(DateTimeLib.dateToEpochDay(1970, 3, 1), 59);
        assertEq(DateTimeLib.dateToEpochDay(1970, 4, 1), 90);
        assertEq(DateTimeLib.dateToEpochDay(1970, 5, 1), 120);
        assertEq(DateTimeLib.dateToEpochDay(1970, 6, 1), 151);
        assertEq(DateTimeLib.dateToEpochDay(1970, 7, 1), 181);
        assertEq(DateTimeLib.dateToEpochDay(1970, 8, 1), 212);
        assertEq(DateTimeLib.dateToEpochDay(1970, 9, 1), 243);
        assertEq(DateTimeLib.dateToEpochDay(1970, 10, 1), 273);
        assertEq(DateTimeLib.dateToEpochDay(1970, 11, 1), 304);
        assertEq(DateTimeLib.dateToEpochDay(1970, 12, 1), 334);
        assertEq(DateTimeLib.dateToEpochDay(1970, 12, 31), 364);
        assertEq(DateTimeLib.dateToEpochDay(1971, 1, 1), 365);
        assertEq(DateTimeLib.dateToEpochDay(1980, 11, 3), 3959);
        assertEq(DateTimeLib.dateToEpochDay(2000, 3, 1), 11017);
        assertEq(DateTimeLib.dateToEpochDay(2355, 12, 31), 140982);
        assertEq(DateTimeLib.dateToEpochDay(99999, 12, 31), 35804721);
        assertEq(DateTimeLib.dateToEpochDay(100000, 12, 31), 35805087);
        assertEq(DateTimeLib.dateToEpochDay(604800, 2, 29), 220179195);
        assertEq(DateTimeLib.dateToEpochDay(1667347200, 2, 29), 608985340227);
        assertEq(DateTimeLib.dateToEpochDay(1667952000, 2, 29), 609206238891);
    }

    function testDaysToDate() public {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = DateTimeLib.epochDayToDate(0);
        assertTrue(year == 1970 && month == 1 && day == 1);
        (year, month, day) = DateTimeLib.epochDayToDate(31);
        assertTrue(year == 1970 && month == 2 && day == 1);
        (year, month, day) = DateTimeLib.epochDayToDate(59);
        assertTrue(year == 1970 && month == 3 && day == 1);
        (year, month, day) = DateTimeLib.epochDayToDate(90);
        assertTrue(year == 1970 && month == 4 && day == 1);
        (year, month, day) = DateTimeLib.epochDayToDate(120);
        assertTrue(year == 1970 && month == 5 && day == 1);
        (year, month, day) = DateTimeLib.epochDayToDate(151);
        assertTrue(year == 1970 && month == 6 && day == 1);
        (year, month, day) = DateTimeLib.epochDayToDate(181);
        assertTrue(year == 1970 && month == 7 && day == 1);
        (year, month, day) = DateTimeLib.epochDayToDate(212);
        assertTrue(year == 1970 && month == 8 && day == 1);
        (year, month, day) = DateTimeLib.epochDayToDate(243);
        assertTrue(year == 1970 && month == 9 && day == 1);
        (year, month, day) = DateTimeLib.epochDayToDate(273);
        assertTrue(year == 1970 && month == 10 && day == 1);
        (year, month, day) = DateTimeLib.epochDayToDate(304);
        assertTrue(year == 1970 && month == 11 && day == 1);
        (year, month, day) = DateTimeLib.epochDayToDate(334);
        assertTrue(year == 1970 && month == 12 && day == 1);
        (year, month, day) = DateTimeLib.epochDayToDate(365);
        assertTrue(year == 1971 && month == 1 && day == 1);
        (year, month, day) = DateTimeLib.epochDayToDate(10987);
        assertTrue(year == 2000 && month == 1 && day == 31);
        (year, month, day) = DateTimeLib.epochDayToDate(18321);
        assertTrue(year == 2020 && month == 2 && day == 29);
        (year, month, day) = DateTimeLib.epochDayToDate(156468);
        assertTrue(year == 2398 && month == 5 && day == 25);
        (year, month, day) = DateTimeLib.epochDayToDate(35805087);
        assertTrue(year == 100000 && month == 12 && day == 31);
    }

    function testFuzzEpochDayToDate(uint256 epochDay) public {
        (uint256 y, uint256 m, uint256 d) = DateTimeLib.epochDayToDate(epochDay);
        assertEq(epochDay, DateTimeLib.dateToEpochDay(y, m, d));
    }

    function testFuzzDateToAndFroEpochDay(
        uint256 year,
        uint256 month,
        uint256 day
    ) public {
        year = _bound(year, 1970, DateTimeLib.MAX_SUPPORTED_YEAR);
        month = _bound(month, 1, 12);
        uint256 md = DateTimeLib.daysInMonth(year, month);
        day = _bound(day, 1, md);
        uint256 epochDay = DateTimeLib.dateToEpochDay(year, month, day);
        (uint256 y, uint256 m, uint256 d) = DateTimeLib.epochDayToDate(epochDay);
        assertTrue(year == y && month == m && day == d);
    }

    function testFuzzDateToAndFroEpochDay() public {
        unchecked {
            uint256 randomness;
            for (uint256 i; i < 256; ++i) {
                randomness = _stepRandomness(randomness);
                uint256 year = _bound(randomness, 1970, DateTimeLib.MAX_SUPPORTED_YEAR);
                randomness = _stepRandomness(randomness);
                uint256 month = _bound(randomness, 1, 12);
                uint256 md = DateTimeLib.daysInMonth(year, month);
                randomness = _stepRandomness(randomness);
                uint256 day = _bound(randomness, 1, md);
                uint256 epochDay = DateTimeLib.dateToEpochDay(year, month, day);
                (uint256 y, uint256 m, uint256 d) = DateTimeLib.epochDayToDate(epochDay);
                assertTrue(year == y && month == m && day == d);
            }
        }
    }

    function testFuzzDateToAndFroTimestamp() public {
        unchecked {
            uint256 randomness;
            for (uint256 i; i < 256; ++i) {
                randomness = _stepRandomness(randomness);
                uint256 year = _bound(randomness, 1970, DateTimeLib.MAX_SUPPORTED_YEAR);
                randomness = _stepRandomness(randomness);
                uint256 month = _bound(randomness, 1, 12);
                uint256 md = DateTimeLib.daysInMonth(year, month);
                randomness = _stepRandomness(randomness);
                uint256 day = _bound(randomness, 1, md);
                uint256 timestamp = DateTimeLib.dateToTimestamp(year, month, day);
                assertEq(timestamp, DateTimeLib.dateToEpochDay(year, month, day) * 86400);
                (uint256 y, uint256 m, uint256 d) = DateTimeLib.timestampToDate(timestamp);
                assertTrue(year == y && month == m && day == d);
            }
        }
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

    function testFuzzIsLeapYear(uint256 year) public {
        assertEq(DateTimeLib.isLeapYear(year), (year % 4 == 0) && (year % 100 != 0 || year % 400 == 0));
    }

    function testDaysInMonth() public {
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

    function testFuzzDaysInMonth(uint256 year, uint256 month) public {
        month = _bound(month, 1, 12);
        if (DateTimeLib.isLeapYear(year) && month == 2) {
            assertEq(DateTimeLib.daysInMonth(year, month), 29);
        } else if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            assertEq(DateTimeLib.daysInMonth(year, month), 31);
        } else if (month == 2) {
            assertEq(DateTimeLib.daysInMonth(year, month), 28);
        } else {
            assertEq(DateTimeLib.daysInMonth(year, month), 30);
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

    function testFuzzDayOfWeek() public {
        uint256 timestamp = 0;
        uint256 weekday = 3;
        unchecked {
            for (uint256 i = 0; i < 1000; ++i) {
                assertEq(DateTimeLib.dayOfWeek(timestamp), weekday);
                timestamp += 86400;
                weekday = (weekday + 1) % 7;
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
        assertTrue(DateTimeLib.isSupportedDate(DateTimeLib.MAX_SUPPORTED_YEAR, 5, 31));
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
        assertFalse(DateTimeLib.isSupportedDate(DateTimeLib.MAX_SUPPORTED_YEAR + 1, 5, 31));
        assertFalse(DateTimeLib.isSupportedDate(type(uint256).max, 5, 31));
    }

    function testFuzzIsSupportedDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) public {
        bool isSupportedYear = 1970 <= year && year <= DateTimeLib.MAX_SUPPORTED_YEAR;
        bool isSupportedMonth = 1 <= month && month <= 12;
        bool isSupportedDay = 1 <= day && day <= DateTimeLib.daysInMonth(year, month);
        bool isSupported = isSupportedYear && isSupportedMonth && isSupportedDay;
        assertEq(DateTimeLib.isSupportedDate(year, month, day), isSupported);
    }

    function testIsSupportedEpochDayTrue() public {
        assertTrue(DateTimeLib.isSupportedEpochDay(0));
        assertTrue(DateTimeLib.isSupportedEpochDay(DateTimeLib.MAX_SUPPORTED_EPOCH_DAY));
    }

    function testIsSupportedEpochDayFalse() public {
        assertFalse(DateTimeLib.isSupportedEpochDay(DateTimeLib.MAX_SUPPORTED_EPOCH_DAY + 1));
        assertFalse(DateTimeLib.isSupportedEpochDay(DateTimeLib.MAX_SUPPORTED_EPOCH_DAY + 2));
    }

    function testIsSupportedTimestampTrue() public {
        assertTrue(DateTimeLib.isSupportedTimestamp(0));
        assertTrue(DateTimeLib.isSupportedTimestamp(DateTimeLib.MAX_SUPPORTED_TIMESTAMP));
    }

    function testIsSupportedTimestampFalse() public {
        assertFalse(DateTimeLib.isSupportedTimestamp(DateTimeLib.MAX_SUPPORTED_TIMESTAMP + 1));
        assertFalse(DateTimeLib.isSupportedTimestamp(DateTimeLib.MAX_SUPPORTED_TIMESTAMP + 2));
    }

    function testNthWeekdayInMonthOfYearTimestamp() public {
        uint256 wd;
        // 1st 2nd 3rd 4th monday in Novermber 2022.
        wd = DateTimeLib.MON;
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 11, 1, wd), 1667779200);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 11, 2, wd), 1668384000);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 11, 3, wd), 1668988800);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 11, 4, wd), 1669593600);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 11, 5, wd), 0);

        // 1st... 5th Wednesday in Novermber 2022.
        wd = DateTimeLib.WED;
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 11, 1, wd), 1667347200);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 11, 2, wd), 1667952000);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 11, 3, wd), 1668556800);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 11, 4, wd), 1669161600);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 11, 5, wd), 1669766400);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 11, 6, wd), 0);

        // 1st... 5th Friday in December 2022.
        wd = DateTimeLib.FRI;
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 12, 1, wd), 1669939200);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 12, 2, wd), 1670544000);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 12, 3, wd), 1671148800);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 12, 4, wd), 1671753600);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 12, 5, wd), 1672358400);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 12, 6, wd), 0);

        // 1st... 5th Sunday in January 2023.
        wd = DateTimeLib.SUN;
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2023, 1, 1, wd), 1672531200);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2023, 1, 2, wd), 1673136000);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2023, 1, 3, wd), 1673740800);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2023, 1, 4, wd), 1674345600);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2023, 1, 5, wd), 1674950400);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2023, 1, 6, wd), 0);
    }

    function testFuzzNthWeekdayInMonthOfYearTimestamp(
        uint256 year,
        uint256 month,
        uint256 n,
        uint256 weekday
    ) public {
        unchecked {
            year = _bound(year, 1970, DateTimeLib.MAX_SUPPORTED_YEAR);
            month = _bound(month, 1, 12);
            n = _bound(n, 1, 10);
            weekday = _bound(weekday, 0, 6);
            // Count number of weekdays for the month in the year.
            uint256 md = DateTimeLib.daysInMonth(year, month);
            uint256 timestamp = DateTimeLib.dateToTimestamp(year, month, 1);
            uint256 m;
            uint256 found;
            for (uint256 i; i < md; ) {
                if (DateTimeLib.dayOfWeek(timestamp) == weekday) {
                    if (++m == n) {
                        found = 1;
                        break;
                    }
                }
                if (m == 0) {
                    timestamp += 86400;
                    i += 1;
                } else {
                    timestamp += 86400 * 7;
                    i += 7;
                }
            }
            assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(year, month, n, weekday), found * timestamp);
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

    function testFuzzMondayTimestamp(uint256 timestamp) public {
        uint256 day = timestamp / 86400;
        uint256 weekday = (day + 3) % 7;
        assertEq(DateTimeLib.mondayTimestamp(timestamp), timestamp > 345599 ? (day - weekday) * 86400 : 0);
    }
}
