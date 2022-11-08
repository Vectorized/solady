// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library DateTimeLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    uint256 internal constant MAX_SUPPORTED_YEAR = 4294967295;
    uint256 internal constant MAX_SUPPORTED_DAYS = 1568703872776;
    uint256 internal constant MAX_SUPPORTED_TIMESTAMP = 135536014607932799;

    uint256 internal constant MON = 0;
    uint256 internal constant TUE = 1;
    uint256 internal constant WED = 2;
    uint256 internal constant THU = 3;
    uint256 internal constant FRI = 4;
    uint256 internal constant SAT = 5;
    uint256 internal constant SUN = 6;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    DATE TIME OPERATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the number of days since 1970-01-01 from (`year`,`month`,`day`).
    /// See: https://howardhinnant.github.io/date_algorithms.html
    /// Note: Inputs outside the supported range result in undefined behavior.
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
    /// Note: Inputs outside the supported range result in undefined behavior.
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
            let era := div(epochDay, 146097)
            let doe := mod(epochDay, 146097)
            let yoe := div(sub(sub(add(doe, div(doe, 36524)), div(doe, 1460)), eq(doe, 146096)), 365)
            let doy := add(sub(sub(doe, mul(365, yoe)), shr(2, yoe)), div(yoe, 100))
            let mp := div(add(mul(5, doy), 2), 153)
            day := add(sub(doy, shr(11, add(mul(mp, 62719), 769))), 1)
            month := add(sub(mp, 9), mul(lt(mp, 10), 12))
            year := add(add(yoe, mul(era, 400)), lt(month, 3))
        }
    }

    /// @dev Returns the unix timestamp from (`year`,`month`,`day`).
    /// Note: Inputs outside the supported range result in undefined behavior.
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
    /// Note: Inputs outside the supported range result in undefined behavior.
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
        (year, month, day) = epochDayToDate(timestamp / 86400);
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

    /// @dev Returns the day of week from the unix timestamp.
    /// Monday: 0, Tuesday: 1, ....., Sunday: 6.
    function dayOfWeek(uint256 timestamp) internal pure returns (uint256 result) {
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
                and(lt(sub(year, 1970), sub(MAX_SUPPORTED_YEAR, 1969)), lt(add(month, w), 12)),
                lt(add(day, w), md)
            )
        }
    }

    /// @dev Returns if `epochDay` is a supported unix epoch day.
    function isSupportedEpochDay(uint256 epochDay) internal pure returns (bool result) {
        result = epochDay < MAX_SUPPORTED_DAYS + 1;
    }

    /// @dev Returns if `timestamp` is a supported unix timestamp.
    function isSupportedTimestamp(uint256 timestamp) internal pure returns (bool result) {
        result = timestamp < MAX_SUPPORTED_TIMESTAMP + 1;
    }

    /// @dev Returns the unix timestamp of the given `n`th `weekday` in `month` of `year`.
    /// Example: 3rd Friday of 2022 Feb: `nthWeekdayInMonthOfYearTimestamp(2022, 2, 3, 5))`
    /// Note: Behavior is undefined if `weekday` is invalid (i.e. `weekday > 6`).
    function nthWeekdayInMonthOfYearTimestamp(
        uint256 year,
        uint256 month,
        uint256 n,
        uint256 weekday
    ) internal pure returns (uint256 result) {
        uint256 d = dateToEpochDay(year, month, 1);
        uint256 md = daysInMonth(year, month);
        assembly {
            let diff := sub(weekday, mod(add(d, 3), 7))
            let date := add(mul(sub(n, 1), 7), add(mul(gt(diff, 6), 7), diff))
            result := mul(mul(86400, add(date, d)), and(lt(date, md), iszero(iszero(n))))
        }
    }

    /// @dev Returns the unix timestamp of the most recent Monday.
    function mondayTimestamp(uint256 timestamp) internal pure returns (uint256 result) {
        uint256 t = timestamp;
        assembly {
            let day := div(t, 86400)
            result := mul(mul(sub(day, mod(add(day, 3), 7)), 86400), gt(t, 345599))
        }
    }
}
