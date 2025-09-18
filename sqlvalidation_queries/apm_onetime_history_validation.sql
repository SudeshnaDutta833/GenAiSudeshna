-- Validate Bronze Layer Data - Check if data was loaded correctly
%sql
SELECT COUNT(*) AS total_records, 
       COUNT(DISTINCT DMDUNIT) AS distinct_products,
       COUNT(DISTINCT LOC) AS distinct_locations,
       COUNT(DISTINCT DMDGROUP) AS distinct_demand_groups,
       SUM(CASE WHEN HISTSTREAM = 'HIST' THEN 1 ELSE 0 END) AS hist_records,
       SUM(CASE WHEN HISTSTREAM = 'RTNS' THEN 1 ELSE 0 END) AS return_records,
       SUM(CASE WHEN HISTSTREAM NOT IN ('HIST', 'RTNS') THEN 1 ELSE 0 END) AS other_records
FROM b_um_isc.apm_onetime_history_sales_orders;

-- Validate Reference Data - Check if mapping data is available
%sql
SELECT COUNT(*) AS total_mappings,
       COUNT(DISTINCT LOC) AS distinct_locations,
       COUNT(DISTINCT REGION_SALES_ORG) AS distinct_regions,
       COUNT(DISTINCT BD_SALES_ORG) AS distinct_sales_orgs,
       COUNT(DISTINCT BD_PLANT) AS distinct_plants
FROM b_um_isc.apm_onetime_history_sales_org_plant_xref;

-- Validate Silver Layer Data - Check transformation results
%sql
SELECT COUNT(*) AS total_records,
       COUNT(DISTINCT APM_Model_Number) AS distinct_products,
       COUNT(DISTINCT Country) AS distinct_countries,
       COUNT(DISTINCT Sales_Organization) AS distinct_sales_orgs,
       COUNT(DISTINCT PLANT) AS distinct_plants,
       COUNT(DISTINCT Planning_Partner) AS distinct_planning_partners,
       SUM(Demand_Quantity_MTS) AS total_demand_qty,
       SUM(Returns_Qty_MTS) AS total_returns_qty
FROM s_isc.sales_orders_demand_fcst_apm_onetime_history;

-- Validate Planning Partner Mapping
%sql
SELECT DMDGROUP, Planning_Partner, COUNT(*) AS record_count
FROM b_um_isc.apm_onetime_history_sales_orders h
JOIN s_isc.sales_orders_demand_fcst_apm_onetime_history s
ON h.DMDUNIT = s.APM_Model_Number AND h.LOC = s.Country
GROUP BY DMDGROUP, Planning_Partner
ORDER BY DMDGROUP;

-- Validate Records with Missing Mappings
%sql
SELECT h.DMDUNIT, h.LOC, h.DMDGROUP, h.HISTSTREAM, h.QTY,
       s.Sales_Organization, s.PLANT
FROM b_um_isc.apm_onetime_history_sales_orders h
LEFT JOIN s_isc.sales_orders_demand_fcst_apm_onetime_history s
ON h.DMDUNIT = s.APM_Model_Number AND h.LOC = s.Country
WHERE (s.Sales_Organization IS NULL OR s.Sales_Organization = '')
AND h.HISTSTREAM IN ('HIST', 'RTNS')
LIMIT 100;

-- Validate Gold View Data
%sql
SELECT COUNT(*) AS total_records,
       COUNT(DISTINCT APO_Product) AS distinct_products,
       COUNT(DISTINCT Country) AS distinct_countries,
       COUNT(DISTINCT Sales_Org) AS distinct_sales_orgs,
       COUNT(DISTINCT ZPLANT) AS distinct_plants,
       COUNT(DISTINCT Planning_Partner) AS distinct_planning_partners,
       SUM(Demand_Quantity_MTS) AS total_demand_qty,
       SUM(Returns_Qty_MTS) AS total_returns_qty
FROM g_external.v_sales_orders_demand_fcst_apm_onetime_history;

-- Compare Bronze to Silver Record Counts (should match for HIST and RTNS records)
%sql
SELECT 'Bronze' AS layer, COUNT(*) AS record_count
FROM b_um_isc.apm_onetime_history_sales_orders
WHERE HISTSTREAM IN ('HIST', 'RTNS')
UNION ALL
SELECT 'Silver' AS layer, COUNT(*) AS record_count
FROM s_isc.sales_orders_demand_fcst_apm_onetime_history;

-- Validate Data Quality - Check for Nulls in Key Fields
%sql
SELECT 
  SUM(CASE WHEN APM_Model_Number IS NULL THEN 1 ELSE 0 END) AS null_product_count,
  SUM(CASE WHEN Country IS NULL THEN 1 ELSE 0 END) AS null_country_count,
  SUM(CASE WHEN Sales_Organization IS NULL OR Sales_Organization = '' THEN 1 ELSE 0 END) AS null_sales_org_count,
  SUM(CASE WHEN PLANT IS NULL OR PLANT = '' THEN 1 ELSE 0 END) AS null_plant_count,
  SUM(CASE WHEN Planning_Partner IS NULL OR Planning_Partner = '' THEN 1 ELSE 0 END) AS null_planning_partner_count
FROM s_isc.sales_orders_demand_fcst_apm_onetime_history;