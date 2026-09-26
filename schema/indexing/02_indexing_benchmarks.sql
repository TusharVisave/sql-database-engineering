-- ============================================================
-- 02 - INDEXING BENCHMARKS & QUERY PLAN ANALYSIS
-- ============================================================
-- Purpose:
-- Benchmark query performance and query execution plans before and
-- after creating B-tree indexes on a 10,000-row `orders` table.
--
-- Target Query:
-- SELECT * FROM orders WHERE customer_email = 'sophia.miller@example.com';
-- ============================================================

USE order_management;

-- ------------------------------------------------------------
-- STEP 1: Verify Initial Table State & Existing Indexes
-- ------------------------------------------------------------
-- Note: Initially, only the PRIMARY KEY index (Clustered Index) exists.

SHOW INDEX FROM orders;


-- ------------------------------------------------------------
-- STEP 2: Baseline Query Plan WITHOUT Index (Full Table Scan)
-- ------------------------------------------------------------
-- The storage engine must inspect every single row in the table (10,000 rows)
-- because customer_email values are unordered across the data pages.

-- Traditional tabular explain
EXPLAIN
SELECT *
FROM orders
WHERE customer_email = 'sophia.miller@example.com';

-- Detailed JSON execution plan with optimizer cost estimates
EXPLAIN FORMAT=JSON
SELECT *
FROM orders
WHERE customer_email = 'sophia.miller@example.com';

-- Real-time execution profile (actual execution time, cost, rows read)
EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE customer_email = 'sophia.miller@example.com';


-- ------------------------------------------------------------
-- STEP 3: Add Secondary B-Tree Index on `customer_email`
-- ------------------------------------------------------------
-- Creates a separate B+ tree structure ordered alphabetically by email.
-- Each leaf node stores: (customer_email, order_id [PK]).

CREATE INDEX idx_orders_customer_email ON orders (customer_email);

-- Verify the new index is active
SHOW INDEX FROM orders;


-- ------------------------------------------------------------
-- STEP 4: Query Plan WITH B-Tree Index (Index Ref Lookup)
-- ------------------------------------------------------------
-- The optimizer now performs a B-Tree search (Root -> Branch -> Leaf)
-- to locate the exact 5 matching keys, then fetches only those 5 rows
-- from the clustered index via the primary key (bookmark lookup).

EXPLAIN
SELECT *
FROM orders
WHERE customer_email = 'sophia.miller@example.com';

EXPLAIN FORMAT=JSON
SELECT *
FROM orders
WHERE customer_email = 'sophia.miller@example.com';

EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE customer_email = 'sophia.miller@example.com';


-- ------------------------------------------------------------
-- STEP 5: Composite Index vs Single-Column Index
-- ------------------------------------------------------------
-- Scenario: Query frequently filters by BOTH customer_email AND order_date.

-- 5A. Query using only single-column index:
-- MySQL uses idx_orders_customer_email to find rows, then checks order_date in memory.
EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE customer_email = 'sophia.miller@example.com'
  AND order_date >= '2026-01-01';

-- 5B. Add Composite Index (customer_email, order_date):
-- Keys are sorted first by customer_email, then by order_date.
CREATE INDEX idx_orders_email_date ON orders (customer_email, order_date);

-- 5C. Query using composite index:
-- Both conditions are evaluated directly within the B-Tree range scan.
EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE customer_email = 'sophia.miller@example.com'
  AND order_date >= '2026-01-01';


-- ------------------------------------------------------------
-- STEP 6: Covering Index Demonstration (`Using index`)
-- ------------------------------------------------------------
-- When all requested SELECT columns are in the index leaf nodes,
-- MySQL avoids reading the table rows entirely (Zero table access).

EXPLAIN
SELECT customer_email, order_date
FROM orders
WHERE customer_email = 'sophia.miller@example.com';


-- ------------------------------------------------------------
-- STEP 7: Measure Physical Storage Overhead of Indexes
-- ------------------------------------------------------------

SELECT
    table_name AS `Table`,
    ROUND(data_length / 1024, 2) AS `Data Size (KB)`,
    ROUND(index_length / 1024, 2) AS `Index Size (KB)`,
    ROUND((data_length + index_length) / 1024, 2) AS `Total Size (KB)`
FROM information_schema.tables
WHERE table_schema = 'order_management'
  AND table_name = 'orders';
