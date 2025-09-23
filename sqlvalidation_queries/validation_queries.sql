-- Validation query for bronze tables
%sql
SELECT COUNT(*) AS record_count FROM b_um_xyz.ABC_onetime_history_sales_orders;

%sql
SELECT COUNT(*) AS record_count FROM b_um_xyz.ABC_onetime_history_sales_org_plant_xref;

-- Sample data validation for bronze tables
%sql
SELECT * FROM b_um_xyz.ABC_onetime_history_sales_orders LIMIT 10;

%sql
SELECT * FROM b_um_xyz.ABC_onetime_history_sales_org_plant_xref LIMIT 10;

-- Validation query for silver table
%sql
SELECT COUNT(*) AS record_count FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history;

-- Sample data validation for silver table
%sql
SELECT * FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history LIMIT 10;

-- Validation query for gold view
%sql
SELECT COUNT(*) AS record_count FROM g_external.v_sales_orders_demand_fcst_ABC_onetime_history;

-- Sample data validation for gold view
%sql
SELECT * FROM g_external.v_sales_orders_demand_fcst_ABC_onetime_history LIMIT 10;

-- Validation query to check if only HIST and RTNS data is loaded (no FCST data)
%sql
SELECT DISTINCT HISTSTREAM 
FROM b_um_xyz.ABC_onetime_history_sales_orders
WHERE HISTSTREAM NOT IN ('HIST', 'RTNS');

-- Validation query to check Planning Partner mapping
%sql
SELECT 
    DMDGROUP,
    PlanningPartner,
    COUNT(*) AS count
FROM b_um_xyz.ABC_onetime_history_sales_orders h
JOIN s_xyz.sales_orders_demand_fcst_ABC_onetime_history s
ON h.DMDUNIT = s.ABCModelNumber AND h.LOC = s.SalesOffice
GROUP BY DMDGROUP, PlanningPartner
ORDER BY DMDGROUP, PlanningPartner;

-- Validation query to check Country transformation
%sql
SELECT 
    h.LOC AS original_loc,
    s.Country AS transformed_country,
    COUNT(*) AS count
FROM b_um_xyz.ABC_onetime_history_sales_orders h
JOIN s_xyz.sales_orders_demand_fcst_ABC_onetime_history s
ON h.DMDUNIT = s.ABCModelNumber AND h.LOC = s.SalesOffice
GROUP BY h.LOC, s.Country
ORDER BY h.LOC;

-- Validation query to check Sales Organization mapping
%sql
SELECT 
    h.LOC,
    x.REGION,
    s.SalesOrganization,
    COUNT(*) AS count
FROM b_um_xyz.ABC_onetime_history_sales_orders h
LEFT JOIN b_um_xyz.ABC_onetime_history_sales_org_plant_xref x
ON h.DMDUNIT = x.Product AND h.LOC = x.LOC
JOIN s_xyz.sales_orders_demand_fcst_ABC_onetime_history s
ON h.DMDUNIT = s.ABCModelNumber AND h.LOC = s.SalesOffice
GROUP BY h.LOC, x.REGION, s.SalesOrganization
ORDER BY h.LOC;