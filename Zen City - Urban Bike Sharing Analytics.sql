/* =============================================================================
   PROJECT: Zen City - Urban Bike Sharing Analytics (Austin, Texas)
   DATASET: Google BigQuery - `bqproj26.zen_city`
   PURPOSE: End-to-end analytical pipeline
            - Chapter 2: Exploratory Data Analysis (EDA)
            - Chapter 4: Data Cleaning & Wrangling Pipeline
            - Chapter 5: Hypotheses Validation & Visualizations
            - Chapter 6: Predictive Modeling (Hub 2498 Forecast)
   ============================================================================= */


-- =============================================================================
-- CHAPTER 2: DATA EXPLORATION (EDA)
-- =============================================================================

/* -----------------------------------------------------------------------------
   Section 2.1: Volumetrics and Date Range Coverage (Table 2.1)
   Goal: Audit total record volume, primary key uniqueness, temporal boundaries,
         active fleet size, and origin/destination station counts.
   ----------------------------------------------------------------------------- */
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT trip_id) AS distinct_trips,
    COUNT(*) - COUNT(DISTINCT trip_id) AS duplicate_trip_ids,
    MIN(SAFE_CAST(start_time AS TIMESTAMP)) AS earliest_trip_time,
    MAX(SAFE_CAST(start_time AS TIMESTAMP)) AS latest_trip_time,
    COUNT(DISTINCT bike_id) AS total_unique_bikes,
    COUNT(DISTINCT start_station_id) AS unique_start_stations,
    COUNT(DISTINCT end_station_id) AS unique_end_stations
FROM `bqproj26.zen_city.rentals`;


/* -----------------------------------------------------------------------------
   Section 2.2: Mapping the 10 Departure Stations & Core Hub 2498 (Table 2.2)
   Goal: Map all 10 origin stations, aggregate departure volumes, and evaluate
         system dependency on Hub 2498 and the UT Austin campus perimeter.
   ----------------------------------------------------------------------------- */
SELECT 
    start_station_id,
    start_station_name,
    COUNT(*) AS departures_count,
    ROUND(COUNT(*) * 100.0 / 16585, 2) AS pct_of_total
FROM `bqproj26.zen_city.rentals`
GROUP BY 1, 2
ORDER BY departures_count DESC;


/* -----------------------------------------------------------------------------
   Section 2.3a: Descriptive Statistics for Trip Duration (Table 2.3a)
   Goal: Quantify central tendency, dispersion, and percentile distribution
         to detect extreme statistical skewness in ride duration.
   ----------------------------------------------------------------------------- */
SELECT 
    COUNT(*) AS total_trips,
    ROUND(AVG(duration_minutes), 2) AS mean_duration_min,
    ROUND(STDDEV(duration_minutes), 2) AS stddev_duration_min,
    MIN(duration_minutes) AS min_duration_min,
    MAX(duration_minutes) AS max_duration_min,
    APPROX_QUANTILES(duration_minutes, 100)[OFFSET(25)] AS percentile_25,
    APPROX_QUANTILES(duration_minutes, 100)[OFFSET(50)] AS median_duration_min,
    APPROX_QUANTILES(duration_minutes, 100)[OFFSET(75)] AS percentile_75,
    APPROX_QUANTILES(duration_minutes, 100)[OFFSET(95)] AS percentile_95,
    APPROX_QUANTILES(duration_minutes, 100)[OFFSET(99)] AS percentile_99
FROM `bqproj26.zen_city.rentals`;


/* -----------------------------------------------------------------------------
   Section 2.3b: Trip Duration Segmentation and Outlier Breakdown (Table 2.3b)
   Goal: Classify trip lengths into operational segments, isolating technical
         false starts (<=2 min circular trips) and extreme outliers (>8 hours).
   ----------------------------------------------------------------------------- */
SELECT 
    CASE 
        WHEN duration_minutes <= 2 AND start_station_id = end_station_id 
            THEN '1. Potential False Start (2m, same station)'
        WHEN duration_minutes <= 15 
            THEN '2. Short Commute / Micro-trip (2-15m)'
        WHEN duration_minutes BETWEEN 16 AND 30 
            THEN '3. Standard Commute (16-30m)'
        WHEN duration_minutes BETWEEN 31 AND 60 
            THEN '4. Extended Trip (31-60m)'
        WHEN duration_minutes BETWEEN 61 AND 240 
            THEN '5. Leisure / Long Rental (1-4h)'
        WHEN duration_minutes BETWEEN 241 AND 480 
            THEN '6. Full Day / Very Long (4-8h)'
        ELSE '7. Extreme Outlier (>8h / >480m)'
    END AS duration_segment,
    COUNT(*) AS trip_count,
    ROUND(COUNT(*) * 100.0 / 16585, 2) AS pct_of_total_trips,
    ROUND(AVG(duration_minutes), 1) AS avg_duration_in_bucket
