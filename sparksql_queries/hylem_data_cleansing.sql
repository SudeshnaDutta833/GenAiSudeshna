%sql
-- Step 1: Create a temporary view to identify probable duplicate customers based on fuzzy matching
CREATE OR REPLACE TEMPORARY VIEW customer_duplicates AS
WITH fuzzy_matches AS (
  SELECT 
    a.UniqueCustomerId as id1, 
    b.UniqueCustomerId as id2,
    a.CustomerName as name1,
    b.CustomerName as name2,
    a.Address as addr1,
    b.Address as addr2,
    -- Using levenshtein distance for fuzzy matching of names and addresses
    levenshtein(lower(trim(a.CustomerName)), lower(trim(b.CustomerName))) as name_distance,
    levenshtein(lower(trim(a.Address)), lower(trim(b.Address))) as addr_distance
  FROM b_Hylem.customers a
  JOIN b_Hylem.customers b 
  ON a.UniqueCustomerId < b.UniqueCustomerId -- Avoid self-joins and duplicates
  WHERE 
    -- Fuzzy match conditions for names and addresses
    levenshtein(lower(trim(a.CustomerName)), lower(trim(b.CustomerName))) <= 3 
    AND levenshtein(lower(trim(a.Address)), lower(trim(b.Address))) <= 5
)
SELECT 
  id1, 
  id2,
  name1,
  name2,
  addr1,
  addr2,
  name_distance,
  addr_distance,
  -- Calculate combined fuzzy score (lower is better match)
  (name_distance + addr_distance) as combined_score
FROM fuzzy_matches
ORDER BY combined_score ASC;

%sql
-- Step 2: Create a view for duplicate products based on fuzzy matching of item names
CREATE OR REPLACE TEMPORARY VIEW product_duplicates AS
WITH fuzzy_matches AS (
  SELECT 
    a.UniqueProductId as id1, 
    b.UniqueProductId as id2,
    a.ItemName as name1,
    b.ItemName as name2,
    -- Using levenshtein distance for fuzzy matching of product names
    levenshtein(lower(trim(a.ItemName)), lower(trim(b.ItemName))) as name_distance
  FROM b_Hylem.products a
  JOIN b_Hylem.products b 
  ON a.UniqueProductId < b.UniqueProductId -- Avoid self-joins and duplicates
  WHERE 
    -- Fuzzy match conditions for product names
    levenshtein(lower(trim(a.ItemName)), lower(trim(b.ItemName))) <= 3
)
SELECT 
  id1, 
  id2,
  name1,
  name2,
  name_distance
FROM fuzzy_matches
ORDER BY name_distance ASC;

%sql
-- Step 3: Update customers table to mark duplicates (one-time historical data update)
-- This creates a new column to flag duplicates
CREATE OR REPLACE TABLE b_Hylem.customers_dedupe AS
SELECT 
  c.*,
  CASE 
    WHEN d.id1 IS NOT NULL THEN true
    WHEN d.id2 IS NOT NULL THEN true
    ELSE false
  END AS is_duplicate,
  CASE
    WHEN d.id1 IS NOT NULL THEN d.id2
    WHEN d.id2 IS NOT NULL THEN d.id1
    ELSE NULL
  END AS duplicate_of_id
FROM b_Hylem.customers c
LEFT JOIN customer_duplicates d ON c.UniqueCustomerId = d.id1 OR c.UniqueCustomerId = d.id2;

%sql
-- Step 4: Update products table to mark duplicates (one-time historical data update)
CREATE OR REPLACE TABLE b_Hylem.products_dedupe AS
SELECT 
  p.*,
  CASE 
    WHEN d.id1 IS NOT NULL THEN true
    WHEN d.id2 IS NOT NULL THEN true
    ELSE false
  END AS is_duplicate,
  CASE
    WHEN d.id1 IS NOT NULL THEN d.id2
    WHEN d.id2 IS NOT NULL THEN d.id1
    ELSE NULL
  END AS duplicate_of_id
FROM b_Hylem.products p
LEFT JOIN product_duplicates d ON p.UniqueProductId = d.id1 OR p.UniqueProductId = d.id2;

%sql
-- Step 5: Create a silver layer view for cleansed customers
CREATE OR REPLACE VIEW s_Hylem.customers AS
SELECT
  UniqueCustomerId,
  UniqueCustomerIdNew,
  CustomerName,
  Address,
  City,
  State,
  ZipCode,
  Country,
  Phone,
  Email,
  is_duplicate,
  duplicate_of_id,
  -- Additional columns as needed
  CURRENT_TIMESTAMP() AS last_updated
FROM b_Hylem.customers_dedupe
WHERE NOT is_duplicate OR duplicate_of_id IS NULL;

