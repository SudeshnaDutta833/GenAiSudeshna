%sql
-- Create Bronze Layer Tables

-- Create Bronze Table for APM Sales Order History
CREATE TABLE IF NOT EXISTS b_um_isc.apm_onetime_history_sales_orders (
  DMDUNIT STRING COMMENT 'APM Model Number',
  DMDGROUP STRING COMMENT 'Type of Sales',
  LOC STRING COMMENT 'Individual country code',
  STARDATE DATE COMMENT 'Transaction date',
  DUR INT COMMENT 'Month duration in days',
  TYPE INT COMMENT '1 or 2',
  EVENT STRING COMMENT 'Comments/Notes against manual update',
  QTY DECIMAL(18,2) COMMENT 'Number',
  HISTSTREAM STRING COMMENT 'FCST, HIST, RTNS (Type of Transactional Data)'
)
USING DELTA
COMMENT 'Raw historical order demand data from JDA';

%sql
-- Create Bronze Table for Sales Org and Plant Mapping
CREATE TABLE IF NOT EXISTS b_um_isc.apm_onetime_history_sales_org_plant_xref (
  Product STRING COMMENT 'Product',
  LOC STRING COMMENT 'LOC',
  Region STRING COMMENT 'Region',
  Country STRING COMMENT 'Country',
  Channel STRING COMMENT 'Channel',
  BD_Sales_Org STRING COMMENT 'BD Sales Org',
  BD_Plant_DC STRING COMMENT 'BD Plant/DC'
)
USING DELTA
COMMENT 'Sales org and plant mapping data';

%sql
-- Load Data into Bronze Tables from ADLS
-- This assumes the files are already mounted or accessible via ADLS path

-- Load APM Sales Order History Data
COPY INTO b_um_isc.apm_onetime_history_sales_orders
FROM 'abfss://user-managed@{storage_account}.dfs.core.windows.net/inbound/isc/apm_onetime_history/apm_sales_order/'
FILEFORMAT = CSV
FORMAT_OPTIONS ('header' = 'true', 'inferSchema' = 'true')
COPY_OPTIONS ('mergeSchema' = 'true');

%sql
-- Load Sales Org Plant Mapping Data
COPY INTO b_um_isc.apm_onetime_history_sales_org_plant_xref
FROM 'abfss://user-managed@{storage_account}.dfs.core.windows.net/inbound/isc/apm_onetime_history/apm_sales_org_plant_xref'
FILEFORMAT = CSV
FORMAT_OPTIONS ('header' = 'true', 'inferSchema' = 'true')
COPY_OPTIONS ('mergeSchema' = 'true');

%sql
-- Create Silver Layer Table with Transformed Data
CREATE TABLE IF NOT EXISTS s_isc.sales_orders_demand_fcst_apm_onetime_history (
  DMDUNIT STRING COMMENT 'APM Model Number',
  DMDGROUP STRING COMMENT 'Type of Sales',
  LOC STRING COMMENT 'Individual country code',
  STARDATE DATE COMMENT 'Transaction date',
  DUR INT COMMENT 'Month duration in days',
  TYPE INT COMMENT '1 or 2',
  EVENT STRING COMMENT 'Comments/Notes against manual update',
  QTY DECIMAL(18,2) COMMENT 'Number',
  HISTSTREAM STRING COMMENT 'FCST, HIST, RTNS (Type of Transactional Data)',
  Region STRING COMMENT 'Region',
  Country STRING COMMENT 'Country',
  Channel STRING COMMENT 'Channel',
  BD_Sales_Org STRING COMMENT 'BD Sales Org',
  BD_Plant_DC STRING COMMENT 'BD Plant/DC',
  processed_timestamp TIMESTAMP COMMENT 'Timestamp when record was processed'
)
USING DELTA
COMMENT 'Transformed Silver table based on business mapping logic';

%sql
-- Transform and Load Data into Silver Layer
INSERT INTO s_isc.sales_orders_demand_fcst_apm_onetime_history
SELECT 
  so.DMDUNIT,
  so.DMDGROUP,
  so.LOC,
  so.STARDATE,
  so.DUR,
  so.TYPE,
  so.EVENT,
  so.QTY,
  so.HISTSTREAM,
  xref.Region,
  xref.Country,
  xref.Channel,
  xref.BD_Sales_Org,
  xref.BD_Plant_DC,
  current_timestamp() AS processed_timestamp
FROM b_um_isc.apm_onetime_history_sales_orders so
LEFT JOIN b_um_isc.apm_onetime_history_sales_org_plant_xref xref
  ON so.DMDUNIT = xref.Product AND so.LOC = xref.LOC;

%sql
-- Create External View for SCM Consumption
CREATE OR REPLACE VIEW g_external.v_sales_orders_demand_fcst_apm_onetime_history AS
SELECT 
  DMDUNIT,
  DMDGROUP,
  LOC,
  STARDATE,
  DUR,
  TYPE,
  EVENT,
  QTY,
  HISTSTREAM,
  Region,
  Country,
  Channel,
  BD_Sales_Org,
  BD_Plant_DC
FROM s_isc.sales_orders_demand_fcst_apm_onetime_history;

%sql
-- Export Data to CSV for SCM Consumption
CREATE WIDGET TEXT storage_account DEFAULT "bdprodeastus2adls01";

%sql
-- Export the data to CSV file in ADLS
CREATE OR REPLACE TEMPORARY VIEW temp_export_view AS
SELECT 
  DMDUNIT,
  DMDGROUP,
  LOC,
  STARDATE,
  DUR,
  TYPE,
  EVENT,
  QTY,
  HISTSTREAM,
  Region,
  Country,
  Channel,
  BD_Sales_Org,
  BD_Plant_DC
FROM s_isc.sales_orders_demand_fcst_apm_onetime_history;

%sql
-- Write the data to CSV in ADLS
-- Note: This is a Databricks-specific command that needs to be executed in a notebook
COPY INTO 'abfss://mft@${storage_account}.dfs.core.windows.net/outbound/supply-chain-management/one-time/apm_history/scm_order_demand_history/5Y_JDA_APM_SCM_demand_history.csv'
FROM temp_export_view
FILEFORMAT = CSV
FORMAT_OPTIONS ('header' = 'true', 'dateFormat' = 'yyyy-MM-dd')
COPY_OPTIONS ('overwrite' = 'true');

%sql
-- Optimize Silver Table for Better Performance
OPTIMIZE s_isc.sales_orders_demand_fcst_apm_onetime_history
ZORDER BY (DMDUNIT, LOC, STARDATE);

%sql
-- Set Table Properties for Data Retention
ALTER TABLE s_isc.sales_orders_demand_fcst_apm_onetime_history
SET TBLPROPERTIES (
  'delta.logRetentionDuration' = '15 days',
  'delta.deletedFileRetentionDuration' = '15 days'
);