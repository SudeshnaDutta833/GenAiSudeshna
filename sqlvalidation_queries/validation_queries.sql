-- Validation query for bronze layer tables
%sql
SELECT COUNT(*) AS record_count FROM b_um_xyz.ABC_onetime_history_sales_orders;

%sql
SELECT COUNT(*) AS record_count FROM b_um_xyz.ABC_onetime_history_sales_org_plant_xref;

-- Sample data validation for bronze layer
%sql
SELECT * FROM b_um_xyz.ABC_onetime_history_sales_orders LIMIT 10;

%sql
SELECT * FROM b_um_xyz.ABC_onetime_history_sales_org_plant_xref LIMIT 10;

-- Validation query for silver layer
%sql
SELECT COUNT(*) AS record_count FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history;

-- Sample data validation for silver layer
%sql
SELECT * FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history LIMIT 10;

-- Validation query for gold view
%sql
SELECT COUNT(*) AS record_count FROM g_external.v_sales_orders_demand_fcst_ABC_onetime_history;

-- Sample data validation for gold view
%sql
SELECT * FROM g_external.v_sales_orders_demand_fcst_ABC_onetime_history LIMIT 10;

-- Validate historical data load (HIST records)
%sql
SELECT 
  COUNT(*) AS hist_record_count,
  SUM(DemandQuantityMTS) AS total_demand_qty
FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history
WHERE DemandQuantityMTS IS NOT NULL;

-- Validate return data load (RTNS records)
%sql
SELECT 
  COUNT(*) AS returns_record_count,
  SUM(ReturnsQtyMTS) AS total_returns_qty
FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history
WHERE ReturnsQtyMTS IS NOT NULL;

-- Validate planning partner assignment
%sql
SELECT 
  PlanningPartner,
  COUNT(*) AS record_count
FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history
GROUP BY PlanningPartner
ORDER BY PlanningPartner;

-- Validate country code transformation
%sql
SELECT 
  h.LOC AS original_loc,
  s.Country AS transformed_country,
  COUNT(*) AS record_count
FROM b_um_xyz.ABC_onetime_history_sales_orders h
JOIN s_xyz.sales_orders_demand_fcst_ABC_onetime_history s
  ON h.DMDUNIT = s.ABCModelNumber
GROUP BY h.LOC, s.Country
ORDER BY h.LOC;