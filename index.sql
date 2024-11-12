WITH RECURSIVE time_intervals AS (
    -- Generate 5-minute intervals for a specific date, e.g., '2024-04-24'.
    SELECT TIMESTAMP('2024-04-08 00:00:00') AS interval_start,
           TIMESTAMP('2024-04-08 00:05:00') AS interval_end
    UNION ALL
    SELECT interval_end AS interval_start,
           interval_end + INTERVAL 5 MINUTE AS interval_end
    FROM time_intervals
    WHERE interval_end < '2024-04-08 23:59:59'
),
app_usage AS (
    -- Calculate total duration of each app within each interval
    SELECT 
        t.interval_start,
        t.interval_end,
        u.app_name,
        SUM(TIMESTAMPDIFF(SECOND, GREATEST(u.start_time, t.interval_start), LEAST(u.end_time, t.interval_end))) AS duration,
        u.productivity_level
    FROM time_intervals t
    JOIN user_app_usage_1 u ON u.start_time < t.interval_end AND u.end_time > t.interval_start
    GROUP BY t.interval_start, t.interval_end, u.app_name, u.productivity_level
),
productivity_summary AS (
    -- Summarize productivity levels for each interval
    SELECT 
        interval_start,
        interval_end,
        GROUP_CONCAT(DISTINCT CONCAT(app_name, ' (', duration, ')') ORDER BY app_name) AS apps_used,
        SUM(IF(productivity_level = 2, duration, 0)) / SUM(duration) * 100 AS productive_pct,
        SUM(IF(productivity_level = 1, duration, 0)) / SUM(duration) * 100 AS neutral_pct,
        SUM(IF(productivity_level = 0, duration, 0)) / SUM(duration) * 100 AS unproductive_pct
    FROM app_usage
    GROUP BY interval_start, interval_end
)
--  Productivity Percentages:
SELECT 
    interval_start,
    interval_end,
    apps_used,
    CONCAT(ROUND(productive_pct, 2), '%') AS productive_percentage,
    CONCAT(ROUND(neutral_pct, 2), '%') AS neutral_percentage,
    CONCAT(ROUND(unproductive_pct, 2), '%') AS unproductive_percentage
FROM productivity_summary
ORDER BY interval_start;