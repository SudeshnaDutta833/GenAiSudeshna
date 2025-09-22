%sql
-- Validate bronze tables have data
SELECT COUNT(*) AS row_count FROM b_onc.Sales;

%sql
SELECT COUNT(*) AS row_count FROM b_onc.sales_org;

%sql
-- Validate silver table has data
SELECT COUNT(*) AS row_count FROM s_onc.sales_ord_his;

%sql
-- Validate gold view has data
SELECT COUNT(*) AS row_count FROM g_onc.v_sales_ord_his;

%sql
-- Validate data quality in silver layer
SELECT 
  COUNT(*) AS total_records,
  COUNT(CASE WHEN APOPlanningVersion = '001' THEN 1 END) AS valid_planning_version,
  COUNT(CASE WHEN APMModelNumber IS NULL THEN 1 END) AS null_model_numbers,
  COUNT(CASE WHEN Country IS NULL THEN 1 END) AS null_countries,
  COUNT(CASE WHEN SourceSystem = 'JDAAPM' THEN 1 END) AS valid_source_system
FROM s_onc.sales_ord_his;

%sql
-- Validate transformation logic for Planning Partner
SELECT 
  DMDGROUP,
  PlanningPartner,
  COUNT(*) AS count
FROM b_onc.Sales s
JOIN s_onc.sales_ord_his soh ON s.DMDUNIT = soh.APMModelNumber
GROUP BY DMDGROUP, PlanningPartner
ORDER BY DMDGROUP;

%sql
-- Validate the quantitative measures
SELECT 
  SUM(DemandQuantityMTS) AS total_demand_qty,
  SUM(TotalDemand) AS total_demand,
  SUM(ReturnsQtyMTS) AS total_returns
FROM s_onc.sales_ord_his;