-- Validation query for bronze layer tables
%sql
SELECT COUNT(*) AS record_count, 
       COUNT(DISTINCT DMDUNIT) AS unique_products 
FROM b_um_isc.apm_onetime_history_sales_orders;

-- Validation query for regional mapping table
%sql
SELECT COUNT(*) AS record_count, 
       COUNT(DISTINCT Product) AS unique_products,
       COUNT(DISTINCT LOC) AS unique_locations
FROM b_um_isc.apm_onetime_history_sales_org_plant_xref;

-- Validate the silver layer data after transformation
%sql
SELECT COUNT(*) AS record_count,
       COUNT(DISTINCT `APM Model Number`) AS unique_products,
       COUNT(DISTINCT Country) AS unique_countries,
       COUNT(DISTINCT `Sales Organization`) AS unique_sales_orgs,
       COUNT(DISTINCT PLANT) AS unique_plants
FROM s_isc.sales_orders_demand_fcst_apm_onetime_history;

-- Validate that only HIST and RTNS data is loaded (no FCST)
%sql
SELECT HISTSTREAM, COUNT(*) AS record_count
FROM b_um_isc.apm_onetime_history_sales_orders
GROUP BY HISTSTREAM;

-- Validate planning partner mapping logic
%sql
SELECT DMDGROUP, 
       Planning_Partner,
       COUNT(*) AS record_count
FROM s_isc.sales_orders_demand_fcst_apm_onetime_history s
JOIN b_um_isc.apm_onetime_history_sales_orders b
  ON s.`APM Model Number` = b.DMDUNIT
GROUP BY DMDGROUP, Planning_Partner
ORDER BY DMDGROUP;

-- Validate gold view data
%sql
SELECT COUNT(*) AS record_count,
       COUNT(DISTINCT `APO Product`) AS unique_products,
       COUNT(DISTINCT Country) AS unique_countries,
       COUNT(DISTINCT `Sales Org`) AS unique_sales_orgs,
       COUNT(DISTINCT ZPLANT) AS unique_plants,
       COUNT(DISTINCT `Planning Partner`) AS unique_planning_partners
FROM g_external.v_sales_orders_demand_fcst_apm_onetime_history;