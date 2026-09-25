USE order_management;

-- ============================================================
-- DAY 2 VALIDATION
-- ============================================================

-- ------------------------------------------------------------
-- 1. Insert categories
-- ------------------------------------------------------------

INSERT INTO categories (category_name, description)
VALUES
    ('Electronics', 'Electronic products'),
    ('Computers', 'Computers and computing devices'),
    ('Accessories', 'Computer and electronic accessories'),
    ('Office', 'Office-related products');


-- ------------------------------------------------------------
-- 2. Display categories
-- ------------------------------------------------------------

SELECT *
FROM categories;


-- ------------------------------------------------------------
-- 3. Display existing products
-- ------------------------------------------------------------

SELECT *
FROM products_3nf;