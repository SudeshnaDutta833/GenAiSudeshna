-- Validation Queries for Data Quality and Completeness

%sql
-- Validate Bronze Layer - Sales Table
SELECT 
    'b_onc.sales' as TableName,
    COUNT(*) as RecordCount,
    COUNT(DISTINCT Product) as UniqueProducts,
    COUNT(DISTINCT Loc) as UniqueLocations,
    MIN(LoadTimestamp) as FirstLoadTime,
    MAX(LoadTimestamp) as LastLoadTime
FROM b_onc.sales;

%sql
-- Validate Bronze Layer - Sales Org Table
SELECT 
    'b_onc.sales_org' as TableName,
    COUNT(*) as RecordCount,
    COUNT(DISTINCT Loc) as UniqueLocations,
    COUNT(DISTINCT Region) as UniqueRegions,
    MIN(LoadTimestamp) as FirstLoadTime,
    MAX(LoadTimestamp) as LastLoadTime
FROM b_onc.sales_org;

%sql
-- Validate Silver Layer - Data Quality Checks
SELECT 
    'Data Quality Check' as CheckType,
    COUNT(*) as TotalRecords,
    COUNT(CASE WHEN ApoPlanningVersion IS NULL THEN 1 END) as NullApoPlanningVersion,
    COUNT(CASE WHEN ApmModelNumber IS NULL THEN 1 END) as NullApmModelNumber,
    COUNT(CASE WHEN Country IS NULL OR LENGTH(Country) != 2 THEN 1 END) as InvalidCountry,
    COUNT(CASE WHEN CalMonth IS NULL THEN 1 END) as NullCalMonth,
    COUNT(CASE WHEN DemandQuantityMts < 0 THEN 1 END) as NegativeDemandQty
FROM s_onc.sales_ord_his;

%sql
-- Validate Silver Layer - Transformation Rules
SELECT 
    PlanningPartner,
    COUNT(*) as RecordCount
FROM s_onc.sales_ord_his
GROUP BY PlanningPartner
ORDER BY RecordCount DESC;

%sql
-- Validate Gold View - Summary Statistics
SELECT 
    'Gold View Summary' as ViewName,
    COUNT(*) as SummaryRecords,
    SUM(TotalDemandQuantityMts) as TotalDemandSum,
    SUM(TotalReturnsQtyMts) as TotalReturnsSum,
    MIN(CalMonth) as EarliestMonth,
    MAX(CalMonth) as LatestMonth
FROM g_onc.vw_sales_ord_his_summary;

%sql
-- Data Lineage Validation - Bronze to Silver
SELECT 
    'Bronze to Silver Lineage' as CheckType,
    b.bronze_count,
    s.silver_count,
    ROUND((s.silver_count * 100.0 / b.bronze_count), 2) as TransformationRate
FROM 
    (SELECT COUNT(*) as bronze_count FROM b_onc.sales) b
CROSS JOIN 
    (SELECT COUNT(*) as silver_count FROM s_onc.sales_ord_his) s;

%sql
-- Monthly Data Distribution Validation
SELECT 
    CalMonth,
    COUNT(*) as RecordCount,
    SUM(DemandQuantityMts) as TotalDemand,
    SUM(ReturnsQtyMts) as TotalReturns,
    COUNT(DISTINCT Country) as UniqueCountries
FROM s_onc.sales_ord_his
GROUP BY CalMonth
ORDER BY CalMonth DESC;

%sql
-- Country-wise Data Distribution
SELECT 
    Country,
    COUNT(*) as RecordCount,
    SUM(DemandQuantityMts) as TotalDemand,
    AVG(DemandQuantityMts) as AvgDemand
FROM s_onc.sales_ord_his
WHERE Country IS NOT NULL
GROUP BY Country
ORDER BY TotalDemand DESC;

%sql
-- Planning Partner Distribution Validation
SELECT 
    PlanningPartner,
    COUNT(*) as RecordCount,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as Percentage
FROM s_onc.sales_ord_his
GROUP BY PlanningPartner
ORDER BY RecordCount DESC;

%sql
-- Data Freshness Check
SELECT 
    'Data Freshness' as CheckType,
    MAX(ProcessedTimestamp) as LastProcessedTime,
    DATEDIFF(HOUR, MAX(ProcessedTimestamp), CURRENT_TIMESTAMP()) as HoursSinceLastLoad
FROM s_onc.sales_ord_his;