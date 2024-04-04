-- DRILL DOWN

-- Analyzing the total delay time per day of week, we can drill down from year to month to day of month to day of week.
SELECT 
    dd."DayOfWeek",
    SUM(ff."TotalDelayTime") AS "TotalDelayTime",
    ld1."Airport_Code" AS "Origin_Airport",
    ld2."Airport_Code" AS "Destination_Airport"
FROM 
    "flights_fact_table" ff
JOIN 
    "date_dimension" dd ON ff."Date_Key" = dd."Date_Key"
JOIN 
    "location_dimension" ld1 ON ff."Origin_Key" = ld1."Location_Key"
JOIN 
    "location_dimension" ld2 ON ff."Dest_Key" = ld2."Location_Key"
GROUP BY 
    dd."DayOfWeek",
    ld1."Airport_Code",
    ld2."Airport_Code"
ORDER BY 
    dd."DayOfWeek", "TotalDelayTime" DESC;


-- Analyzing the total delay time per specific aircraft, we can drill down from unique carrier to tail number. 
SELECT 
    ad."UniqueCarrier",
    ad."TailNum",
    dd."DayOfWeek",
    SUM(ff."TotalDelayTime") AS "TotalDelayTime"
FROM 
    "flights_fact_table" ff
JOIN 
    "date_dimension" dd ON ff."Date_Key" = dd."Date_Key"
JOIN 
    "aircraft_dimension" ad ON ff."Aircraft_Key" = ad."Aircraft_Key"
GROUP BY 
    ad."UniqueCarrier",
    ad."TailNum",
    dd."DayOfWeek"
ORDER BY 
    ad."UniqueCarrier",
    ad."TailNum",
    dd."DayOfWeek";



-- SLICE

-- Return the total delay time during January for all flights
SELECT 
    f."TotalDelayTime",
    a."TailNum",
    l."Airport_Code" AS "Origin airport"
FROM 
    "flights_fact_table" f
JOIN 
    "date_dimension" d ON f."Date_Key" = d."Date_Key"
JOIN 
    "aircraft_dimension" a ON f."Aircraft_Key" = a."Aircraft_Key"
JOIN 
    "location_dimension" l ON f."Origin_Key" = l."Location_Key"
WHERE 
    d."Month" = 1;



-- DICE

-- Return the departure delay for all flights during January that originate from airport code ‘ABE’.
SELECT 
  ff."FlightNum", 
  ff."DepDelay", 
  dd."Month",
  ld."Airport_Code"
from
  flights_fact_table ff
JOIN
  date_dimension dd ON dd."Date_Key" = ff."Date_Key"
JOIN
  location_Dimension ld ON ld."Location_Key" = ff."Origin_Key"
WHERE
  dd."Month" = 1
  AND ld."Airport_Code" = 'ABE'
ORDER BY
  ff."DepDelay" ASC;


-- Return the distance for all flights during February associated with the unique carrier ‘WN’.
SELECT 
  ff."FlightNum", 
  ff."Distance", 
  aa."UniqueCarrier"
FROM 
  flights_fact_table ff
JOIN 
  date_dimension dd ON ff."Date_Key" = dd."Date_Key"
JOIN 
  aircraft_dimension aa ON ff."Aircraft_Key" = aa."Aircraft_Key"
WHERE 
  dd."Month" = 2
AND aa."UniqueCarrier" = 'WN';



-- COMBINED OLAP QUERIES

-- Compare the total flight delays of all flights arriving in ‘ABE’ versus ‘DEN’ in the month of June
SELECT 
  SUM(ff."TotalDelayTime") AS "TotalDelayTime",
  ld."Airport_Code"
FROM 
  flights_fact_table ff
JOIN
  location_dimension ld ON ld."Location_Key" = ff."Dest_Key"
JOIN
  date_dimension dd ON dd."Date_Key" = ff."Date_Key"
WHERE
  dd."Month" = 6 
  AND ld."Airport_Code" = 'ABE' OR ld."Airport_Code" = 'DEN'
GROUP BY
  ld."Airport_Code"
ORDER BY
  ld."Airport_Code" ASC;


-- Compare the total flight delays of all flights arriving in ‘ABE’ versus ‘DEN’ for unique carrier ‘XE’ in June versus July
SELECT 
  SUM(ff."TotalDelayTime") AS "TotalDelayTime",
  ld."Airport_Code",
  dd."Month"
FROM 
  flights_fact_table ff
JOIN
  location_dimension ld ON ld."Location_Key" = ff."Dest_Key"
JOIN
  date_dimension dd ON dd."Date_Key" = ff."Date_Key"
JOIN
  aircraft_dimension ad ON ad."Aircraft_Key"=ff."Aircraft_Key"
