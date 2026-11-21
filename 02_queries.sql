-- CareLoop Clinics: No-Show Guard
-- Part 2: MySQL Analysis

-- 2.1 Duplicate primary-key validation
-- Run separately to demonstrate ERROR 1062.
-- INSERT INTO appointments
-- SELECT * FROM (
--   SELECT * FROM appointments
--   ORDER BY appointment_id LIMIT 1
-- ) AS duplicate_record;

SELECT COUNT(*) AS total_appointments,
       COUNT(DISTINCT appointment_id) AS unique_appointments,
       SUM(no_show) AS total_no_shows
FROM appointments;

-- 2.2 Clinic no-show rates (minimum 95 appointments)
SELECT c.clinic_id, c.clinic_name, c.city,
       COUNT(a.appointment_id) AS total_appointments,
       SUM(a.no_show) AS total_no_shows,
       ROUND(100.0 * SUM(a.no_show) /
             NULLIF(COUNT(a.appointment_id), 0), 2)
             AS no_show_rate_pct
FROM clinics c
JOIN appointments a ON c.clinic_id = a.clinic_id
GROUP BY c.clinic_id, c.clinic_name, c.city
HAVING COUNT(a.appointment_id) >= 95
ORDER BY no_show_rate_pct DESC;

-- 2.2 Additional analysis: all eight clinics
SELECT c.clinic_id, c.clinic_name, c.city,
       COUNT(a.appointment_id) AS total_appointments,
       SUM(a.no_show) AS total_no_shows,
       ROUND(100.0 * SUM(a.no_show) /
             NULLIF(COUNT(a.appointment_id), 0), 2)
             AS no_show_rate_pct
FROM clinics c
LEFT JOIN appointments a ON c.clinic_id = a.clinic_id
GROUP BY c.clinic_id, c.clinic_name, c.city
ORDER BY no_show_rate_pct DESC;

-- 2.3 No-show rates by booking lead time
SELECT
    CASE
        WHEN lead_days BETWEEN 0 AND 2 THEN '0-2 days'
        WHEN lead_days BETWEEN 3 AND 7 THEN '3-7 days'
        WHEN lead_days BETWEEN 8 AND 14 THEN '8-14 days'
        WHEN lead_days >= 15 THEN '15+ days'
        ELSE 'Unknown'
    END AS lead_time_band,
    COUNT(*) AS total_appointments,
    SUM(no_show) AS total_no_shows,
    ROUND(100.0 * SUM(no_show) / COUNT(*), 2)
        AS no_show_rate_pct
FROM appointments
GROUP BY lead_time_band
ORDER BY CASE lead_time_band
    WHEN '0-2 days' THEN 1
    WHEN '3-7 days' THEN 2
    WHEN '8-14 days' THEN 3
    WHEN '15+ days' THEN 4
    ELSE 5
END;

-- 2.4 Monthly trends using CTE and LAG
WITH monthly_summary AS (
    SELECT DATE_FORMAT(appt_date, '%Y-%m') AS appt_month,
           COUNT(*) AS total_appointments,
           SUM(no_show) AS total_no_shows,
           ROUND(100.0 * SUM(no_show) / COUNT(*), 2)
               AS no_show_rate_pct
    FROM appointments
    GROUP BY DATE_FORMAT(appt_date, '%Y-%m')
),
monthly_comparison AS (
    SELECT *,
           LAG(no_show_rate_pct) OVER (
               ORDER BY appt_month
           ) AS previous_month_rate
    FROM monthly_summary
)
SELECT *,
       ROUND(no_show_rate_pct - previous_month_rate, 2)
           AS month_over_month_change_pp
FROM monthly_comparison
ORDER BY appt_month;

-- 2.5 Clinic ranking by city versus overall rate
WITH clinic_summary AS (
    SELECT c.clinic_id, c.clinic_name, c.city,
           COUNT(a.appointment_id) AS total_appointments,
           SUM(a.no_show) AS total_no_shows,
           ROUND(100.0 * SUM(a.no_show) /
                 NULLIF(COUNT(a.appointment_id), 0), 2)
                 AS no_show_rate_pct
    FROM clinics c
    JOIN appointments a ON c.clinic_id = a.clinic_id
    GROUP BY c.clinic_id, c.clinic_name, c.city
),
overall_summary AS (
    SELECT ROUND(100.0 * SUM(no_show) / COUNT(*), 2)
               AS overall_no_show_rate_pct
    FROM appointments
),
clinic_rankings AS (
    SELECT cs.*,
           RANK() OVER (
               PARTITION BY city
               ORDER BY no_show_rate_pct DESC
           ) AS city_rank
    FROM clinic_summary cs
)
SELECT cr.*, os.overall_no_show_rate_pct,
       ROUND(cr.no_show_rate_pct -
             os.overall_no_show_rate_pct, 2)
             AS difference_from_overall_pp
FROM clinic_rankings cr
CROSS JOIN overall_summary os
ORDER BY cr.city, cr.city_rank, cr.clinic_id;
