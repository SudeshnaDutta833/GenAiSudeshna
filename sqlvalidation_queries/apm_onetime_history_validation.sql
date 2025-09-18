-- Validation Query 1: Check if bronze tables are properly loaded with data
%sql
SELECT COUNT(*) AS record_count FROM b_um_isc.apm_onetime_history_sales_orders;

%sql
SELECT COUNT(*) AS record_count FROM b_um_isc.apm_onetime_history_sales_org_plant_xref;

-- Validation Query 2: Verify data filtering is working (only HIST and RTNS records)
%sql
SELECT 
  HISTSTREAM,
  COUNT(*) AS record_count
FROM b_um_isc.apm_onetime_history_sales_orders
GROUP BY HISTSTREAM
ORDER BY HISTSTREAM;

-- Validation Query 3: Check silver table for proper data transformation
%sql
SELECT COUNT(*) AS record_count FROM s_isc.sales_orders_demand_fcst_apm_onetime_history;

-- Validation Query 4: Verify planning partner mapping
%sql
SELECT 
  DMDGROUP,
  Planning_Partner,
  COUNT(*) AS record_count
FROM b_um_isc.apm_onetime_history_sales_orders h
JOIN s_isc.sales_orders_demand_fcst_apm_onetime_history s
  ON h.DMDUNIT = s.APM_Model_Number
  AND h.LOC = s.Country
  AND h.STARTDATE = TO_DATE(CONCAT(SUBSTRING(CAST(s.Cal_month AS STRING), 1, 4), '-', 
                                 SUBSTRING(CAST(s.Cal_month AS STRING), 5, 2), '-01'))
GROUP BY DMDGROUP, Planning_Partner
ORDER BY DMDGROUP;

-- Validation Query 5: Check join between history and mapping tables
%sql
SELECT 
  'Matched Records' AS record_type,
  COUNT(*) AS record_count
FROM s_isc.sales_orders_demand_fcst_apm_onetime_history s
WHERE Sales_Organization IS NOT NULL AND Sales_Organization != ''
UNION ALL
SELECT 
  'Unmatched Records' AS record_type,
  COUNT(*) AS record_count
FROM s_isc.sales_orders_demand_fcst_apm_onetime_history s
WHERE Sales_Organization IS NULL OR Sales_Organization = '';

-- Validation Query 6: Check gold view data
%sql
SELECT 
  COUNT(*) AS record_count 
FROM g_external.v_sales_orders_demand_fcst_apm_onetime_history;

-- Validation Query 7: Sample data from gold view
%sql
SELECT * 
FROM g_external.v_sales_orders_demand_fcst_apm_onetime_history
LIMIT 100;

-- Validation Query 8: Check for any null values in key fields
%sql
SELECT
  SUM(CASE WHEN APO_Product IS NULL THEN 1 ELSE 0 END) AS null_product_count,
  SUM(CASE WHEN Country IS NULL THEN 1 ELSE 0 END) AS null_country_count,
  SUM(CASE WHEN Sales_Org IS NULL THEN 1 ELSE 0 END) AS null_sales_org_count,
  SUM(CASE WHEN ZPLANT IS NULL THEN 1 ELSE 0 END) AS null_plant_count,
  SUM(CASE WHEN Planning_Partner IS NULL THEN 1 ELSE 0 END) AS null_planning_partner_count
FROM g_external.v_sales_orders_demand_fcst_apm_onetime_history;

-- Validation Query 9: Verify demand and return quantities
%sql
SELECT
  SUM(Demand_Quantity_MTS) AS total_demand_qty,
  SUM(Returns_Qty_MTS) AS total_returns_qty,
  COUNT(*) AS total_records
FROM g_external.v_sales_orders_demand_fcst_apm_onetime_history;

-- Validation Query 10: Check distribution of data by planning partner
%sql
SELECT
  Planning_Partner,
  COUNT(*) AS record_count,
  SUM(Demand_Quantity_MTS) AS total_demand_qty,
  SUM(Returns_Qty_MTS) AS total_returns_qty
FROM g_external.v_sales_orders_demand_fcst_apm_onetime_history
GROUP BY Planning_Partner
ORDER BY Planning_Partner;