FROM `bqproj26.zen_city.rentals`
GROUP BY 1
ORDER BY duration_segment;


/* -----------------------------------------------------------------------------
   Section 2.4a: Monthly Volume Progression and Daily Averages (Table 2.4a)
   Goal: Evaluate monthly velocity and track average daily trips across Q1
         to observe semester start ramp-up and Spring Break fluctuation.
   ----------------------------------------------------------------------------- */
SELECT 
    FORMAT_TIMESTAMP('%B', SAFE_CAST(start_time AS TIMESTAMP)) AS month_name,
    COUNT(*) AS total_rentals,
    COUNT(DISTINCT EXTRACT(DATE FROM SAFE_CAST(start_time AS TIMESTAMP))) AS active_days,
    ROUND(COUNT(*) / COUNT(DISTINCT EXTRACT(DATE FROM SAFE_CAST(start_time AS TIMESTAMP))), 1) AS daily_avg
FROM `bqproj26.zen_city.rentals`
GROUP BY 1, EXTRACT(MONTH FROM SAFE_CAST(start_time AS TIMESTAMP))
ORDER BY EXTRACT(MONTH FROM SAFE_CAST(start_time AS TIMESTAMP));


/* -----------------------------------------------------------------------------
   Section 2.4b: Hourly Demand Profile - Weekday vs. Weekend (Table 2.4b)
   Goal: Compare diurnal hourly patterns between instructional weekdays and
         leisure weekends to locate peak commuting windows and off-peak gaps.
   ----------------------------------------------------------------------------- */
SELECT 
    EXTRACT(HOUR FROM SAFE_CAST(start_time AS TIMESTAMP)) AS trip_hour,
    COUNTIF(EXTRACT(DAYOFWEEK FROM SAFE_CAST(start_time AS TIMESTAMP)) BETWEEN 2 AND 6) AS weekday_trips,
    ROUND(COUNTIF(EXTRACT(DAYOFWEEK FROM SAFE_CAST(start_time AS TIMESTAMP)) BETWEEN 2 AND 6) * 100.0 / 
          SUM(COUNTIF(EXTRACT(DAYOFWEEK FROM SAFE_CAST(start_time AS TIMESTAMP)) BETWEEN 2 AND 6)) OVER(), 2) AS weekday_pct,
    COUNTIF(EXTRACT(DAYOFWEEK FROM SAFE_CAST(start_time AS TIMESTAMP)) IN (1, 7)) AS weekend_trips,
    ROUND(COUNTIF(EXTRACT(DAYOFWEEK FROM SAFE_CAST(start_time AS TIMESTAMP)) IN (1, 7)) * 100.0 / 
          SUM(COUNTIF(EXTRACT(DAYOFWEEK FROM SAFE_CAST(start_time AS TIMESTAMP)) IN (1, 7))) OVER(), 2) AS weekend_pct
FROM `bqproj26.zen_city.rentals`
GROUP BY 1
ORDER BY trip_hour;


/* -----------------------------------------------------------------------------
   Section 2.5a: Fleet Performance - Electric vs. Classic Bikes (Table 2.5a)
   Goal: Measure volume share, inventory size, and daily asset turnover rate
         (trips/bike/day) by bike type across the 90-day operational quarter.
   ----------------------------------------------------------------------------- */
SELECT 
    LOWER(TRIM(bike_type)) AS bike_type,
    COUNT(*) AS total_trips,
    ROUND(COUNT(*) * 100.0 / 16585, 2) AS pct_of_total_trips,
    COUNT(DISTINCT bike_id) AS distinct_bikes,
    ROUND(COUNT(*) / NULLIF(COUNT(DISTINCT bike_id), 0), 1) AS trips_per_bike_in_q1,
    ROUND((COUNT(*) / NULLIF(COUNT(DISTINCT bike_id), 0)) / 90.0, 2) AS avg_daily_trips_per_bike,
    APPROX_QUANTILES(duration_minutes, 100)[OFFSET(50)] AS median_duration_min
