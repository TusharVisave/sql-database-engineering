USE order_management;

-- ============================================================
-- DAY 2: CATEGORIES
-- ============================================================

CREATE TABLE IF NOT EXISTS categories (
                                          category_id BIGINT PRIMARY KEY AUTO_INCREMENT,

                                          category_name VARCHAR(100) NOT NULL,

    description VARCHAR(255),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_categories_name
    UNIQUE (category_name)
    );