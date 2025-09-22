%sql
-- Validate bronze table for sales orders
SELECT COUNT(*) AS total_records, 
       COUNT(DISTINCT DMDUNIT) AS distinct_products,
       COUNT(DISTINCT LOC) AS distinct_locations,
       SUM(CASE WHEN HISTSTREAM = 'HIST' THEN 1 ELSE 0 END) AS hist_records,
       SUM(CASE WHEN HISTSTREAM = 'RTNS' THEN 1 ELSE 0 END) AS returns_records
FROM b_um_xyz.ABC_onetime_history_sales_orders;

%sql
-- Validate bronze table for sales org plant cross reference
SELECT COUNT(*) AS total_records,
       COUNT(DISTINCT Product) AS distinct_products,
       COUNT(DISTINCT LOC) AS distinct_locations,
       COUNT(DISTINCT REGION_SALES_ORG) AS distinct_sales_orgs
FROM b_um_xyz.ABC_onetime_history_sales_org_plant_xref;

%sql
-- Validate silver table data
SELECT COUNT(*) AS total_records,
       COUNT(DISTINCT ABCModelNumber) AS distinct_products,
       COUNT(DISTINCT Country) AS distinct_countries,
       COUNT(DISTINCT SalesOrganization) AS distinct_sales_orgs,
       SUM(DemandQuantityMTS) AS total_demand,
       SUM(ReturnsQtyMTS) AS total_returns
FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history;

%sql
-- Validate gold view data
SELECT COUNT(*) AS total_records,
       COUNT(DISTINCT ABCModelNumber) AS distinct_products,
       COUNT(DISTINCT Country) AS distinct_countries,
       COUNT(DISTINCT SalesOrganization) AS distinct_sales_orgs,
       SUM(DemandQuantityMTS) AS total_demand,
       SUM(ReturnsQtyMTS) AS total_returns
FROM g_external.v_sales_orders_demand_fcst_ABC_onetime_history;

%sql
-- Validate planning partner logic
SELECT PlanningPartner, COUNT(*) AS record_count
FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history
GROUP BY PlanningPartner
ORDER BY PlanningPartner;

%sql
-- Validate country transformation
SELECT 
    so.LOC AS original_loc,
    s.Country AS transformed_country,
    COUNT(*) AS record_count
FROM b_um_xyz.ABC_onetime_history_sales_orders so
JOIN s_xyz.sales_orders_demand_fcst_ABC_onetime_history s
ON so.DMDUNIT = s.ABCModelNumber
GROUP BY so.LOC, s.Country
ORDER BY so.LOC;