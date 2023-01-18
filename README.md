# MySQL SunRiseSet Calculation

MySQL/MariaDB function to calculate the sunrise/sunset time based on date and latitude/longitude.

This implementation is based by the algorithm found on http://web.archive.org/web/20161202180207/http://williams.best.vwh.net/sunrise_sunset_algorithm.htm

A more powerful variant can be found as a MySQL Loadable Function implementation under [lib_mysqludf_astro](https://github.com/curzon01/lib_mysqludf_astro).

## Installation

Execute the code of SunRiseSet.sql, for example
```
mysql -u <username> -p <yourdb> < SunRiseSet.sql
```

## Usage

Call the function with date, your location and which time you want to get back (sunrise, sunset)

### SunRiseSet(date, latitude, longitude, zenith, sunriseset)

The paramater are:
#### date
Date of interest - MySQL date format `yyyy-mm-dd`

#### latitude
Location latitude - FLOAT

#### longitude
Location longitude - FLOAT  
Positive for east and negative for west.

#### zenith
Sun's zenith for sunrise/sunset: enum['official','civil','nautical','astronomical'] or FLOAT

#### sunriseset
Desired result - enum['sunrise','sunset']


### Examples
Replace latitude 0.0000 and longitude 0.0000 with your local settings:
```
-- official sunset/sunrise
SELECT system.SunRiseSet(NOW(), 0.0000, 0.0000, 'official', 'sunset'), system.SunRiseSet(NOW(), 0.0000, 0.0000, 'official', 'sunrise');
SELECT system.SunRiseSet(NOW(), 0.0000, 0.0000, 90+(50/60), 'sunset'), system.SunRiseSet(NOW(), 0.0000, 0.0000, 90.833333333, 'sunrise');
-- civil
SELECT system.SunRiseSet(NOW(), 0.0000, 0.0000, 'civil', 'sunset'), system.SunRiseSet(NOW(), 0.0000, 0.0000, 'civil', 'rise');
SELECT system.SunRiseSet(NOW(), 0.0000, 0.0000, 96, 'sunset'), system.SunRiseSet(NOW(), 0.0000, 0.0000, 96, 'rise');
-- nautical
SELECT system.SunRiseSet(NOW(), 0.0000, 0.0000, 'nautical', 'set'), system.SunRiseSet(NOW(), 0.0000, 0.0000, 'nautical', 'rise');
-- astronomical
SELECT system.SunRiseSet(NOW(), 0.0000, 0.0000, 'astro', 'sunset'), system.SunRiseSet(NOW(), 0.0000, 0.0000, 'astro', 'sunrise');

-- self defined sun horizon level
SELECT system.SunRiseSet(NOW(), 0.0000, 0.0000, 86.2, 'sunset'), system.SunRiseSet(NOW(), 0.0000, 0.0000, 86.2, 'sunrise');
```
