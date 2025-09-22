-- Bronze Layer Tables DDL

-- Create bronze table for Sales data
%sql
CREATE TABLE IF NOT EXISTS b_onc.sales (
  DMDUNIT STRING,
  DMDGROUP STRING,
  LOC STRING,
  STARDATE DATE,
  DUR INT,
  TYPE STRING,
  EVENT STRING,
  QTY DECIMAL(17,3),
  HISTSTREAM STRING,
  PRODUCT STRING,
  SourceFile STRING
);

-- Create bronze table for Sales Organization data
%sql
CREATE TABLE IF NOT EXISTS b_onc.sales_org (
  LOC STRING,
  Region STRING,
  Country STRING,
  Channel STRING,
  SalesOrg STRING,
  PlantDC STRING,
  SourceFile STRING
);

-- Silver Layer Table DDL
%sql
CREATE TABLE IF NOT EXISTS s_onc.sales_ord_his (
  APOPlanningVersion CHAR(10),
  APMModelNumber CHAR(40),
  ProductPlannerCode CHAR(40),
  Country CHAR(3),
  SalesOffice CHAR(4),
  SalesOrganization CHAR(4),
  PLANT CHAR(4),
  PlanningPartner CHAR(10),
  DistributionChannel CHAR(2),
  CustomerGroup CHAR(3),
  ShipToParty CHAR(10),
  SoldToParty CHAR(10),
  WWBusiness CHAR(18),
  StrategyCenter CHAR(18),
  ProductLine CHAR(18),
  PlanningSet CHAR(18),
  ProductSubset CHAR(18),
  ItemCategory CHAR(4),
  SalesDocumentType CHAR(4),
  SnapshotID CHAR(10),
  CalMonth DECIMAL(6,0),
  BaseUnitOfMeasure CHAR(3),
  SourceSystem CHAR(10),
  DemandQuantityMTS DECIMAL(17,3),
  TotalDemand DECIMAL(17,3),
  ReturnsQtyMTS DECIMAL(17,3)
);

-- Gold Layer View DDL
%sql
CREATE OR REPLACE VIEW g_onc.sales_order_history_view AS
SELECT 
  APOPlanningVersion,
  APMModelNumber,
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
FROM s_onc.sales_ord_his;