%sql
-- Creating Bronze tables for ABC_onetime_history_sales_orders
CREATE TABLE IF NOT EXISTS b_um_xyz.ABC_onetime_history_sales_orders (
    DMDUNIT STRING,
    DMDGROUP STRING,
    LOC STRING,
    STARTDATE STRING,
    DUR INT,
    TYPE INT,
    EVENT STRING,
    QTY DECIMAL(17,3),
    HISTSTREAM STRING,
    SourceFile STRING
) USING DELTA
COMMENT 'Bronze layer table for ABC onetime history sales orders data';

-- Creating Bronze tables for ABC_onetime_history_sales_org_plant_xref
CREATE TABLE IF NOT EXISTS b_um_xyz.ABC_onetime_history_sales_org_plant_xref (
    Product STRING,
    LOC STRING,
    REGION_SALES_ORG STRING,
    COUNTRY STRING,
    CHANNEL STRING,
    SourceFile STRING
) USING DELTA
COMMENT 'Bronze layer table for ABC onetime history sales org plant cross reference data';