FROM `bqproj26.zen_city.rentals`
GROUP BY 1;


/* -----------------------------------------------------------------------------
   Section 2.5b: User Segmentation by Subscriber Type (Table 2.5b)
   Goal: Analyze demand concentration and duration patterns across all 11
         original membership plans to identify dominant customer cohorts.
   ----------------------------------------------------------------------------- */
SELECT 
    TRIM(subscriber_type) AS subscriber_type,
    COUNT(*) AS total_trips,
    ROUND(COUNT(*) * 100.0 / 16585, 2) AS pct_of_total_trips,
    ROUND(AVG(duration_minutes), 1) AS avg_duration_min,
    APPROX_QUANTILES(duration_minutes, 100)[OFFSET(50)] AS median_duration_min
FROM `bqproj26.zen_city.rentals`
GROUP BY 1
ORDER BY total_trips DESC;



-- =============================================================================
-- CHAPTER 4: DATA CLEANING & DATA WRANGLING
-- =============================================================================

/* -----------------------------------------------------------------------------
   Section 4.1: Missing Value Audit Across Rentals Core Attributes
   Goal: Verify attribute completeness across all columns in `rentals`
         and identify anomalous NULL keys.
   ----------------------------------------------------------------------------- */
SELECT 
    COUNTIF(trip_id IS NULL) AS null_trip_id,
    COUNTIF(subscriber_type IS NULL) AS null_subscriber_type,
    COUNTIF(bike_id IS NULL) AS null_bike_id,
    COUNTIF(bike_type IS NULL) AS null_bike_type,
    COUNTIF(start_time IS NULL) AS null_start_time,
    COUNTIF(start_station_id IS NULL) AS null_start_station_id,
    COUNTIF(start_station_name IS NULL) AS null_start_station_name,
    COUNTIF(end_station_id IS NULL) AS null_end_station_id,
    COUNTIF(end_station_name IS NULL) AS null_end_station_name,
    COUNTIF(duration_minutes IS NULL) AS null_duration_minutes
FROM `bqproj26.zen_city.rentals`;


/* -----------------------------------------------------------------------------
   Section 4.1b: Pop-up Event Destination Anomaly Inspection
   Goal: Inspect the single record with NULL end_station_id to confirm it represents
         a legitimate trip to the 'Springfest 2022' temporary pop-up station.
   ----------------------------------------------------------------------------- */
SELECT 
    trip_id,
    subscriber_type,
    bike_id,
    bike_type,
    start_time,
    start_station_id,
    start_station_name,
    end_station_id,
    end_station_name,
    duration_minutes
FROM `bqproj26.zen_city.rentals`
WHERE end_station_id IS NULL;


/* -----------------------------------------------------------------------------
   Section 4.3: Subscriber Tier Standardization Logic (Table 4.3)
   Goal: Consolidate 11 raw membership variations into 4 business tiers:
         Student, Local Commuter, Casual / Pay-per-use, and Other.
   ----------------------------------------------------------------------------- */
SELECT 
    CASE 
        WHEN subscriber_type LIKE '%Student%' THEN 'Student'
        WHEN subscriber_type IN ('Local31', 'Local365', 'Annual Membership') THEN 'Local Commuter'
        WHEN subscriber_type IN ('Pay-as-you-ride', 'Single Trip (Pay-as-you-ride)', 
                                 'Explorer', '24 Hour Walk Up Pass', '3-Day Weekender') THEN 'Casual / Pay-per-use'
        ELSE 'Other'
    END AS clean_subscriber_tier,
    COUNT(*) AS total_trips,
    ROUND(COUNT(*) * 100.0 / 16585, 2) AS pct_of_total,
    ROUND(AVG(duration_minutes), 1) AS avg_duration_min,
    APPROX_QUANTILES(duration_minutes, 100)[OFFSET(50)] AS median_duration_min
FROM `bqproj26.zen_city.rentals`
GROUP BY 1
ORDER BY total_trips DESC;


/* -----------------------------------------------------------------------------
   Section 4.4: Infrastructure Integration Audit & Dock Churn Rate (Table 4.4)
   Goal: Cross-reference departure hubs with `station_info`, diagnosing the 3
         unmatched stations (7125, 7188, 4938), resolving naming discrepancies,
         and calculating the AI-derived Dock Churn Rate.
   ----------------------------------------------------------------------------- */
