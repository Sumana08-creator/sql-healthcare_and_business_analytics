/*
DATA QUALITY & GOVERNANCE ANALYSIS

Objective:
This section focuses on validating data quality, logical consistency,
and referential integrity across the dataset. The analysis is designed
to ensure that operational, risk, quality, and cost insights are based
on reliable and trustworthy data.

Key Questions Addressed:
1. Are key date fields valid and correctly formatted?
2. Are there logical inconsistencies in admission and discharge dates?
3. Are there orphan records across core tables?
4. Are key numeric fields stored and populated correctly?
5. Are data quality risks present that could affect reporting accuracy?

Tables Used:
- dbo.Encounters
- dbo.Departments
- dbo.Hospitals
- dbo.QualityMeasureData
- dbo.OrdersProcedures
- dbo.SurgicalEncounters

Analytical Value:
The outputs from this section support:
- Audit readiness
- Governance and compliance assurance
- Confidence in downstream reporting and analytics
- Identification of data quality risks requiring remediation

All analysis is based on simulated, non-production healthcare data and is intended
for portfolio and demonstration purposes only.
*/


/* 
DATA QUALITY QUERY 1 — Invalid Admission and Discharge Dates

Purpose:
Identifies records where admission or discharge dates cannot be
successfully converted to datetime, indicating data quality issues.
*/

SELECT
    COUNT(*) AS total_records,
    SUM(
        CASE 
            WHEN TRY_CONVERT(datetime, [Patient Admission Datetime]) IS NULL 
            THEN 1 ELSE 0 
        END
    ) AS invalid_admission_dates,
    SUM(
        CASE 
            WHEN TRY_CONVERT(datetime, [Patient Discharge Datetime]) IS NULL 
            THEN 1 ELSE 0 
        END
    ) AS invalid_discharge_dates
FROM dbo.Encounters;


/* 
DATA QUALITY QUERY 2 — Discharge Before Admission

Purpose:
Identifies encounters where discharge datetime occurs before admission,
indicating logical inconsistencies in the data.
*/

;WITH e AS (
    SELECT
        [Patient Encounter ID],
        TRY_CONVERT(datetime, [Patient Admission Datetime]) AS admit_dt,
        TRY_CONVERT(datetime, [Patient Discharge Datetime]) AS discharge_dt
    FROM dbo.Encounters
)
SELECT
    *
FROM e
WHERE admit_dt IS NOT NULL
  AND discharge_dt IS NOT NULL
  AND discharge_dt < admit_dt;


/* 
DATA QUALITY QUERY 3 — Orphan Encounters Without Department

Purpose:
Identifies encounter records that do not map to a valid department,
indicating referential integrity issues.
*/

SELECT
    e.[Patient Encounter ID],
    e.[Department ID]
FROM dbo.Encounters e
LEFT JOIN dbo.Departments d
    ON d.[Department ID] = e.[Department ID]
WHERE d.[Department ID] IS NULL;


/* 
DATA QUALITY QUERY 4 — Orphan Quality Measure Records

Purpose:
Identifies quality measure records without a valid hospital or practice,
which may affect compliance reporting accuracy.
*/

SELECT
    q.[Measure Name],
    q.[Hospital ID],
    q.[Practice ID]
FROM dbo.QualityMeasureData q
LEFT JOIN dbo.Hospitals h
    ON h.[Hospital ID] = q.[Hospital ID]
LEFT JOIN dbo.Practices p
    ON p.[Practice ID] = q.[Practice ID]
WHERE h.[Hospital ID] IS NULL
   OR p.[Practice ID] IS NULL;


/* 
DATA QUALITY QUERY 5 — LOS Conversion Check

Purpose:
Checks whether Length of Stay (LOS) values can be reliably converted
to numeric format for analytical use.
*/

SELECT
    COUNT(*) AS total_records,
    SUM(
        CASE 
            WHEN TRY_CONVERT(float, [Patient LOS]) IS NULL 
            THEN 1 ELSE 0 
        END
    ) AS non_numeric_los_values
FROM dbo.Encounters;
