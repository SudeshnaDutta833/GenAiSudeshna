%sql
-- Validate source tables exist
SELECT * FROM s_xyz.sales_orders_demand_fcst_everest LIMIT 10;

%sql
-- Validate regional lookup table for sales office derivation
SELECT * FROM regional_table LIMIT 10;

%sql
-- Validate material master data for product hierarchy
SELECT * FROM material_master WHERE MARA_MATNR IN (
  SELECT DISTINCT MATNR FROM s_xyz.sales_orders_demand_fcst_everest
) LIMIT 10;

%sql
-- Validate global calendar static table
SELECT * FROM s_shared.global_calendar_static LIMIT 10;

%sql
-- Check for missing or null values in key fields
SELECT 
  COUNT(*) AS total_records,
  SUM(CASE WHEN MATNR IS NULL THEN 1 ELSE 0 END) AS null_matnr,
  SUM(CASE WHEN SHIP_TO_COUNTRY IS NULL THEN 1 ELSE 0 END) AS null_ship_to_country,
  SUM(CASE WHEN CUSTGRP4 IS NULL THEN 1 ELSE 0 END) AS null_custgrp4,
  SUM(CASE WHEN SALES_DOC_TYPE IS NULL THEN 1 ELSE 0 END) AS null_sales_doc_type
FROM s_xyz.sales_orders_demand_fcst_everest;

%sql
-- Validate sales document types for planning partner derivation
SELECT DISTINCT SALES_DOC_TYPE
FROM s_xyz.sales_orders_demand_fcst_everest
ORDER BY SALES_DOC_TYPE;

%sql
-- Check if the gold view was created successfully
SELECT * FROM g_external.v_sales_orders_demand_fcst_everest LIMIT 10;