WITH start_counts AS (
    SELECT 
        start_station_id,
        start_station_name,
        COUNT(*) AS total_departures
    FROM `bqproj26.zen_city.rentals`
    GROUP BY 1, 2
)
SELECT 
    sc.start_station_id,
    sc.start_station_name AS rental_table_name,
    si.name AS station_info_name,
    si.status,
    si.property_type,
    si.number_of_docks,
    sc.total_departures,
    ROUND(sc.total_departures / NULLIF(si.number_of_docks, 0), 1) AS departures_per_dock_churn_rate
FROM start_counts sc
LEFT JOIN `bqproj26.zen_city.station_info` si
    ON sc.start_station_id = si.station_id
ORDER BY sc.total_departures DESC;


/* -----------------------------------------------------------------------------
   Section 4.5: Master Clean CTE Query & Data Quality Audit (Table 4.5)
   Goal: Unified data transformation pipeline executing safe type-casting, 
         temporal feature extraction, COALESCE-based station name preservation, 
         pop-up key replacement (9999), and data validity tagging.
   ----------------------------------------------------------------------------- */
WITH MasterClean AS (
    SELECT 
        SAFE_CAST(r.trip_id AS INT64) AS trip_id,
        TRIM(r.bike_id) AS bike_id,
        LOWER(TRIM(r.bike_type)) AS bike_type,

        -- Temporal attributes
        SAFE_CAST(r.start_time AS TIMESTAMP) AS trip_start_time,
        EXTRACT(DATE FROM SAFE_CAST(r.start_time AS TIMESTAMP)) AS trip_date,
        EXTRACT(MONTH FROM SAFE_CAST(r.start_time AS TIMESTAMP)) AS trip_month,
        FORMAT_TIMESTAMP('%B', SAFE_CAST(r.start_time AS TIMESTAMP)) AS month_name,
        EXTRACT(HOUR FROM SAFE_CAST(r.start_time AS TIMESTAMP)) AS trip_hour,
        EXTRACT(DAYOFWEEK FROM SAFE_CAST(r.start_time AS TIMESTAMP)) AS day_of_week_num,
        FORMAT_TIMESTAMP('%A', SAFE_CAST(r.start_time AS TIMESTAMP)) AS day_name,
        CASE 
            WHEN EXTRACT(DAYOFWEEK FROM SAFE_CAST(r.start_time AS TIMESTAMP)) IN (1, 7) THEN 'Weekend' 
            ELSE 'Weekday' 
        END AS day_type,

        -- Standardized subscriber tier
        CASE 
            WHEN r.subscriber_type LIKE '%Student%' THEN 'Student'
            WHEN r.subscriber_type IN ('Local31', 'Local365', 'Annual Membership') THEN 'Local Commuter'
            WHEN r.subscriber_type IN ('Pay-as-you-ride', 'Single Trip (Pay-as-you-ride)', 
                                     'Explorer', '24 Hour Walk Up Pass', '3-Day Weekender') THEN 'Casual / Pay-per-use'
            ELSE 'Other'
        END AS clean_subscriber_tier,

        -- Station details (Preserving unmatched stations & fixing pop-up NULL)
        SAFE_CAST(r.start_station_id AS INT64) AS start_station_id,
        COALESCE(s_start.name, r.start_station_name) AS start_station_name,
        COALESCE(s_start.number_of_docks, 0) AS start_docks,
        s_start.council_district AS start_district,

        COALESCE(SAFE_CAST(r.end_station_id AS INT64), 9999) AS end_station_id,
        COALESCE(s_end.name, r.end_station_name) AS end_station_name,
        COALESCE(s_end.number_of_docks, 0) AS end_docks,
        s_end.council_district AS end_district,

        -- Trip pattern and duration
        SAFE_CAST(r.duration_minutes AS INT64) AS duration_minutes,
        CASE 
            WHEN r.start_station_id = r.end_station_id THEN 'Round Trip' 
            ELSE 'Point-to-Point' 
        END AS trip_pattern,

        -- Data quality and anomaly tagging
        CASE 
            WHEN r.duration_minutes <= 2 AND r.start_station_id = r.end_station_id THEN 'False Start'
            WHEN r.duration_minutes > 480 THEN 'Extreme Outlier (>8h)'
            ELSE 'Valid'
        END AS validity_status

    FROM `bqproj26.zen_city.rentals` r
    LEFT JOIN `bqproj26.zen_city.station_info` s_start 
        ON r.start_station_id = s_start.station_id
    LEFT JOIN `bqproj26.zen_city.station_info` s_end 
        ON r.end_station_id = s_end.station_id
)
SELECT 
    validity_status AS trip_status,
    COUNT(*) AS trip_count,
    ROUND(COUNT(*) * 100.0 / 16585, 2) AS pct_of_total
