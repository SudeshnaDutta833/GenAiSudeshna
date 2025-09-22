-- Validation queries to check data quality and transformation correctness

-- 1. Check bronze tables record count
%sql
SELECT COUNT(*) AS record_count FROM b_um_xyz.ABC_onetime_history_sales_orders;

%sql
SELECT COUNT(*) AS record_count FROM b_um_xyz.ABC_onetime_history_sales_org_plant_xref;

-- 2. Check silver table record count
%sql
SELECT COUNT(*) AS record_count FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history;

-- 3. Validate gold view record count
%sql
SELECT COUNT(*) AS record_count FROM g_external.v_sales_orders_demand_fcst_ABC_onetime_history;

-- 4. Check distribution of planning partner values
%sql
SELECT 
  PlanningPartner, 
  COUNT(*) AS record_count 
FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history 
GROUP BY PlanningPartner
ORDER BY PlanningPartner;

-- 5. Verify HIST records have demand quantities
%sql
SELECT 
  COUNT(*) AS record_count
FROM b_um_xyz.ABC_onetime_history_sales_orders 
WHERE HISTSTREAM = 'HIST' AND QTY > 0;

%sql
SELECT 
  COUNT(*) AS record_count
FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history 
WHERE DemandQuantityMTS > 0;

-- 6. Verify RTNS records have return quantities
%sql
SELECT 
  COUNT(*) AS record_count
FROM b_um_xyz.ABC_onetime_history_sales_orders 
WHERE HISTSTREAM = 'RTNS' AND QTY > 0;

%sql
SELECT 
  COUNT(*) AS record_count
FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history 
WHERE ReturnsQtyMTS > 0;

-- 7. Check for any null values in key fields
%sql
SELECT 
  COUNT(*) AS null_apo_planning_version
FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history 
WHERE APOPlanningVersion IS NULL;

%sql
SELECT 
  COUNT(*) AS null_abc_model_number
FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history 
WHERE ABCModelNumber IS NULL;

%sql
SELECT 
  COUNT(*) AS null_country
FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history 
WHERE Country IS NULL;

-- 8. Check for records without matching sales org plant mapping
%sql
SELECT 
  so.DMDUNIT,
  so.LOC,
  COUNT(*) AS record_count
FROM b_um_xyz.ABC_onetime_history_sales_orders so
LEFT JOIN b_um_xyz.ABC_onetime_history_sales_org_plant_xref xref
  ON so.DMDUNIT = xref.Product AND so.LOC = xref.LOC
WHERE xref.Product IS NULL
GROUP BY so.DMDUNIT, so.LOC
ORDER BY record_count DESC
LIMIT 10;

-- 9. Check if all FCST records are excluded
%sql
SELECT 
  COUNT(*) AS fcst_count
FROM b_um_xyz.ABC_onetime_history_sales_orders
WHERE HISTSTREAM = 'FCST';

%sql
SELECT 
  COUNT(*) AS fcst_in_silver
FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history
WHERE SourceSystem = 'JDAABC' AND (DemandQuantityMTS = 0 AND ReturnsQtyMTS = 0);

-- 10. Verify date transformation is correct
%sql
SELECT 
  DISTINCT b.STARTDATE AS original_date,
  s.CalMonth AS transformed_date
FROM b_um_xyz.ABC_onetime_history_sales_orders b
JOIN s_xyz.sales_orders_demand_fcst_ABC_onetime_history s
  ON b.DMDUNIT = s.ABCModelNumber
LIMIT 10;