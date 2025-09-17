%sql
-- Validation query to check for NULL or blank customer IDs
SELECT COUNT(*) AS null_blank_customer_ids
FROM b_Hylem.customers
WHERE UniqueCustomerId IS NULL OR TRIM(UniqueCustomerId) = '' 
OR UniqueCustomerIdNew IS NULL OR TRIM(UniqueCustomerIdNew) = '';

%sql
-- Validation query to check for NULL or blank product IDs
SELECT COUNT(*) AS null_blank_product_ids
FROM b_Hylem.products
WHERE UniqueProductId IS NULL OR TRIM(UniqueProductId) = '' 
OR UniqueProductIdNew IS NULL OR TRIM(UniqueProductIdNew) = '';

%sql
-- Validation query to check for anomalies in sales data
SELECT COUNT(*) AS anomalous_sales_records
FROM b_Hylem.sales
WHERE Quantity < 1 OR Price < 1;

%sql
-- Check for duplicate customer records based on name and address
SELECT CustomerName, Address, COUNT(*) as duplicate_count
FROM b_Hylem.customers
GROUP BY CustomerName, Address
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

%sql
-- Check for duplicate product records based on item name
SELECT ItemName, COUNT(*) as duplicate_count
FROM b_Hylem.products
GROUP BY ItemName
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

%sql
-- Validate price deviation from median by SKU
WITH MedianPrices AS (
  SELECT 
    UniqueProductId,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Price) OVER (PARTITION BY UniqueProductId) AS median_price
  FROM b_Hylem.sales
)
SELECT 
  s.UniqueProductId,
  s.Price,
  m.median_price,
  ABS(s.Price - m.median_price) / m.median_price * 100 AS deviation_percentage
FROM b_Hylem.sales s
JOIN MedianPrices m ON s.UniqueProductId = m.UniqueProductId
WHERE ABS(s.Price - m.median_price) / m.median_price > 20
ORDER BY deviation_percentage DESC;