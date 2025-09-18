-- Validation Queries for ABC Onetime History Processing

-- 1. Validate Bronze Layer Data Ingestion
%sql
SELECT COUNT(*) AS total_records FROM b_um_xyz.ABC_onetime_history_sales_orders;

%sql
SELECT COUNT(*) AS total_records FROM b_um_xyz.ABC_onetime_history_sales_org_plant_xref;

-- 2. Validate Data Types in Bronze Layer
%sql
DESCRIBE TABLE b_um_xyz.ABC_onetime_history_sales_orders;

%sql
DESCRIBE TABLE b_um_xyz.ABC_onetime_history_sales_org_plant_xref;

-- 3. Check for HIST and RTNS Records Only (No FCST)
%sql
SELECT HISTSTREAM, COUNT(*) AS record_count
FROM b_um_xyz.ABC_onetime_history_sales_orders
GROUP BY HISTSTREAM
ORDER BY HISTSTREAM;

-- 4. Validate Silver Layer Transformation
%sql
SELECT COUNT(*) AS total_records FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history;

-- 5. Check Planning Partner Mapping
%sql
SELECT 
  DMDGROUP,
  Planning_Partner,
  COUNT(*) AS record_count
FROM b_um_xyz.ABC_onetime_history_sales_orders hist
JOIN s_xyz.sales_orders_demand_fcst_ABC_onetime_history silver
  ON hist.DMDUNIT = silver.ABC_Model_Number
  AND hist.STARTDATE = TO_DATE(CONCAT(SUBSTRING(CAST(silver.Cal_month AS STRING), 1, 4), '-', 
                                      SUBSTRING(CAST(silver.Cal_month AS STRING), 5, 2), '-01'))
GROUP BY DMDGROUP, Planning_Partner
ORDER BY DMDGROUP;

-- 6. Validate Join Between History and Regional Mapping
%sql
SELECT 
  COUNT(*) AS total_history_records,
  SUM(CASE WHEN xref.Product IS NOT NULL AND xref.LOC IS NOT NULL THEN 1 ELSE 0 END) AS matched_records,
  SUM(CASE WHEN xref.Product IS NULL OR xref.LOC IS NULL THEN 1 ELSE 0 END) AS unmatched_records
FROM b_um_xyz.ABC_onetime_history_sales_orders hist
LEFT JOIN b_um_xyz.ABC_onetime_history_sales_org_plant_xref xref
  ON hist.DMDUNIT = xref.Product AND hist.LOC = xref.LOC;

-- 7. Validate Gold View Data
%sql
SELECT COUNT(*) AS total_records FROM g_external.v_sales_orders_demand_fcst_ABC_onetime_history;

-- 8. Check for NULL Values in Required Fields
%sql
SELECT
  SUM(CASE WHEN Product IS NULL THEN 1 ELSE 0 END) AS null_product,
  SUM(CASE WHEN Country IS NULL THEN 1 ELSE 0 END) AS null_country,
  SUM(CASE WHEN Sales_Org IS NULL THEN 1 ELSE 0 END) AS null_sales_org,
  SUM(CASE WHEN ZPLANT IS NULL THEN 1 ELSE 0 END) AS null_plant,
  SUM(CASE WHEN Sales_Office IS NULL THEN 1 ELSE 0 END) AS null_sales_office,
  SUM(CASE WHEN Planning_Partner IS NULL THEN 1 ELSE 0 END) AS null_planning_partner
FROM g_external.v_sales_orders_demand_fcst_ABC_onetime_history;

-- 9. Validate Demand and Return Quantities
%sql
SELECT
  SUM(Demand_Quantity_MTS) AS total_demand_qty,
  SUM(Returns_Qty_MTS) AS total_returns_qty
FROM g_external.v_sales_orders_demand_fcst_ABC_onetime_history;

-- 10. Sample Data from Each Layer for Manual Verification
%sql
SELECT * FROM b_um_xyz.ABC_onetime_history_sales_orders LIMIT 10;

%sql
SELECT * FROM b_um_xyz.ABC_onetime_history_sales_org_plant_xref LIMIT 10;

%sql
SELECT * FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history LIMIT 10;

%sql
SELECT * FROM g_external.v_sales_orders_demand_fcst_ABC_onetime_history LIMIT 10;