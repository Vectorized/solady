# DateTimeLib

Library for date time operations.


<b>Conventions:</b>

| Unit      | Range                | Notes                            |
| -- | -- | -- |
| timestamp | 0..0x1e18549868c76ff | Unix timestamp.                  |
| epochDay  | 0..0x16d3e098039     | Days since 1970-01-01.           |
| year      | 1970..0xffffffff     | Gregorian calendar year.         |
| month     | 1..12                | Gregorian calendar month.        |
| day       | 1..31                | Gregorian calendar day of month. |
| weekday   | 1..7                 | The day of the week (1-indexed). |

All timestamps of days are rounded down to 00&#58;00&#58;00 UTC.



<!-- customintro:start --><!-- customintro:end -->

## Date Time Operations

### dateToEpochDay(uint256,uint256,uint256)

```solidity
function dateToEpochDay(uint256 year, uint256 month, uint256 day)
    internal
    pure
    returns (uint256 epochDay)
```

Returns the number of days since 1970-01-01 from (`year`,`month`,`day`).   
See: https://howardhinnant.github.io/date_algorithms.html   
Note: Inputs outside the supported ranges result in undefined behavior.   
Use `isSupportedDate` to check if the inputs are supported.

### epochDayToDate(uint256)

```solidity
function epochDayToDate(uint256 epochDay)
    internal
    pure
    returns (uint256 year, uint256 month, uint256 day)
```

Returns (`year`,`month`,`day`) from the number of days since 1970-01-01.   
Note: Inputs outside the supported ranges result in undefined behavior.   
Use `isSupportedDays` to check if the inputs is supported.

### dateToTimestamp(uint256,uint256,uint256)

```solidity
function dateToTimestamp(uint256 year, uint256 month, uint256 day)
    internal
    pure
    returns (uint256 result)
```

Returns the unix timestamp from (`year`,`month`,`day`).   
Note: Inputs outside the supported ranges result in undefined behavior.   
Use `isSupportedDate` to check if the inputs are supported.

### timestampToDate(uint256)

```solidity
function timestampToDate(uint256 timestamp)
    internal
    pure
    returns (uint256 year, uint256 month, uint256 day)
```

Returns (`year`,`month`,`day`) from the given unix timestamp.   
Note: Inputs outside the supported ranges result in undefined behavior.   
Use `isSupportedTimestamp` to check if the inputs are supported.

### dateTimeToTimestamp(uint256,uint256,uint256,uint256,uint256,uint256)

```solidity
function dateTimeToTimestamp(
    uint256 year,
    uint256 month,
    uint256 day,
    uint256 hour,
    uint256 minute,
    uint256 second
) internal pure returns (uint256 result)
```

Returns the unix timestamp from   
(`year`,`month`,`day`,`hour`,`minute`,`second`).   
Note: Inputs outside the supported ranges result in undefined behavior.   
Use `isSupportedDateTime` to check if the inputs are supported.

### timestampToDateTime(uint256)

```solidity
function timestampToDateTime(uint256 timestamp)
    internal
    pure
    returns (
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    )
```

Returns (`year`,`month`,`day`,`hour`,`minute`,`second`)   
from the given unix timestamp.   
Note: Inputs outside the supported ranges result in undefined behavior.   
Use `isSupportedTimestamp` to check if the inputs are supported.

### isLeapYear(uint256)

```solidity
function isLeapYear(uint256 year) internal pure returns (bool leap)
```

Returns if the `year` is leap.

### daysInMonth(uint256,uint256)

```solidity
function daysInMonth(uint256 year, uint256 month)
    internal
    pure
    returns (uint256 result)
```

Returns number of days in given `month` of `year`.

### weekday(uint256)

```solidity
function weekday(uint256 timestamp)
    internal
    pure
    returns (uint256 result)
```

Returns the weekday from the unix timestamp.   
Monday: 1, Tuesday: 2, ....., Sunday: 7.

### isSupportedDate(uint256,uint256,uint256)

```solidity
function isSupportedDate(uint256 year, uint256 month, uint256 day)
    internal
    pure
    returns (bool result)
```

