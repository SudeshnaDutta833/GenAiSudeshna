%sql
-- Silver transformation SQL to transform bronze data to silver layer
INSERT OVERWRITE TABLE s_xyz.sales_orders_demand_fcst_ABC_onetime_history
SELECT
  '001' AS APOPlanningVersion,
  so.DMDUNIT AS ABCModelNumber,
  so.DMDUNIT AS ProductPlannerCode,
  -- Country logic: Trim to 2 characters if LOC has 'X' at the end
  CASE 
    WHEN so.LOC LIKE '%X' THEN SUBSTRING(so.LOC, 1, 2)
    ELSE so.LOC
  END AS Country,
  so.LOC AS SalesOffice,
  -- Sales Organization from mapping table
  COALESCE(xref.REGION, 'NONE') AS SalesOrganization,
  -- Plant from mapping table
  COALESCE(xref.REGION, 'NONE') AS PLANT,
  -- Planning Partner based on DMDGROUP
  CASE 
    WHEN so.DMDGROUP = 'SALES' THEN 'R'
    WHEN so.DMDGROUP = 'SAMPLES' THEN 'N'
    WHEN so.DMDGROUP = 'CONSIGN' THEN 'C'
    ELSE 'NONE'
  END AS PlanningPartner,
  '10' AS DistributionChannel,
  '500' AS CustomerGroup,
  'NONE' AS ShipToParty,
  'NONE' AS SoldToParty,
  'NONE' AS WWBusiness,
  'NONE' AS StrategyCenter,
  'NONE' AS ProductLine,
  'NONE' AS PlanningSet,
  'NONE' AS ProductSubset,
  'NONE' AS ItemCategory,
  'NONE' AS SalesDocumentType,
  CURRENT_TIMESTAMP() AS SnapshotID,
  -- Convert STARTDATE to numeric format (YYYYMM)
  CAST(CONCAT(YEAR(TO_DATE(so.STARTDATE, 'dd-MMM-yy')), 
              LPAD(MONTH(TO_DATE(so.STARTDATE, 'dd-MMM-yy')), 2, '0')) AS INT) AS CalMonth,
  'EA' AS BaseUnitOfMeasure,
  'JDAABC' AS SourceSystem,
  -- Demand quantity for HIST records
  CASE 
    WHEN so.HISTSTREAM = 'HIST' THEN CAST(so.QTY AS DECIMAL(17,3))
    ELSE 0
  END AS DemandQuantityMTS,
  -- Total demand (same as demand quantity)
  CASE 
    WHEN so.HISTSTREAM = 'HIST' THEN CAST(so.QTY AS DECIMAL(17,3))
    ELSE 0
  END AS TotalDemand,
  -- Returns quantity for RTNS records
  CASE 
    WHEN so.HISTSTREAM = 'RTNS' THEN CAST(so.QTY AS DECIMAL(17,3))
    ELSE 0
  END AS ReturnsQtyMTS,
  CURRENT_TIMESTAMP() AS ProcessedTimestamp
FROM b_um_xyz.ABC_onetime_history_sales_orders so
LEFT JOIN b_um_xyz.ABC_onetime_history_sales_org_plant_xref xref
  ON so.DMDUNIT = xref.Product AND so.LOC = xref.LOC
WHERE so.HISTSTREAM IN ('HIST', 'RTNS');