-- Create bronze layer tables to ingest raw data

-- Create bronze layer table for APM historical data
%sql
CREATE TABLE IF NOT EXISTS bronze.apm_historical_data (
  product STRING,
  loc STRING,
  dmdgroup STRING,
  dmddate STRING,
  qty DECIMAL(18,2),
  uom STRING,
  histstream STRING
) USING DELTA
COMMENT 'Raw APM 5-year historical demand data';

-- Create bronze layer table for regional mapping data
%sql
CREATE TABLE IF NOT EXISTS bronze.apm_regional_mapping (
  product STRING,
  loc STRING,
  region STRING,
  country STRING,
  bd_sales_org STRING,
  bd_plant STRING
) USING DELTA
COMMENT 'APM regional, sales org, and plant mapping data';

-- Create bronze layer table for ECC sales order delta data (Version 2)
%sql
CREATE TABLE IF NOT EXISTS bronze.ecc_sales_orders (
  sales_document STRING,
  sales_document_item STRING,
  material STRING,
  sales_doc_type STRING,
  ship_to_country STRING,
  customer_classification STRING,
  order_quantity DECIMAL(18,2),
  base_uom STRING,
  product_hierarchy STRING,
  lab_office STRING,
  created_date TIMESTAMP,
  last_changed_date TIMESTAMP
) USING DELTA
COMMENT 'Raw ECC sales order delta data for APM products';

-- Create bronze layer table for regional structure mapping (Version 2)
%sql
CREATE TABLE IF NOT EXISTS bronze.regional_structure (
  country STRING,
  customer_classification STRING,
  sales_office STRING
) USING DELTA
COMMENT 'Regional structure mapping for sales office derivation';

-- Load data from flat files into bronze layer tables
-- Note: In Databricks, this would typically be done with Spark code, but showing SQL representation

-- Ingest APM historical data from landing zone
%sql
COPY INTO bronze.apm_historical_data
FROM '/interfaces/SCP/nonidoc/inbound/global_dphist/5Y_JDA_APM_SCM_demand_history.csv'
FILEFORMAT = CSV
FORMAT_OPTIONS ('header' = 'true', 'delimiter' = ',')
COPY_OPTIONS ('mergeSchema' = 'true');

-- Ingest regional mapping data
%sql
COPY INTO bronze.apm_regional_mapping
FROM '/mnt/landing/apm/regional_mapping.csv'
FILEFORMAT = CSV
FORMAT_OPTIONS ('header' = 'true', 'delimiter' = ',')
COPY_OPTIONS ('mergeSchema' = 'true');

-- Ingest regional structure data for Version 2
%sql
COPY INTO bronze.regional_structure
FROM '/mnt/landing/apm/regional_structure.csv'
FILEFORMAT = CSV
FORMAT_OPTIONS ('header' = 'true', 'delimiter' = ',')
COPY_OPTIONS ('mergeSchema' = 'true');

-- Create silver layer tables for transformed data

-- Create silver layer table for enriched APM historical data
%sql
CREATE TABLE IF NOT EXISTS silver.apm_sales_history (
  product STRING,
  sales_organization STRING,
  region STRING,
  sales_office STRING,
  plant STRING,
  planning_partner STRING,
  demand_date DATE,
  demand_quantity DECIMAL(18,2),
  return_quantity DECIMAL(18,2),
  uom STRING,
  source_system STRING,
  load_date TIMESTAMP
) USING DELTA
PARTITIONED BY (region)
COMMENT 'Enriched APM historical sales data with organizational attributes';

-- Create silver layer table for ECC sales order delta (Version 2)
%sql
CREATE TABLE IF NOT EXISTS silver.apm_sales_delta (
  sales_document STRING,
  sales_document_item STRING,
  material STRING,
  sales_organization STRING,
  region STRING,
  sales_office STRING,
  plant STRING,
  planning_partner STRING,
  ship_to_country STRING,
  customer_classification STRING,
  order_quantity DECIMAL(18,2),
  base_uom STRING,
  product_hierarchy STRING,
  wwb_level1 STRING,
  created_date TIMESTAMP,
  last_changed_date TIMESTAMP,
  load_date TIMESTAMP
) USING DELTA
PARTITIONED BY (region)
COMMENT 'Transformed ECC sales order delta data for APM products';

