/*
COST & VALUE ANALYSIS (SURGICAL & FINANCIAL)

Objective:
This section focuses on analysing surgical cost, length of stay, and
profitability to understand value delivery within hospital operations.
The analysis supports financial sustainability, operational efficiency,
and value-based care decision-making.

Key Questions Addressed:
1. Which surgical specialties have the highest average cost and LOS?
2. Which specialties generate the highest and lowest total profit?
3. What resources contribute most to surgical costs?
4. Are there patterns indicating inefficiency or cost pressure?

Tables Used:
- dbo.SurgicalEncounters
- dbo.SurgicalCosts
- dbo.Encounters (where applicable)
- dbo.Accounts (for financial context)

Analytical Value:
The outputs from this section support:
- Cost control and financial planning
- Identification of high-cost service lines
- Value-based care analysis
- Executive and governance-level decision-making

All analysis is based on simulated, non-production healthcare data and is intended
for portfolio and demonstration purposes only.
*/


/* 
COST QUERY 1 — Average Surgical LOS and Cost by Specialty

Purpose:
Evaluates surgical efficiency and cost by specialty to identify
high-cost and long-stay service lines.
*/

SELECT
    [Surgical Specialty],
    COUNT(*) AS surgery_cases,
    AVG(TRY_CONVERT(float, [Surgical LOS])) AS avg_surgical_los,
    AVG([Surgical Total Cost]) AS avg_surgical_cost
FROM dbo.SurgicalEncounters
WHERE TRY_CONVERT(float, [Surgical LOS]) IS NOT NULL
GROUP BY
    [Surgical Specialty]
HAVING COUNT(*) >= 30
ORDER BY
    avg_surgical_cost DESC,
    avg_surgical_los DESC;

/* 
COST QUERY 2 — Profitability by Surgical Specialty

Purpose:
Analyses profitability by specialty to understand which service lines
generate the most value and which may require cost optimisation.
*/

SELECT
    [Surgical Specialty],
    COUNT(*) AS surgery_cases,
    SUM([Surgical Total Profit]) AS total_profit,
    AVG([Surgical Total Profit]) AS avg_profit_per_case,
    AVG([Surgical Total Cost]) AS avg_cost_per_case
FROM dbo.SurgicalEncounters
GROUP BY
    [Surgical Specialty]
HAVING COUNT(*) >= 30
ORDER BY
    total_profit DESC;


/* 
COST QUERY 3 — Highest-Cost Surgical Resources

Purpose:
Identifies surgical resources with the highest average cost,
helping highlight cost drivers within surgical procedures.
*/

SELECT
    [Surgical Resource Type],
    [Surgical Resource Name],
    COUNT(*) AS usage_count,
    AVG([Surgical Resource Cost]) AS avg_resource_cost,
    SUM([Surgical Resource Cost]) AS total_resource_cost
FROM dbo.SurgicalCosts
GROUP BY
    [Surgical Resource Type],
    [Surgical Resource Name]
HAVING COUNT(*) >= 20
ORDER BY
    avg_resource_cost DESC;