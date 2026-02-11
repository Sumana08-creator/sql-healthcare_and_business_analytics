Use GeneralHospital


/* 
OPERATIONAL PERFORMANCE ANALYSIS

Objective:
This section focuses on understanding hospital activity, patient flow, and capacity
using core operational data. The analysis is designed to provide visibility into how
resources are utilised across hospitals and departments, and to highlight potential
pressure points that may impact service delivery, patient experience, and operational
efficiency.

Key Questions Addressed:
1. How many patient admissions occur by hospital and by month?
2. Which departments handle the highest patient volumes?
3. What is the average Length of Stay (LOS) by hospital and department?
4. What proportion of patient encounters involve ICU care?
5. Are there identifiable peak admission days or times indicating capacity strain?

Tables Used:
- dbo.Encounters
- dbo.Departments
- dbo.Hospitals

Analytical Value:
The outputs from this section support:
- Capacity and workload planning
- Identification of high-demand departments
- Early detection of operational bottlenecks
- Data-driven decision-making for staffing and resource allocation

All analysis is based on simulated, non-production healthcare data and is intended
for portfolio and demonstration purposes only.
*/


/* 
QUERY 1 — Admissions by Hospital and Month

Purpose:
Shows monthly admission volume per hospital to support capacity planning,
trend monitoring, and identification of peak periods.

Tables:
- dbo.Encounters
- dbo.Departments
- dbo.Hospitals

Notes:
- Patient Admission Datetime is stored as VARCHAR in this dataset, so TRY_CONVERT is used.
*/

/* 
QUERY 1 — Admissions by Hospital and Month

Purpose:
Shows monthly admission volume per hospital to support capacity planning,
trend monitoring, and identification of peak periods.
*/

;WITH e AS (
    SELECT
        [Department ID],
        TRY_CONVERT(datetime, [Patient Admission Datetime]) AS admit_dt
    FROM dbo.Encounters
)
SELECT
    h.[Hospital Name],
    YEAR(e.admit_dt)  AS admit_year,
    MONTH(e.admit_dt) AS admit_month,
    COUNT(*)          AS admissions
FROM e
JOIN dbo.Departments d
    ON d.[Department ID] = e.[Department ID]
JOIN dbo.Hospitals h
    ON h.[Hospital ID] = d.[Hospital ID]
WHERE e.admit_dt IS NOT NULL
GROUP BY
    h.[Hospital Name],
    YEAR(e.admit_dt),
    MONTH(e.admit_dt)
ORDER BY
    admit_year,
    admit_month,
    admissions DESC;


/* 
QUERY 2 — Busiest Departments (by total admissions)

Purpose:
Identifies departments with the highest patient encounter volumes.
Useful for workload analysis, staffing planning, and capacity monitoring.

Tables:
- dbo.Encounters
- dbo.Departments
*/

SELECT
    d.[Department Name],
    COUNT(*) AS total_encounters
FROM dbo.Encounters e
JOIN dbo.Departments d
    ON d.[Department ID] = e.[Department ID]
GROUP BY
    d.[Department Name]
ORDER BY
    total_encounters DESC;


/* 
QUERY 3 — Average Length of Stay (LOS) by Hospital and Department

Purpose:
Evaluates patient flow efficiency by measuring average Length of Stay (LOS)
across hospitals and departments. Helps identify bottlenecks and capacity strain.

Tables:
- dbo.Encounters
- dbo.Departments
- dbo.Hospitals

Notes:
- Patient LOS is stored as text in this dataset, so TRY_CONVERT is used.
*/

;WITH e AS (
    SELECT
        [Department ID],
        TRY_CONVERT(float, [Patient LOS]) AS los_days
    FROM dbo.Encounters
)
SELECT
    h.[Hospital Name],
    d.[Department Name],
    COUNT(*)            AS encounter_count,
    AVG(e.los_days)     AS avg_los_days
FROM e
JOIN dbo.Departments d
    ON d.[Department ID] = e.[Department ID]
JOIN dbo.Hospitals h
    ON h.[Hospital ID] = d.[Hospital ID]
WHERE e.los_days IS NOT NULL
GROUP BY
    h.[Hospital Name],
    d.[Department Name]
HAVING COUNT(*) >= 30     -- removes very small samples
ORDER BY
    avg_los_days DESC;


/* 
QUERY 4 — ICU Utilisation Rate by Hospital

Purpose:
Calculates the proportion of patient encounters involving ICU care
to identify hospitals with higher acuity and operational pressure.

Tables:
- dbo.Encounters
- dbo.Departments
- dbo.Hospitals
*/

SELECT
    h.[Hospital Name],
    COUNT(*) AS total_encounters,
    SUM(
        CASE 
            WHEN e.[Patient InICU Flag] IN ('1', 'Y', 'Yes', 'TRUE') 
            THEN 1 
            ELSE 0 
        END
    ) AS icu_encounters,
    CAST(
        1.0 * SUM(
            CASE 
                WHEN e.[Patient InICU Flag] IN ('1', 'Y', 'Yes', 'TRUE') 
                THEN 1 
                ELSE 0 
            END
        ) / NULLIF(COUNT(*), 0)
        AS decimal(10,4)
    ) AS icu_utilisation_rate
FROM dbo.Encounters e
JOIN dbo.Departments d
    ON d.[Department ID] = e.[Department ID]
JOIN dbo.Hospitals h
    ON h.[Hospital ID] = d.[Hospital ID]
GROUP BY
    h.[Hospital Name]
ORDER BY
    icu_utilisation_rate DESC;

/* 
QUERY 5A — Peak Admission Days (Day of Week)

Purpose:
Identifies which days of the week experience the highest admission volumes.
Useful for workload planning and identifying peak demand patterns.

Note:
- Uses TRY_CONVERT because admission datetime is stored as VARCHAR.
*/

;WITH e AS (
    SELECT
        TRY_CONVERT(datetime, [Patient Admission Datetime]) AS admit_dt
    FROM dbo.Encounters
)
SELECT
    DATENAME(WEEKDAY, admit_dt) AS day_of_week,
    COUNT(*) AS admissions
FROM e
WHERE admit_dt IS NOT NULL
GROUP BY DATENAME(WEEKDAY, admit_dt)
ORDER BY admissions DESC;

