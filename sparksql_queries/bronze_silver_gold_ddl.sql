-- Bronze Layer Table DDLs
%sql
CREATE DATABASE IF NOT EXISTS b_um_xyz;

-- Bronze table for ABC sales order history
%sql
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
)
USING DELTA
COMMENT 'Bronze layer table for ABC onetime history sales orders';

-- Bronze table for sales org plant cross-reference
%sql
CREATE TABLE IF NOT EXISTS b_um_xyz.ABC_onetime_history_sales_org_plant_xref (
  Product STRING,
  LOC STRING,
  REGION STRING,
  COUNTRY STRING,
  CHANNEL STRING,
  SourceFile STRING
)
USING DELTA
COMMENT 'Bronze layer table for ABC sales org and plant cross-reference data';

-- Silver Layer Table DDL
%sql
CREATE DATABASE IF NOT EXISTS s_xyz;

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
)
USING DELTA
COMMENT 'Silver layer table for ABC sales orders demand forecast';

-- Gold Layer View DDL
%sql
CREATE DATABASE IF NOT EXISTS g_external;

%sql
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