-- ============================================================
-- DAY 4 - TRANSACTION VALIDATION
-- ============================================================

USE order_management;

-- ------------------------------------------------------------
-- 1. Verify baseline
-- ------------------------------------------------------------

SELECT COUNT(*) AS order_count
FROM orders_3nf;

SELECT COUNT(*) AS order_item_count
FROM order_items_3nf;

-- ------------------------------------------------------------
-- 2. Verify committed transaction
-- ------------------------------------------------------------

SELECT *
FROM orders_3nf
WHERE order_id = 9001;

SELECT *
FROM order_items_3nf
WHERE order_id = 9001;

-- ------------------------------------------------------------
-- 3. Verify rollback transaction
-- ------------------------------------------------------------

SELECT *
FROM orders_3nf
WHERE order_id = 9002;

SELECT *
FROM order_items_3nf
WHERE order_id = 9002;

-- Expected:
-- 9001 exists because it was COMMITTED.
-- 9002 does not exist because it was ROLLED BACK.

-- ------------------------------------------------------------
-- 4. Check referential integrity
-- ------------------------------------------------------------

SELECT oi.*
FROM order_items_3nf oi
         LEFT JOIN orders_3nf o
                   ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Expected: empty result set.

-- ------------------------------------------------------------
-- 5. Check invalid quantities
-- ------------------------------------------------------------

SELECT *
FROM order_items_3nf
WHERE quantity <= 0;

-- Expected: empty result set.