Returns if (`year`,`month`,`day`) is a supported date.   
- `1970 <= year <= MAX_SUPPORTED_YEAR`.   
- `1 <= month <= 12`.   
- `1 <= day <= daysInMonth(year, month)`.

### isSupportedDateTime(uint256,uint256,uint256,uint256,uint256,uint256)

```solidity
function isSupportedDateTime(
    uint256 year,
    uint256 month,
    uint256 day,
    uint256 hour,
    uint256 minute,
    uint256 second
) internal pure returns (bool result)
```

Returns if (`year`,`month`,`day`,`hour`,`minute`,`second`) is a supported date time.   
- `1970 <= year <= MAX_SUPPORTED_YEAR`.   
- `1 <= month <= 12`.   
- `1 <= day <= daysInMonth(year, month)`.   
- `hour < 24`.   
- `minute < 60`.   
- `second < 60`.

### isSupportedEpochDay(uint256)

```solidity
function isSupportedEpochDay(uint256 epochDay)
    internal
    pure
    returns (bool result)
```

Returns if `epochDay` is a supported unix epoch day.

### isSupportedTimestamp(uint256)

```solidity
function isSupportedTimestamp(uint256 timestamp)
    internal
    pure
    returns (bool result)
```

Returns if `timestamp` is a supported unix timestamp.

### nthWeekdayInMonthOfYearTimestamp(uint256,uint256,uint256,uint256)

```solidity
function nthWeekdayInMonthOfYearTimestamp(
    uint256 year,
    uint256 month,
    uint256 n,
    uint256 wd
) internal pure returns (uint256 result)
```

Returns the unix timestamp of the given `n`th weekday `wd`, in `month` of `year`.   
Example: 3rd Friday of Feb 2022 is `nthWeekdayInMonthOfYearTimestamp(2022, 2, 3, 5)`   
Note: `n` is 1-indexed for traditional consistency.   
Invalid weekdays (i.e. `wd == 0 || wd > 7`) result in undefined behavior.

### mondayTimestamp(uint256)

```solidity
function mondayTimestamp(uint256 timestamp)
    internal
    pure
    returns (uint256 result)
```

Returns the unix timestamp of the most recent Monday.

### isWeekEnd(uint256)

```solidity
function isWeekEnd(uint256 timestamp) internal pure returns (bool result)
```

Returns whether the unix timestamp falls on a Saturday or Sunday.   
To check whether it is a week day, just take the negation of the result.

## Date Time Arithmetic Operations

### addYears(uint256,uint256)

```solidity
function addYears(uint256 timestamp, uint256 numYears)
    internal
    pure
    returns (uint256 result)
```

Adds `numYears` to the unix timestamp, and returns the result.   
Note: The result will share the same Gregorian calendar month,   
but different Gregorian calendar years for non-zero `numYears`.   
If the Gregorian calendar month of the result has less days   
than the Gregorian calendar month day of the `timestamp`,   
the result's month day will be the maximum possible value for the month.   
(e.g. from 29th Feb to 28th Feb)

### addMonths(uint256,uint256)

```solidity
function addMonths(uint256 timestamp, uint256 numMonths)
    internal
    pure
    returns (uint256 result)
```

Adds `numMonths` to the unix timestamp, and returns the result.   
Note: If the Gregorian calendar month of the result has less days   
than the Gregorian calendar month day of the `timestamp`,   
the result's month day will be the maximum possible value for the month.   
(e.g. from 29th Feb to 28th Feb)

### addDays(uint256,uint256)

```solidity
function addDays(uint256 timestamp, uint256 numDays)
    internal
    pure
    returns (uint256 result)
```

Adds `numDays` to the unix timestamp, and returns the result.

### addHours(uint256,uint256)

```solidity
function addHours(uint256 timestamp, uint256 numHours)
    internal
    pure
    returns (uint256 result)
```

Adds `numHours` to the unix timestamp, and returns the result.

### addMinutes(uint256,uint256)

