-- Validation Queries for ABC Demand History Processing

-- 1. Validate Bronze Layer Data Ingestion
%sql
-- Check if sales order history data was loaded correctly
SELECT COUNT(*) AS total_records, 
       COUNT(DISTINCT DMDUNIT) AS distinct_products,
       COUNT(DISTINCT LOC) AS distinct_locations,
       COUNT(DISTINCT HISTSTREAM) AS distinct_histstreams
FROM b_um_xyz.ABC_onetime_history_sales_orders;

%sql
-- Check if mapping data was loaded correctly
SELECT COUNT(*) AS total_records,
       COUNT(DISTINCT Product) AS distinct_products,
       COUNT(DISTINCT LOC) AS distinct_locations,
       COUNT(DISTINCT REGION_SALES_ORG) AS distinct_regions
FROM b_um_xyz.ABC_onetime_history_sales_org_plant_xref;

-- 2. Validate Silver Layer Transformations
%sql
-- Verify that only HIST and RTNS records were included
SELECT HISTSTREAM, COUNT(*) AS record_count
FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history
GROUP BY HISTSTREAM;

%sql
-- Validate Planning Partner mapping logic
SELECT DISTINCT Planning_Partner, COUNT(*) AS count
FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history
GROUP BY Planning_Partner
ORDER BY Planning_Partner;

%sql
-- Check for any missing Sales Organization or Plant mappings
SELECT COUNT(*) AS missing_sales_org_count
FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history
WHERE Sales_Organization = '0000';

%sql
-- Verify the Country code transformation logic
SELECT 
    s.Country, 
    h.LOC AS Original_LOC,
    COUNT(*) AS record_count
FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history s
JOIN b_um_xyz.ABC_onetime_history_sales_orders h
    ON s.ABC_Model_Number = h.DMDUNIT AND s.STARTDATE = h.STARTDATE
GROUP BY s.Country, h.LOC
ORDER BY s.Country;

-- 3. Validate Gold Layer View
%sql
-- Check record counts in gold view
SELECT COUNT(*) AS total_records
FROM g_external.v_sales_orders_demand_fcst_ABC_onetime_history;

%sql
-- Verify demand quantity calculations
SELECT 
    SUM(Demand_Quantity_MTS) AS total_demand_qty,
    SUM(Returns_Qty_MTS) AS total_returns_qty
FROM g_external.v_sales_orders_demand_fcst_ABC_onetime_history;

%sql
-- Check distribution by Planning Partner
SELECT 
    Planning_Partner,
    COUNT(*) AS record_count,
    SUM(Demand_Quantity_MTS) AS total_demand
FROM g_external.v_sales_orders_demand_fcst_ABC_onetime_history
GROUP BY Planning_Partner
ORDER BY Planning_Partner;

%sql
-- Verify data completeness - check for null values in key fields
SELECT 
    SUM(CASE WHEN Product IS NULL THEN 1 ELSE 0 END) AS null_product_count,
    SUM(CASE WHEN Country IS NULL THEN 1 ELSE 0 END) AS null_country_count,
    SUM(CASE WHEN Sales_Org IS NULL THEN 1 ELSE 0 END) AS null_sales_org_count,
    SUM(CASE WHEN ZPLANT IS NULL THEN 1 ELSE 0 END) AS null_plant_count,
    SUM(CASE WHEN Planning_Partner IS NULL THEN 1 ELSE 0 END) AS null_planning_partner_count,
    SUM(CASE WHEN Cal_month IS NULL THEN 1 ELSE 0 END) AS null_cal_month_count
FROM g_external.v_sales_orders_demand_fcst_ABC_onetime_history;

-- 4. Validate Sample Data
%sql
-- Check sample data for specific products
SELECT *
FROM g_external.v_sales_orders_demand_fcst_ABC_onetime_history
WHERE Product IN ('12A0403F', '140806', '1408010')
ORDER BY Product, Cal_month
LIMIT 100;