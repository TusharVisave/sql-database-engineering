-- ============================================================
-- DAY 4 - TRANSACTION ROLLBACK
-- ============================================================
-- Demonstrates that related changes are discarded together
-- when a transaction fails.
-- ============================================================

USE order_management;

-- ------------------------------------------------------------
-- Clean up from previous manual executions
-- ------------------------------------------------------------

DELETE FROM order_items_3nf
WHERE order_id = 9002;

DELETE FROM orders_3nf
WHERE order_id = 9002;

-- ------------------------------------------------------------
-- Start transaction
-- ------------------------------------------------------------

START TRANSACTION;

-- Create order

INSERT INTO orders_3nf (
    order_id,
    customer_id,
    order_date
)
VALUES (
           9002,
           1,
           CURRENT_DATE
       );

-- Create first order item

INSERT INTO order_items_3nf (
    order_id,
    product_id,
    quantity
)
VALUES (
           9002,
           101,
           2
       );

-- ------------------------------------------------------------
-- Simulate a failure:
-- product_id 999999 does not exist.
--
-- The foreign-key constraint should reject this statement.
-- ------------------------------------------------------------

INSERT INTO order_items_3nf (
    order_id,
    product_id,
    quantity
)
VALUES (
           9002,
           999999,
           1
       );

-- ------------------------------------------------------------
-- Because the transaction encountered an error,
-- explicitly roll back.
-- ------------------------------------------------------------

ROLLBACK;

-- ------------------------------------------------------------
-- Verify that the order and its first item were removed.
-- ------------------------------------------------------------

SELECT *
FROM orders_3nf
WHERE order_id = 9002;

SELECT *
FROM order_items_3nf
WHERE order_id = 9002;