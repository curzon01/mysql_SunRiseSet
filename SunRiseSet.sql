DELIMITER //
CREATE FUNCTION `SunRiseSet`(
	`date` DATE,
	`latitude` FLOAT,
	`longitude` FLOAT,
	`zenith` TINYTEXT,
	`sunriseset` TINYTEXT
)
RETURNS time
LANGUAGE SQL
NOT DETERMINISTIC
NO SQL
SQL SECURITY DEFINER
COMMENT 'Sunrise/Sunset Algorithm'
BEGIN
    /* Sunrise/Sunset algorithm 
        taken from  http://web.archive.org/web/20161202180207/http://williams.best.vwh.net/sunrise_sunset_algorithm.htm
    inputs:
        `date`          date of interest
        `latitude`      latitude location
        `longitude`     longitude location:
                            is positive for East and negative for West
        `zenith`        sun's zenith for sunrise/sunset:
                            enum['official','civil','nautical','astronomical'] or FLOAT
        `sunriseset`    desired result:
                            enum['sunrise','sunset']
    output:
        time of sunrise or sunset
    */

    DECLARE zenithangle FLOAT DEFAULT NULL;
    DECLARE sunriseval BOOL DEFAULT FALSE;
    DECLARE _day, lngHour, M, _t, L, RA, Lquadrant, RAquadrant, sinDec, cosDec, cosH, H, T, UT FLOAT;

    -- some constant
    DECLARE ZENITH_OFFICIAL     FLOAT DEFAULT 90.83333333;
    DECLARE ZENITH_CIVIL        FLOAT DEFAULT 96;
    DECLARE ZENITH_NAUTICAL     FLOAT DEFAULT 102;
    DECLARE ZENITH_ASTRONOMICAL FLOAT DEFAULT 108;
    -- factor for degree to radian
    DECLARE D2R FLOAT DEFAULT PI() / 180;
    -- factor for radian to degree
    DECLARE R2D FLOAT DEFAULT 180 / PI();

    -- process zenith argument (enum['official','civil','nautical','astronomical'] or FLOAT)
    IF LEFT(LOWER(zenith),3)='off' THEN
        SET zenithangle = ZENITH_OFFICIAL;
    ELSEIF LEFT(LOWER(zenith),3)='civ' THEN
        SET zenithangle = ZENITH_CIVIL;
    ELSEIF LEFT(LOWER(zenith),3)='nau' THEN
        SET zenithangle = ZENITH_NAUTICAL;
    ELSEIF LEFT(LOWER(zenith),3)='ast' THEN
        SET zenithangle = ZENITH_ASTRONOMICAL;
    ELSE
        SET zenithangle = CAST(zenith AS DECIMAL(9,6));
    END IF;
    -- set defaults if unset
    SET zenithangle = IFNULL(zenithangle, ZENITH_OFFICIAL);

    -- process sunriseset argument (enum['sunrise','sunset'])
    IF RIGHT(LOWER(sunriseset),4)='rise' THEN
        SET sunriseval = true;
    ELSEIF RIGHT(LOWER(sunriseset),3)='set' THEN
        SET sunriseval = false;
    END IF;

    SET date=IFNULL(date, NOW());

    -- 1. first calculate the day of the year
    SET _day=dayofyear(date);

    -- 2. convert the longitude to hour value and calculate an approximate time
    SET lngHour = longitude / 15;
    SET _t = IF(sunriseval, _day + ((6 - lngHour) / 24), _day + ((18 - lngHour) / 24));

    -- 3. calculate the Sun's mean anomaly
    SET M = (0.9856 * _t) - 3.289;

    -- 4. calculate the Sun's true longitude
    SET L = M + (1.916 * SIN(M * D2R)) + (0.020 * SIN(2 * M * D2R)) + 282.634;
    -- NOTE: L potentially needs to be adjusted into the range [0,360) by adding/subtracting 360
    WHILE L > 360.0 DO
        SET L = L - 360.0;
    END WHILE;
    WHILE UT < 0.0 DO
        SET L = L + 360.0;
    END WHILE;

    -- 5a. calculate the Sun's right ascension
    SET RA = R2D * ATAN(0.91764 * TAN(L * D2R));
    -- NOTE: RA potentially needs to be adjusted into the range [0,360) by adding/subtracting 360
    WHILE RA > 360.0 DO
        SET RA = RA - 360.0;
    END WHILE;
    WHILE UT < 0.0 DO
        SET RA = RA + 360.0;
    END WHILE;

    -- 5b. right ascension value needs to be in the same quadrant as L
    SET Lquadrant = (FLOOR(L / (90.0))) * 90.0;
    SET RAquadrant = (FLOOR(RA / 90.0)) * 90.0;
    SET RA = RA + (Lquadrant - RAquadrant);

    -- 5c. right ascension value needs to be converted into hours
    SET RA = RA / 15;

    -- 6. calculate the Sun's declination
    SET sinDec = 0.39782 * SIN(L * D2R);
    SET cosDec = COS(ASIN(sinDec));

    -- 7a. calculate the Sun's local hour angle
    SET cosH = (COS(zenithangle * D2R) - (sinDec * SIN(latitude * D2R))) / (cosDec * COS(latitude * D2R));

    -- 7b. finish calculating H and convert into hours
    SET H = IF(sunriseval, 360.0 - R2D * ACOS(cosH), R2D * ACOS(cosH));
    SET H = H / 15;

    -- 8. calculate local mean time of rising/setting
    SET T = H + RA - (0.06571 * _t) - 6.622;

    -- 9. adjust back to UTC
    SET UT = T - lngHour;
    -- NOTE: UT potentially needs to be adjusted into the range [0,24) by adding/subtracting 24
    WHILE UT > 24.0 DO
        SET UT = UT - 24.0;
    END WHILE;
    WHILE UT < 0.0 DO
        SET UT = UT + 24.0;
    END WHILE;

    -- 10. convert UT value to local time zone of latitude/longitude
    RETURN TIME(CONVERT_TZ(CONCAT(DATE(date),' ',SEC_TO_TIME(UT * 3600.0)),'UTC','SYSTEM'));
END//

DELIMITER ;
