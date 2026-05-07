--WORK Check

SELECT * FROM oil_cleaned ORDER BY date;

--data dimensions

SELECT
    COUNT(*)                          AS total_records,
    MIN(date::date)                   AS start_date,
    MAX(date::date)                   AS end_date,
    MAX(date::date) - MIN(date::date) AS observation_days,
    SUM(CASE WHEN event = 1 THEN 1 ELSE 0 END) AS event_days,
    SUM(CASE WHEN event = 0 THEN 1 ELSE 0 END) AS normal_days
FROM oil_cleaned;

-- daily price difference between Brent and WTI
SELECT
    date,
    brent_usd,
    wti_usd,
    ROUND((brent_usd - wti_usd)::numeric, 2) AS price_gap
FROM oil_cleaned
ORDER BY date;

-- highest Brent price and WTI  in a day
SELECT date, brent_usd, wti_usd, event
FROM oil_cleaned
ORDER BY brent_usd DESC
LIMIT 1;

--lowest Brent price and WTI in a day
SELECT date, brent_usd, wti_usd, event
FROM oil_cleaned
ORDER BY brent_usd ASC
LIMIT 1;

--days where Brent crossed $100
SELECT date, brent_usd,  wti_usd, event
FROM oil_cleaned
WHERE brent_usd > 100
ORDER BY date;

-- days where Brent and WTI was less than $80
SELECT date, brent_usd, wti_usd, event
FROM oil_cleaned 
WHERE brent_usd < 80
ORDER BY date;

-- Best and worst return days for Brent
SELECT date, brent_usd, ROUND((brent_return * 100)::numeric, 2) AS return_pct, event
FROM oil_cleaned
ORDER BY brent_return DESC
LIMIT 5;

SELECT date, brent_usd, ROUND((brent_return * 100)::numeric, 2) AS return_pct, event
FROM oil_cleaned
ORDER BY brent_return ASC
LIMIT 5;

-- positive days vs negative days
SELECT
    CASE WHEN brent_return >= 0 THEN 'Positive Day' ELSE 'Negative Day' END AS day_type,
    COUNT(*) AS num_days,
    ROUND(AVG(brent_return * 100)::numeric, 3) AS avg_return_pct
FROM oil_cleaned
GROUP BY day_type;

-- How many up days vs down days
SELECT
    CASE WHEN brent_return > 0 THEN 'Up'
         WHEN brent_return < 0 THEN 'Down'
         ELSE 'Flat' END AS direction,
    COUNT(*) AS days
FROM oil_cleaned
GROUP BY direction;

-- Average volatility overall
SELECT
    ROUND(AVG(brent_volatility)::numeric, 4) AS avg_brent_vol,
    ROUND(AVG(wti_volatility)::numeric, 4)   AS avg_wti_vol,
    ROUND(MAX(brent_volatility)::numeric, 4) AS max_brent_vol,
    ROUND(MIN(brent_volatility)::numeric, 4) AS min_brent_vol
FROM oil_cleaned;

-- Top 5 most volatile days
SELECT date, brent_usd,
    ROUND(brent_volatility::numeric, 4) AS brent_vol,
    ROUND(wti_volatility::numeric, 4)   AS wti_vol,
    event
FROM oil_cleaned
ORDER BY brent_volatility DESC
LIMIT 5;

-- Low volatility days 
SELECT date, brent_usd,
    ROUND(brent_volatility::numeric, 4) AS brent_vol, event
FROM oil_cleaned
WHERE brent_volatility < 0.03
ORDER BY brent_volatility ASC;

-- each day by volatility level
SELECT
    date, brent_usd,
    ROUND(brent_volatility::numeric, 4) AS vol,
    CASE
        WHEN brent_volatility >= 0.065 THEN 'Extreme'
        WHEN brent_volatility >= 0.05  THEN 'High'
        WHEN brent_volatility >= 0.035 THEN 'Moderate'
        ELSE 'Low'
    END AS vol_level,
    event
FROM oil_cleaned
ORDER BY date;

-- Count of days in each volatility level
SELECT
    CASE
        WHEN brent_volatility >= 0.065 THEN 'Extreme'
        WHEN brent_volatility >= 0.05  THEN 'High'
        WHEN brent_volatility >= 0.035 THEN 'Moderate'
        ELSE 'Low'
    END AS vol_level,
    COUNT(*) AS num_days
