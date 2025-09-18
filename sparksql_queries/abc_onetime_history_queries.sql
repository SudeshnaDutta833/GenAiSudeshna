-- Bronze layer: Create tables for raw data ingestion

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
);

%sql
CREATE TABLE IF NOT EXISTS b_um_xyz.ABC_onetime_history_sales_org_plant_xref (
  Product STRING,
  LOC STRING,
  REGION STRING,
  COUNTRY STRING,
  CHANNEL STRING
);

-- Silver layer: Transform and clean data

%sql
CREATE TABLE IF NOT EXISTS s_xyz.sales_orders_demand_fcst_ABC_onetime_history AS
SELECT
  'APO' AS APO_Planning_Version,
  h.DMDUNIT AS Product,
  h.DMDUNIT AS Product_Planner_Code,
  CASE 
    WHEN SUBSTR(h.LOC, 1, 1) = 'X' THEN 'EUX'
    WHEN LENGTH(h.LOC) > 3 THEN SUBSTR(h.LOC, 1, 3)
    ELSE h.LOC
  END AS Country,
  h.LOC AS Sales_Office,
  COALESCE(x.REGION, 'Unknown') AS Sales_Organization,
  COALESCE(x.REGION, 'Unknown') AS PLANT,
  CASE 
    WHEN h.DMDGROUP = 'SALES' THEN 'R'
    WHEN h.DMDGROUP = 'SAMPLES' THEN 'N'
    WHEN h.DMDGROUP = 'CONSIGN' THEN 'C'
    ELSE 'R'
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
  'SYSTEM' AS Snapshot_ID,
  DATE_FORMAT(h.STARTDATE, 'yyyyMM') AS Cal_month,
  'EA' AS Base_Unit_of_Measure,
  'JDAABC' AS Source_system,
  CASE WHEN h.HISTSTREAM = 'HIST' THEN h.QTY ELSE 0 END AS Demand_Quantity_MTS,
  CASE WHEN h.HISTSTREAM = 'HIST' THEN h.QTY ELSE 0 END AS Total_Demand,
  CASE WHEN h.HISTSTREAM = 'RTNS' THEN h.QTY ELSE 0 END AS Returns_Qty_MTS
FROM b_um_xyz.ABC_onetime_history_sales_orders h
LEFT JOIN b_um_xyz.ABC_onetime_history_sales_org_plant_xref x
  ON h.DMDUNIT = x.Product AND h.LOC = x.LOC
WHERE h.HISTSTREAM IN ('HIST', 'RTNS');

-- Gold layer: Create view for consumption

%sql
CREATE OR REPLACE VIEW g_external.v_sales_orders_demand_fcst_ABC_onetime_history AS
SELECT
  APO_Planning_Version AS APO,
  Product,
  Country,
  '500' AS Key,
  Customer_Group AS Customer_Grp,
  Distribution_Channel,
  Sales_Organization AS Sales_Org,
  PLANT AS ZPLANT,
  Sales_Office,
  Planning_Partner,
  Item_Category,
  Sales_Document_Type AS Sales_Doc_Type,
  Source_system,
  Demand_Quantity_MTS,
  Total_Demand,
  Returns_Qty_MTS
FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history;

-- Export data to CSV

%sql
CREATE TABLE IF NOT EXISTS temp_export_table AS
SELECT * FROM g_external.v_sales_orders_demand_fcst_ABC_onetime_history;

-- Note: The following command would be executed in a %python cell in Databricks
-- but as per requirements, we're only providing SQL
-- This is just for reference of what would be done to export to CSV
-- df = spark.table("temp_export_table")
-- df.coalesce(1).write.option("header", "true").csv("abfss://mft@{storage_account}.dfs.core.windows.net/outbound/supply-chain-management/scm-demand-fcst/5Y_ABC_onetime_SCM_demand_history.csv")