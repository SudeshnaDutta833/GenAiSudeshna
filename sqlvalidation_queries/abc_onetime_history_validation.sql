-- Validation query 1: Check if bronze tables have data

%sql
SELECT COUNT(*) AS record_count FROM b_um_xyz.ABC_onetime_history_sales_orders;

%sql
SELECT COUNT(*) AS record_count FROM b_um_xyz.ABC_onetime_history_sales_org_plant_xref;

-- Validation query 2: Verify data filtering for HIST and RTNS only

%sql
SELECT 
  HISTSTREAM,
  COUNT(*) AS record_count
FROM b_um_xyz.ABC_onetime_history_sales_orders
GROUP BY HISTSTREAM
ORDER BY HISTSTREAM;

-- Validation query 3: Check for proper planning partner mapping

%sql
SELECT 
  DMDGROUP,
  Planning_Partner,
  COUNT(*) AS record_count
FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history
GROUP BY DMDGROUP, Planning_Partner
ORDER BY DMDGROUP;

-- Validation query 4: Verify join success rate between history and mapping tables

%sql
SELECT 
  CASE WHEN x.Product IS NULL THEN 'Unmapped' ELSE 'Mapped' END AS mapping_status,
  COUNT(*) AS record_count
FROM b_um_xyz.ABC_onetime_history_sales_orders h
LEFT JOIN b_um_xyz.ABC_onetime_history_sales_org_plant_xref x
  ON h.DMDUNIT = x.Product AND h.LOC = x.LOC
WHERE h.HISTSTREAM IN ('HIST', 'RTNS')
GROUP BY CASE WHEN x.Product IS NULL THEN 'Unmapped' ELSE 'Mapped' END;

-- Validation query 5: Check for correct demand and return quantity calculations

%sql
SELECT 
  SUM(Demand_Quantity_MTS) AS total_demand_qty,
  SUM(Returns_Qty_MTS) AS total_returns_qty
FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history;

-- Validation query 6: Verify gold view has expected data

%sql
SELECT COUNT(*) AS record_count FROM g_external.v_sales_orders_demand_fcst_ABC_onetime_history;

-- Validation query 7: Sample data from gold view

%sql
SELECT * FROM g_external.v_sales_orders_demand_fcst_ABC_onetime_history LIMIT 10;

-- Validation query 8: Check for any null values in required fields

%sql
SELECT 
  SUM(CASE WHEN Product IS NULL THEN 1 ELSE 0 END) AS null_product,
  SUM(CASE WHEN Country IS NULL THEN 1 ELSE 0 END) AS null_country,
  SUM(CASE WHEN Sales_Org IS NULL THEN 1 ELSE 0 END) AS null_sales_org,
  SUM(CASE WHEN ZPLANT IS NULL THEN 1 ELSE 0 END) AS null_plant,
  SUM(CASE WHEN Sales_Office IS NULL THEN 1 ELSE 0 END) AS null_sales_office,
  SUM(CASE WHEN Planning_Partner IS NULL THEN 1 ELSE 0 END) AS null_planning_partner
FROM g_external.v_sales_orders_demand_fcst_ABC_onetime_history;

-- Validation query 9: Check data distribution by planning partner

%sql
SELECT 
  Planning_Partner,
  COUNT(*) AS record_count,
  SUM(Demand_Quantity_MTS) AS total_demand,
  SUM(Returns_Qty_MTS) AS total_returns
FROM g_external.v_sales_orders_demand_fcst_ABC_onetime_history
GROUP BY Planning_Partner
ORDER BY Planning_Partner;

-- Validation query 10: Check data distribution by country

%sql
SELECT 
  Country,
  COUNT(*) AS record_count
FROM g_external.v_sales_orders_demand_fcst_ABC_onetime_history
GROUP BY Country
ORDER BY record_count DESC
LIMIT 20;