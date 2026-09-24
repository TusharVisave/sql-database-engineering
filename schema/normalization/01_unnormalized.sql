-- ============================================================
-- 01 - UNNORMALIZED ORDER SCHEMA
-- ============================================================
-- Purpose:
-- Deliberately demonstrate a poorly designed table before
-- normalization.
--
-- Problems demonstrated:
-- 1. Repeating groups
-- 2. Multiple values stored in one column
-- 3. Data duplication
-- 4. Update anomalies
-- 5. Insert anomalies
-- 6. Delete anomalies
-- ============================================================

DROP TABLE IF EXISTS orders_unnormalized;

CREATE TABLE orders_unnormalized (
                                     order_id INT PRIMARY KEY,
                                     customer_id INT,
                                     customer_name VARCHAR(100),
                                     customer_email VARCHAR(150),

                                     product_ids VARCHAR(255),
                                     product_names VARCHAR(255),
                                     product_prices VARCHAR(255),
                                     quantities VARCHAR(255),

                                     order_date DATE
);

-- ============================================================
-- Sample data
-- ============================================================

INSERT INTO orders_unnormalized (
    order_id,
    customer_id,
    customer_name,
    customer_email,
    product_ids,
    product_names,
    product_prices,
    quantities,
    order_date
)
VALUES
    (
        1001,
        1,
        'Rahul Sharma',
        'rahul@example.com',
        '101,102',
        'Keyboard,Mouse',
        '2500.00,800.00',
        '1,2',
        '2026-09-20'
    ),
    (
        1002,
        2,
        'Priya Patil',
        'priya@example.com',
        '103',
        'Monitor',
        '12000.00',
        '1',
        '2026-09-21'
    ),
    (
        1003,
        1,
        'Rahul Sharma',
        'rahul@example.com',
        '101,104',
        'Keyboard,USB Cable',
        '2500.00,300.00',
        '1,3',
        '2026-09-22'
    );

-- ============================================================
-- Inspect data
-- ============================================================

SELECT *
FROM orders_unnormalized;

-- ============================================================
-- Demonstration of the problem
-- ============================================================
-- Product information is stored as comma-separated values.
-- This makes querying individual products difficult.
--
-- Example:
-- product_ids = '101,102'
-- product_names = 'Keyboard,Mouse'
-- quantities = '1,2'
--
-- These are not atomic values.
-- ============================================================