```solidity
function addMinutes(uint256 timestamp, uint256 numMinutes)
    internal
    pure
    returns (uint256 result)
```

Adds `numMinutes` to the unix timestamp, and returns the result.

### addSeconds(uint256,uint256)

```solidity
function addSeconds(uint256 timestamp, uint256 numSeconds)
    internal
    pure
    returns (uint256 result)
```

Adds `numSeconds` to the unix timestamp, and returns the result.

### subYears(uint256,uint256)

```solidity
function subYears(uint256 timestamp, uint256 numYears)
    internal
    pure
    returns (uint256 result)
```

Subtracts `numYears` from the unix timestamp, and returns the result.   
Note: The result will share the same Gregorian calendar month,   
but different Gregorian calendar years for non-zero `numYears`.   
If the Gregorian calendar month of the result has less days   
than the Gregorian calendar month day of the `timestamp`,   
the result's month day will be the maximum possible value for the month.   
(e.g. from 29th Feb to 28th Feb)

### subMonths(uint256,uint256)

```solidity
function subMonths(uint256 timestamp, uint256 numMonths)
    internal
    pure
    returns (uint256 result)
```

Subtracts `numYears` from the unix timestamp, and returns the result.   
Note: If the Gregorian calendar month of the result has less days   
than the Gregorian calendar month day of the `timestamp`,   
the result's month day will be the maximum possible value for the month.   
(e.g. from 29th Feb to 28th Feb)

### subDays(uint256,uint256)

```solidity
function subDays(uint256 timestamp, uint256 numDays)
    internal
    pure
    returns (uint256 result)
```

Subtracts `numDays` from the unix timestamp, and returns the result.

### subHours(uint256,uint256)

```solidity
function subHours(uint256 timestamp, uint256 numHours)
    internal
    pure
    returns (uint256 result)
```

Subtracts `numHours` from the unix timestamp, and returns the result.

### subMinutes(uint256,uint256)

```solidity
function subMinutes(uint256 timestamp, uint256 numMinutes)
    internal
    pure
    returns (uint256 result)
```

Subtracts `numMinutes` from the unix timestamp, and returns the result.

### subSeconds(uint256,uint256)

```solidity
function subSeconds(uint256 timestamp, uint256 numSeconds)
    internal
    pure
    returns (uint256 result)
```

Subtracts `numSeconds` from the unix timestamp, and returns the result.

### diffYears(uint256,uint256)

```solidity
function diffYears(uint256 fromTimestamp, uint256 toTimestamp)
    internal
    pure
    returns (uint256 result)
```

Returns the difference in Gregorian calendar years   
between `fromTimestamp` and `toTimestamp`.   
Note: Even if the true time difference is less than a year,   
the difference can be non-zero is the timestamps are   
from different Gregorian calendar years

### diffMonths(uint256,uint256)

```solidity
function diffMonths(uint256 fromTimestamp, uint256 toTimestamp)
    internal
    pure
    returns (uint256 result)
```

Returns the difference in Gregorian calendar months   
between `fromTimestamp` and `toTimestamp`.   
Note: Even if the true time difference is less than a month,   
the difference can be non-zero is the timestamps are   
from different Gregorian calendar months.

### diffDays(uint256,uint256)

```solidity
function diffDays(uint256 fromTimestamp, uint256 toTimestamp)
    internal
    pure
    returns (uint256 result)
```

Returns the difference in days between `fromTimestamp` and `toTimestamp`.

### diffHours(uint256,uint256)

```solidity
function diffHours(uint256 fromTimestamp, uint256 toTimestamp)
    internal
    pure
    returns (uint256 result)
```

Returns the difference in hours between `fromTimestamp` and `toTimestamp`.

### diffMinutes(uint256,uint256)

```solidity
function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp)
    internal
    pure
    returns (uint256 result)
```

Returns the difference in minutes between `fromTimestamp` and `toTimestamp`.

### diffSeconds(uint256,uint256)

```solidity
function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp)
    internal
    pure
    returns (uint256 result)
```

Returns the difference in seconds between `fromTimestamp` and `toTimestamp`.