-- ============================================================
-- 05 - NORMALIZATION VALIDATION
-- ============================================================

-- ============================================================
-- 1. Inspect table structures
-- ============================================================

DESCRIBE customers_3nf;

DESCRIBE products_3nf;

DESCRIBE orders_3nf;

DESCRIBE order_items_3nf;


-- ============================================================
-- 2. Check customers
-- ============================================================

SELECT *
FROM customers_3nf;


-- ============================================================
-- 3. Check products
-- ============================================================

SELECT *
FROM products_3nf;


-- ============================================================
-- 4. Check orders
-- ============================================================

SELECT *
FROM orders_3nf;


-- ============================================================
-- 5. Check order items
-- ============================================================

SELECT *
FROM order_items_3nf;


-- ============================================================
-- 6. Verify complete order information
-- ============================================================

SELECT
    o.order_id,
    o.order_date,
    c.customer_name,
    c.customer_email,
    p.product_name,
    p.product_price,
    oi.quantity,
    p.product_price * oi.quantity AS line_total
FROM orders_3nf o
         INNER JOIN customers_3nf c
                    ON o.customer_id = c.customer_id
         INNER JOIN order_items_3nf oi
                    ON o.order_id = oi.order_id
         INNER JOIN products_3nf p
                    ON oi.product_id = p.product_id
ORDER BY
    o.order_id,
    p.product_id;


-- ============================================================
-- 7. Calculate order totals
-- ============================================================

SELECT
    o.order_id,
    c.customer_name,
    SUM(p.product_price * oi.quantity) AS order_total
FROM orders_3nf o
         INNER JOIN customers_3nf c
                    ON o.customer_id = c.customer_id
         INNER JOIN order_items_3nf oi
                    ON o.order_id = oi.order_id
         INNER JOIN products_3nf p
                    ON oi.product_id = p.product_id
GROUP BY
    o.order_id,
    c.customer_name
ORDER BY
    o.order_id;


-- ============================================================
-- 8. Check for duplicate customer emails
-- ============================================================

SELECT
    customer_email,
    COUNT(*) AS occurrences
FROM customers_3nf
GROUP BY customer_email
HAVING COUNT(*) > 1;


-- Expected result:
-- Empty result set.


-- ============================================================
-- 9. Check for invalid quantities
-- ============================================================

SELECT *
FROM order_items_3nf
WHERE quantity <= 0;


-- Expected result:
-- Empty result set.


-- ============================================================
-- 10. Check for products with invalid prices
-- ============================================================

SELECT *
FROM products_3nf
WHERE product_price < 0;


-- Expected result:
-- Empty result set.


-- ============================================================
-- 11. Check orphan order items
-- ============================================================

SELECT oi.*
FROM order_items_3nf oi
         LEFT JOIN orders_3nf o
                   ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;


-- Expected result:
-- Empty result set.


-- ============================================================
-- 12. Check orphan products
-- ============================================================

SELECT oi.*
FROM order_items_3nf oi
         LEFT JOIN products_3nf p
                   ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;


-- Expected result:
-- Empty result set.