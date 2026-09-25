USE order_management;

-- ============================================================
-- DAY 2: MANY-TO-MANY RELATIONSHIP
--
-- Product <----> Category
--
-- One product can have many categories.
-- One category can contain many products.
--
-- Resolved using:
-- product_categories
-- ============================================================

CREATE TABLE IF NOT EXISTS product_categories (

                                                  product_id BIGINT NOT NULL,

                                                  category_id BIGINT NOT NULL,

                                                  assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

                                                  PRIMARY KEY (product_id, category_id),

    CONSTRAINT fk_product_categories_product
    FOREIGN KEY (product_id)
    REFERENCES products_3nf(product_id)
    ON DELETE CASCADE,

    CONSTRAINT fk_product_categories_category
    FOREIGN KEY (category_id)
    REFERENCES categories(category_id)
    ON DELETE CASCADE
    );