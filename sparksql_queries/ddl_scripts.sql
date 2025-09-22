-- Bronze Layer DDL Scripts

%sql
CREATE DATABASE IF NOT EXISTS b_onc;

%sql
CREATE TABLE IF NOT EXISTS b_onc.sales (
    Product STRING,
    DmdUnit STRING,
    DmdGroup STRING,
    Loc STRING,
    StartDate STRING,
    Dur STRING,
    Type STRING,
    Event STRING,
    Qty DECIMAL(17,3),
    HistStream STRING,
    SourceFile STRING,
    LoadTimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
) USING DELTA
LOCATION '/mnt/datalake/bronze/onc/sales/'
TBLPROPERTIES (
    'delta.autoOptimize.optimizeWrite' = 'true',
    'delta.autoOptimize.autoCompact' = 'true'
);

%sql
CREATE TABLE IF NOT EXISTS b_onc.sales_org (
    Loc STRING,
    Region STRING,
    Country STRING,
    Channel STRING,
    SalesOrg STRING,
    PlantDc STRING,
    SourceFile STRING,
    LoadTimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
) USING DELTA
LOCATION '/mnt/datalake/bronze/onc/sales_org/'
TBLPROPERTIES (
    'delta.autoOptimize.optimizeWrite' = 'true',
    'delta.autoOptimize.autoCompact' = 'true'
);

-- Silver Layer DDL Scripts

%sql
CREATE DATABASE IF NOT EXISTS s_onc;

%sql
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
    CalMonth INT,
    BaseUnitOfMeasure STRING,
    SourceSystem STRING,
    DemandQuantityMts DECIMAL(17,3),
    TotalDemand DECIMAL(17,3),
    ReturnsQtyMts DECIMAL(17,3),
    ProcessedTimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
) USING DELTA
LOCATION '/mnt/datalake/silver/onc/sales_ord_his/'
PARTITIONED BY (CalMonth)
TBLPROPERTIES (
    'delta.autoOptimize.optimizeWrite' = 'true',
    'delta.autoOptimize.autoCompact' = 'true'
);

-- Gold Layer View DDL

%sql
CREATE DATABASE IF NOT EXISTS g_onc;

%sql
CREATE OR REPLACE VIEW g_onc.vw_sales_ord_his_summary AS
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
    SUM(DemandQuantityMts) as TotalDemandQuantityMts,
    SUM(TotalDemand) as TotalDemandSum,
    SUM(ReturnsQtyMts) as TotalReturnsQtyMts,
    COUNT(*) as RecordCount,
    MAX(ProcessedTimestamp) as LastProcessedTimestamp
FROM s_onc.sales_ord_his
GROUP BY 
    ApoPlanningVersion, ApmModelNumber, ProductPlannerCode, Country,
    SalesOffice, SalesOrganization, Plant, PlanningPartner,
    DistributionChannel, CustomerGroup, ShipToParty, SoldToParty,
    WwBusiness, StrategyCenter, ProductLine, PlanningSet,
    ProductSubset, ItemCategory, SalesDocumentType, SnapshotId,
    CalMonth, BaseUnitOfMeasure, SourceSystem;