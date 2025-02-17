// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../test/utils/SoladyTest.sol";
import {DateTimeLib} from "../src/utils/DateTimeLib.sol";

contract DateTimeLibTest is SoladyTest {
    struct DateTime {
        uint256 year;
        uint256 month;
        uint256 day;
        uint256 hour;
        uint256 minute;
        uint256 second;
    }

    function testDateTimeMaxSupported() public {
        DateTime memory d;
        assertEq(
            DateTimeLib.dateToEpochDay(DateTimeLib.MAX_SUPPORTED_YEAR, 12, 31),
            DateTimeLib.MAX_SUPPORTED_EPOCH_DAY
        );
        assertEq(
            DateTimeLib.dateToTimestamp(DateTimeLib.MAX_SUPPORTED_YEAR, 12, 31) + 86400 - 1,
            DateTimeLib.MAX_SUPPORTED_TIMESTAMP
        );
        (d.year, d.month, d.day) = DateTimeLib.timestampToDate(DateTimeLib.MAX_SUPPORTED_TIMESTAMP);
        assertTrue(d.year == DateTimeLib.MAX_SUPPORTED_YEAR && d.month == 12 && d.day == 31);
        (d.year, d.month, d.day) = DateTimeLib.epochDayToDate(DateTimeLib.MAX_SUPPORTED_EPOCH_DAY);
        assertTrue(d.year == DateTimeLib.MAX_SUPPORTED_YEAR && d.month == 12 && d.day == 31);
        (d.year, d.month, d.day) =
            DateTimeLib.timestampToDate(DateTimeLib.MAX_SUPPORTED_TIMESTAMP + 1);
        assertFalse(d.year == DateTimeLib.MAX_SUPPORTED_YEAR && d.month == 12 && d.day == 31);
        (d.year, d.month, d.day) =
            DateTimeLib.epochDayToDate(DateTimeLib.MAX_SUPPORTED_EPOCH_DAY + 1);
        assertFalse(d.year == DateTimeLib.MAX_SUPPORTED_YEAR && d.month == 12 && d.day == 31);
    }

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

    function testDateToEpochDayGas() public {
        unchecked {
            uint256 sum;
            for (uint256 i; i < 256; ++i) {
                uint256 year = _bound(_random(), 1970, DateTimeLib.MAX_SUPPORTED_YEAR);
                uint256 month = _bound(_random(), 1, 12);
                uint256 md = DateTimeLib.daysInMonth(year, month);
                uint256 day = _bound(_random(), 1, md);
                uint256 epochDay = DateTimeLib.dateToEpochDay(year, month, day);
                sum += epochDay;
            }
            assertTrue(sum != 0);
        }
    }

    function testDateToEpochDayGas2() public {
        unchecked {
            uint256 sum;
            for (uint256 i; i < 256; ++i) {
                uint256 year = _bound(_random(), 1970, DateTimeLib.MAX_SUPPORTED_YEAR);
                uint256 month = _bound(_random(), 1, 12);
                uint256 md = DateTimeLib.daysInMonth(year, month);
                uint256 day = _bound(_random(), 1, md);
                uint256 epochDay = _dateToEpochDayOriginal2(year, month, day);
                sum += epochDay;
            }
            assertTrue(sum != 0);
        }
    }

    function testEpochDayToDateGas() public {
        unchecked {
            uint256 sum;
            for (uint256 i; i < 256; ++i) {
                uint256 epochDay = _bound(_random(), 0, DateTimeLib.MAX_SUPPORTED_EPOCH_DAY);
                (uint256 year, uint256 month, uint256 day) = DateTimeLib.epochDayToDate(epochDay);
                sum += year + month + day;
            }
            assertTrue(sum != 0);
        }
    }

    function testEpochDayToDateGas2() public {
        unchecked {
            uint256 sum;
            for (uint256 i; i < 256; ++i) {
                uint256 epochDay = _bound(_random(), 0, DateTimeLib.MAX_SUPPORTED_EPOCH_DAY);
                (uint256 year, uint256 month, uint256 day) = _epochDayToDateOriginal2(epochDay);
                sum += year + month + day;
            }
            assertTrue(sum != 0);
        }
    }

    function testDateToEpochDayDifferential(DateTime memory d) public {
        d.year = _bound(d.year, 1970, DateTimeLib.MAX_SUPPORTED_YEAR);
        d.month = _bound(d.month, 1, 12);
        d.day = _bound(d.day, 1, DateTimeLib.daysInMonth(d.year, d.month));
        uint256 expectedResult = _dateToEpochDayOriginal(d.year, d.month, d.day);
        assertEq(DateTimeLib.dateToEpochDay(d.year, d.month, d.day), expectedResult);
    }

    function testDateToEpochDayDifferential2(DateTime memory d) public {
        d.year = _bound(d.year, 1970, DateTimeLib.MAX_SUPPORTED_YEAR);
        d.month = _bound(d.month, 1, 12);
        d.day = _bound(d.day, 1, DateTimeLib.daysInMonth(d.year, d.month));
        uint256 expectedResult = _dateToEpochDayOriginal2(d.year, d.month, d.day);
        assertEq(DateTimeLib.dateToEpochDay(d.year, d.month, d.day), expectedResult);
    }

    function testEpochDayToDateDifferential(uint256 timestamp) public {
        timestamp = _bound(timestamp, 0, DateTimeLib.MAX_SUPPORTED_TIMESTAMP);
        DateTime memory a;
        DateTime memory b;
        (a.year, a.month, a.day) = _epochDayToDateOriginal(timestamp);
        (b.year, b.month, b.day) = DateTimeLib.epochDayToDate(timestamp);
        assertTrue(a.year == b.year && a.month == b.month && a.day == b.day);
    }

    function testEpochDayToDateDifferential2(uint256 timestamp) public {
        timestamp = _bound(timestamp, 0, DateTimeLib.MAX_SUPPORTED_TIMESTAMP);
        DateTime memory a;
        DateTime memory b;
        (a.year, a.month, a.day) = _epochDayToDateOriginal2(timestamp);
        (b.year, b.month, b.day) = DateTimeLib.epochDayToDate(timestamp);
        assertTrue(a.year == b.year && a.month == b.month && a.day == b.day);
    }

    function testDaysToDate() public {
        DateTime memory d;
        (d.year, d.month, d.day) = DateTimeLib.epochDayToDate(0);
        assertTrue(d.year == 1970 && d.month == 1 && d.day == 1);
        (d.year, d.month, d.day) = DateTimeLib.epochDayToDate(31);
        assertTrue(d.year == 1970 && d.month == 2 && d.day == 1);
        (d.year, d.month, d.day) = DateTimeLib.epochDayToDate(59);
        assertTrue(d.year == 1970 && d.month == 3 && d.day == 1);
        (d.year, d.month, d.day) = DateTimeLib.epochDayToDate(90);
        assertTrue(d.year == 1970 && d.month == 4 && d.day == 1);
        (d.year, d.month, d.day) = DateTimeLib.epochDayToDate(120);
        assertTrue(d.year == 1970 && d.month == 5 && d.day == 1);
        (d.year, d.month, d.day) = DateTimeLib.epochDayToDate(151);
        assertTrue(d.year == 1970 && d.month == 6 && d.day == 1);
        (d.year, d.month, d.day) = DateTimeLib.epochDayToDate(181);
        assertTrue(d.year == 1970 && d.month == 7 && d.day == 1);
        (d.year, d.month, d.day) = DateTimeLib.epochDayToDate(212);
        assertTrue(d.year == 1970 && d.month == 8 && d.day == 1);
        (d.year, d.month, d.day) = DateTimeLib.epochDayToDate(243);
        assertTrue(d.year == 1970 && d.month == 9 && d.day == 1);
        (d.year, d.month, d.day) = DateTimeLib.epochDayToDate(273);
        assertTrue(d.year == 1970 && d.month == 10 && d.day == 1);
        (d.year, d.month, d.day) = DateTimeLib.epochDayToDate(304);
        assertTrue(d.year == 1970 && d.month == 11 && d.day == 1);
        (d.year, d.month, d.day) = DateTimeLib.epochDayToDate(334);
        assertTrue(d.year == 1970 && d.month == 12 && d.day == 1);
        (d.year, d.month, d.day) = DateTimeLib.epochDayToDate(365);
        assertTrue(d.year == 1971 && d.month == 1 && d.day == 1);
        (d.year, d.month, d.day) = DateTimeLib.epochDayToDate(10987);
        assertTrue(d.year == 2000 && d.month == 1 && d.day == 31);
        (d.year, d.month, d.day) = DateTimeLib.epochDayToDate(18321);
        assertTrue(d.year == 2020 && d.month == 2 && d.day == 29);
        (d.year, d.month, d.day) = DateTimeLib.epochDayToDate(156468);
        assertTrue(d.year == 2398 && d.month == 5 && d.day == 25);
        (d.year, d.month, d.day) = DateTimeLib.epochDayToDate(35805087);
        assertTrue(d.year == 100000 && d.month == 12 && d.day == 31);
    }

    function testEpochDayToDate(uint256 epochDay) public {
        DateTime memory d;
        (d.year, d.month, d.day) = DateTimeLib.epochDayToDate(epochDay);
        assertEq(epochDay, DateTimeLib.dateToEpochDay(d.year, d.month, d.day));
    }

    function testDateToAndFroEpochDay(DateTime memory a) public {
        a.year = _bound(a.year, 1970, DateTimeLib.MAX_SUPPORTED_YEAR);
        a.month = _bound(a.month, 1, 12);
        uint256 md = DateTimeLib.daysInMonth(a.year, a.month);
        a.day = _bound(a.day, 1, md);
        uint256 epochDay = DateTimeLib.dateToEpochDay(a.year, a.month, a.day);
        DateTime memory b;
        (b.year, b.month, b.day) = DateTimeLib.epochDayToDate(epochDay);
        assertTrue(a.year == b.year && a.month == b.month && a.day == b.day);
    }

    function testDateTimeToAndFroTimestamp(DateTime memory a) public {
        a.year = _bound(a.year, 1970, DateTimeLib.MAX_SUPPORTED_YEAR);
        a.month = _bound(a.month, 1, 12);
        uint256 md = DateTimeLib.daysInMonth(a.year, a.month);
        a.day = _bound(a.day, 1, md);
        a.hour = _bound(a.hour, 0, 23);
        a.minute = _bound(a.minute, 0, 59);
        a.second = _bound(a.second, 0, 59);
        uint256 timestamp =
            DateTimeLib.dateTimeToTimestamp(a.year, a.month, a.day, a.hour, a.minute, a.second);
        DateTime memory b;
        (b.year, b.month, b.day, b.hour, b.minute, b.second) =
            DateTimeLib.timestampToDateTime(timestamp);
        assertTrue(a.year == b.year && a.month == b.month && a.day == b.day);
        assertTrue(a.hour == b.hour && a.minute == b.minute && a.second == b.second);
    }

    function testDateToAndFroEpochDay() public {
        unchecked {
            for (uint256 i; i < 256; ++i) {
                uint256 year = _bound(_random(), 1970, DateTimeLib.MAX_SUPPORTED_YEAR);
                uint256 month = _bound(_random(), 1, 12);
                uint256 md = DateTimeLib.daysInMonth(year, month);
                uint256 day = _bound(_random(), 1, md);
                uint256 epochDay = DateTimeLib.dateToEpochDay(year, month, day);
                (uint256 y, uint256 m, uint256 d) = DateTimeLib.epochDayToDate(epochDay);
                assertTrue(year == y && month == m && day == d);
            }
        }
    }

    function testDateToAndFroTimestamp() public {
        unchecked {
            for (uint256 i; i < 256; ++i) {
                uint256 year = _bound(_random(), 1970, DateTimeLib.MAX_SUPPORTED_YEAR);
                uint256 month = _bound(_random(), 1, 12);
                uint256 md = DateTimeLib.daysInMonth(year, month);
                uint256 day = _bound(_random(), 1, md);
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

    function testIsLeapYear(uint256 year) public {
        assertEq(
            DateTimeLib.isLeapYear(year), (year % 4 == 0) && (year % 100 != 0 || year % 400 == 0)
        );
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

    function testDaysInMonth(uint256 year, uint256 month) public {
        month = _bound(month, 1, 12);
        if (DateTimeLib.isLeapYear(year) && month == 2) {
            assertEq(DateTimeLib.daysInMonth(year, month), 29);
        } else if (
            month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10
                || month == 12
        ) {
            assertEq(DateTimeLib.daysInMonth(year, month), 31);
        } else if (month == 2) {
            assertEq(DateTimeLib.daysInMonth(year, month), 28);
        } else {
            assertEq(DateTimeLib.daysInMonth(year, month), 30);
        }
    }

    function testWeekday() public {
        assertEq(DateTimeLib.weekday(1), 4);
        assertEq(DateTimeLib.weekday(86400), 5);
        assertEq(DateTimeLib.weekday(86401), 5);
        assertEq(DateTimeLib.weekday(172800), 6);
        assertEq(DateTimeLib.weekday(259200), 7);
        assertEq(DateTimeLib.weekday(345600), 1);
        assertEq(DateTimeLib.weekday(432000), 2);
        assertEq(DateTimeLib.weekday(518400), 3);
    }

    function testDayOfWeek() public {
        uint256 timestamp = 0;
        uint256 weekday = 3;
        unchecked {
            for (uint256 i = 0; i < 1000; ++i) {
                assertEq(DateTimeLib.weekday(timestamp) - 1, weekday);
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

    function testIsSupportedDateTime(DateTime memory a) public {
        a.month = _bound(a.month, 0, 20);
        a.day = _bound(a.day, 0, 50);
        a.hour = _bound(a.hour, 0, 50);
        a.minute = _bound(a.minute, 0, 100);
        a.second = _bound(a.second, 0, 100);
        bool isSupported = (1970 <= a.year && a.year <= DateTimeLib.MAX_SUPPORTED_YEAR)
            && (1 <= a.month && a.month <= 12)
            && (1 <= a.day && a.day <= DateTimeLib.daysInMonth(a.year, a.month)) && (a.hour < 24)
            && (a.minute < 60) && (a.second < 60);
        assertEq(
            DateTimeLib.isSupportedDateTime(a.year, a.month, a.day, a.hour, a.minute, a.second),
            isSupported
        );
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
        // 1st 2nd 3rd 4th monday in November 2022.
        wd = DateTimeLib.MON;
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 11, 1, wd), 1667779200);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 11, 2, wd), 1668384000);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 11, 3, wd), 1668988800);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 11, 4, wd), 1669593600);
        assertEq(DateTimeLib.nthWeekdayInMonthOfYearTimestamp(2022, 11, 5, wd), 0);

        // 1st... 5th Wednesday in November 2022.
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

    function testNthWeekdayInMonthOfYearTimestamp(
        uint256 year,
        uint256 month,
        uint256 n,
        uint256 weekday
    ) public {
        unchecked {
            year = _bound(year, 1970, DateTimeLib.MAX_SUPPORTED_YEAR);
            month = _bound(month, 1, 12);
            n = _bound(n, 1, 10);
            weekday = _bound(weekday, 1, 7);
            // Count number of weekdays for the month in the year.
            uint256 md = DateTimeLib.daysInMonth(year, month);
            uint256 timestamp = DateTimeLib.dateToTimestamp(year, month, 1);
            uint256 m;
            uint256 found;
            for (uint256 i; i < md;) {
                if (DateTimeLib.weekday(timestamp) == weekday) {
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
            assertEq(
                DateTimeLib.nthWeekdayInMonthOfYearTimestamp(year, month, n, weekday),
                found * timestamp
            );
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
        // Monday 07 November 2022 -> 1667779200
        assertEq(DateTimeLib.mondayTimestamp(1667779200), 1667779200);
        // Sunday 06 November 2022 -> 1667692800
        assertEq(DateTimeLib.mondayTimestamp(1667692800), 1667174400);
        // Saturday 05 November 2022 -> 1667606400
        assertEq(DateTimeLib.mondayTimestamp(1667606400), 1667174400);
        // Friday 04 November 2022 -> 1667520000
        assertEq(DateTimeLib.mondayTimestamp(1667520000), 1667174400);
        // Thursday 03 November 2022 -> 1667433600
        assertEq(DateTimeLib.mondayTimestamp(1667433600), 1667174400);
        // Wednesday 02 November 2022 -> 1667347200
        assertEq(DateTimeLib.mondayTimestamp(1667347200), 1667174400);
        // Tuesday 01 November 2022 -> 1667260800
        assertEq(DateTimeLib.mondayTimestamp(1667260800), 1667174400);
        // Monday 01 November 2022 -> 1667260800
        assertEq(DateTimeLib.mondayTimestamp(1667174400), 1667174400);
    }

    function testMondayTimestamp(uint256 timestamp) public {
        uint256 day = timestamp / 86400;
        uint256 weekday = (day + 3) % 7;
        assertEq(
            DateTimeLib.mondayTimestamp(timestamp), timestamp > 345599 ? (day - weekday) * 86400 : 0
        );
    }

    function testIsWeekEnd(uint256 timestamp) public {
        timestamp = _bound(timestamp, 0, DateTimeLib.MAX_SUPPORTED_TIMESTAMP);
        uint256 weekday = DateTimeLib.weekday(timestamp);
        assertEq(
            DateTimeLib.isWeekEnd(timestamp),
            weekday == DateTimeLib.SAT || weekday == DateTimeLib.SUN
        );
    }

    function testAddSubDiffYears(uint256 timestamp, uint256 numYears) public {
        uint256 maxNumYears = 1000000;
        numYears = _bound(numYears, 0, maxNumYears);
        timestamp =
            _bound(timestamp, 0, DateTimeLib.MAX_SUPPORTED_TIMESTAMP - maxNumYears * 366 * 86400);
        uint256 result = DateTimeLib.addYears(timestamp, numYears);
        DateTime memory a;
        DateTime memory b;
        (a.year, a.month, a.day, a.hour, a.minute, a.second) =
            DateTimeLib.timestampToDateTime(timestamp);
        (b.year, b.month, b.day, b.hour, b.minute, b.second) =
            DateTimeLib.timestampToDateTime(result);
        if (numYears != 0) assertTrue(a.year != b.year);
        if (a.day <= 28) assertEq(a.day, b.day);
        assertTrue(a.month == b.month);
        assertTrue(a.hour == b.hour && a.minute == b.minute && a.second == b.second);
        uint256 diff = DateTimeLib.diffYears(timestamp, result);
        assertTrue(diff == numYears);
        result = DateTimeLib.subYears(result, numYears);
        (b.year, b.month, b.day, b.hour, b.minute, b.second) =
            DateTimeLib.timestampToDateTime(result);
        assertTrue(a.year == b.year && a.month == b.month);
        assertTrue(a.hour == b.hour && a.minute == b.minute && a.second == b.second);
    }

    function addYears(uint256 timestamp, uint256 numYears) public pure returns (uint256) {
        return DateTimeLib.addYears(timestamp, numYears);
    }

    function subYears(uint256 timestamp, uint256 numYears) public pure returns (uint256) {
        return DateTimeLib.subYears(timestamp, numYears);
    }

    function diffYears(uint256 timestamp, uint256 numYears) public pure returns (uint256) {
        return DateTimeLib.diffYears(timestamp, numYears);
    }

    function addMonths(uint256 timestamp, uint256 numMonths) public pure returns (uint256) {
        return DateTimeLib.addMonths(timestamp, numMonths);
    }

    function subMonths(uint256 timestamp, uint256 numMonths) public pure returns (uint256) {
        return DateTimeLib.subMonths(timestamp, numMonths);
    }

    function diffMonths(uint256 timestamp, uint256 numMonths) public pure returns (uint256) {
        return DateTimeLib.diffMonths(timestamp, numMonths);
    }

    function addDays(uint256 timestamp, uint256 numDays) public pure returns (uint256) {
        return DateTimeLib.addDays(timestamp, numDays);
    }

    function subDays(uint256 timestamp, uint256 numDays) public pure returns (uint256) {
        return DateTimeLib.subDays(timestamp, numDays);
    }

    function diffDays(uint256 timestamp, uint256 numDays) public pure returns (uint256) {
        return DateTimeLib.diffDays(timestamp, numDays);
    }

    function addHours(uint256 timestamp, uint256 numHours) public pure returns (uint256) {
        return DateTimeLib.addHours(timestamp, numHours);
    }

    function subHours(uint256 timestamp, uint256 numHours) public pure returns (uint256) {
        return DateTimeLib.subHours(timestamp, numHours);
    }

    function diffHours(uint256 timestamp, uint256 numHours) public pure returns (uint256) {
        return DateTimeLib.diffHours(timestamp, numHours);
    }

    function addMinutes(uint256 timestamp, uint256 numMinutes) public pure returns (uint256) {
        return DateTimeLib.addMinutes(timestamp, numMinutes);
    }

    function subMinutes(uint256 timestamp, uint256 numMinutes) public pure returns (uint256) {
        return DateTimeLib.subMinutes(timestamp, numMinutes);
    }

    function diffMinutes(uint256 timestamp, uint256 numMinutes) public pure returns (uint256) {
        return DateTimeLib.diffMinutes(timestamp, numMinutes);
    }

    function addSeconds(uint256 timestamp, uint256 numSeconds) public pure returns (uint256) {
        return DateTimeLib.addSeconds(timestamp, numSeconds);
    }

    function subSeconds(uint256 timestamp, uint256 numSeconds) public pure returns (uint256) {
        return DateTimeLib.subSeconds(timestamp, numSeconds);
    }

    function diffSeconds(uint256 timestamp, uint256 numSeconds) public pure returns (uint256) {
        return DateTimeLib.diffSeconds(timestamp, numSeconds);
    }

    function testDateTimeArithmeticReverts() public {
        vm.expectRevert(stdError.arithmeticError);
        this.addYears(2 ** 128 - 1, 2 ** 255 - 1);
        vm.expectRevert(stdError.arithmeticError);
        this.subYears(2 ** 128 - 1, 2 ** 255 - 1);
        vm.expectRevert(stdError.arithmeticError);
        this.diffYears(2 ** 128 - 1, 2 ** 127 - 1);

        vm.expectRevert(stdError.arithmeticError);
        this.addMonths(2 ** 128 - 1, 2 ** 255 - 1);
        vm.expectRevert(stdError.arithmeticError);
        this.subMonths(2 ** 128 - 1, 2 ** 255 - 1);
        vm.expectRevert(stdError.arithmeticError);
        this.diffMonths(2 ** 128 - 1, 2 ** 127 - 1);

        vm.expectRevert(stdError.arithmeticError);
        this.addDays(2 ** 128 - 1, 2 ** 255 - 1);
        vm.expectRevert(stdError.arithmeticError);
        this.subDays(2 ** 128 - 1, 2 ** 255 - 1);
        vm.expectRevert(stdError.arithmeticError);
        this.diffDays(2 ** 128 - 1, 2 ** 127 - 1);

        vm.expectRevert(stdError.arithmeticError);
        this.addHours(2 ** 128 - 1, 2 ** 255 - 1);
        vm.expectRevert(stdError.arithmeticError);
        this.subHours(2 ** 128 - 1, 2 ** 255 - 1);
        vm.expectRevert(stdError.arithmeticError);
        this.diffHours(2 ** 128 - 1, 2 ** 127 - 1);

        vm.expectRevert(stdError.arithmeticError);
        this.addMinutes(2 ** 128 - 1, 2 ** 255 - 1);
        vm.expectRevert(stdError.arithmeticError);
        this.subMinutes(2 ** 128 - 1, 2 ** 255 - 1);
        vm.expectRevert(stdError.arithmeticError);
        this.diffMinutes(2 ** 128 - 1, 2 ** 127 - 1);

        vm.expectRevert(stdError.arithmeticError);
        this.addSeconds(2 ** 256 - 1, 2 ** 256 - 1);
        vm.expectRevert(stdError.arithmeticError);
        this.subSeconds(2 ** 128 - 1, 2 ** 255 - 1);
        vm.expectRevert(stdError.arithmeticError);
        this.diffSeconds(2 ** 128 - 1, 2 ** 127 - 1);
    }

    function testAddSubDiffMonths(uint256 timestamp, uint256 numMonths) public {
        uint256 maxNumMonths = 1000000;
        numMonths = _bound(numMonths, 0, maxNumMonths);
        timestamp =
            _bound(timestamp, 0, DateTimeLib.MAX_SUPPORTED_TIMESTAMP - maxNumMonths * 32 * 86400);
        uint256 result = DateTimeLib.addMonths(timestamp, numMonths);
        DateTime memory a;
        DateTime memory b;
        (a.year, a.month, a.day, a.hour, a.minute, a.second) =
            DateTimeLib.timestampToDateTime(timestamp);
        (b.year, b.month, b.day, b.hour, b.minute, b.second) =
            DateTimeLib.timestampToDateTime(result);
        if (numMonths != 0) assertTrue(a.year != b.year || a.month != b.month);
        if (a.day <= 28) assertEq(a.day, b.day);
        assertTrue(a.hour == b.hour && a.minute == b.minute && a.second == b.second);
        uint256 diff = DateTimeLib.diffMonths(timestamp, result);
        assertTrue(diff == numMonths);
        result = DateTimeLib.subMonths(result, numMonths);
        (b.year, b.month, b.day, b.hour, b.minute, b.second) =
            DateTimeLib.timestampToDateTime(result);
        assertTrue(a.year == b.year && a.month == b.month);
        assertTrue(a.hour == b.hour && a.minute == b.minute && a.second == b.second);
    }

    function testAddSubDiffDays(uint256 timestamp, uint256 numDays) public {
        uint256 maxNumDays = 100000000;
        numDays = _bound(numDays, 0, maxNumDays);
        timestamp = _bound(timestamp, 0, DateTimeLib.MAX_SUPPORTED_TIMESTAMP - maxNumDays * 86400);
        uint256 result = DateTimeLib.addDays(timestamp, numDays);
        DateTime memory a;
        DateTime memory b;
        (a.year, a.month, a.day, a.hour, a.minute, a.second) =
            DateTimeLib.timestampToDateTime(timestamp);
        (b.year, b.month, b.day, b.hour, b.minute, b.second) =
            DateTimeLib.timestampToDateTime(result);
        if (numDays != 0) {
            assertTrue(a.year != b.year || a.month != b.month || a.day != b.day);
        }
        assertTrue(a.hour == b.hour && a.minute == b.minute && a.second == b.second);
        uint256 diff = DateTimeLib.diffDays(timestamp, result);
        assertTrue(diff == numDays);
        result = DateTimeLib.subDays(result, numDays);
        (b.year, b.month, b.day, b.hour, b.minute, b.second) =
            DateTimeLib.timestampToDateTime(result);
        assertTrue(a.year == b.year && a.month == b.month);
        assertTrue(a.hour == b.hour && a.minute == b.minute && a.second == b.second);
    }

    function testAddSubDiffHours(uint256 timestamp, uint256 numHours) public {
        uint256 maxNumHours = 10000000000;
        numHours = _bound(numHours, 0, maxNumHours);
        timestamp = _bound(timestamp, 0, DateTimeLib.MAX_SUPPORTED_TIMESTAMP - maxNumHours * 3600);
        uint256 result = DateTimeLib.addHours(timestamp, numHours);
        DateTime memory a;
        DateTime memory b;
        (a.year, a.month, a.day, a.hour, a.minute, a.second) =
            DateTimeLib.timestampToDateTime(timestamp);
        (b.year, b.month, b.day, b.hour, b.minute, b.second) =
            DateTimeLib.timestampToDateTime(result);
        if (numHours != 0) {
            assertTrue(a.year != b.year || a.month != b.month || a.day != b.day || a.hour != b.hour);
        }
        assertTrue(a.minute == b.minute && a.second == b.second);
        uint256 diff = DateTimeLib.diffHours(timestamp, result);
        assertTrue(diff == numHours);
        result = DateTimeLib.subHours(result, numHours);
        (b.year, b.month, b.day, b.hour, b.minute, b.second) =
            DateTimeLib.timestampToDateTime(result);
        assertTrue(a.year == b.year && a.month == b.month);
        assertTrue(a.hour == b.hour && a.minute == b.minute && a.second == b.second);
    }

    function testAddSubDiffMinutes(uint256 timestamp, uint256 numMinutes) public {
        uint256 maxNumMinutes = 10000000000;
        numMinutes = _bound(numMinutes, 0, maxNumMinutes);
        timestamp = _bound(timestamp, 0, DateTimeLib.MAX_SUPPORTED_TIMESTAMP - maxNumMinutes * 60);
        uint256 result = DateTimeLib.addMinutes(timestamp, numMinutes);
        DateTime memory a;
        DateTime memory b;
        (a.year, a.month, a.day, a.hour, a.minute, a.second) =
            DateTimeLib.timestampToDateTime(timestamp);
        (b.year, b.month, b.day, b.hour, b.minute, b.second) =
            DateTimeLib.timestampToDateTime(result);
        if (numMinutes != 0) {
            assertTrue(
                (a.year != b.year || a.month != b.month || a.day != b.day)
                    || (a.hour != b.hour || a.minute != b.minute)
            );
        }
        assertTrue(a.second == b.second);
        uint256 diff = DateTimeLib.diffMinutes(timestamp, result);
        assertTrue(diff == numMinutes);
        result = DateTimeLib.subMinutes(result, numMinutes);
        (b.year, b.month, b.day, b.hour, b.minute, b.second) =
            DateTimeLib.timestampToDateTime(result);
        assertTrue(a.year == b.year && a.month == b.month);
        assertTrue(a.hour == b.hour && a.minute == b.minute && a.second == b.second);
    }

    function testAddSubDiffSeconds(uint256 timestamp, uint256 numSeconds) public {
        uint256 maxNumSeconds = 1000000000000;
        numSeconds = _bound(numSeconds, 0, maxNumSeconds);
        timestamp = _bound(timestamp, 0, DateTimeLib.MAX_SUPPORTED_TIMESTAMP - maxNumSeconds);
        uint256 result = DateTimeLib.addSeconds(timestamp, numSeconds);
        DateTime memory a;
        DateTime memory b;
        (a.year, a.month, a.day, a.hour, a.minute, a.second) =
            DateTimeLib.timestampToDateTime(timestamp);
        (b.year, b.month, b.day, b.hour, b.minute, b.second) =
            DateTimeLib.timestampToDateTime(result);
        if (numSeconds != 0) {
            assertTrue(
                (a.year != b.year || a.month != b.month || a.day != b.day)
                    || (a.hour != b.hour || a.minute != b.minute || a.second != b.second)
            );
        }
        uint256 diff = DateTimeLib.diffSeconds(timestamp, result);
        assertTrue(diff == numSeconds);
        result = DateTimeLib.subSeconds(result, numSeconds);
        (b.year, b.month, b.day, b.hour, b.minute, b.second) =
            DateTimeLib.timestampToDateTime(result);
        assertTrue(a.year == b.year && a.month == b.month);
        assertTrue(a.hour == b.hour && a.minute == b.minute && a.second == b.second);
    }

    function _dateToEpochDayOriginal(uint256 year, uint256 month, uint256 day)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            if (month <= 2) {
                year -= 1;
            }
            uint256 era = year / 400;
            uint256 yoe = year - era * 400;
            uint256 doy = (153 * (month > 2 ? month - 3 : month + 9) + 2) / 5 + day - 1;
            uint256 doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
            return era * 146097 + doe - 719468;
        }
    }

    function _dateToEpochDayOriginal2(uint256 year, uint256 month, uint256 day)
        internal
        pure
        returns (uint256 _days)
    {
        unchecked {
            int256 _year = int256(year);
            int256 _month = int256(month);
            int256 _day = int256(day);

            int256 _m = (_month - 14) / 12;
            int256 __days = _day - 32075 + ((1461 * (_year + 4800 + _m)) / 4)
                + ((367 * (_month - 2 - _m * 12)) / 12) - ((3 * ((_year + 4900 + _m) / 100)) / 4)
                - 2440588;

            _days = uint256(__days);
        }
    }

    function _epochDayToDateOriginal(uint256 timestamp)
        internal
        pure
        returns (uint256 year, uint256 month, uint256 day)
    {
        unchecked {
            timestamp += 719468;
            uint256 era = timestamp / 146097;
            uint256 doe = timestamp - era * 146097;
            uint256 yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
            year = yoe + era * 400;
            uint256 doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
            uint256 mp = (5 * doy + 2) / 153;
            day = doy - (153 * mp + 2) / 5 + 1;
            month = mp < 10 ? mp + 3 : mp - 9;
            if (month <= 2) {
                year += 1;
            }
        }
    }

    function _epochDayToDateOriginal2(uint256 _days)
        internal
        pure
        returns (uint256 year, uint256 month, uint256 day)
    {
        unchecked {
            int256 __days = int256(_days);

            int256 L = __days + 68569 + 2440588;
            int256 N = (4 * L) / 146097;
            L = L - (146097 * N + 3) / 4;
            int256 _year = (4000 * (L + 1)) / 1461001;
            L = L - (1461 * _year) / 4 + 31;
            int256 _month = (80 * L) / 2447;
            int256 _day = L - (2447 * _month) / 80;
            L = _month / 11;
            _month = _month + 2 - 12 * L;
            _year = 100 * (N - 49) + _year + L;

            year = uint256(_year);
            month = uint256(_month);
            day = uint256(_day);
        }
    }
}
