-- Bronze table for Sales
CREATE TABLE IF NOT EXISTS b_onc.sales (
    DMDUNIT STRING,
    DMDGROUP STRING,
    LOC STRING,
    STARDATE STRING,
    DUR STRING,
    TYPE STRING,
    EVENT STRING,
    QTY DOUBLE,
    HISTSTREAM STRING,
    SourceFile STRING
) USING delta;

-- Bronze table for Sales Org
CREATE TABLE IF NOT EXISTS b_onc.sales_org (
    PRODUCT STRING,
    LOC STRING,
    Region STRING,
    Country STRING,
    Channel STRING,
    SalesOrg STRING,
    PlantDC STRING,
    SourceFile STRING
) USING delta;

-- Silver table for Sales Order History
CREATE TABLE IF NOT EXISTS s_onc.sales_ord_his (
    ApoPlanningVersion STRING,
    ApmModelNumber STRING,
    ProductPlannerCode STRING,
    Country STRING,
    SalesOffice STRING,
    SalesOrganization STRING,
    Plant STRING,
    PlanningPartner STRING,
    DistributionChannel STRING,
    CustomerGroup STRING,
    ShipToParty STRING,
    SoldToParty STRING,
    WwBusiness STRING,
    StrategyCenter STRING,
    ProductLine STRING,
    PlanningSet STRING,
    ProductSubset STRING,
    ItemCategory STRING,
    SalesDocumentType STRING,
    SnapshotId STRING,
    CalMonth STRING,
    BaseUnitOfMeasure STRING,
    SourceSystem STRING,
    DemandQuantityMts DOUBLE,
    TotalDemand DOUBLE,
    ReturnsQtyMts DOUBLE
) USING delta;

-- Gold view
CREATE OR REPLACE VIEW g_onc.sales_ord_his_gold
AS
SELECT 
    ApoPlanningVersion,
    ApmModelNumber,
    ProductPlannerCode,
    Country,
    SalesOffice,
    SalesOrganization,
    Plant,
    PlanningPartner,
    DistributionChannel,
    CustomerGroup,
    ShipToParty,
    SoldToParty,
    WwBusiness,
    StrategyCenter,
    ProductLine,
    PlanningSet,
    ProductSubset,
    ItemCategory,
    SalesDocumentType,
    SnapshotId,
    CalMonth,
    BaseUnitOfMeasure,
    SourceSystem,
    DemandQuantityMts,
    TotalDemand,
    ReturnsQtyMts
FROM s_onc.sales_ord_his;

-- Transform data from bronze tables to silver table
INSERT INTO s_onc.sales_ord_his
SELECT 
    CASE 
        WHEN b_onc.sales_org.PRODUCT IS NULL OR b_onc.sales_org.PRODUCT = '' THEN '001'
        ELSE '001'
    END AS ApoPlanningVersion,
    CASE 
        WHEN b_onc.sales_org.PRODUCT IS NULL OR b_onc.sales_org.PRODUCT = '' THEN b_onc.sales.DMDUNIT
        ELSE b_onc.sales.DMDUNIT
    END AS ApmModelNumber,
    CASE 
        WHEN b_onc.sales_org.PRODUCT IS NULL OR b_onc.sales_org.PRODUCT = '' THEN b_onc.sales.DMDUNIT
        ELSE b_onc.sales.DMDUNIT
    END AS ProductPlannerCode,
    TRIM(SUBSTR(b_onc.sales.LOC, 1, 2)) AS Country,
    CONCAT(b_onc.sales.LOC, b_onc.sales_org.Region) AS SalesOffice,
    CONCAT(b_onc.sales.LOC, b_onc.sales_org.SalesOrg) AS SalesOrganization,
    CONCAT(b_onc.sales.LOC, b_onc.sales_org.PlantDC) AS Plant,
    CASE 
        WHEN b_onc.sales.DMDGROUP = 'SALES' THEN 'R'
        WHEN b_onc.sales.DMDGROUP = 'SAMPLES' THEN 'N'
        WHEN b_onc.sales.DMDGROUP = 'CONSIGN' THEN 'C'
        ELSE b_onc.sales.DMDGROUP
    END AS PlanningPartner,
    '10' AS DistributionChannel,
    '500' AS CustomerGroup,
    'NONE' AS ShipToParty,
    'NONE' AS SoldToParty,
    'None' AS WwBusiness,
    'None' AS StrategyCenter,
    'None' AS ProductLine,
    'None' AS PlanningSet,
    'None' AS ProductSubset,
    'None' AS ItemCategory,
    'None' AS SalesDocumentType,
    CURRENT_TIMESTAMP() AS SnapshotId,
    DATE_FORMAT(b_onc.sales.STARDATE, 'yyyyMM') AS CalMonth,
    'EA' AS BaseUnitOfMeasure,
    'JDAAPM' AS SourceSystem,
    CASE 
        WHEN b_onc.sales.HISTSTREAM = 'Actual Sales Qty' THEN b_onc.sales.QTY
        ELSE 0
    END AS DemandQuantityMts,
    CASE 
        WHEN b_onc.sales.HISTSTREAM = 'Actual Sales Qty' THEN b_onc.sales.QTY
        ELSE 0
    END AS TotalDemand,
    CASE 
        WHEN b_onc.sales.HISTSTREAM = 'Return Qty' THEN b_onc.sales.QTY
        ELSE 0
    END AS ReturnsQtyMts
FROM b_onc.sales
LEFT JOIN b_onc.sales_org ON b_onc.sales.LOC = b_onc.sales_org.LOC;

-- Save data to CSV
COPY INTO 'outbound_location_in_adls'
FROM g_onc.sales_ord_his_gold
FILEFORMAT = CSV
FORMAT_OPTIONS ('header' = 'true');