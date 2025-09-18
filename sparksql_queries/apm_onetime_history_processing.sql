-- Create Bronze Tables
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
) USING DELTA
LOCATION 'abfss://user-managed@{storage_account}.dfs.core.windows.net/inbound/isc/apm_onetime_history/apm_sales_order';

%sql
CREATE TABLE IF NOT EXISTS b_um_isc.apm_onetime_history_sales_org_plant_xref (
  Product STRING,
  LOC STRING,
  REGION_SALES_ORG STRING,
  COUNTRY STRING,
  CHANNEL STRING,
  BD_SALES_ORG STRING,
  BD_PLANT STRING
) USING DELTA
LOCATION 'abfss://user-managed@{storage_account}.dfs.core.windows.net/inbound/isc/apm_onetime_history/apm_sales_org_plant_xref';

-- Create Silver Table
%sql
CREATE TABLE IF NOT EXISTS s_isc.sales_orders_demand_fcst_apm_onetime_history (
  APO_Planning_Version STRING,
  APM_Model_Number STRING,
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
  Demand_Quantity_MTS DECIMAL(17,3),
  Total_Demand DECIMAL(17,3),
  Returns_Qty_MTS DECIMAL(17,3)
) USING DELTA;

-- Populate Silver Table from Bronze Tables
%sql
INSERT INTO s_isc.sales_orders_demand_fcst_apm_onetime_history
SELECT
  'APO version' AS APO_Planning_Version,
  h.DMDUNIT AS APM_Model_Number,
  h.DMDUNIT AS Product_Planner_Code,
  CASE 
    WHEN LENGTH(h.LOC) > 3 AND SUBSTRING(h.LOC, -1) = 'X' THEN SUBSTRING(h.LOC, 1, LENGTH(h.LOC) - 1)
    ELSE h.LOC
  END AS Country,
  h.LOC AS Sales_Office,
  COALESCE(x.BD_SALES_ORG, '') AS Sales_Organization,
  COALESCE(x.BD_PLANT, '') AS PLANT,
  CASE 
    WHEN h.DMDGROUP = 'SALES' THEN 'R'
    WHEN h.DMDGROUP = 'SAMPLES' THEN 'N'
    WHEN h.DMDGROUP = 'CONSIGN' THEN 'C'
    ELSE ''
  END AS Planning_Partner,
  '10' AS Distribution_Channel,
  '500' AS Customer_Group,
  '9999999999' AS Ship_To_Party,
  '9999999999' AS Sold_to_party,
  NULL AS WW_Business,
  NULL AS Strategy_Center,
  NULL AS Product_Line,
  NULL AS Planning_Set,
  NULL AS Product_Subset,
  NULL AS Item_Category,
  NULL AS Sales_Document_Type,
  CONCAT('APM', DATE_FORMAT(CURRENT_DATE(), 'yyyyMMdd')) AS Snapshot_ID,
  DATE_FORMAT(h.STARTDATE, 'yyyyMM') AS Cal_month,
  'EA' AS Base_Unit_of_Measure,
  'JDAAPM' AS Source_system,
  CASE WHEN h.HISTSTREAM = 'HIST' THEN h.QTY ELSE 0 END AS Demand_Quantity_MTS,
  CASE WHEN h.HISTSTREAM = 'HIST' THEN h.QTY ELSE 0 END AS Total_Demand,
  CASE WHEN h.HISTSTREAM = 'RTNS' THEN h.QTY ELSE 0 END AS Returns_Qty_MTS
FROM b_um_isc.apm_onetime_history_sales_orders h
LEFT JOIN b_um_isc.apm_onetime_history_sales_org_plant_xref x
  ON h.DMDUNIT = x.Product AND h.LOC = x.LOC
WHERE h.HISTSTREAM IN ('HIST', 'RTNS');

-- Create Gold View
%sql
CREATE OR REPLACE VIEW g_external.v_sales_orders_demand_fcst_apm_onetime_history AS
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

-- Export Gold View to CSV
%sql
CREATE OR REPLACE TEMPORARY VIEW temp_export_view AS
SELECT * FROM g_external.v_sales_orders_demand_fcst_apm_onetime_history;

-- Note: The following command would be executed in a separate cell or as part of a notebook workflow
-- DBFS export command would be handled in a Python cell, not SQL