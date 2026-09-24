-- ============================================================
-- 04 - THIRD NORMAL FORM (3NF)
-- ============================================================
-- 3NF requirements:
--
-- 1. Table must already be in 2NF.
-- 2. No transitive dependencies.
--
-- Previous dependency:
--
-- order_id
--    -> customer_id
--        -> customer_name
--        -> customer_email
--
-- Customer information therefore belongs in a separate
-- customers table.
--
-- Final structure:
--
-- customers
--     |
--     v
-- orders
--     |
--     v
-- order_items
--     ^
--     |
-- products
-- ============================================================

-- ============================================================
-- Drop tables if they already exist
-- ============================================================

DROP TABLE IF EXISTS order_items_3nf;
DROP TABLE IF EXISTS orders_3nf;
DROP TABLE IF EXISTS products_3nf;
DROP TABLE IF EXISTS customers_3nf;

-- ============================================================
-- CUSTOMERS
-- ============================================================

CREATE TABLE customers_3nf (
                               customer_id INT PRIMARY KEY,

                               customer_name VARCHAR(100) NOT NULL,

                               customer_email VARCHAR(150) NOT NULL,

                               CONSTRAINT uq_customer_email
                                   UNIQUE (customer_email)
);

-- ============================================================
-- PRODUCTS
-- ============================================================

CREATE TABLE products_3nf (
                              product_id INT PRIMARY KEY,

                              product_name VARCHAR(100) NOT NULL,

                              product_price DECIMAL(10, 2) NOT NULL,

                              CONSTRAINT chk_product_price
                                  CHECK (product_price >= 0)
);

-- ============================================================
-- ORDERS
-- ============================================================

CREATE TABLE orders_3nf (
                            order_id INT PRIMARY KEY,

                            customer_id INT NOT NULL,

                            order_date DATE NOT NULL,

                            CONSTRAINT fk_orders_customer
                                FOREIGN KEY (customer_id)
                                    REFERENCES customers_3nf(customer_id)
);

-- ============================================================
-- ORDER ITEMS
-- ============================================================

CREATE TABLE order_items_3nf (
                                 order_id INT NOT NULL,

                                 product_id INT NOT NULL,

                                 quantity INT NOT NULL,

                                 PRIMARY KEY (order_id, product_id),

                                 CONSTRAINT fk_order_items_order
                                     FOREIGN KEY (order_id)
                                         REFERENCES orders_3nf(order_id),

                                 CONSTRAINT fk_order_items_product
                                     FOREIGN KEY (product_id)
                                         REFERENCES products_3nf(product_id),

                                 CONSTRAINT chk_order_item_quantity
                                     CHECK (quantity > 0)
);

-- ============================================================
-- CUSTOMERS DATA
-- ============================================================

INSERT INTO customers_3nf (
    customer_id,
    customer_name,
    customer_email
)
VALUES
    (1, 'Rahul Sharma', 'rahul@example.com'),
    (2, 'Priya Patil', 'priya@example.com');

-- ============================================================
-- PRODUCTS DATA
-- ============================================================

INSERT INTO products_3nf (
    product_id,
    product_name,
    product_price
)
VALUES
    (101, 'Keyboard', 2500.00),
    (102, 'Mouse', 800.00),
    (103, 'Monitor', 12000.00),
    (104, 'USB Cable', 300.00);

-- ============================================================
-- ORDERS DATA
-- ============================================================

INSERT INTO orders_3nf (
    order_id,
    customer_id,
    order_date
)
VALUES
    (1001, 1, '2026-09-20'),
    (1002, 2, '2026-09-21'),
    (1003, 1, '2026-09-22');

-- ============================================================
-- ORDER ITEMS DATA
-- ============================================================

INSERT INTO order_items_3nf (
    order_id,
    product_id,
    quantity
)
VALUES
    (1001, 101, 1),
    (1001, 102, 2),
    (1002, 103, 1),
    (1003, 101, 1),
    (1003, 104, 3);

-- ============================================================
-- BASIC VALIDATION
-- ============================================================

SELECT *
FROM customers_3nf;

SELECT *
FROM products_3nf;

SELECT *
FROM orders_3nf;

SELECT *
FROM order_items_3nf;

-- ============================================================
-- JOIN VALIDATION
-- ============================================================

SELECT
    o.order_id,
    o.order_date,
    c.customer_name,
    c.customer_email,
    p.product_name,
    p.product_price,
    oi.quantity,
    (p.product_price * oi.quantity) AS line_total
FROM orders_3nf o
         JOIN customers_3nf c
              ON o.customer_id = c.customer_id
         JOIN order_items_3nf oi
              ON o.order_id = oi.order_id
         JOIN products_3nf p
              ON oi.product_id = p.product_id
ORDER BY o.order_id, p.product_id;

-- ============================================================
-- ORDER TOTALS
-- ============================================================

SELECT
    o.order_id,
    c.customer_name,
    SUM(p.product_price * oi.quantity) AS order_total
FROM orders_3nf o
         JOIN customers_3nf c
              ON o.customer_id = c.customer_id
         JOIN order_items_3nf oi
              ON o.order_id = oi.order_id
         JOIN products_3nf p
              ON oi.product_id = p.product_id
GROUP BY
    o.order_id,
    c.customer_name
ORDER BY o.order_id;