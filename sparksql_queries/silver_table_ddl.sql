%sql
-- Creating Silver table for sales_orders_demand_fcst_ABC_onetime_history
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
    ReturnsQtyMTS DECIMAL(17,3),
    ProcessedTimestamp TIMESTAMP
) USING DELTA
COMMENT 'Silver layer table for ABC onetime history sales orders demand forecast data';