%sql
-- Step 6: Create a silver layer view for cleansed products
CREATE OR REPLACE VIEW s_Hylem.products AS
SELECT
  UniqueProductId,
  UniqueProductIdNew,
  ItemName,
  Description,
  Category,
  SubCategory,
  UnitPrice,
  is_duplicate,
  duplicate_of_id,
  -- Additional columns as needed
  CURRENT_TIMESTAMP() AS last_updated
FROM b_Hylem.products_dedupe
WHERE NOT is_duplicate OR duplicate_of_id IS NULL;

%sql
-- Step 7: Update sales data for anomalies (Qty<1 or Price<1)
CREATE OR REPLACE TABLE b_Hylem.sales_cleansed AS
WITH MedianPrices AS (
  SELECT 
    UniqueProductId,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Price) OVER (PARTITION BY UniqueProductId) AS median_price
  FROM b_Hylem.sales
  WHERE Price > 0 AND Quantity > 0
)
SELECT 
  s.SalesId,
  s.UniqueCustomerId,
  s.UniqueProductId,
  -- Fix anomalous quantities
  CASE 
    WHEN s.Quantity < 1 THEN 1
    ELSE s.Quantity
  END AS Quantity,
  -- Fix anomalous prices or prices that deviate by more than 20% from median
  CASE 
    WHEN s.Price < 1 THEN m.median_price
    WHEN ABS(s.Price - m.median_price) / m.median_price > 0.2 THEN m.median_price
    ELSE s.Price
  END AS Price,
  s.SaleDate,
  CASE 
    WHEN s.Quantity < 1 OR s.Price < 1 OR (ABS(s.Price - m.median_price) / m.median_price > 0.2) THEN true
    ELSE false
  END AS was_corrected,
  s.OriginalPrice,
  s.Discount,
  -- Additional columns as needed
  CURRENT_TIMESTAMP() AS last_updated
FROM b_Hylem.sales s
JOIN MedianPrices m ON s.UniqueProductId = m.UniqueProductId;

%sql
-- Step 8: Create a silver layer view for cleansed sales data
CREATE OR REPLACE VIEW s_Hylem.sales AS
SELECT
  SalesId,
  -- Use non-duplicate customer and product IDs
  COALESCE(c.duplicate_of_id, s.UniqueCustomerId) AS UniqueCustomerId,
  COALESCE(p.duplicate_of_id, s.UniqueProductId) AS UniqueProductId,
  Quantity,
  Price,
  SaleDate,
  was_corrected,
  OriginalPrice,
  Discount,
  -- Additional columns as needed
  CURRENT_TIMESTAMP() AS last_updated
FROM b_Hylem.sales_cleansed s
LEFT JOIN b_Hylem.customers_dedupe c ON s.UniqueCustomerId = c.UniqueCustomerId AND c.is_duplicate = true
LEFT JOIN b_Hylem.products_dedupe p ON s.UniqueProductId = p.UniqueProductId AND p.is_duplicate = true;

%sql
-- Step 9: Create gold layer view for customer analytics with deduplication
CREATE OR REPLACE VIEW g_Hylem.customer_analytics AS
SELECT
  c.UniqueCustomerId,
  c.UniqueCustomerIdNew,
  c.CustomerName,
  c.Address,
  c.City,
  c.State,
  c.ZipCode,
  c.Country,
  COUNT(s.SalesId) AS total_transactions,
  SUM(s.Quantity * s.Price) AS total_sales_amount,
  MIN(s.SaleDate) AS first_purchase_date,
  MAX(s.SaleDate) AS last_purchase_date
FROM s_Hylem.customers c
LEFT JOIN s_Hylem.sales s ON c.UniqueCustomerId = s.UniqueCustomerId
GROUP BY 
  c.UniqueCustomerId,
  c.UniqueCustomerIdNew,
  c.CustomerName,
  c.Address,
  c.City,
  c.State,
  c.ZipCode,
  c.Country;

%sql
-- Step 10: Create gold layer view for product analytics with deduplication
CREATE OR REPLACE VIEW g_Hylem.product_analytics AS
SELECT
  p.UniqueProductId,
  p.UniqueProductIdNew,
  p.ItemName,
  p.Category,
  p.SubCategory,
  COUNT(s.SalesId) AS total_transactions,
  SUM(s.Quantity) AS total_quantity_sold,
  SUM(s.Quantity * s.Price) AS total_sales_amount,
  AVG(s.Price) AS average_selling_price
FROM s_Hylem.products p
LEFT JOIN s_Hylem.sales s ON p.UniqueProductId = s.UniqueProductId
GROUP BY 
  p.UniqueProductId,
  p.UniqueProductIdNew,
  p.ItemName,
  p.Category,
  p.SubCategory;