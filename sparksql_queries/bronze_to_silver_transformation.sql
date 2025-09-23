%sql
-- Transform data from bronze to silver layer
INSERT INTO s_xyz.sales_orders_demand_fcst_ABC_onetime_history
SELECT
  '001' AS APOPlanningVersion, -- Hardcoded as per requirement
  h.DMDUNIT AS ABCModelNumber,
  h.DMDUNIT AS ProductPlannerCode,
  CASE
    -- Handle export country code transformation by dropping the last 'X' character
    WHEN SUBSTRING(h.LOC, LENGTH(h.LOC), 1) = 'X' THEN SUBSTRING(h.LOC, 1, LENGTH(h.LOC) - 1)
    ELSE h.LOC
  END AS Country,
  h.LOC AS SalesOffice, -- Use LOC as Sales Office
  x.REGION AS SalesOrganization, -- Map from cross-reference table
  x.REGION AS PLANT, -- Map from cross-reference table (BD Plant)
  CASE 
    WHEN h.DMDGROUP = 'SALES' THEN 'R'
    WHEN h.DMDGROUP = 'SAMPLES' THEN 'N'
    WHEN h.DMDGROUP = 'CONSIGN' THEN 'C'
    ELSE NULL
  END AS PlanningPartner,
  '10' AS DistributionChannel, -- Default value
  '500' AS CustomerGroup, -- Default value
  'NONE' AS ShipToParty, -- Default value
  'NONE' AS SoldToParty, -- Default value
  NULL AS WWBusiness, -- Default None
  NULL AS StrategyCenter, -- Default None
  NULL AS ProductLine, -- Default None
  NULL AS PlanningSet, -- Default None
  NULL AS ProductSubset, -- Default None
  NULL AS ItemCategory, -- Default None
  NULL AS SalesDocumentType, -- Default None
  CURRENT_TIMESTAMP() AS SnapshotID, -- System date and time
  TO_NUMBER(DATE_FORMAT(TO_DATE(h.STARTDATE, 'dd-MMM-yy'), 'yyyyMM')) AS CalMonth, -- Convert date to calendar month
  'EA' AS BaseUnitOfMeasure, -- Default value
  'JDAABC' AS SourceSystem, -- Default value
  CASE 
    WHEN h.HISTSTREAM = 'HIST' THEN h.QTY
    ELSE NULL
  END AS DemandQuantityMTS,
  CASE 
    WHEN h.HISTSTREAM = 'HIST' THEN h.QTY
    ELSE NULL
  END AS TotalDemand,
  CASE 
    WHEN h.HISTSTREAM = 'RTNS' THEN h.QTY
    ELSE NULL
  END AS ReturnsQtyMTS
FROM b_um_xyz.ABC_onetime_history_sales_orders h
LEFT JOIN b_um_xyz.ABC_onetime_history_sales_org_plant_xref x
  ON h.DMDUNIT = x.Product AND h.LOC = x.LOC
WHERE h.HISTSTREAM IN ('HIST', 'RTNS'); -- Filter for historical and returns data only