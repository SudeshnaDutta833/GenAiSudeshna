-- Bronze layer table DDL for ABC_onetime_history_sales_orders
%sql
CREATE TABLE IF NOT EXISTS b_um_xyz.ABC_onetime_history_sales_orders (
    DMDUNIT STRING,
    DMDGROUP STRING,
    LOC STRING,
    STARTDATE STRING,
    DUR INT,
    TYPE INT,
    EVENT STRING,
    QTY INT,
    HISTSTREAM STRING,
    SourceFile STRING
) USING DELTA
COMMENT 'Bronze layer table for ABC onetime history sales orders data';

-- Bronze layer table DDL for ABC_onetime_history_sales_org_plant_xref
%sql
CREATE TABLE IF NOT EXISTS b_um_xyz.ABC_onetime_history_sales_org_plant_xref (
    Product STRING,
    LOC STRING,
    REGION STRING,
    COUNTRY STRING,
    CHANNEL STRING,
    SourceFile STRING
) USING DELTA
COMMENT 'Bronze layer table for ABC onetime history sales org plant cross-reference data';

-- Silver layer table DDL
%sql
CREATE TABLE IF NOT EXISTS s_xyz.sales_orders_demand_fcst_ABC_onetime_history (
    APOPlanningVersion STRING,
    ABCModelNumber STRING,
    ProductPlannerCode STRING,
    Country STRING,
    SalesOffice STRING,
    SalesOrganization STRING,
    PLANT STRING,
    PlanningPartner STRING,
    DistributionChannel STRING,
    CustomerGroup STRING,
    ShipToParty STRING,
    SoldToParty STRING,
    WWBusiness STRING,
    StrategyCenter STRING,
    ProductLine STRING,
    PlanningSet STRING,
    ProductSubset STRING,
    ItemCategory STRING,
    SalesDocumentType STRING,
    SnapshotID STRING,
    CalMonth INT,
    BaseUnitOfMeasure STRING,
    SourceSystem STRING,
    DemandQuantityMTS DECIMAL(17,3),
    TotalDemand DECIMAL(17,3),
    ReturnsQtyMTS DECIMAL(17,3)
) USING DELTA
COMMENT 'Silver layer table for sales orders demand forecast ABC onetime history';

-- Gold layer view DDL
%sql
CREATE OR REPLACE VIEW g_external.v_sales_orders_demand_fcst_ABC_onetime_history AS
SELECT
    APOPlanningVersion,
    ABCModelNumber AS APOProduct,
    Country AS CountryKey,
    CustomerGroup AS CustomerGrp,
    DistributionChannel,
    SalesOrganization AS SalesOrg,
    PLANT AS ZPLANT,
    SalesOffice,
    PlanningPartner,
    ItemCategory,
    SalesDocumentType AS SalesDocType,
    SnapshotID AS Snapshot,
    BaseUnitOfMeasure AS BaseunitMeasure,
    SourceSystem,
    CalMonth AS CalendarDay,
    DemandQuantityMTS AS DemandQtyMTS,
    ReturnsQtyMTS AS ReturnQty
FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history;