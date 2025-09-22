%sql
-- Creating Gold view for sales_orders_demand_fcst_ABC_onetime_history
CREATE OR REPLACE VIEW g_external.v_sales_orders_demand_fcst_ABC_onetime_history AS
SELECT
    APOPlanningVersion,
    ABCModelNumber,
    ProductPlannerCode,
    Country,
    SalesOffice,
    SalesOrganization,
    PLANT,
    PlanningPartner,
    DistributionChannel,
    CustomerGroup,
    ShipToParty,
    SoldToParty,
    WWBusiness,
    StrategyCenter,
    ProductLine,
    PlanningSet,
    ProductSubset,
    ItemCategory,
    SalesDocumentType,
    SnapshotID,
    CalMonth,
    BaseUnitOfMeasure,
    SourceSystem,
    DemandQuantityMTS,
    TotalDemand,
    ReturnsQtyMTS
FROM s_xyz.sales_orders_demand_fcst_ABC_onetime_history;