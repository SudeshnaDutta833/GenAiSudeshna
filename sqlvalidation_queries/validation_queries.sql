-- Validation queries to check data quality and transformation correctness

-- 1. Check if bronze tables have data
%sql
SELECT COUNT(*) AS record_count FROM b_onc.sales;

%sql
SELECT COUNT(*) AS record_count FROM b_onc.sales_org;

-- 2. Check if silver table has data
%sql
SELECT COUNT(*) AS record_count FROM s_onc.sales_ord_his;

-- 3. Check if gold view is accessible
%sql
SELECT COUNT(*) AS record_count FROM g_onc.sales_order_history_view;

-- 4. Validate Planning Partner transformation
%sql
SELECT 
  DMDGROUP,
  PlanningPartner,
  COUNT(*) as count
FROM b_onc.sales s
JOIN s_onc.sales_ord_his h ON s.DMDUNIT = h.APMModelNumber AND s.LOC = h.Country
GROUP BY DMDGROUP, PlanningPartner
ORDER BY DMDGROUP;

-- 5. Validate Demand Quantity transformation
%sql
SELECT 
  HISTSTREAM,
  SUM(QTY) as total_qty_bronze,
  SUM(DemandQuantityMTS) as total_demand_silver
FROM b_onc.sales s
JOIN s_onc.sales_ord_his h ON s.DMDUNIT = h.APMModelNumber AND s.LOC = h.Country
GROUP BY HISTSTREAM;

-- 6. Validate Returns Qty transformation
%sql
SELECT 
  HISTSTREAM,
  SUM(QTY) as total_qty_bronze,
  SUM(ReturnsQtyMTS) as total_returns_silver
FROM b_onc.sales s
JOIN s_onc.sales_ord_his h ON s.DMDUNIT = h.APMModelNumber AND s.LOC = h.Country
WHERE HISTSTREAM = 'Return Qty'
GROUP BY HISTSTREAM;

-- 7. Check for any null values in key fields
%sql
SELECT 
  SUM(CASE WHEN APMModelNumber IS NULL THEN 1 ELSE 0 END) as null_model_count,
  SUM(CASE WHEN Country IS NULL THEN 1 ELSE 0 END) as null_country_count,
  SUM(CASE WHEN PlanningPartner IS NULL THEN 1 ELSE 0 END) as null_partner_count
FROM s_onc.sales_ord_his;

-- 8. Verify data distribution by country
%sql
SELECT 
  Country,
  COUNT(*) as record_count,
  SUM(DemandQuantityMTS) as total_demand,
  SUM(ReturnsQtyMTS) as total_returns
FROM s_onc.sales_ord_his
GROUP BY Country
ORDER BY record_count DESC;

-- 9. Check if any data was lost during transformation
%sql
SELECT 
  (SELECT COUNT(*) FROM b_onc.sales) as bronze_count,
  (SELECT COUNT(*) FROM s_onc.sales_ord_his) as silver_count,
  (SELECT COUNT(*) FROM g_onc.sales_order_history_view) as gold_count;