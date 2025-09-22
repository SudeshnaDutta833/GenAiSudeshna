%sql
-- SQL transformation for loading data from bronze to silver table
INSERT INTO s_xyz.sales_orders_demand_fcst_ABC_onetime_history
SELECT
    '001' AS APOPlanningVersion,  -- Hard-coded value as per requirements
    so.DMDUNIT AS ABCModelNumber,
    so.DMDUNIT AS ProductPlannerCode,
    -- Transform country code based on requirements
    CASE 
        WHEN LENGTH(so.LOC) = 3 AND SUBSTRING(so.LOC, 3, 1) = 'X' THEN SUBSTRING(so.LOC, 1, 2)
        ELSE so.LOC
    END AS Country,
    so.LOC AS SalesOffice,  -- Sales Office is the LOC from history file
    -- Sales Organization from mapping table
    COALESCE(xref.REGION_SALES_ORG, 
        CASE 
            WHEN LENGTH(so.LOC) = 3 AND SUBSTRING(so.LOC, 3, 1) = 'X' THEN 'EUX'
            ELSE 'EUR'  -- Default value
        END
    ) AS SalesOrganization,
    -- Plant from mapping table (BD Plant)
    COALESCE(xref.PLANT, '0001') AS PLANT,  -- Default plant if not found
    -- Planning partner based on DMDGROUP
    CASE 
        WHEN so.DMDGROUP = 'SALES' THEN 'R'
        WHEN so.DMDGROUP = 'SAMPLES' THEN 'N'
        WHEN so.DMDGROUP = 'CONSIGN' THEN 'C'
        ELSE 'R'  -- Default value
    END AS PlanningPartner,
    '10' AS DistributionChannel,  -- Default value as per requirements
    '500' AS CustomerGroup,       -- Default value as per requirements
    'NONE' AS ShipToParty,        -- Default value as per requirements
    'NONE' AS SoldToParty,        -- Default value as per requirements
    'NONE' AS WWBusiness,         -- Default value
    'NONE' AS StrategyCenter,     -- Default value
    'NONE' AS ProductLine,        -- Default value
    'NONE' AS PlanningSet,        -- Default value
    'NONE' AS ProductSubset,      -- Default value
    'NONE' AS ItemCategory,       -- Default value
    'NONE' AS SalesDocumentType,  -- Default value
    CAST(CURRENT_TIMESTAMP() AS STRING) AS SnapshotID,  -- System date and time
    -- Convert STARTDATE to CalMonth (YYYYMM format)
    CAST(
        CONCAT(
            YEAR(TO_DATE(so.STARTDATE, 'dd-MMM-yy')),
            LPAD(MONTH(TO_DATE(so.STARTDATE, 'dd-MMM-yy')), 2, '0')
        ) AS INT
    ) AS CalMonth,
    'EA' AS BaseUnitOfMeasure,    -- Default value as per requirements
    'JDAABC' AS SourceSystem,     -- Default value as per requirements
    -- Demand quantity - only for HIST records
    CASE WHEN so.HISTSTREAM = 'HIST' THEN so.QTY ELSE 0 END AS DemandQuantityMTS,
    -- Total demand is same as Demand Quantity
    CASE WHEN so.HISTSTREAM = 'HIST' THEN so.QTY ELSE 0 END AS TotalDemand,
    -- Returns quantity - only for RTNS records
    CASE WHEN so.HISTSTREAM = 'RTNS' THEN so.QTY ELSE 0 END AS ReturnsQtyMTS,
    CURRENT_TIMESTAMP() AS ProcessedTimestamp
FROM b_um_xyz.ABC_onetime_history_sales_orders so
LEFT JOIN b_um_xyz.ABC_onetime_history_sales_org_plant_xref xref
    ON so.DMDUNIT = xref.Product AND so.LOC = xref.LOC
WHERE so.HISTSTREAM IN ('HIST', 'RTNS');  -- Only include HIST and RTNS data, exclude FCST