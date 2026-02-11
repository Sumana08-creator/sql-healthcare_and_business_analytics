/*
QUALITY & COMPLIANCE ANALYSIS

Objective:
This section focuses on evaluating healthcare quality and compliance
using standardised quality measure data. The analysis is designed to
identify areas of underperformance, monitor adherence to defined quality
standards, and support governance, audit, and regulatory oversight.

Key Questions Addressed:
1. What are the compliance rates by hospital across quality measures?
2. Which quality measures show lower compliance and may require attention?
3. How does compliance vary across practices?
4. Are there patterns of persistent non-compliance indicating systemic issues?

Tables Used:
- dbo.QualityMeasureData
- dbo.Hospitals
- dbo.Practices
- dbo.Physicians (where applicable)

Analytical Value:
The outputs from this section support:
- Quality improvement initiatives
- Regulatory and audit reporting
- Governance and risk oversight
- Performance benchmarking across hospitals and practices

All analysis is based on simulated, non-production healthcare data and is intended
for portfolio and demonstration purposes only.
*/

/* 
QUALITY QUERY 1 — Compliance Rate by Hospital and Measure

Purpose:
Calculates compliance rates for each quality measure at hospital level,
highlighting areas of strong performance and potential non-compliance risk.
*/

SELECT
    h.[Hospital Name],
    q.[Measure Name],
    COUNT(*) AS total_records,
    SUM(
        CASE 
            WHEN q.[IsCompliant] IN ('1','Y','Yes','TRUE')
            THEN 1 ELSE 0
        END
    ) AS compliant_records,
    CAST(
        1.0 * SUM(
            CASE 
                WHEN q.[IsCompliant] IN ('1','Y','Yes','TRUE')
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*),0)
        AS decimal(10,4)
    ) AS compliance_rate
FROM dbo.QualityMeasureData q
JOIN dbo.Hospitals h
    ON h.[Hospital ID] = q.[Hospital ID]
GROUP BY
    h.[Hospital Name],
    q.[Measure Name]
ORDER BY
    compliance_rate ASC,
    total_records DESC;



/* 
QUALITY QUERY 2 — Compliance Rate by Practice and Measure

Purpose:
Calculates quality compliance rates at the practice level,
supporting benchmarking and targeted improvement actions.

Tables:
- dbo.QualityMeasureData
- dbo.Practices
*/

SELECT
    p.[Practice Name],
    q.[Measure Name],
    COUNT(*) AS total_records,
    SUM(
        CASE 
            WHEN q.[IsCompliant] IN ('1','Y','Yes','TRUE')
            THEN 1 ELSE 0
        END
    ) AS compliant_records,
    CAST(
        1.0 * SUM(
            CASE 
                WHEN q.[IsCompliant] IN ('1','Y','Yes','TRUE')
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*),0)
        AS decimal(10,4)
    ) AS compliance_rate
FROM dbo.QualityMeasureData q
JOIN dbo.Practices p
    ON p.[Practice ID] = q.[Practice ID]
GROUP BY
    p.[Practice Name],
    q.[Measure Name]
ORDER BY
    compliance_rate ASC,
    total_records DESC;

/* 
QUALITY QUERY 3 — Lowest-Performing Quality Measures (Overall)

Purpose:
Identifies quality measures with the lowest overall compliance rates
across the organisation, highlighting priority areas for quality
improvement and governance attention.
*/

SELECT
    q.[Measure Name],
    COUNT(*) AS total_records,
    SUM(
        CASE 
            WHEN q.[IsCompliant] IN ('1','Y','Yes','TRUE')
            THEN 1 ELSE 0
        END
    ) AS compliant_records,
    CAST(
        1.0 * SUM(
            CASE 
                WHEN q.[IsCompliant] IN ('1','Y','Yes','TRUE')
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*),0)
        AS decimal(10,4)
    ) AS compliance_rate
FROM dbo.QualityMeasureData q
GROUP BY
    q.[Measure Name]
HAVING COUNT(*) >= 50   -- avoids misleading small samples
ORDER BY
    compliance_rate ASC,
    total_records DESC;