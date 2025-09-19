%sql
-- Create or replace silver table with all required fields
CREATE OR REPLACE TABLE s_xyz.sales_orders_demand_fcst_everest AS
WITH base_data AS (
  SELECT
    so.VBELN,
    so.POSNR,
    so.MATNR,
    so.SHIP_TO_COUNTRY,
    so.CUSTGRP4,
    so.DISTRIBUTION_CHANNEL,
    so.SALES_ORG,
    so.PLANT,
    so.SALES_DOC_TYPE,
    so.ITEM_CATEGORY,
    so.SHIP_TO_PARTY,
    so.SOLD_TO_PARTY,
    so.VBTYP,
    so.AUGRU,
    so.REQUESTED_DELIVERY_DATE,
    so.QUANTITY,
    so.SALES_UNIT,
    mm.PRODH AS PRODUCT_HIERARCHY,
    CURRENT_TIMESTAMP() AS SYSTEM_TIME,
    so.CUSTOMER_CLASSIFICATION
  FROM nb_sales_orders_aggregate so
  LEFT JOIN material_master mm ON so.MATNR = mm.MARA_MATNR
),
unit_conversion AS (
  SELECT
    bd.*,
    CASE
      WHEN bd.SALES_UNIT = 'EA' THEN bd.QUANTITY
      ELSE COALESCE(bd.QUANTITY * uom.CONVERSION_FACTOR, bd.QUANTITY)
    END AS QUANTITY_IN_EA
  FROM base_data bd
  LEFT JOIN unit_of_measure_conversion uom 
    ON bd.MATNR = uom.MATERIAL_NUMBER 
    AND bd.SALES_UNIT = uom.FROM_UNIT 
    AND uom.TO_UNIT = 'EA'
),
calendar_data AS (
  SELECT
    uc.*,
    cal.CALWEEK,
    cal.CALMONTH
  FROM unit_conversion uc
  LEFT JOIN s_shared.global_calendar_static cal
    ON DATE(uc.REQUESTED_DELIVERY_DATE) = cal.DATE
)
SELECT
  'APO' AS "9AVERSION",
  LTRIM(cd.MATNR, '0') AS "9AMATNR",
  LTRIM(cd.MATNR, '0') AS "ZDPPRDPC",
  cd.SHIP_TO_COUNTRY AS "0COUNTRY",
  CASE
    WHEN cd.CUSTGRP4 IS NULL THEN '500'
    ELSE cd.CUSTGRP4
  END AS "ZCUSTGRP",
  cd.DISTRIBUTION_CHANNEL AS "0DISTR_CHAN",
  cd.SALES_ORG AS "ZSALESOR",
  cd.PLANT AS "ZPLANT",
  SUBSTRING(cd.PRODUCT_HIERARCHY, 1, 3) AS "ZPRODH1",
  SUBSTRING(cd.PRODUCT_HIERARCHY, 1, 6) AS "ZPRODH2",
  SUBSTRING(cd.PRODUCT_HIERARCHY, 1, 9) AS "ZPRODH3",
  SUBSTRING(cd.PRODUCT_HIERARCHY, 1, 12) AS "ZPRODH4",
  cd.PRODUCT_HIERARCHY AS "ZPRODH5",
  cd.ITEM_CATEGORY AS "0ITEM_CATEG",
  cd.SALES_DOC_TYPE AS "0DOC_TYPE",
  FORMAT_TIMESTAMP(cd.SYSTEM_TIME, 'yyyyMMddHH') AS "ZSNAPSHOT",
  cd.CUSTOMER_CLASSIFICATION AS "CUSTOMER_CLASSIFICATION",
  rt.SALES_OFFICE AS "0SALES_OFF",
  'DEFAULT' AS "ZSHIP_TO",
  'DEFAULT' AS "ZSOLD_TO",
  CASE
    WHEN cd.SALES_DOC_TYPE IN ('ZFO2', 'ZFO3', 'ZFOC', 'ZKRF') THEN 'N'
    WHEN cd.SALES_DOC_TYPE IN ('ZKET', 'ZSTD') THEN 'R'
    WHEN cd.SALES_DOC_TYPE IN ('ZKEF') THEN 'C'
    WHEN cd.SALES_DOC_TYPE IN ('ZCL', 'ZDL', 'ZIPE', 'ZJCL', 'ZJDL', 'ZOF', 'ZOFC', 'ZST', 'ZSTI', 'ZIKB', 'ZOFC') THEN 'R'
    ELSE NULL
  END AS "ZPLNPTR",
  'EA' AS "0BASE_UOM",
  CASE
    WHEN cd.SALES_DOC_TYPE IN ('ZCL', 'ZDL', 'ZIPE', 'ZJCL', 'ZJDL', 'ZOF', 'ZOFC', 'ZST', 'ZSTI', 'ZIKB', 'ZOFC') 
    THEN cd.QUANTITY
    ELSE NULL
  END AS "ZDPDQMTS",
  CASE
    WHEN cd.SALES_DOC_TYPE IN ('ZCL', 'ZDL', 'ZIPE', 'ZJCL', 'ZJDL', 'ZOF', 'ZOFC', 'ZST', 'ZSTI', 'ZIKB', 'ZOFC') 
    THEN cd.QUANTITY_IN_EA
    ELSE NULL
  END AS "DEMAND_QUANTITY_MTS_EA",
  CASE
    WHEN cd.VBTYP = 'H' THEN cd.QUANTITY
    ELSE NULL
  END AS "RETURN_QUANTITY",
  CASE
    WHEN cd.VBTYP = 'H' THEN cd.QUANTITY_IN_EA
    ELSE NULL
  END AS "RETURN_QUANTITY_EA",
  cd.CALWEEK AS "0CALWEEK",
  cd.CALMONTH AS "0CALMONTH"