FROM MasterClean
GROUP BY 1
ORDER BY trip_count DESC;



-- =============================================================================
-- CHAPTER 5: DATA ANALYSIS & VISUALIZATIONS (HYPOTHESES TESTING)
-- =============================================================================

/* -----------------------------------------------------------------------------
   Section 5.1: Subscriber Tier vs. Fleet Type Interaction (Table 5.1)
   Hypothesis 1 Validation:
   Goal: Demonstrate overwhelmingly high electric bike preference (>88%) across 
         core commuting segments, confirming classic bikes cause dock congestion.
   ----------------------------------------------------------------------------- */
WITH MasterClean AS (
    SELECT 
        CASE 
            WHEN subscriber_type LIKE '%Student%' THEN 'Student'
            WHEN subscriber_type IN ('Local31', 'Local365', 'Annual Membership') THEN 'Local Commuter'
            WHEN subscriber_type IN ('Pay-as-you-ride', 'Single Trip (Pay-as-you-ride)', 
                                     'Explorer', '24 Hour Walk Up Pass', '3-Day Weekender') THEN 'Casual / Pay-per-use'
            ELSE 'Other'
        END AS clean_tier,
        LOWER(TRIM(bike_type)) AS bike_type,
        SAFE_CAST(duration_minutes AS INT64) AS duration_minutes,
        CASE 
            WHEN duration_minutes <= 2 AND start_station_id = end_station_id THEN 'False Start'
            WHEN duration_minutes > 480 THEN 'Extreme Outlier (>8h)'
            ELSE 'Valid'
        END AS validity_status
    FROM `bqproj26.zen_city.rentals`
)
SELECT 
    clean_tier,
    COUNTIF(bike_type = 'electric') AS electric_trips,
    COUNTIF(bike_type = 'classic') AS classic_trips,
    ROUND(COUNTIF(bike_type = 'electric') * 100.0 / COUNT(*), 1) AS electric_share_pct,
    ROUND(AVG(CASE WHEN bike_type = 'electric' THEN duration_minutes END), 1) AS avg_electric_dur,
    ROUND(AVG(CASE WHEN bike_type = 'classic' THEN duration_minutes END), 1) AS avg_classic_dur
FROM MasterClean
WHERE validity_status = 'Valid'
GROUP BY 1
ORDER BY electric_trips DESC;


/* -----------------------------------------------------------------------------
   Section 5.2: Hourly Corridor Drainage - Station 2498 to 3798 (PCL) (Table 5.3a)
   Hypothesis 2 Validation:
   Goal: Track outbound volume from Hub 2498 to Station 3798 (PCL Library), proving
         the station drains rapidly between 12:00-17:00, causing artificial shortage.
   ----------------------------------------------------------------------------- */
WITH MasterClean AS (
    SELECT 
        EXTRACT(HOUR FROM SAFE_CAST(start_time AS TIMESTAMP)) AS trip_hour,
        SAFE_CAST(start_station_id AS INT64) AS start_station_id,
        SAFE_CAST(end_station_id AS INT64) AS end_station_id,
        CASE 
            WHEN duration_minutes <= 2 AND start_station_id = end_station_id THEN 'False Start'
            WHEN duration_minutes > 480 THEN 'Extreme Outlier (>8h)'
            ELSE 'Valid'
        END AS validity_status
    FROM `bqproj26.zen_city.rentals`
)
SELECT 
    trip_hour,
    COUNTIF(start_station_id = 2498) AS departures_from_2498,
    COUNTIF(start_station_id = 2498 AND end_station_id = 3798) AS corridor_to_pcl,
    ROUND(COUNTIF(start_station_id = 2498 AND end_station_id = 3798) * 100.0 / 
          NULLIF(COUNTIF(start_station_id = 2498), 0), 1) AS pct_absorbed_by_pcl
FROM MasterClean
WHERE validity_status = 'Valid'
GROUP BY 1
HAVING departures_from_2498 > 0
ORDER BY trip_hour;


/* -----------------------------------------------------------------------------
   Section 5.2b: The Core Feeder Trio Flow to PCL Library (Table 5.3b)
   Hypothesis 2 Advanced Validation:
   Goal: Quantify the top 3 origin stations generating 64.2% of all short 
         trips (2-7 min) to PCL Library (3798), supporting the Loop Shuttle strategy.
   ----------------------------------------------------------------------------- */
