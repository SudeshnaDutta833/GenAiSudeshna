-- Bronze Layer: Raw data ingestion
-- Create bronze tables for the source data

%sql
CREATE DATABASE IF NOT EXISTS b_um_xyz;

-- Create bronze table for ABC sales order history data
%sql
CREATE TABLE IF NOT EXISTS b_um_xyz.ABC_onetime_history_sales_orders (
  DMDUNIT STRING,
  DMDGROUP STRING,
  LOC STRING,
  STARTDATE DATE,
  DUR INT,
  TYPE INT,
  EVENT STRING,
  QTY DOUBLE,
  HISTSTREAM STRING
) USING DELTA
LOCATION 'abfss://user-managed@{storage_account}.dfs.core.windows.net/inbound/xyz/ABC_onetime_history/ABC_sales_order';

-- Create bronze table for ABC sales org plant cross-reference data
%sql
CREATE TABLE IF NOT EXISTS b_um_xyz.ABC_onetime_history_sales_org_plant_xref (
  Product STRING,
  LOC STRING,
  REGION_SALES_ORG STRING,
  COUNTRY STRING,
  CHANNEL STRING,
  BD_SALES_ORG STRING,
  BD_PLANT STRING
) USING DELTA
LOCATION 'abfss://user-managed@{storage_account}.dfs.core.windows.net/inbound/xyz/ABC_onetime_history/ABC_sales_org_plant_xref';

-- Silver Layer: Data cleaning and augmentation
-- Create silver database if not exists
%sql
CREATE DATABASE IF NOT EXISTS s_xyz;

-- Create silver table for cleaned and enriched data
%sql
CREATE TABLE IF NOT EXISTS s_xyz.sales_orders_demand_fcst_ABC_onetime_history (
  APO_Planning_Version STRING,
  ABC_Model_Number STRING,
  Product_Planner_Code STRING,
  Country STRING,
  Sales_Office STRING,
  Sales_Organization STRING,
  PLANT STRING,
  Planning_Partner STRING,
  Distribution_Channel STRING,
  Customer_Group STRING,
  Ship_To_Party STRING,
  Sold_to_party STRING,
  WW_Business STRING,
  Strategy_Center STRING,
  Product_Line STRING,
  Planning_Set STRING,
  Product_Subset STRING,
  Item_Category STRING,
  Sales_Document_Type STRING,
  Snapshot_ID STRING,
  Cal_month INT,
  Base_Unit_of_Measure STRING,
  Source_system STRING,
  Demand_Quantity_MTS DOUBLE,
  Total_Demand DOUBLE,
  Returns_Qty_MTS DOUBLE
) USING DELTA;

-- Populate silver table from bronze tables
%sql
INSERT INTO s_xyz.sales_orders_demand_fcst_ABC_onetime_history
SELECT
  'APO' AS APO_Planning_Version,
  hist.DMDUNIT AS ABC_Model_Number,
  hist.DMDUNIT AS Product_Planner_Code,
  CASE 
    WHEN SUBSTRING(hist.LOC, 1, 1) = 'X' THEN SUBSTRING(hist.LOC, 2, 3)
    WHEN LENGTH(hist.LOC) > 3 THEN SUBSTRING(hist.LOC, 1, 3)
    ELSE hist.LOC
  END AS Country,
  hist.LOC AS Sales_Office,
  COALESCE(xref.BD_SALES_ORG, '') AS Sales_Organization,
  COALESCE(xref.BD_PLANT, '') AS PLANT,
  CASE 
    WHEN hist.DMDGROUP = 'SALES' THEN 'R'
    WHEN hist.DMDGROUP = 'SAMPLES' THEN 'N'
    WHEN hist.DMDGROUP = 'CONSIGN' THEN 'C'
    ELSE ''
  END AS Planning_Partner,
  '10' AS Distribution_Channel,
  '500' AS Customer_Group,
  '0000000000' AS Ship_To_Party,
  '0000000000' AS Sold_to_party,
  NULL AS WW_Business,
  NULL AS Strategy_Center,
  NULL AS Product_Line,
  NULL AS Planning_Set,
  NULL AS Product_Subset,
  NULL AS Item_Category,
  NULL AS Sales_Document_Type,
  NULL AS Snapshot_ID,
  CAST(DATE_FORMAT(hist.STARTDATE, 'yyyyMM') AS INT) AS Cal_month,
  'EA' AS Base_Unit_of_Measure,
  'JDAABC' AS Source_system,
  CASE WHEN hist.HISTSTREAM = 'HIST' THEN hist.QTY ELSE 0 END AS Demand_Quantity_MTS,
  CASE WHEN hist.HISTSTREAM = 'HIST' THEN hist.QTY ELSE 0 END AS Total_Demand,
  CASE WHEN hist.HISTSTREAM = 'RTNS' THEN hist.QTY ELSE 0 END AS Returns_Qty_MTS
FROM b_um_xyz.ABC_onetime_history_sales_orders hist
LEFT JOIN b_um_xyz.ABC_onetime_history_sales_org_plant_xref xref
  ON hist.DMDUNIT = xref.Product AND hist.LOC = xref.LOC
WHERE hist.HISTSTREAM IN ('HIST', 'RTNS');

-- Gold Layer: Filtered and aggregated data ready for consumption
-- Create gold database if not exists
%sql
CREATE DATABASE IF NOT EXISTS g_external;

-- Create gold view for consumption
%sql
CREATE OR REPLACE VIEW g_external.v_sales_orders_demand_fcst_ABC_onetime_history AS
SELECT
  APO_Planning_Version AS APO,
  ABC_Model_Number AS Product,
  Country,
  Customer_Group AS Key_Customer_Grp,
  Distribution_Channel,
  Sales_Organization AS Sales_Org,
  PLANT AS ZPLANT,
  Sales_Office,
  Planning_Partner,
  Item_Category,
  Sales_Document_Type AS Sales_Doc_Type,
  Snapshot_ID,
  Cal_month,
  Base_Unit_of_Measure,
  Source_system,
  Demand_Quantity_MTS,
  Total_Demand,
  Returns_Qty_MTS
FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history;

-- Export gold view to CSV file
%sql
CREATE OR REPLACE TEMPORARY VIEW temp_export_view AS
SELECT * FROM g_external.v_sales_orders_demand_fcst_ABC_onetime_history;

-- Note: The following command would typically be executed in a Python cell, but is included here for completeness
-- of the workflow. In an actual implementation, this would be handled via a Python cell or a Databricks workflow.
-- %python
-- (spark.table("temp_export_view")
--   .coalesce(1)
--   .write
--   .option("header", "true")
--   .option("delimiter", ",")
--   .mode("overwrite")
--   .csv("abfss://mft@{storage_account}.dfs.core.windows.net/outbound/supply-chain-management/scm-demand-fcst/5Y_ABC_onetime_SCM_demand_history"))