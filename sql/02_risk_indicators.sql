/*
RISK INDICATORS ANALYSIS

Objective:
This section focuses on identifying clinical and operational risk signals
using encounter, readmission, and acuity-related data. The analysis highlights
areas where patient outcomes, operational stability, or governance oversight
may require attention.

Key Questions Addressed:
1. What are the readmission rates by hospital and department?
2. Which departments show higher inpatient readmission risk?
3. Are there areas combining high LOS and high readmission (risk hotspots)?
4. Which diagnosis or procedure groups are associated with higher risk?
5. Are there observable patient acuity signals that may contribute to risk?

Tables Used:
- dbo.Encounters
- dbo.Departments
- dbo.Hospitals
- dbo.Accounts
- dbo.Vitals (where applicable)

Analytical Value:
The outputs from this section support:
- Patient safety monitoring
- Identification of high-risk operational areas
- Targeted risk mitigation planning
- Governance and quality oversight reporting

All analysis is based on simulated, non-production healthcare data and is intended
for portfolio and demonstration purposes only.
*/

/* 
RISK QUERY 1 — Readmission Rate by Hospital

Purpose:
Measures the proportion of patient encounters resulting in readmission,
highlighting potential quality and operational risk at hospital level.
*/

SELECT
    h.[Hospital Name],
    COUNT(*) AS total_encounters,
    SUM(
        CASE 
            WHEN e.[Patient Readmission Flag] IN ('1','Y','Yes','TRUE')
            THEN 1 ELSE 0
        END
    ) AS readmissions,
    CAST(
        1.0 * SUM(
            CASE 
                WHEN e.[Patient Readmission Flag] IN ('1','Y','Yes','TRUE')
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*),0)
        AS decimal(10,4)
    ) AS readmission_rate
FROM dbo.Encounters e
JOIN dbo.Departments d
    ON d.[Department ID] = e.[Department ID]
JOIN dbo.Hospitals h
    ON h.[Hospital ID] = d.[Hospital ID]
GROUP BY
    h.[Hospital Name]
ORDER BY
    readmission_rate DESC;


/* 
RISK QUERY 2 — Inpatient Readmission Rate by Department

Purpose:
Identifies departments with higher inpatient readmission rates,
highlighting potential clinical and operational risk hotspots.
*/

SELECT
    d.[Department Name],
    COUNT(*) AS total_encounters,
    SUM(
        CASE 
            WHEN e.[Patient Inpatient Readmission Flag] IN ('1','Y','Yes','TRUE')
            THEN 1 ELSE 0
        END
    ) AS inpatient_readmissions,
    CAST(
        1.0 * SUM(
            CASE 
                WHEN e.[Patient Inpatient Readmission Flag] IN ('1','Y','Yes','TRUE')
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*),0)
        AS decimal(10,4)
    ) AS inpatient_readmission_rate
FROM dbo.Encounters e
JOIN dbo.Departments d
    ON d.[Department ID] = e.[Department ID]
GROUP BY
    d.[Department Name]
ORDER BY
    inpatient_readmission_rate DESC;


/* 
RISK QUERY 3 — High LOS and High Readmission Hotspots

Purpose:
Identifies departments that exhibit both higher-than-average
Length of Stay (LOS) and higher readmission rates, highlighting
areas of elevated operational and clinical risk.
*/

;WITH dept_metrics AS (
    SELECT
        d.[Department Name],
        COUNT(*) AS total_encounters,
        AVG(TRY_CONVERT(float, e.[Patient LOS])) AS avg_los_days,
        SUM(
            CASE 
                WHEN e.[Patient Readmission Flag] IN ('1','Y','Yes','TRUE')
                THEN 1 ELSE 0
            END
        ) AS readmissions,
        CAST(
            1.0 * SUM(
                CASE 
                    WHEN e.[Patient Readmission Flag] IN ('1','Y','Yes','TRUE')
                    THEN 1 ELSE 0
                END
            ) / NULLIF(COUNT(*),0)
            AS decimal(10,4)
        ) AS readmission_rate
    FROM dbo.Encounters e
    JOIN dbo.Departments d
        ON d.[Department ID] = e.[Department ID]
    WHERE TRY_CONVERT(float, e.[Patient LOS]) IS NOT NULL
    GROUP BY d.[Department Name]
)
SELECT
    *
FROM dept_metrics
WHERE
    avg_los_days > (SELECT AVG(avg_los_days) FROM dept_metrics)
    AND readmission_rate > (SELECT AVG(readmission_rate) FROM dept_metrics)
ORDER BY
    avg_los_days DESC,
    readmission_rate DESC;


/* 
RISK QUERY 4A — Readmission Rate by Primary ICD Diagnosis Code

Purpose:
Identifies diagnosis groups associated with higher readmission rates.
Useful for clinical risk monitoring and targeted quality improvement.

Tables:
- dbo.Encounters
- dbo.Accounts
*/

;WITH dx AS (
    SELECT
        a.[Primary ICD Diagnosis Code] AS primary_dx,
        COUNT(*) AS total_encounters,
        SUM(
            CASE 
                WHEN e.[Patient Readmission Flag] IN ('1','Y','Yes','TRUE')
                THEN 1 ELSE 0
            END
        ) AS readmissions
    FROM dbo.Encounters e
    JOIN dbo.Accounts a
        ON a.[Hospital Account ID] = e.[Hospital Account ID]
    WHERE a.[Primary ICD Diagnosis Code] IS NOT NULL
    GROUP BY a.[Primary ICD Diagnosis Code]
)
SELECT TOP 30
    primary_dx,
    total_encounters,
    readmissions,
    CAST(1.0 * readmissions / NULLIF(total_encounters,0) AS decimal(10,4)) AS readmission_rate
FROM dx
WHERE total_encounters >= 50   -- avoids tiny samples
ORDER BY readmission_rate DESC, total_encounters DESC;


/* 
RISK QUERY 5 — High-Acuity Risk Hotspots (ICU + Readmission)

Purpose:
Identifies departments with a higher concentration of encounters
that involve both ICU care and patient readmission, signalling
elevated clinical and operational risk.
*/

SELECT
    d.[Department Name],
    COUNT(*) AS total_encounters,
    SUM(
        CASE 
            WHEN e.[Patient InICU Flag] IN ('1','Y','Yes','TRUE')
             AND e.[Patient Readmission Flag] IN ('1','Y','Yes','TRUE')
            THEN 1 ELSE 0
        END
    ) AS icu_readmit_cases,
    CAST(
        1.0 * SUM(
            CASE 
                WHEN e.[Patient InICU Flag] IN ('1','Y','Yes','TRUE')
                 AND e.[Patient Readmission Flag] IN ('1','Y','Yes','TRUE')
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*),0)
        AS decimal(10,4)
    ) AS icu_readmit_rate
FROM dbo.Encounters e
JOIN dbo.Departments d
    ON d.[Department ID] = e.[Department ID]
GROUP BY
    d.[Department Name]
ORDER BY
    icu_readmit_rate DESC;