WITH short_trips_to_pcl AS (
    SELECT 
        SAFE_CAST(start_station_id AS INT64) AS start_station_id,
        start_station_name,
        duration_minutes
    FROM `bqproj26.zen_city.rentals`
    WHERE end_station_id = 3798 
      AND duration_minutes BETWEEN 2 AND 7
      AND NOT (duration_minutes <= 2 AND start_station_id = end_station_id)
)
SELECT 
    start_station_id,
    start_station_name,
    COUNT(*) AS short_trips_to_pcl,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct_of_all_short_trips_to_pcl,
    ROUND(AVG(duration_minutes), 1) AS avg_duration_min
FROM short_trips_to_pcl
WHERE start_station_id IN (2498, 7125, 7188)
GROUP BY 1, 2
ORDER BY short_trips_to_pcl DESC;


/* -----------------------------------------------------------------------------
   Section 5.3: Monthly Evolution by Day Type - Weekday vs. Weekend (Table 5.2)
   Combined Hypothesis 3 Validation:
   Goal: Show how weekday demand is coupled with academic months, while weekend 
         volume remained stagnant during winter, highlighting the Q2 leisure opportunity.
   ----------------------------------------------------------------------------- */
WITH MasterClean AS (
    SELECT 
        FORMAT_TIMESTAMP('%B', SAFE_CAST(start_time AS TIMESTAMP)) AS month_name,
        EXTRACT(MONTH FROM SAFE_CAST(start_time AS TIMESTAMP)) AS month_num,
        EXTRACT(DATE FROM SAFE_CAST(start_time AS TIMESTAMP)) AS trip_date,
        CASE 
            WHEN EXTRACT(DAYOFWEEK FROM SAFE_CAST(start_time AS TIMESTAMP)) IN (1, 7) THEN 'Weekend' 
            ELSE 'Weekday' 
        END AS day_type,
        CASE 
            WHEN duration_minutes <= 2 AND start_station_id = end_station_id THEN 'False Start'
            WHEN duration_minutes > 480 THEN 'Extreme Outlier (>8h)'
            ELSE 'Valid'
        END AS validity_status
    FROM `bqproj26.zen_city.rentals`
)
SELECT 
    month_name,
    month_num,
    COUNTIF(day_type = 'Weekday') AS weekday_trips,
    COUNT(DISTINCT CASE WHEN day_type = 'Weekday' THEN trip_date END) AS weekday_count,
    COUNTIF(day_type = 'Weekend') AS weekend_trips,
    COUNT(DISTINCT CASE WHEN day_type = 'Weekend' THEN trip_date END) AS weekend_count
FROM MasterClean
WHERE validity_status = 'Valid'
GROUP BY 1, 2
ORDER BY month_num;



-- =============================================================================
-- CHAPTER 6: PREDICTION MODEL (HUB 2498 - FRIDAY, APRIL 1, 2022)
-- =============================================================================

/* -----------------------------------------------------------------------------
   Section 6.1: Historical Friday Rental Time Series at Core Hub 2498 (Table 6.1)
   Goal: Extract Friday volume time-series at Station 2498 to isolate academic 
         baseline Fridays, filtering out winter break, severe weather, and Spring Break.
   ----------------------------------------------------------------------------- */
WITH MasterClean AS (
    SELECT 
        EXTRACT(DATE FROM SAFE_CAST(start_time AS TIMESTAMP)) AS rental_date,
        FORMAT_TIMESTAMP('%B', SAFE_CAST(start_time AS TIMESTAMP)) AS month_name,
        SAFE_CAST(start_station_id AS INT64) AS start_station_id,
        EXTRACT(DAYOFWEEK FROM SAFE_CAST(start_time AS TIMESTAMP)) AS day_of_week_num,
        CASE 
            WHEN duration_minutes <= 2 AND start_station_id = end_station_id THEN 'False Start'
            WHEN duration_minutes > 480 THEN 'Extreme Outlier (>8h)'
            ELSE 'Valid'
        END AS validity_status
    FROM `bqproj26.zen_city.rentals`
)
SELECT 
    rental_date,
    month_name,
    COUNT(*) AS rentals_from_2498
FROM MasterClean
WHERE start_station_id = 2498
  AND day_of_week_num = 6 -- Friday
  AND validity_status = 'Valid'
GROUP BY 1, 2
ORDER BY rental_date;

