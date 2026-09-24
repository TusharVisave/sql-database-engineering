-- ============================================================
-- 03 - SECOND NORMAL FORM (2NF)
-- ============================================================
-- 2NF requirements:
-- 1. Table must already be in 1NF.
-- 2. No partial dependency on part of a composite key.
--
-- Previous composite key:
--     (order_id, product_id)
--
-- Dependencies:
--
--     order_id
--         -> customer_id
--         -> customer_name
--         -> customer_email
--         -> order_date
--
--     product_id
--         -> product_name
--         -> product_price
--
-- Therefore we separate order-level and product-level data.
-- ============================================================

DROP TABLE IF EXISTS order_items_2nf;
DROP TABLE IF EXISTS orders_2nf;
DROP TABLE IF EXISTS products_2nf;

-- ============================================================
-- Products
-- ============================================================

CREATE TABLE products_2nf (
                              product_id INT PRIMARY KEY,
                              product_name VARCHAR(100) NOT NULL,
                              product_price DECIMAL(10, 2) NOT NULL
);

-- ============================================================
-- Orders
-- ============================================================

CREATE TABLE orders_2nf (
                            order_id INT PRIMARY KEY,
                            customer_id INT NOT NULL,
                            customer_name VARCHAR(100) NOT NULL,
                            customer_email VARCHAR(150) NOT NULL,
                            order_date DATE NOT NULL
);

-- ============================================================
-- Order Items
-- ============================================================

CREATE TABLE order_items_2nf (
                                 order_id INT NOT NULL,
                                 product_id INT NOT NULL,
                                 quantity INT NOT NULL,

                                 PRIMARY KEY (order_id, product_id),

                                 FOREIGN KEY (order_id)
                                     REFERENCES orders_2nf(order_id),

                                 FOREIGN KEY (product_id)
                                     REFERENCES products_2nf(product_id)
);

-- ============================================================
-- Products data
-- ============================================================

INSERT INTO products_2nf (
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
-- Orders data
-- ============================================================

INSERT INTO orders_2nf (
    order_id,
    customer_id,
    customer_name,
    customer_email,
    order_date
)
VALUES
    (1001, 1, 'Rahul Sharma', 'rahul@example.com', '2026-09-20'),
    (1002, 2, 'Priya Patil', 'priya@example.com', '2026-09-21'),
    (1003, 1, 'Rahul Sharma', 'rahul@example.com', '2026-09-22');

-- ============================================================
-- Order items data
-- ============================================================

INSERT INTO order_items_2nf (
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
-- Validation
-- ============================================================

SELECT *
FROM products_2nf;

SELECT *
FROM orders_2nf;

SELECT *
FROM order_items_2nf;