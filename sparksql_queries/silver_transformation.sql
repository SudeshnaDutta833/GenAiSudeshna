%sql
-- Silver layer transformation
INSERT INTO s_xyz.sales_orders_demand_fcst_ABC_onetime_history
SELECT
    '001' AS APOPlanningVersion,
    h.DMDUNIT AS ABCModelNumber,
    h.DMDUNIT AS ProductPlannerCode,
    CASE 
        WHEN LENGTH(h.LOC) = 3 AND SUBSTRING(h.LOC, 3, 1) = 'X' THEN SUBSTRING(h.LOC, 1, 2)
        ELSE h.LOC
    END AS Country,
    h.LOC AS SalesOffice,
    CASE 
        WHEN LENGTH(h.LOC) = 3 AND SUBSTRING(h.LOC, 3, 1) = 'X' THEN 'EUX'
        ELSE COALESCE(x.REGION, 'UNKNOWN')
    END AS SalesOrganization,
    COALESCE(x.REGION, 'UNKNOWN') AS PLANT,
    CASE 
        WHEN h.DMDGROUP = 'SALES' THEN 'R'
        WHEN h.DMDGROUP = 'SAMPLES' THEN 'N'
        WHEN h.DMDGROUP = 'CONSIGN' THEN 'C'
        ELSE 'UNKNOWN'
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
    DATE_FORMAT(TO_DATE(h.STARTDATE, 'dd-MMM-yy'), 'yyyyMM') AS CalMonth,
    'EA' AS BaseUnitOfMeasure,
    'JDAABC' AS SourceSystem,
    CASE WHEN h.HISTSTREAM = 'HIST' THEN CAST(h.QTY AS DECIMAL(17,3)) ELSE 0 END AS DemandQuantityMTS,
    CASE WHEN h.HISTSTREAM = 'HIST' THEN CAST(h.QTY AS DECIMAL(17,3)) ELSE 0 END AS TotalDemand,
    CASE WHEN h.HISTSTREAM = 'RTNS' THEN CAST(h.QTY AS DECIMAL(17,3)) ELSE 0 END AS ReturnsQtyMTS
FROM b_um_xyz.ABC_onetime_history_sales_orders h
LEFT JOIN b_um_xyz.ABC_onetime_history_sales_org_plant_xref x
    ON h.DMDUNIT = x.Product AND h.LOC = x.LOC
WHERE h.HISTSTREAM IN ('HIST', 'RTNS');