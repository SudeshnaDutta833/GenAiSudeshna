%sql
-- SQL transformation from bronze to silver layer
INSERT OVERWRITE TABLE s_onc.sales_ord_his
SELECT
  -- APO Planning Version
  '001' AS APOPlanningVersion,
  
  -- APM Model Number - Mapped against APO Product in SCM
  s.DMDUNIT AS APMModelNumber,
  
  -- Product Planner Code - Mapped against Product Planner code in SCM
  s.DMDUNIT AS ProductPlannerCode,
  
  -- Country - trim to 2 characters
  SUBSTRING(s.LOC, 1, 2) AS Country,
  
  -- Sales Office - Use LOC + map to Region Code via X-Ref
  CASE
    WHEN so.PRODUCT IS NULL OR TRIM(so.PRODUCT) = '' THEN CONCAT(s.LOC, '_REG')
    ELSE CONCAT(s.LOC, '_REG')
  END AS SalesOffice,
  
  -- Sales Organization - Map LOC to BD Salesorg via X-Ref
  CASE
    WHEN so.PRODUCT IS NULL OR TRIM(so.PRODUCT) = '' THEN CONCAT(s.LOC, '_ORG')
    ELSE so.SalesOrg
  END AS SalesOrganization,
  
  -- PLANT - Map LOC to BD Location via X-Ref
  CASE
    WHEN so.PRODUCT IS NULL OR TRIM(so.PRODUCT) = '' THEN CONCAT(s.LOC, '_PLT')
    ELSE so.PlantDC
  END AS PLANT,
  
  -- Planning Partner based on DMDGROUP
  CASE
    WHEN s.DMDGROUP = 'SALES' THEN 'R'
    WHEN s.DMDGROUP = 'SAMPLES' THEN 'N'
    WHEN s.DMDGROUP = 'CONSIGN' THEN 'C'
    ELSE s.DMDGROUP
  END AS PlanningPartner,
  
  -- Default values for standardized fields
  '10' AS DistributionChannel,
  '500' AS CustomerGroup,
  'NONE' AS ShipToParty,
  'NONE' AS SoldToParty,
  'None' AS WWBusiness,
  'None' AS StrategyCenter,
  'None' AS ProductLine,
  'None' AS PlanningSet,
  'None' AS ProductSubset,
  'None' AS ItemCategory,
  'None' AS SalesDocumentType,
  
  -- Snapshot ID - Use system date/time
  DATE_FORMAT(CURRENT_TIMESTAMP(), 'yyyyMMddHH') AS SnapshotID,
  
  -- Cal Month - Map from STARTDATE
  CAST(DATE_FORMAT(TO_DATE(s.STARDATE, 'yyyy-MM-dd'), 'yyyyMM') AS DECIMAL(6,0)) AS CalMonth,
  
  -- Base Unit of Measure
  'EA' AS BaseUnitOfMeasure,
  
  -- Source System
  'JDAAPM' AS SourceSystem,
  
  -- Demand Quantity - MTS (HISTSTREAM = Actual Sales Qty)
  CASE WHEN s.HISTSTREAM = 'Actual Sales Qty' THEN s.QTY ELSE 0 END AS DemandQuantityMTS,
  
  -- Total Demand - Same as Demand Quantity
  CASE WHEN s.HISTSTREAM = 'Actual Sales Qty' THEN s.QTY ELSE 0 END AS TotalDemand,
  
  -- Returns Qty - MTS (HISTSTREAM = Return Qty)
  CASE WHEN s.HISTSTREAM = 'Return Qty' THEN s.QTY ELSE 0 END AS ReturnsQtyMTS

FROM b_onc.Sales s
LEFT JOIN b_onc.sales_org so ON s.LOC = so.LOC;