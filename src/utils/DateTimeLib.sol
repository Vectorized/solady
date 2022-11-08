// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for date time operations.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/DateTimeLib.sol)
///
/// Conventions:
/// --------------------------------------------------------------------------------------+
/// Unit      | Range                | Notes                                              |
/// --------------------------------------------------------------------------------------|
/// timestamp | 0..0x1e18549868c76ff | Unix timestamp, number of seconds since 1970-01-01 |
/// epochDay  | 0..0x16d3e098039     | Days since 1970-01-01                              |
/// year      | 1970..0xffffffff     | Gregorian calendar year                            |
/// month     | 1..12                | Gregorian calendar month                           |
/// day       | 1..31                | Gregorian calendar day of month                    |
/// weekday   | 0..6                 | Index of the day of week                           |
/// --------------------------------------------------------------------------------------+
/// All timestamps of days are rounded down to 00:00:00 UTC.
library DateTimeLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Weekdays are 0-indexed for gas efficiency purposes.

    uint256 internal constant MON = 0;
    uint256 internal constant TUE = 1;
    uint256 internal constant WED = 2;
    uint256 internal constant THU = 3;
    uint256 internal constant FRI = 4;
    uint256 internal constant SAT = 5;
    uint256 internal constant SUN = 6;

    // Months and days of months are 1-indexed for ease of use.

    uint256 internal constant JAN = 1;
    uint256 internal constant FEB = 2;
    uint256 internal constant MAR = 3;
    uint256 internal constant APR = 4;
    uint256 internal constant MAY = 5;
    uint256 internal constant JUN = 6;
    uint256 internal constant JUL = 7;
    uint256 internal constant AUG = 8;
    uint256 internal constant SEP = 9;
    uint256 internal constant OCT = 10;
    uint256 internal constant NOV = 11;
    uint256 internal constant DEC = 12;

    // The maximum supported limits are large enough for most pratical purposes.
    // Inputs that exceed the supported limits result in undefined behavior.

    uint256 internal constant MAX_SUPPORTED_YEAR = 0xffffffff;
    uint256 internal constant MAX_SUPPORTED_EPOCH_DAY = 0x16d3e098039;
    uint256 internal constant MAX_SUPPORTED_TIMESTAMP = 0x1e18549868c76ff;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    DATE TIME OPERATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the number of days since 1970-01-01 from (`year`,`month`,`day`).
    /// See: https://howardhinnant.github.io/date_algorithms.html
    /// Note: Inputs outside the supported ranges result in undefined behavior.
    /// Use {isSupportedDate} to check if the date is supported.
    function dateToEpochDay(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 epochDay) {
        /// @solidity memory-safe-assembly
        assembly {
            year := sub(year, lt(month, 3))
            let doy := add(shr(11, add(mul(62719, mod(add(month, 9), 12)), 769)), day)
            let yoe := mod(year, 400)
            let doe := sub(add(add(mul(yoe, 365), shr(2, yoe)), doy), div(yoe, 100))
            epochDay := sub(add(mul(div(year, 400), 146097), doe), 719469)
        }
    }

    /// @dev Returns (`year`,`month`,`day`) from the number of days since 1970-01-01.
    /// Note: Inputs outside the supported ranges result in undefined behavior.
    /// Use {isSupportedDays} to check if the inputs is supported.
    function epochDayToDate(uint256 epochDay)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        /// @solidity memory-safe-assembly
        assembly {
            epochDay := add(epochDay, 719468)
            let doe := mod(epochDay, 146097)
            let yoe := div(sub(sub(add(doe, div(doe, 36524)), div(doe, 1460)), eq(doe, 146096)), 365)
            let doy := sub(doe, sub(add(mul(365, yoe), shr(2, yoe)), div(yoe, 100)))
            let mp := div(add(mul(5, doy), 2), 153)
            day := add(sub(doy, shr(11, add(mul(mp, 62719), 769))), 1)
            month := sub(add(mp, 3), mul(gt(mp, 9), 12))
            year := add(add(yoe, mul(div(epochDay, 146097), 400)), lt(month, 3))
        }
    }

    /// @dev Returns the unix timestamp from (`year`,`month`,`day`).
    /// Note: Inputs outside the supported ranges result in undefined behavior.
    /// Use {isSupportedDate} to check if the date is supported.
    function dateToTimestamp(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 result) {
        unchecked {
            result = dateToEpochDay(year, month, day) * 86400;
        }
    }

    /// @dev Returns (`year`,`month`,`day`) from the given unix timestamp.
    /// Note: Inputs outside the supported ranges result in undefined behavior.
    /// Use {isSupportedTimestamp} to check if the date is supported.
    function timestampToDate(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        unchecked {
            (year, month, day) = epochDayToDate(timestamp / 86400);
        }
    }

    /// @dev Returns if the `year` is leap.
    function isLeapYear(uint256 year) internal pure returns (bool leap) {
        /// @solidity memory-safe-assembly
        assembly {
            leap := iszero(and(add(mul(iszero(mod(year, 25)), 12), 3), year))
        }
    }

    /// @dev Returns number of days in given `month` of `year`.
    function daysInMonth(uint256 year, uint256 month) internal pure returns (uint256 result) {
        bool flag = isLeapYear(year);
        /// @solidity memory-safe-assembly
        assembly {
            // `daysInMonths = [31,28,31,30,31,30,31,31,30,31,30,31]`.
            // `result = daysInMonths[month - 1] + isLeapYear(year)`.
            result := add(byte(month, shl(152, 0x1F1C1F1E1F1E1F1F1E1F1E1F)), and(eq(month, 2), flag))
        }
    }

    /// @dev Returns the weekday from the unix timestamp.
    /// Monday: 0, Tuesday: 1, ....., Sunday: 6.
    function weekday(uint256 timestamp) internal pure returns (uint256 result) {
        unchecked {
            result = (timestamp / 86400 + 3) % 7;
        }
    }

    /// @dev Returns if (`year`,`month`,`day`) is a supported date.
    /// - `1970 <= year <= MAX_SUPPORTED_YEAR`
    /// - `1 <= month <= 12`
    /// - `1 <= day <= daysInMonth(year, month)`
    function isSupportedDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (bool result) {
        uint256 md = daysInMonth(year, month);
        /// @solidity memory-safe-assembly
        assembly {
            let w := not(0)
            result := and(
                lt(sub(year, 1970), sub(MAX_SUPPORTED_YEAR, 1969)),
                and(lt(add(month, w), 12), lt(add(day, w), md))
            )
        }
    }

    /// @dev Returns if `epochDay` is a supported unix epoch day.
    function isSupportedEpochDay(uint256 epochDay) internal pure returns (bool result) {
        unchecked {
            result = epochDay < MAX_SUPPORTED_EPOCH_DAY + 1;
        }
    }

    /// @dev Returns if `timestamp` is a supported unix timestamp.
    function isSupportedTimestamp(uint256 timestamp) internal pure returns (bool result) {
        unchecked {
            result = timestamp < MAX_SUPPORTED_TIMESTAMP + 1;
        }
    }

    /// @dev Returns the unix timestamp of the given `n`th weekday `wd`, in `month` of `year`.
    /// Example: 3rd Friday of 2022 Feb: `nthWeekdayInMonthOfYearTimestamp(2022, 2, 3, 5))`
    /// Note: Invalid weekdays (i.e. `wd > 6`) result in undefined behavior.
    function nthWeekdayInMonthOfYearTimestamp(
        uint256 year,
        uint256 month,
        uint256 n,
        uint256 wd
    ) internal pure returns (uint256 result) {
        uint256 d = dateToEpochDay(year, month, 1);
        uint256 md = daysInMonth(year, month);
        /// @solidity memory-safe-assembly
        assembly {
            let diff := sub(wd, mod(add(d, 3), 7))
            let date := add(mul(sub(n, 1), 7), add(mul(gt(diff, 6), 7), diff))
            result := mul(mul(86400, add(date, d)), and(lt(date, md), iszero(iszero(n))))
        }
    }

    /// @dev Returns the unix timestamp of the most recent Monday.
    function mondayTimestamp(uint256 timestamp) internal pure returns (uint256 result) {
        uint256 t = timestamp;
        /// @solidity memory-safe-assembly
        assembly {
            let day := div(t, 86400)
            result := mul(mul(sub(day, mod(add(day, 3), 7)), 86400), gt(t, 345599))
        }
    }
}