-- Transform and load data into silver layer - APM Historical Data
%sql
INSERT OVERWRITE silver.apm_sales_history
SELECT 
  h.product,
  r.bd_sales_org as sales_organization,
  r.region,
  r.loc as sales_office,
  r.bd_plant as plant,
  CASE 
    WHEN h.dmdgroup = 'SALES' THEN 'R'
    WHEN h.dmdgroup = 'SAMPLES' THEN 'N'
    WHEN h.dmdgroup = 'CONSIGN' THEN 'C'
    ELSE NULL
  END as planning_partner,
  TO_DATE(h.dmddate, 'yyyy-MM-dd') as demand_date,
  CASE WHEN h.histstream = 'HIST' THEN h.qty ELSE 0 END as demand_quantity,
  CASE WHEN h.histstream = 'RTNS' THEN h.qty ELSE 0 END as return_quantity,
  h.uom,
  'JDA-APM' as source_system,
  CURRENT_TIMESTAMP() as load_date
FROM bronze.apm_historical_data h
JOIN bronze.apm_regional_mapping r
  ON h.product = r.product
  AND h.loc = r.loc
WHERE h.histstream IN ('HIST', 'RTNS');

-- Transform and load data into silver layer - ECC Sales Delta (Version 2)
%sql
INSERT INTO silver.apm_sales_delta
SELECT 
  e.sales_document,
  e.sales_document_item,
  e.material,
  CASE 
    WHEN SUBSTR(e.product_hierarchy, 1, 3) IN ('242', '243', '244', '245', '246') THEN '1000'
    ELSE NULL
  END as sales_organization,
  CASE 
    WHEN e.ship_to_country IN (SELECT country FROM bronze.apm_regional_mapping WHERE region = 'NA') THEN 'NA'
    WHEN e.ship_to_country IN (SELECT country FROM bronze.apm_regional_mapping WHERE region = 'LATM') THEN 'LATM'
    WHEN e.ship_to_country IN (SELECT country FROM bronze.apm_regional_mapping WHERE region = 'GAR') THEN 'GAR'
    ELSE NULL
  END as region,
  rs.sales_office,
  CASE 
    WHEN e.lab_office = '481' THEN e.lab_office
    ELSE NULL
  END as plant,
  CASE 
    WHEN e.sales_doc_type IN ('ZFO2', 'ZFO3', 'ZFOC', 'ZKRF') THEN 'N'
    WHEN e.sales_doc_type IN ('ZKET', 'ZSTD') THEN 'R'
    WHEN e.sales_doc_type = 'ZKEF' THEN 'C'
    ELSE NULL
  END as planning_partner,
  e.ship_to_country,
  e.customer_classification,
  e.order_quantity,
  e.base_uom,
  e.product_hierarchy,
  SUBSTR(e.product_hierarchy, 1, 3) as wwb_level1,
  e.created_date,
  e.last_changed_date,
  CURRENT_TIMESTAMP() as load_date
FROM bronze.ecc_sales_orders e
LEFT JOIN bronze.regional_structure rs
  ON e.ship_to_country = rs.country
  AND e.customer_classification = rs.customer_classification
WHERE SUBSTR(e.product_hierarchy, 1, 3) IN ('242', '243', '244', '245', '246');

-- Create gold layer tables for consumption

-- Create gold layer table for APM demand history
%sql
CREATE TABLE IF NOT EXISTS gold.apm_demand_history (
  product STRING,
  sales_organization STRING,
  region STRING,
  sales_office STRING,
  plant STRING,
  planning_partner STRING,
  demand_date DATE,
  demand_quantity DECIMAL(18,2),
  return_quantity DECIMAL(18,2),
  net_quantity DECIMAL(18,2),
  uom STRING,
  source_system STRING,
  load_date TIMESTAMP
) USING DELTA
PARTITIONED BY (region)
COMMENT 'APM demand history for consumption by planning applications';

