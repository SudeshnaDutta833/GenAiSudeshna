-- Bronze Layer: Create tables for raw data ingestion

-- Create the bronze table for ABC sales order history
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

-- Create the bronze table for ABC sales org plant cross-reference
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

-- Create silver table for sales orders demand forecast
%sql
CREATE TABLE IF NOT EXISTS s_xyz.sales_orders_demand_fcst_ABC_onetime_history
USING DELTA
AS
SELECT
  'APO' AS APO_Planning_Version,
  h.DMDUNIT AS ABC_Model_Number,
  h.DMDUNIT AS Product_Planner_Code,
  CASE 
    WHEN SUBSTR(h.LOC, 1, 1) = 'X' THEN 
      CASE 
        WHEN LENGTH(h.LOC) = 4 THEN SUBSTR(h.LOC, 2, 3)
        ELSE 'EUX'
      END
    WHEN LENGTH(h.LOC) > 3 THEN SUBSTR(h.LOC, 1, 3)
    ELSE h.LOC
  END AS Country,
  h.LOC AS Sales_Office,
  COALESCE(x.BD_SALES_ORG, '0000') AS Sales_Organization,
  COALESCE(x.BD_PLANT, '0000') AS PLANT,
  CASE 
    WHEN h.DMDGROUP = 'SALES' THEN 'R'
    WHEN h.DMDGROUP = 'SAMPLES' THEN 'N'
    WHEN h.DMDGROUP = 'CONSIGN' THEN 'C'
    ELSE ''
  END AS Planning_Partner,
  '10' AS Distribution_Channel,
  '500' AS Customer_Group,
  '0000000000' AS Ship_To_Party,
  '0000000000' AS Sold_to_party,
  '' AS WW_Business,
  '' AS Strategy_Center,
  '' AS Product_Line,
  '' AS Planning_Set,
  '' AS Product_Subset,
  '' AS Item_Category,
  '' AS Sales_Document_Type,
  CONCAT(YEAR(h.STARTDATE), LPAD(MONTH(h.STARTDATE), 2, '0')) AS Cal_month,
  'EA' AS Base_Unit_of_Measure,
  'JDAABC' AS Source_system,
  CASE WHEN h.HISTSTREAM = 'HIST' THEN h.QTY ELSE 0 END AS Demand_Quantity_MTS,
  CASE WHEN h.HISTSTREAM = 'HIST' THEN h.QTY ELSE 0 END AS Total_Demand,
  CASE WHEN h.HISTSTREAM = 'RTNS' THEN h.QTY ELSE 0 END AS Returns_Qty_MTS,
  h.STARTDATE,
  h.HISTSTREAM
FROM b_um_xyz.ABC_onetime_history_sales_orders h
LEFT JOIN b_um_xyz.ABC_onetime_history_sales_org_plant_xref x
  ON h.DMDUNIT = x.Product AND h.LOC = x.LOC
WHERE h.HISTSTREAM IN ('HIST', 'RTNS'); -- Filter for historical and return data only

-- Gold Layer: Create view for filtered and aggregated data ready for consumption

%sql
CREATE OR REPLACE VIEW g_external.v_sales_orders_demand_fcst_ABC_onetime_history
AS
SELECT
  APO_Planning_Version AS APO,
  ABC_Model_Number AS Product,
  Country,
  '500' AS Key_Customer_Grp,
  '10' AS Distribution_Channel,
  Sales_Organization AS Sales_Org,
  PLANT AS ZPLANT,
  Sales_Office,
  Planning_Partner,
  Item_Category,
  Sales_Document_Type,
  Source_system,
  Cal_month,
  Demand_Quantity_MTS,
  Total_Demand,
  Returns_Qty_MTS,
  Base_Unit_of_Measure
FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history;

-- Create CSV extract from the gold view
%sql
CREATE OR REPLACE TEMPORARY VIEW temp_export_view AS
SELECT * FROM g_external.v_sales_orders_demand_fcst_ABC_onetime_history;

-- Export to CSV using Databricks utility
%sql
CREATE WIDGET TEXT output_path DEFAULT "abfss://mft@{storage_account}.dfs.core.windows.net/outbound/supply-chain-management/scm-demand-fcst/5Y_ABC_onetime_SCM_demand_history.csv";

-- Note: The actual export would be done using Python in a Databricks notebook
-- This is a placeholder for the export command
-- In a real implementation, you would use:
-- dbutils.fs.rm(getArgument("output_path"), true)
-- df = spark.table("temp_export_view")
-- df.coalesce(1).write.option("header", "true").csv(getArgument("output_path"))