-- Validation query to check if the APM historical data was loaded correctly
%sql
SELECT COUNT(*) as total_records,
       COUNT(DISTINCT product) as distinct_products,
       COUNT(DISTINCT loc) as distinct_locations,
       SUM(CASE WHEN histstream = 'HIST' THEN 1 ELSE 0 END) as hist_records,
       SUM(CASE WHEN histstream = 'RTNS' THEN 1 ELSE 0 END) as returns_records,
       SUM(CASE WHEN histstream = 'FCST' THEN 1 ELSE 0 END) as forecast_records
FROM bronze.apm_historical_data;

-- Validation query to check if regional mapping data was loaded correctly
%sql
SELECT COUNT(*) as total_mappings,
       COUNT(DISTINCT product) as distinct_products,
       COUNT(DISTINCT loc) as distinct_locations,
       COUNT(DISTINCT region) as distinct_regions,
       COUNT(DISTINCT bd_sales_org) as distinct_sales_orgs,
       COUNT(DISTINCT bd_plant) as distinct_plants
FROM bronze.apm_regional_mapping;

-- Validation query to check the enriched data in silver layer
%sql
SELECT COUNT(*) as total_records,
       COUNT(DISTINCT product) as distinct_products,
       COUNT(DISTINCT sales_organization) as distinct_sales_orgs,
       COUNT(DISTINCT region) as distinct_regions,
       COUNT(DISTINCT sales_office) as distinct_sales_offices,
       COUNT(DISTINCT plant) as distinct_plants,
       COUNT(DISTINCT planning_partner) as distinct_planning_partners,
       SUM(CASE WHEN planning_partner = 'R' THEN 1 ELSE 0 END) as revenue_records,
       SUM(CASE WHEN planning_partner = 'N' THEN 1 ELSE 0 END) as non_revenue_records,
       SUM(CASE WHEN planning_partner = 'C' THEN 1 ELSE 0 END) as consignment_records
FROM silver.apm_sales_history;

-- Validation query to check the gold layer data
%sql
SELECT region, 
       sales_organization, 
       COUNT(*) as record_count,
       SUM(demand_quantity) as total_demand,
       SUM(return_quantity) as total_returns
FROM gold.apm_demand_history
GROUP BY region, sales_organization
ORDER BY region, sales_organization;

-- Validation query for ECC delta load data (Version 2)
%sql
SELECT COUNT(*) as total_records,
       COUNT(DISTINCT material) as distinct_products,
       COUNT(DISTINCT sales_document) as distinct_sales_docs,
       COUNT(DISTINCT ship_to_country) as distinct_countries,
       COUNT(DISTINCT customer_classification) as distinct_cust_class,
       SUM(CASE WHEN planning_partner = 'R' THEN 1 ELSE 0 END) as revenue_records,
       SUM(CASE WHEN planning_partner = 'N' THEN 1 ELSE 0 END) as non_revenue_records,
       SUM(CASE WHEN planning_partner = 'C' THEN 1 ELSE 0 END) as consignment_records
FROM silver.apm_sales_delta;

-- Validation query to check if sales office mapping is correctly applied
%sql
SELECT rm.customer_classification, 
       rm.country,
       rm.sales_office,
       COUNT(sd.sales_document) as order_count
FROM silver.apm_sales_delta sd
JOIN silver.regional_mapping rm 
  ON sd.ship_to_country = rm.country
 AND sd.customer_classification = rm.customer_classification
GROUP BY rm.customer_classification, rm.country, rm.sales_office
ORDER BY order_count DESC;