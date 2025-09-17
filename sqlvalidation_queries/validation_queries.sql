%sql
-- Validate Bronze Layer Tables Exist
SELECT * 
FROM information_schema.tables 
WHERE table_schema = 'b_um_isc' 
AND table_name IN ('apm_onetime_history_sales_orders', 'apm_onetime_history_sales_org_plant_xref');

%sql
-- Validate Silver Layer Table Exists
SELECT * 
FROM information_schema.tables 
WHERE table_schema = 's_isc' 
AND table_name = 'sales_orders_demand_fcst_apm_onetime_history';

%sql
-- Validate External View Exists
SELECT * 
FROM information_schema.tables 
WHERE table_schema = 'g_external' 
AND table_name = 'v_sales_orders_demand_fcst_apm_onetime_history';

%sql
-- Validate Bronze Layer APM Sales Orders Data
SELECT 
  COUNT(*) AS total_records,
  COUNT(DISTINCT DMDUNIT) AS unique_products,
  MIN(STARDATE) AS min_date,
  MAX(STARDATE) AS max_date
FROM b_um_isc.apm_onetime_history_sales_orders;

%sql
-- Validate Bronze Layer Sales Org Plant Mapping Data
SELECT 
  COUNT(*) AS total_records,
  COUNT(DISTINCT Product) AS unique_products,
  COUNT(DISTINCT LOC) AS unique_locations,
  COUNT(DISTINCT Region) AS unique_regions
FROM b_um_isc.apm_onetime_history_sales_org_plant_xref;

%sql
-- Validate Silver Layer Data Transformation
SELECT 
  COUNT(*) AS total_records,
  COUNT(DISTINCT DMDUNIT) AS unique_products,
  COUNT(DISTINCT LOC) AS unique_locations,
  COUNT(DISTINCT HISTSTREAM) AS unique_histstream_values,
  MIN(STARDATE) AS min_date,
  MAX(STARDATE) AS max_date
FROM s_isc.sales_orders_demand_fcst_apm_onetime_history;

%sql
-- Check for Null Values in Critical Fields in Silver Layer
SELECT
  SUM(CASE WHEN DMDUNIT IS NULL THEN 1 ELSE 0 END) AS null_dmdunit,
  SUM(CASE WHEN DMDGROUP IS NULL THEN 1 ELSE 0 END) AS null_dmdgroup,
  SUM(CASE WHEN LOC IS NULL THEN 1 ELSE 0 END) AS null_loc,
  SUM(CASE WHEN STARDATE IS NULL THEN 1 ELSE 0 END) AS null_stardate,
  SUM(CASE WHEN QTY IS NULL THEN 1 ELSE 0 END) AS null_qty,
  SUM(CASE WHEN HISTSTREAM IS NULL THEN 1 ELSE 0 END) AS null_histstream
FROM s_isc.sales_orders_demand_fcst_apm_onetime_history;

%sql
-- Validate Data Distribution by Region
SELECT 
  x.Region,
  COUNT(*) AS record_count
FROM s_isc.sales_orders_demand_fcst_apm_onetime_history s
JOIN b_um_isc.apm_onetime_history_sales_org_plant_xref x
  ON s.DMDUNIT = x.Product AND s.LOC = x.LOC
GROUP BY x.Region
ORDER BY record_count DESC;

%sql
-- Validate Data Distribution by HISTSTREAM (FCST, HIST, RTNS)
SELECT 
  HISTSTREAM,
  COUNT(*) AS record_count,
  SUM(QTY) AS total_quantity
FROM s_isc.sales_orders_demand_fcst_apm_onetime_history
GROUP BY HISTSTREAM
ORDER BY record_count DESC;

%sql
-- Validate Data Distribution by DMDGROUP (SALES, SAMPLES, CONSIGNMENTS)
SELECT 
  DMDGROUP,
  COUNT(*) AS record_count,
  SUM(QTY) AS total_quantity
FROM s_isc.sales_orders_demand_fcst_apm_onetime_history
GROUP BY DMDGROUP
ORDER BY record_count DESC;

%sql
-- Validate Date Range Coverage (Should be 5 years of data)
SELECT 
  YEAR(STARDATE) AS year,
  COUNT(*) AS record_count
FROM s_isc.sales_orders_demand_fcst_apm_onetime_history
GROUP BY YEAR(STARDATE)
ORDER BY year;