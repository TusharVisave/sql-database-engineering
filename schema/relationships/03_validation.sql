USE order_management;

-- ============================================================
-- DAY 2 VALIDATION
-- ============================================================

-- ------------------------------------------------------------
-- 1. Insert categories
-- ------------------------------------------------------------

INSERT IGNORE INTO categories (category_id, category_name, description)
VALUES
    (1, 'Electronics', 'Electronic products'),
    (2, 'Computers', 'Computers and computing devices'),
    (3, 'Accessories', 'Computer and electronic accessories'),
    (4, 'Office', 'Office-related products');


-- ------------------------------------------------------------
-- 2. Display categories
-- ------------------------------------------------------------

SELECT *
FROM categories;


-- ------------------------------------------------------------
-- 3. Display existing products (from 3NF schema)
-- ------------------------------------------------------------

SELECT *
FROM products_3nf;


-- ------------------------------------------------------------
-- 4. Assign products to categories (Many-to-Many junction table)
-- ------------------------------------------------------------

INSERT IGNORE INTO product_categories (product_id, category_id)
VALUES
    (101, 1), -- Keyboard -> Electronics
    (101, 3), -- Keyboard -> Accessories
    (102, 1), -- Mouse -> Electronics
    (102, 3), -- Mouse -> Accessories
    (103, 1), -- Monitor -> Electronics
    (103, 2), -- Monitor -> Computers
    (103, 4), -- Monitor -> Office
    (104, 1), -- USB Cable -> Electronics
    (104, 3); -- USB Cable -> Accessories


-- ------------------------------------------------------------
-- 5. Display product categories junction table
-- ------------------------------------------------------------

SELECT *
FROM product_categories
ORDER BY product_id, category_id;


-- ------------------------------------------------------------
-- 6. Many-to-Many Join: Products with their assigned categories
-- ------------------------------------------------------------

SELECT
    p.product_id,
    p.product_name,
    p.product_price,
    c.category_name,
    pc.assigned_at
FROM products_3nf p
         JOIN product_categories pc
              ON p.product_id = pc.product_id
         JOIN categories c
              ON pc.category_id = c.category_id
ORDER BY p.product_id, c.category_name;


-- ------------------------------------------------------------
-- 7. Aggregation: Count of products per category
-- ------------------------------------------------------------

SELECT
    c.category_id,
    c.category_name,
    COUNT(pc.product_id) AS product_count
FROM categories c
         LEFT JOIN product_categories pc
                   ON c.category_id = pc.category_id
GROUP BY c.category_id, c.category_name
ORDER BY product_count DESC;


-- ------------------------------------------------------------
-- 8. Verify Referential Integrity: Check for invalid category mappings
-- ------------------------------------------------------------

SELECT pc.*
FROM product_categories pc
         LEFT JOIN products_3nf p
                   ON pc.product_id = p.product_id
WHERE p.product_id IS NULL;