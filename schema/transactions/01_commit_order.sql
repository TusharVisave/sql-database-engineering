-- ============================================================
-- DAY 4 - TRANSACTION COMMIT
-- ============================================================
-- Demonstrates atomic creation of an order and its order items.
-- ============================================================

USE order_management;

START TRANSACTION;

-- ------------------------------------------------------------
-- 1. Create a new order
-- ------------------------------------------------------------

INSERT INTO orders_3nf (
    order_id,
    customer_id,
    order_date
)
VALUES (
           9001,
           1,
           CURRENT_DATE
       );

-- ------------------------------------------------------------
-- 2. Add order items
-- ------------------------------------------------------------

INSERT INTO order_items_3nf (
    order_id,
    product_id,
    quantity
)
VALUES
    (9001, 101, 2),
    (9001, 102, 1);

-- ------------------------------------------------------------
-- 3. Verify transaction contents before COMMIT
-- ------------------------------------------------------------

SELECT
    o.order_id,
    o.customer_id,
    o.order_date,
    oi.product_id,
    oi.quantity
FROM orders_3nf o
         JOIN order_items_3nf oi
              ON o.order_id = oi.order_id
WHERE o.order_id = 9001;

-- ------------------------------------------------------------
-- 4. Permanently save the transaction
-- ------------------------------------------------------------

COMMIT;

-- ------------------------------------------------------------
-- 5. Verify committed data
-- ------------------------------------------------------------

SELECT *
FROM orders_3nf
WHERE order_id = 9001;

SELECT *
FROM order_items_3nf
WHERE order_id = 9001;