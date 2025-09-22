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
);

CREATE TABLE IF NOT EXISTS b_onc.sales_org (
  PRODUCT STRING,
  LOC STRING,
  Region STRING,
  Country STRING,
  Channel STRING,
  SalesOrg STRING,
  PlantDC STRING,
  SourceFile STRING
);

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
  CalMonth BIGINT,
  BaseUnitOfMeasure STRING,
  SourceSystem STRING,
  DemandQuantityMts DOUBLE,
  TotalDemand DOUBLE,
  ReturnsQtyMts DOUBLE
);

CREATE VIEW IF NOT EXISTS g_onc.sales_ord_his AS
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