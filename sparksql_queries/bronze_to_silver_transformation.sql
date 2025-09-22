%sql
-- Transformation from Bronze to Silver layer
INSERT OVERWRITE TABLE s_onc.sales_ord_his
SELECT
  -- APO Planning Version (hardcoded as per requirement)
  '001' AS APOPlanningVersion,
  
  -- APM Model Number from Sales table
  s.DMDUNIT AS APMModelNumber,
  
  -- Product Planner Code from Sales table
  s.DMDUNIT AS ProductPlannerCode,
  
  -- Country from Sales table (trimmed to 2 characters)
  SUBSTRING(s.LOC, 1, 3) AS Country,
  
  -- Sales Office (LOC + mapped Region Code)
  CASE 
    WHEN o.PRODUCT IS NULL OR TRIM(o.PRODUCT) = '' THEN s.LOC
    ELSE s.LOC
  END AS SalesOffice,
  
  -- Sales Organization
  COALESCE(o.SalesOrg, 'NONE') AS SalesOrganization,
  
  -- Plant
  COALESCE(o.PlantDC, 'NONE') AS PLANT,
  
  -- Planning Partner based on DMDGROUP
  CASE 
    WHEN s.DMDGROUP = 'SALES' THEN 'R'
    WHEN s.DMDGROUP = 'SAMPLES' THEN 'N'
    WHEN s.DMDGROUP = 'CONSIGN' THEN 'C'
    ELSE s.DMDGROUP
  END AS PlanningPartner,
  
  -- Distribution Channel (default)
  '10' AS DistributionChannel,
  
  -- Customer Group (default)
  '500' AS CustomerGroup,
  
  -- Ship-To Party (default)
  'NONE' AS ShipToParty,
  
  -- Sold-to Party (default)
  'NONE' AS SoldToParty,
  
  -- WW Business (default)
  'None' AS WWBusiness,
  
  -- Strategy Center (default)
  'None' AS StrategyCenter,
  
  -- Product Line (default)
  'None' AS ProductLine,
  
  -- Planning Set (default)
  'None' AS PlanningSet,
  
  -- Product Subset (default)
  'None' AS ProductSubset,
  
  -- Item Category (default)
  'None' AS ItemCategory,
  
  -- Sales Document Type (default)
  'None' AS SalesDocumentType,
  
  -- Snapshot ID (system date/time)
  DATE_FORMAT(CURRENT_TIMESTAMP(), 'yyyyMMddHH') AS SnapshotID,
  
  -- Cal Month (mapped from STARTDATE)
  CAST(DATE_FORMAT(s.STARDATE, 'yyyyMM') AS DECIMAL(6,0)) AS CalMonth,
  
  -- Base Unit of Measure (default)
  'EA' AS BaseUnitOfMeasure,
  
  -- Source System (default)
  'JDAAPM' AS SourceSystem,
  
  -- Demand Quantity - MTS (when HISTSTREAM = Actual Sales Qty)
  CASE 
    WHEN s.HISTSTREAM = 'Actual Sales Qty' THEN s.QTY
    ELSE 0
  END AS DemandQuantityMTS,
  
  -- Total Demand (same as Demand Quantity)
  CASE 
    WHEN s.HISTSTREAM = 'Actual Sales Qty' THEN s.QTY
    ELSE 0
  END AS TotalDemand,
  
  -- Returns Qty - MTS (when HISTSTREAM = Return Qty)
  CASE 
    WHEN s.HISTSTREAM = 'Return Qty' THEN s.QTY
    ELSE 0
  END AS ReturnsQtyMTS
  
FROM b_onc.sales s
LEFT JOIN b_onc.sales_org o ON s.LOC = o.LOC;