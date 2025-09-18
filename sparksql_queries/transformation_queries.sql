-- Create bronze layer tables for raw data ingestion
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

-- Create silver layer table with transformed data
%sql
CREATE TABLE IF NOT EXISTS s_isc.sales_orders_demand_fcst_apm_onetime_history
USING DELTA
AS
SELECT 
  'APO version' AS `APO Planning Version`,
  h.DMDUNIT AS `APM Model Number`,
  h.DMDUNIT AS `Product Planner Code`,
  h.LOC AS Country,
  h.LOC AS `Sales Office`,
  COALESCE(x.BD_SALES_ORG, '0000') AS `Sales Organization`,
  COALESCE(x.BD_PLANT, '0000') AS PLANT,
  CASE 
    WHEN h.DMDGROUP = 'SALES' THEN 'R'
    WHEN h.DMDGROUP = 'SAMPLES' THEN 'N'
    WHEN h.DMDGROUP = 'CONSIGN' THEN 'C'
    ELSE 'R'
  END AS `Planning Partner`,
  '10' AS `Distribution Channel`,
  '500' AS `Customer Group`,
  '0000000000' AS `Ship-To Party`,
  '0000000000' AS `Sold-to party`,
  NULL AS `WW Business`,
  NULL AS `Strategy Center`,
  NULL AS `Product Line`,
  NULL AS `Planning Set`,
  NULL AS `Product Subset`,
  NULL AS `Item Category`,
  NULL AS `Sales Document Type`,
  CURRENT_TIMESTAMP() AS `Snapshot ID`,
  CONCAT(
    YEAR(h.STARTDATE),
    LPAD(MONTH(h.STARTDATE), 2, '0')
  ) AS `Cal month`,
  'EA' AS `Base Unit of Measure`,
  'JDAAPM' AS `Source system`,
  CASE WHEN h.HISTSTREAM = 'HIST' THEN h.QTY ELSE 0 END AS `Demand Quantity - MTS`,
  CASE WHEN h.HISTSTREAM = 'HIST' THEN h.QTY ELSE 0 END AS `Total Demand`,
  CASE WHEN h.HISTSTREAM = 'RTNS' THEN h.QTY ELSE 0 END AS `Returns Qty - MTS`
FROM b_um_isc.apm_onetime_history_sales_orders h
LEFT JOIN b_um_isc.apm_onetime_history_sales_org_plant_xref x
  ON h.DMDUNIT = x.Product AND h.LOC = x.LOC
WHERE h.HISTSTREAM IN ('HIST', 'RTNS');

-- Create gold view for consumption
%sql
CREATE OR REPLACE VIEW g_external.v_sales_orders_demand_fcst_apm_onetime_history AS
SELECT
  `APO Planning Version` AS `APO`,
  `APM Model Number` AS `Product`,
  Country,
  `Customer Group` AS `Key Customer Grp`,
  `Distribution Channel`,
  `Sales Organization` AS `Sales Org`,
  PLANT AS ZPLANT,
  `Sales Office`,
  `Planning Partner`,
  `Item Category`,
  `Sales Document Type`,
  `Cal month`,
  `Base Unit of Measure`,
  `Source system`,
  `Demand Quantity - MTS`,
  `Total Demand`,
  `Returns Qty - MTS`
FROM s_isc.sales_orders_demand_fcst_apm_onetime_history;

-- Export to CSV
%sql
CREATE OR REPLACE TEMPORARY VIEW export_view AS
SELECT * FROM g_external.v_sales_orders_demand_fcst_apm_onetime_history;

-- Note: The following command would be executed in a Python cell, but since you requested only SQL,
-- I'm including it as a SQL comment for reference:
-- %python
-- (spark.table("export_view")
--  .coalesce(1)
--  .write
--  .option("header", "true")
--  .option("delimiter", ",")
--  .mode("overwrite")
--  .csv("abfss://mft@{storage_account}.dfs.core.windows.net/outbound/supply-chain-management/scm-demand-fcst/5Y_APM_onetime_SCM_demand_history"))

-- Alternative SQL approach to export (may vary by Databricks version)
%sql
COPY INTO 'abfss://mft@{storage_account}.dfs.core.windows.net/outbound/supply-chain-management/scm-demand-fcst/5Y_APM_onetime_SCM_demand_history.csv'
FROM export_view
FILEFORMAT = CSV
FORMAT_OPTIONS ('header' = 'true', 'delimiter' = ',')
OVERWRITE = true;