-- Silver Layer Transformation - SQL Code

%sql
INSERT INTO s_onc.sales_ord_his
SELECT 
    '001' as ApoPlanningVersion,
    s.DmdUnit as ApmModelNumber,
    s.DmdUnit as ProductPlannerCode,
    LEFT(TRIM(s.Loc), 2) as Country,
    CONCAT(s.Loc, COALESCE(so.Region, '')) as SalesOffice,
    CASE 
        WHEN so.SalesOrg IS NULL OR TRIM(so.SalesOrg) = '' 
        THEN s.Loc 
        ELSE so.SalesOrg 
    END as SalesOrganization,
    CASE 
        WHEN so.PlantDc IS NULL OR TRIM(so.PlantDc) = '' 
        THEN s.Loc 
        ELSE so.PlantDc 
    END as Plant,
    CASE 
        WHEN UPPER(s.DmdGroup) = 'SALES' THEN 'R'
        WHEN UPPER(s.DmdGroup) = 'SAMPLES' THEN 'N'
        WHEN UPPER(s.DmdGroup) = 'CONSIGN' THEN 'C'
        ELSE s.DmdGroup
    END as PlanningPartner,
    '10' as DistributionChannel,
    '500' as CustomerGroup,
    'NONE' as ShipToParty,
    'NONE' as SoldToParty,
    'None' as WwBusiness,
    'None' as StrategyCenter,
    'None' as ProductLine,
    'None' as PlanningSet,
    'None' as ProductSubset,
    'None' as ItemCategory,
    'None' as SalesDocumentType,
    DATE_FORMAT(CURRENT_TIMESTAMP(), 'yyyyMMddHH') as SnapshotId,
    CAST(DATE_FORMAT(TO_DATE(s.StartDate, 'yyyy-MM-dd'), 'yyyyMM') AS INT) as CalMonth,
    'EA' as BaseUnitOfMeasure,
    'JDAAPM' as SourceSystem,
    CASE 
        WHEN UPPER(s.HistStream) = 'ACTUAL SALES QTY' THEN s.Qty
        ELSE 0
    END as DemandQuantityMts,
    CASE 
        WHEN UPPER(s.HistStream) = 'ACTUAL SALES QTY' THEN s.Qty
        ELSE 0
    END as TotalDemand,
    CASE 
        WHEN UPPER(s.HistStream) = 'RETURN QTY' THEN s.Qty
        ELSE 0
    END as ReturnsQtyMts,
    CURRENT_TIMESTAMP() as ProcessedTimestamp
FROM b_onc.sales s
LEFT JOIN b_onc.sales_org so ON s.Loc = so.Loc
WHERE s.StartDate IS NOT NULL 
  AND s.DmdUnit IS NOT NULL
  AND s.Qty IS NOT NULL;

%sql
-- Optimize silver table after load
OPTIMIZE s_onc.sales_ord_his;

%sql
-- Update table statistics
ANALYZE TABLE s_onc.sales_ord_his COMPUTE STATISTICS;