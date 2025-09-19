-- BRONZE LAYER TABLES CREATION
-- Create bronze layer table for ABC sales order history data
%sql
CREATE TABLE IF NOT EXISTS b_um_xyz.ABC_onetime_history_sales_orders (
  DMDUNIT STRING,
  DMDGROUP STRING,
  LOC STRING,
  STARTDATE DATE,
  DUR INT,
  TYPE INT,
  EVENT STRING,
  QTY DECIMAL(17,3),
  HISTSTREAM STRING
)
USING DELTA
LOCATION 'abfss://user-managed@{storage_account}.dfs.core.windows.net/inbound/xyz/ABC_onetime_history/ABC_sales_order';

-- Create bronze layer table for ABC sales org and plant mapping data
%sql
CREATE TABLE IF NOT EXISTS b_um_xyz.ABC_onetime_history_sales_org_plant_xref (
  Product STRING,
  LOC STRING,
  REGION STRING,
  COUNTRY STRING,
  CHANNEL STRING,
  BD_SALES_ORG STRING,
  BD_PLANT STRING
)
USING DELTA
LOCATION 'abfss://user-managed@{storage_account}.dfs.core.windows.net/inbound/xyz/ABC_onetime_history/ABC_sales_org_plant_xref';

-- SILVER LAYER TRANSFORMATION
-- Create silver layer table with transformed and enriched data
%sql
CREATE TABLE IF NOT EXISTS s_xyz.sales_orders_demand_fcst_ABC_onetime_history
USING DELTA
AS
SELECT
  'APO' AS APO_Planning_Version,
  h.DMDUNIT AS ABC_Model_Number,
  h.DMDUNIT AS Product_Planner_Code,
  CASE 
    WHEN SUBSTR(h.LOC, 1, 1) = 'X' THEN 'EUX'
    ELSE TRIM(h.LOC)
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
  CONCAT('SNAP_', DATE_FORMAT(CURRENT_DATE(), 'yyyyMMdd')) AS Snapshot_ID,
  DATE_FORMAT(h.STARTDATE, 'yyyyMM') AS Cal_month,
  'EA' AS Base_Unit_of_Measure,
  'JDAABC' AS Source_system,
  CASE 
    WHEN h.HISTSTREAM = 'HIST' THEN h.QTY
    ELSE 0
  END AS Demand_Quantity_MTS,
  CASE 
    WHEN h.HISTSTREAM = 'HIST' THEN h.QTY
    ELSE 0
  END AS Total_Demand,
  CASE 
    WHEN h.HISTSTREAM = 'RTNS' THEN h.QTY
    ELSE 0
  END AS Returns_Qty_MTS
FROM b_um_xyz.ABC_onetime_history_sales_orders h
LEFT JOIN b_um_xyz.ABC_onetime_history_sales_org_plant_xref x
  ON h.DMDUNIT = x.Product AND h.LOC = x.LOC
WHERE h.HISTSTREAM IN ('HIST', 'RTNS');

-- GOLD LAYER VIEW CREATION
-- Create gold layer view for consumption
%sql
CREATE OR REPLACE VIEW g_external.v_sales_orders_demand_fcst_ABC_onetime_history AS
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
  Sales_Document_Type AS Sales_Doc_Type,
  Source_system,
  Cal_month,
  Demand_Quantity_MTS,
  Total_Demand,
  Returns_Qty_MTS,
  Base_Unit_of_Measure
FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history;

-- EXPORT TO CSV
-- Export gold view data to CSV file
%sql
CREATE OR REPLACE TEMPORARY VIEW temp_export_view AS
SELECT * FROM g_external.v_sales_orders_demand_fcst_ABC_onetime_history;

-- Note: The following command would be executed in a Python cell, but we're showing the SQL equivalent
-- df = spark.table("temp_export_view")
-- df.coalesce(1).write.mode("overwrite").option("header", "true").csv("abfss://mft@{storage_account}.dfs.core.windows.net/outbound/supply-chain-management/scm-demand-fcst/5Y_ABC_onetime_SCM_demand_history.csv")