FROM calendar_data cd
LEFT JOIN regional_table rt 
  ON cd.SHIP_TO_COUNTRY = rt.COUNTRY 
  AND cd.CUSTOMER_CLASSIFICATION = rt.CUSTOMER_CLASSIFICATION;

%sql
-- Create gold view from silver table
CREATE OR REPLACE VIEW g_external.v_sales_orders_demand_fcst_everest AS
SELECT
  "9AMATNR" AS "APO_Product",
  "0COUNTRY" AS "Country_Key",
  "ZCUSTGRP" AS "Customer_Grp",
  "0DISTR_CHAN" AS "Distribution_Channel",
  "ZSALESOR" AS "Sales_Org",
  "ZPLANT",
  "0SALES_OFF" AS "Sales_Office",
  "ZPLNPTR" AS "Planning_Partner",
  "0CALWEEK" AS "Calendar_Week",
  "0CALMONTH" AS "Calendar_Month",
  "ZPRODH1" AS "Product_Hierarchy_Level_1",
  "ZPRODH2" AS "Product_Hierarchy_Level_2",
  "ZPRODH3" AS "Product_Hierarchy_Level_3",
  "ZPRODH4" AS "Product_Hierarchy_Level_4",
  "ZPRODH5" AS "Product_Hierarchy_Level_5",
  "0ITEM_CATEG" AS "Item_Category",
  "0DOC_TYPE" AS "Document_Type",
  "ZDPDQMTS" AS "Demand_Quantity_MTS",
  "DEMAND_QUANTITY_MTS_EA" AS "Demand_Quantity_MTS_EA",
  "RETURN_QUANTITY" AS "Return_Quantity",
  "RETURN_QUANTITY_EA" AS "Return_Quantity_EA",
  "0BASE_UOM" AS "Base_UOM",
  "ZSNAPSHOT" AS "Snapshot_ID"
FROM s_xyz.sales_orders_demand_fcst_everest;

%sql
-- Export data to CSV
CREATE OR REPLACE TEMPORARY VIEW export_view AS
SELECT * FROM g_external.v_sales_orders_demand_fcst_everest;

-- Use DBFS to write the data to the specified location
-- This will be executed as a Spark SQL command
CREATE OR REPLACE TEMPORARY VIEW export_command AS
SELECT
  "abfss://mft@{storage_account}.dfs.core.windows.net/outbound/supply-chain-management/scm-demand-fcst/EVST_SCM_demand_history.csv" 
  AS export_path;

-- The actual export would be done using Python with dbutils.fs.write
-- But since we're only generating SQL, we'll include a comment on how to perform the export
-- In a real Databricks notebook, you would use:
-- %python
-- df = spark.table("export_view")
-- df.coalesce(1).write.mode("overwrite").option("header", "true").csv(spark.table("export_command").collect()[0][0])