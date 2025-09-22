%sql
-- Validate bronze tables have data
SELECT COUNT(*) AS sales_count FROM b_onc.sales;

%sql
SELECT COUNT(*) AS sales_org_count FROM b_onc.sales_org;

%sql
-- Validate silver table has data
SELECT COUNT(*) AS silver_count FROM s_onc.sales_ord_his;

%sql
-- Validate gold view has data
SELECT COUNT(*) AS gold_count FROM g_onc.v_sales_ord_his;

%sql
-- Sample data from bronze sales table
SELECT * FROM b_onc.sales LIMIT 10;

%sql
-- Sample data from bronze sales_org table
SELECT * FROM b_onc.sales_org LIMIT 10;

%sql
-- Sample data from silver table
SELECT * FROM s_onc.sales_ord_his LIMIT 10;

%sql
-- Sample data from gold view
SELECT * FROM g_onc.v_sales_ord_his LIMIT 10;

%sql
-- Check for null values in important fields in silver table
SELECT 
  COUNT(*) AS total_rows,
  SUM(CASE WHEN APMModelNumber IS NULL THEN 1 ELSE 0 END) AS null_model_count,
  SUM(CASE WHEN Country IS NULL THEN 1 ELSE 0 END) AS null_country_count,
  SUM(CASE WHEN SalesOrganization IS NULL THEN 1 ELSE 0 END) AS null_sales_org_count
FROM s_onc.sales_ord_his;

%sql
-- Check distribution of Planning Partner values
SELECT 
  PlanningPartner,
  COUNT(*) AS count
FROM s_onc.sales_ord_his
GROUP BY PlanningPartner
ORDER BY count DESC;

%sql
-- Check distribution by Country
SELECT 
  Country,
  COUNT(*) AS count
FROM s_onc.sales_ord_his
GROUP BY Country
ORDER BY count DESC;