WHERE
  (dd."Month" = 6 OR dd."Month" = 7)
  AND (ld."Airport_Code" = 'ABE' OR ld."Airport_Code" = 'DEN')
  AND ad."UniqueCarrier" = 'XE'
GROUP BY
  ld."Airport_Code",
  dd."Month"
ORDER BY
  ld."Airport_Code" ASC;


-- Compare the total flight delays of all flights arriving in ‘ABE’ versus ‘DEN’ for unique carrier ‘WN’ versus unique carrier ‘XE’ in the month of June versus the month of July
SELECT 
    dd."Month",
    aa."UniqueCarrier",
    loc."Airport_Code",
    SUM(ff."CarrierDelay" + ff."WeatherDelay" + ff."NASDelay" + ff."SecurityDelay" + ff."LateAircraftDelay") AS TotalDelay
FROM 
    flights_fact_table ff
JOIN 
    date_dimension dd ON ff."Date_Key" = dd."Date_Key"
JOIN 
    aircraft_dimension aa ON ff."Aircraft_Key" = aa."Aircraft_Key"
JOIN 
    location_dimension loc ON ff."Dest_Key" = loc."Location_Key"
WHERE 
    (dd."Month" = 6 OR dd."Month" = 7)
AND 
    (loc."Airport_Code" = 'ABE' OR loc."Airport_Code" = 'DEN')
AND 
    (aa."UniqueCarrier" = 'WN' OR aa."UniqueCarrier" = 'XE')
GROUP BY 
    dd."Month",
    aa."UniqueCarrier",
    loc."Airport_Code";


-- Compare the total flight delays of all flights arriving in ‘ABE’ to that arriving in ‘DEN’, for the unique carrier ‘XE’
SELECT 
    aa."UniqueCarrier",
    loc."Airport_Code" AS Destination,
    SUM(ff."CarrierDelay" + ff."WeatherDelay" + ff."NASDelay" + ff."SecurityDelay" + ff."LateAircraftDelay") AS TotalDelay
FROM 
    flights_fact_table ff
JOIN 
    location_dimension loc ON ff."Dest_Key" = loc."Location_Key"
JOIN 
    aircraft_dimension aa ON ff."Aircraft_Key" = aa."Aircraft_Key"
WHERE 
    loc."Airport_Code" IN ('ABE', 'DEN')
AND 
    aa."UniqueCarrier" = 'XE'
GROUP BY 
    aa."UniqueCarrier",
    loc."Airport_Code";



-- ICERBERG QUERY (TopN)

-- Find the top 10 days of the year with the longest total delay time across all the airport locations
SELECT 
  dd."Year", 
  dd."Month", 
  dd."DayofMonth",
  TO_DATE(dd."Year" || '-' || dd."Month" || '-' || dd."DayofMonth", 'YYYY-MM-DD') AS "Date",
  SUM(ff."TotalDelayTime") AS "TotalDelayTime"
FROM 
  flights_fact_table ff
JOIN
  date_dimension dd ON ff."Date_Key" = dd."Date_Key"
GROUP BY
  dd."Year",
  dd."Month",
  dd."DayofMonth"
ORDER BY 
  "TotalDelayTime" DESC
LIMIT 10;



-- WINDOWING QUERY

-- Find the rank of flight numbers based on its average departure delays with the longest average departure delay being the highest rank
SELECT
    "FlightNum",
    AVG("DepDelay") AS "AvgDepartureDelay",
    RANK() OVER (ORDER BY AVG("DepDelay") DESC) AS "DepartureDelayRank"
FROM
    "flights_fact_table"
GROUP BY
    "FlightNum"
ORDER BY
    "DepartureDelayRank";



-- WINDOW CLAUSE QUERY

-- Find and compare the flight time of flights (including attributes such as CRS elapsed time, actual elapsed time and air time) over the first 3 months of the year 2008
SELECT 
    "Month",
    AVG(AvgCRSElapsedTime) AS AvgCRSElapsedTime,
    AVG(AvgActualElapsedTime) AS AvgActualElapsedTime,
    AVG(AvgAirTime) AS AvgAirTime
FROM (
    SELECT 
        dd."Month",
        AVG(ff."CRSElapsedTime") OVER W AS AvgCRSElapsedTime,
        AVG(ff."ActualElapsedTime") OVER W AS AvgActualElapsedTime,
        AVG(ff."AirTime") OVER W AS AvgAirTime
    FROM 
        (
            SELECT *
            FROM flights_fact_table
            WHERE "Date_Key" IN (SELECT "Date_Key" FROM date_dimension WHERE "Month" BETWEEN 1 AND 3)
        ) AS ff
    JOIN 
        date_dimension dd ON ff."Date_Key" = dd."Date_Key"
    WINDOW W AS (
        PARTITION BY dd."Month"
        ORDER BY dd."Month"
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )
)
GROUP BY "Month";