-- Load gold layer with combined historical and delta data
%sql
MERGE INTO gold.apm_demand_history t
USING (
  -- Historical data
  SELECT 
    product,
    sales_organization,
    region,
    sales_office,
    plant,
    planning_partner,
    demand_date,
    demand_quantity,
    return_quantity,
    (demand_quantity - return_quantity) as net_quantity,
    uom,
    source_system,
    load_date
  FROM silver.apm_sales_history
  
  UNION ALL
  
  -- Delta data from ECC
  SELECT 
    material as product,
    sales_organization,
    region,
    sales_office,
    plant,
    planning_partner,
    CAST(created_date as DATE) as demand_date,
    CASE WHEN planning_partner IN ('R', 'C') THEN order_quantity ELSE 0 END as demand_quantity,
    CASE WHEN planning_partner = 'N' THEN order_quantity ELSE 0 END as return_quantity,
    CASE 
      WHEN planning_partner IN ('R', 'C') THEN order_quantity
      WHEN planning_partner = 'N' THEN -order_quantity
      ELSE 0 
    END as net_quantity,
    base_uom as uom,
    'ECC' as source_system,
    load_date
  FROM silver.apm_sales_delta
) s
ON t.product = s.product 
   AND t.sales_organization = s.sales_organization
   AND t.region = s.region
   AND t.sales_office = s.sales_office
   AND t.demand_date = s.demand_date
   AND t.planning_partner = s.planning_partner
WHEN MATCHED THEN
  UPDATE SET 
    t.demand_quantity = s.demand_quantity,
    t.return_quantity = s.return_quantity,
    t.net_quantity = s.net_quantity,
    t.load_date = s.load_date
WHEN NOT MATCHED THEN
  INSERT (
    product,
    sales_organization,
    region,
    sales_office,
    plant,
    planning_partner,
    demand_date,
    demand_quantity,
    return_quantity,
    net_quantity,
    uom,
    source_system,
    load_date
  )
  VALUES (
    s.product,
    s.sales_organization,
    s.region,
    s.sales_office,
    s.plant,
    s.planning_partner,
    s.demand_date,
    s.demand_quantity,
    s.return_quantity,
    s.net_quantity,
    s.uom,
    s.source_system,
    s.load_date
  );

-- Create output file for SCM target directory
%sql
CREATE OR REPLACE TEMPORARY VIEW scm_output AS
SELECT 
  product,
  sales_organization,
  region,
  sales_office,
  plant,
  planning_partner,
  DATE_FORMAT(demand_date, 'yyyy-MM-dd') as demand_date,
  demand_quantity,
  return_quantity,
  net_quantity,
  uom,
  source_system
FROM gold.apm_demand_history
WHERE load_date >= (SELECT MAX(load_date) FROM gold.apm_demand_history) - INTERVAL 1 DAY;

-- Create audit table to track data processing
%sql
CREATE TABLE IF NOT EXISTS audit.apm_data_processing_log (
  batch_id STRING,
  process_name STRING,
  source_system STRING,
  records_processed BIGINT,
  records_rejected BIGINT,
  start_time TIMESTAMP,
  end_time TIMESTAMP,
  status STRING,
  error_message STRING
) USING DELTA
COMMENT 'Audit log for APM data processing';

-- Insert audit record for successful processing
%sql
INSERT INTO audit.apm_data_processing_log
SELECT 
  CONCAT('BATCH_', DATE_FORMAT(CURRENT_TIMESTAMP(), 'yyyyMMdd_HHmmss')) as batch_id,
  'APM_DEMAND_HISTORY_LOAD' as process_name,
  'JDA-APM,ECC' as source_system,
  (SELECT COUNT(*) FROM gold.apm_demand_history WHERE load_date >= (SELECT MAX(load_date) FROM gold.apm_demand_history) - INTERVAL 1 DAY) as records_processed,
  0 as records_rejected,
  (SELECT MAX(load_date) FROM gold.apm_demand_history) - INTERVAL 1 DAY as start_time,
  CURRENT_TIMESTAMP() as end_time,
  'SUCCESS' as status,
  NULL as error_message;