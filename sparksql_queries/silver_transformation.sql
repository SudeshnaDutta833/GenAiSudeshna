%sql
-- Transformation SQL for loading data from bronze to silver
INSERT OVERWRITE TABLE s_onc.sales_ord_his
SELECT
  -- APO Planning Version - hardcoded value
  '001' AS APOPlanningVersion,
  
  -- APM Model Number from DMDUNIT
  s.DMDUNIT AS APMModelNumber,
  
  -- Product Planner Code from DMDUNIT
  s.DMDUNIT AS ProductPlannerCode,
  
  -- Country - trim to 2 characters
  SUBSTRING(s.LOC, 1, 2) AS Country,
  
  -- Sales Office - LOC + map to Region Code
  CASE 
    WHEN so.PRODUCT IS NULL OR TRIM(so.PRODUCT) = '' THEN s.LOC
    ELSE s.LOC
  END AS SalesOffice,
  
  -- Sales Organization - Map LOC to BD Salesorg
  COALESCE(so.SalesOrg, 'NONE') AS SalesOrganization,
  
  -- PLANT - Map LOC to BD Location
  COALESCE(so.PlantDC, 'NONE') AS PLANT,
  
  -- Planning Partner based on DMDGROUP
  CASE 
    WHEN s.DMDGROUP = 'SALES' THEN 'R'
    WHEN s.DMDGROUP = 'SAMPLES' THEN 'N'
    WHEN s.DMDGROUP = 'CONSIGN' THEN 'C'
    ELSE s.DMDGROUP
  END AS PlanningPartner,
  
  -- Distribution Channel - Default to 10
  '10' AS DistributionChannel,
  
  -- Customer Group - Default to 500
  '500' AS CustomerGroup,
  
  -- Ship-To Party - Default to NONE
  'NONE' AS ShipToParty,
  
  -- Sold-to Party - Default to NONE
  'NONE' AS SoldToParty,
  
  -- WW Business - Default to None
  'None' AS WWBusiness,
  
  -- Strategy Center - Default to None
  'None' AS StrategyCenter,
  
  -- Product Line - Default to None
  'None' AS ProductLine,
  
  -- Planning Set - Default to None
  'None' AS PlanningSet,
  
  -- Product Subset - Default to None
  'None' AS ProductSubset,
  
  -- Item Category - Default to None
  'None' AS ItemCategory,
  
  -- Sales Document Type - Default to None
  'None' AS SalesDocumentType,
  
  -- Snapshot ID - Use system date/time
  DATE_FORMAT(CURRENT_TIMESTAMP(), 'yyyyMMddHH') AS SnapshotID,
  
  -- Cal Month - Map from STARTDATE
  CAST(DATE_FORMAT(TO_DATE(s.STARDATE, 'yyyy-MM-dd'), 'yyyyMM') AS BIGINT) AS CalMonth,
  
  -- Base Unit of Measure - Default to EA
  'EA' AS BaseUnitOfMeasure,
  
  -- Source System - Default to 'JDAAPM'
  'JDAAPM' AS SourceSystem,
  
  -- Demand Quantity - MTS - HISTSTREAM = Actual Sales Qty
  CASE WHEN s.HISTSTREAM = 'Actual Sales Qty' THEN CAST(s.QTY AS DECIMAL(17,3)) ELSE 0 END AS DemandQuantityMTS,
  
  -- Total Demand - Same as Demand Quantity
  CASE WHEN s.HISTSTREAM = 'Actual Sales Qty' THEN CAST(s.QTY AS DECIMAL(17,3)) ELSE 0 END AS TotalDemand,
  
  -- Returns Qty - MTS - HISTSTREAM = Return Qty
  CASE WHEN s.HISTSTREAM = 'Return Qty' THEN CAST(s.QTY AS DECIMAL(17,3)) ELSE 0 END AS ReturnsQtyMTS
  
FROM b_onc.sales s
LEFT JOIN b_onc.sales_org so ON s.LOC = so.LOC;