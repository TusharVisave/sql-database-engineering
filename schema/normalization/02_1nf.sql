-- ============================================================
-- 02 - FIRST NORMAL FORM (1NF)
-- ============================================================
-- 1NF requirements:
-- 1. Each column contains atomic values.
-- 2. No comma-separated lists.
-- 3. No repeating groups.
-- 4. Each row represents one logical record.
--
-- At this stage we remove the repeating product groups.
-- ============================================================

DROP TABLE IF EXISTS orders_1nf;

CREATE TABLE orders_1nf (
                            order_id INT,
                            customer_id INT,
                            customer_name VARCHAR(100),
                            customer_email VARCHAR(150),

                            product_id INT,
                            product_name VARCHAR(100),
                            product_price DECIMAL(10, 2),
                            quantity INT,

                            order_date DATE,

                            PRIMARY KEY (order_id, product_id)
);

-- ============================================================
-- Sample data
-- ============================================================

INSERT INTO orders_1nf (
    order_id,
    customer_id,
    customer_name,
    customer_email,
    product_id,
    product_name,
    product_price,
    quantity,
    order_date
)
VALUES
    (
        1001,
        1,
        'Rahul Sharma',
        'rahul@example.com',
        101,
        'Keyboard',
        2500.00,
        1,
        '2026-09-20'
    ),
    (
        1001,
        1,
        'Rahul Sharma',
        'rahul@example.com',
        102,
        'Mouse',
        800.00,
        2,
        '2026-09-20'
    ),
    (
        1002,
        2,
        'Priya Patil',
        'priya@example.com',
        103,
        'Monitor',
        12000.00,
        1,
        '2026-09-21'
    ),
    (
        1003,
        1,
        'Rahul Sharma',
        'rahul@example.com',
        101,
        'Keyboard',
        2500.00,
        1,
        '2026-09-22'
    ),
    (
        1003,
        1,
        'Rahul Sharma',
        'rahul@example.com',
        104,
        'USB Cable',
        300.00,
        3,
        '2026-09-22'
    );

-- ============================================================
-- Validation
-- ============================================================

SELECT *
FROM orders_1nf
ORDER BY order_id, product_id;

-- Every product now occupies its own row.
-- There are no comma-separated product lists.