FROM oil_cleaned
GROUP BY vol_level
ORDER BY MIN(brent_volatility) DESC;

-- Average price, return and volatility during event vs normal days
SELECT
    CASE WHEN event = 1 THEN 'Event Day' ELSE 'Normal Day' END AS period,
    COUNT(*) AS days,
    ROUND(AVG(brent_usd)::numeric, 2)          AS avg_brent,
    ROUND(AVG(wti_usd)::numeric, 2)            AS avg_wti,
    ROUND(AVG(brent_return * 100)::numeric, 3) AS avg_return_pct,
    ROUND(AVG(brent_volatility)::numeric, 4)   AS avg_volatility
FROM oil_cleaned
GROUP BY event
ORDER BY event DESC;

-- All event days listed
SELECT date, brent_usd, wti_usd,
    ROUND((brent_return * 100)::numeric, 2) AS return_pct,
    ROUND(brent_volatility::numeric, 4)     AS volatility
FROM oil_cleaned
WHERE event = 1
ORDER BY date;

-- All normal days listed
SELECT date, brent_usd, wti_usd,
    ROUND((brent_return * 100)::numeric, 2) AS return_pct,
    ROUND(brent_volatility::numeric, 4)     AS volatility
FROM oil_cleaned
WHERE event = 0
ORDER BY date;

-- Running cumulative return day by day
SELECT
    date,
    brent_usd,
    ROUND((brent_return * 100)::numeric, 2) AS daily_return_pct,
    ROUND(SUM(brent_return) OVER (ORDER BY date)::numeric * 100, 2) AS cumulative_return_pct,
    event
FROM oil_cleaned
ORDER BY date;

-- Price change from very first day to each day
SELECT
    date,
    brent_usd,
    FIRST_VALUE(brent_usd) OVER (ORDER BY date) AS starting_price,
    ROUND((brent_usd - FIRST_VALUE(brent_usd) OVER (ORDER BY date))::numeric, 2) AS change_from_start,
    event
FROM oil_cleaned
ORDER BY date;


-- The exact day the geopolitical event began
SELECT date, brent_usd, wti_usd,
    ROUND((brent_return * 100)::numeric, 2) AS return_pct,
    event
FROM oil_cleaned
WHERE date IN ('2026-02-26', '2026-02-27', '2026-02-28')
ORDER BY date;



-- How fast did prices escalate in the first week
SELECT
    date,
    brent_usd,
    wti_usd,
    ROUND((brent_return * 100)::numeric, 2)                         AS daily_return_pct,
    ROUND((brent_usd - 74.5)::numeric, 2)                           AS rise_from_pre_event,
    ROUND(((brent_usd - 74.5) / 74.5 * 100)::numeric, 2)           AS pct_rise_from_pre_event
FROM oil_cleaned
WHERE event = 1
ORDER BY date
LIMIT 5;

-- Top 5 most expensive days — all during the event
SELECT
    date,
    brent_usd,
    wti_usd,
    ROUND((brent_usd - wti_usd)::numeric, 2) AS brent_wti_gap,
    ROUND((brent_return * 100)::numeric, 2)  AS return_pct,
    event
FROM oil_cleaned
ORDER BY brent_usd DESC
LIMIT 5;

-- Days where even during the crisis prices crashed hard (panic selling, ceasefire rumours etc.)
SELECT
    date,
    brent_usd,
    ROUND((brent_return * 100)::numeric, 2)  AS return_pct,
    ROUND(brent_volatility::numeric, 4)      AS volatility,
    event
FROM oil_cleaned
WHERE brent_return < -0.05
ORDER BY brent_return ASC;

-- Complete chronological story of the event
SELECT
    date,
    brent_usd,
    wti_usd,
    ROUND((brent_return * 100)::numeric, 2)  AS return_pct,
    ROUND(brent_volatility::numeric, 4)      AS volatility,
    CASE
        WHEN date::date < '2026-02-27'  THEN 'Pre-crisis'
        WHEN date::date <= '2026-03-09' THEN 'Shock & escalation'
        WHEN date::date <= '2026-03-31' THEN 'Peak crisis'
        WHEN date::date <= '2026-04-10' THEN 'Extreme swings'
        ELSE 'De-escalation'
    END AS crisis_phase,
    event
FROM oil_cleaned
ORDER BY date;

