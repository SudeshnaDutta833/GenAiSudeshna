-- BRONZE LAYER: Create tables for raw data ingestion

-- Create bronze table for APM sales order history data
%sql
CREATE TABLE IF NOT EXISTS b_um_isc.apm_onetime_history_sales_orders (
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
LOCATION 'abfss://user-managed@{storage_account}.dfs.core.windows.net/inbound/isc/apm_onetime_history/apm_sales_order';

-- Create bronze table for APM regional, sales orgs & plant mapping data
%sql
CREATE TABLE IF NOT EXISTS b_um_isc.apm_onetime_history_sales_org_plant_xref (
  Product STRING,
  LOC STRING,
  REGION STRING,
  COUNTRY STRING,
  CHANNEL STRING,
  BD_SALES_ORG STRING,
  BD_PLANT STRING
)
USING DELTA
LOCATION 'abfss://user-managed@{storage_account}.dfs.core.windows.net/inbound/isc/apm_onetime_history/apm_sales_org_plant_xref';

-- SILVER LAYER: Data cleaning and augmentation

-- Create silver table for cleaned and enriched sales order data
%sql
CREATE TABLE IF NOT EXISTS s_isc.sales_orders_demand_fcst_apm_onetime_history
USING DELTA
AS
SELECT
  'APO' AS APO_Planning_Version,
  h.DMDUNIT AS APM_Model_Number,
  h.DMDUNIT AS Product_Planner_Code,
  
  -- Country handling
  CASE 
    WHEN LENGTH(h.LOC) = 3 AND SUBSTR(h.LOC, 3, 1) = 'X' THEN SUBSTR(h.LOC, 1, 2)
    ELSE h.LOC
  END AS Country,
  
  h.LOC AS Sales_Office,
  
  -- Sales Organization from mapping table
  COALESCE(x.BD_SALES_ORG, '') AS Sales_Organization,
  
  -- Plant from mapping table
  COALESCE(x.BD_PLANT, '') AS PLANT,
  
  -- Planning Partner based on DMDGROUP
  CASE 
    WHEN h.DMDGROUP = 'SALES' THEN 'R'
    WHEN h.DMDGROUP = 'SAMPLES' THEN 'N'
    WHEN h.DMDGROUP = 'CONSIGN' THEN 'C'
    ELSE ''
  END AS Planning_Partner,
  
  '10' AS Distribution_Channel,
  '500' AS Customer_Group,
  'UNKNOWN' AS Ship_To_Party,
  'UNKNOWN' AS Sold_to_party,
  '' AS WW_Business,
  '' AS Strategy_Center,
  '' AS Product_Line,
  '' AS Planning_Set,
  '' AS Product_Subset,
  '' AS Item_Category,
  '' AS Sales_Document_Type,
  CONCAT('APM', DATE_FORMAT(CURRENT_DATE(), 'yyyyMMdd')) AS Snapshot_ID,
  
  -- Calendar month in YYYYMM format
  CAST(CONCAT(YEAR(h.STARTDATE), LPAD(MONTH(h.STARTDATE), 2, '0')) AS INT) AS Cal_month,
  
  'EA' AS Base_Unit_of_Measure,
  'JDAAPM' AS Source_system,
  
  -- Demand Quantity - MTS (only for HIST records)
  CASE WHEN h.HISTSTREAM = 'HIST' THEN h.QTY ELSE 0 END AS Demand_Quantity_MTS,
  
  -- Total Demand (same as Demand Quantity - MTS)
  CASE WHEN h.HISTSTREAM = 'HIST' THEN h.QTY ELSE 0 END AS Total_Demand,
  
  -- Returns Qty - MTS (only for RTNS records)
  CASE WHEN h.HISTSTREAM = 'RTNS' THEN h.QTY ELSE 0 END AS Returns_Qty_MTS
  
FROM b_um_isc.apm_onetime_history_sales_orders h
LEFT JOIN b_um_isc.apm_onetime_history_sales_org_plant_xref x
  ON h.DMDUNIT = x.Product AND h.LOC = x.LOC
WHERE h.HISTSTREAM IN ('HIST', 'RTNS'); -- Filter for historical and returns data only

-- GOLD LAYER: Create view for consumption

%sql
CREATE OR REPLACE VIEW g_external.v_sales_orders_demand_fcst_apm_onetime_history
AS
SELECT
  APO_Planning_Version,
  APM_Model_Number AS APO_Product,
  Country,
  Customer_Group AS Key_Customer_Grp,
  Distribution_Channel,
  Sales_Organization AS Sales_Org,
  PLANT AS ZPLANT,
  Sales_Office,
  Planning_Partner,
  Item_Category,
  Sales_Document_Type,
  Snapshot_ID,
  Cal_month,
  Base_Unit_of_Measure,
  Source_system,
  Demand_Quantity_MTS,
  Total_Demand,
  Returns_Qty_MTS
FROM s_isc.sales_orders_demand_fcst_apm_onetime_history;

-- Export to CSV
%sql
CREATE OR REPLACE TEMPORARY VIEW export_view AS
SELECT * FROM g_external.v_sales_orders_demand_fcst_apm_onetime_history;

-- The following command would be executed through a notebook command or DBFS API call
-- dbutils.fs.rm("abfss://mft@{storage_account}.dfs.core.windows.net/outbound/supply-chain-management/scm-demand-fcst/5Y_APM_onetime_SCM_demand_history.csv", true)
-- df = spark.table("export_view")
-- df.coalesce(1).write.option("header", "true").csv("abfss://mft@{storage_account}.dfs.core.windows.net/outbound/supply-chain-management/scm-demand-fcst/5Y_APM_onetime_SCM_demand_history.csv")