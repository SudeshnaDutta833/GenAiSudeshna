INSERT INTO s_onc.sales_ord_his
SELECT 
  CASE 
    WHEN b_onc.sales_org.PRODUCT IS NULL OR b_onc.sales_org.PRODUCT = '' THEN '001'
    ELSE b_onc.sales_org.PRODUCT
  END AS ApoPlanningVersion,
  CASE 
    WHEN b_onc.sales_org.PRODUCT IS NULL OR b_onc.sales_org.PRODUCT = '' THEN b_onc.sales.DMDUNIT
    ELSE b_onc.sales.DMDUNIT
  END AS ApmModelNumber,
  CASE 
    WHEN b_onc.sales_org.PRODUCT IS NULL OR b_onc.sales_org.PRODUCT = '' THEN b_onc.sales.DMDUNIT
    ELSE b_onc.sales.DMDUNIT
  END AS ProductPlannerCode,
  TRIM(SUBSTRING(b_onc.sales.LOC, 1, 2)) AS Country,
  CONCAT(b_onc.sales.LOC, b_onc.sales_org.Region) AS SalesOffice,
  CONCAT(b_onc.sales.LOC, b_onc.sales_org.SalesOrg) AS SalesOrganization,
  CONCAT(b_onc.sales.LOC, b_onc.sales_org.PlantDC) AS Plant,
  CASE 
    WHEN b_onc.sales.DMDGROUP = 'SALES' THEN 'R'
    WHEN b_onc.sales.DMDGROUP = 'SAMPLES' THEN 'N'
    WHEN b_onc.sales.DMDGROUP = 'CONSIGN' THEN 'C'
    ELSE b_onc.sales.DMDGROUP
  END AS PlanningPartner,
  '10' AS DistributionChannel,
  '500' AS CustomerGroup,
  'NONE' AS ShipToParty,
  'NONE' AS SoldToParty,
  'None' AS WwBusiness,
  'None' AS StrategyCenter,
  'None' AS ProductLine,
  'None' AS PlanningSet,
  'None' AS ProductSubset,
  'None' AS ItemCategory,
  'None' AS SalesDocumentType,
  CURRENT_TIMESTAMP() AS SnapshotId,
  YEAR(b_onc.sales.STARDATE) * 100 + MONTH(b_onc.sales.STARDATE) AS CalMonth,
  'EA' AS BaseUnitOfMeasure,
  'JDAAPM' AS SourceSystem,
  CASE 
    WHEN b_onc.sales.HISTSTREAM = 'Actual Sales Qty' THEN b_onc.sales.QTY
    ELSE 0
  END AS DemandQuantityMts,
  CASE 
    WHEN b_onc.sales.HISTSTREAM = 'Actual Sales Qty' THEN b_onc.sales.QTY
    ELSE 0
  END AS TotalDemand,
  CASE 
    WHEN b_onc.sales.HISTSTREAM = 'Return Qty' THEN b_onc.sales.QTY
    ELSE 0
  END AS ReturnsQtyMts
FROM b_onc.sales
INNER JOIN b_onc.sales_org ON b_onc.sales.LOC = b_onc.sales_org.LOC;