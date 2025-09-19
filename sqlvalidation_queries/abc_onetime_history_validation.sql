-- Validation Query 1: Check if bronze tables have data
%sql
SELECT 'ABC_onetime_history_sales_orders' as table_name, COUNT(*) as record_count 
FROM b_um_xyz.ABC_onetime_history_sales_orders
UNION ALL
SELECT 'ABC_onetime_history_sales_org_plant_xref' as table_name, COUNT(*) as record_count 
FROM b_um_xyz.ABC_onetime_history_sales_org_plant_xref;

-- Validation Query 2: Verify only HIST and RTNS data is loaded (no FCST data)
%sql
SELECT HISTSTREAM, COUNT(*) as record_count 
FROM b_um_xyz.ABC_onetime_history_sales_orders
GROUP BY HISTSTREAM
ORDER BY HISTSTREAM;

-- Validation Query 3: Check for missing mappings in silver layer
%sql
SELECT h.DMDUNIT, h.LOC, 'Missing in mapping table' as issue
FROM b_um_xyz.ABC_onetime_history_sales_orders h
LEFT JOIN b_um_xyz.ABC_onetime_history_sales_org_plant_xref x
  ON h.DMDUNIT = x.Product AND h.LOC = x.LOC
WHERE x.Product IS NULL
  AND h.HISTSTREAM IN ('HIST', 'RTNS')
LIMIT 100;

-- Validation Query 4: Validate Planning Partner mapping
%sql
SELECT 
  DMDGROUP,
  CASE 
    WHEN DMDGROUP = 'SALES' THEN 'R'
    WHEN DMDGROUP = 'SAMPLES' THEN 'N'
    WHEN DMDGROUP = 'CONSIGN' THEN 'C'
    ELSE 'Unknown'
  END AS Expected_Planning_Partner,
  COUNT(*) as record_count
FROM b_um_xyz.ABC_onetime_history_sales_orders
WHERE HISTSTREAM IN ('HIST', 'RTNS')
GROUP BY DMDGROUP
ORDER BY DMDGROUP;

-- Validation Query 5: Check silver layer data completeness
%sql
SELECT 
  COUNT(*) as total_records,
  SUM(CASE WHEN ABC_Model_Number IS NULL THEN 1 ELSE 0 END) as null_product,
  SUM(CASE WHEN Country IS NULL THEN 1 ELSE 0 END) as null_country,
  SUM(CASE WHEN Sales_Organization IS NULL THEN 1 ELSE 0 END) as null_sales_org,
  SUM(CASE WHEN PLANT IS NULL THEN 1 ELSE 0 END) as null_plant,
  SUM(CASE WHEN Planning_Partner IS NULL THEN 1 ELSE 0 END) as null_planning_partner
FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history;

-- Validation Query 6: Verify demand quantity calculation
%sql
SELECT 
  'HIST' as source_type,
  COUNT(*) as record_count,
  SUM(QTY) as total_qty_from_source,
  (SELECT SUM(Demand_Quantity_MTS) FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history) as total_demand_qty_in_silver
FROM b_um_xyz.ABC_onetime_history_sales_orders
WHERE HISTSTREAM = 'HIST';

-- Validation Query 7: Verify return quantity calculation
%sql
SELECT 
  'RTNS' as source_type,
  COUNT(*) as record_count,
  SUM(QTY) as total_qty_from_source,
  (SELECT SUM(Returns_Qty_MTS) FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history) as total_return_qty_in_silver
FROM b_um_xyz.ABC_onetime_history_sales_orders
WHERE HISTSTREAM = 'RTNS';

-- Validation Query 8: Check gold view data
%sql
SELECT COUNT(*) as record_count FROM g_external.v_sales_orders_demand_fcst_ABC_onetime_history;

-- Validation Query 9: Sample data from gold view
%sql
SELECT * FROM g_external.v_sales_orders_demand_fcst_ABC_onetime_history
LIMIT 10;

-- Validation Query 10: Check for duplicate records in gold view
%sql
SELECT 
  Product, 
  Country, 
  Sales_Org, 
  ZPLANT, 
  Planning_Partner, 
  Cal_month,
  COUNT(*) as record_count
FROM g_external.v_sales_orders_demand_fcst_ABC_onetime_history
GROUP BY Product, Country, Sales_Org, ZPLANT, Planning_Partner, Cal_month
HAVING COUNT(*) > 1
ORDER BY record_count DESC
LIMIT 100;