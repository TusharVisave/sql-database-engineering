-- ============================================================
-- 01 - ORDERS SCHEMA FOR INDEXING & PERFORMANCE BENCHMARKS
-- ============================================================
-- Purpose:
-- Define a large-volume orders table to evaluate query performance,
-- query execution plans (EXPLAIN / EXPLAIN ANALYZE), and index overhead.
--
-- Note: Initially created with ONLY the Primary Key (Clustered Index).
-- Secondary indexes on `customer_email` or composite keys are intentionally
-- omitted here to benchmark unindexed Full Table Scans vs indexed lookups.
-- ============================================================

CREATE DATABASE IF NOT EXISTS order_management;
USE order_management;

DROP TABLE IF EXISTS orders;

CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    customer_email VARCHAR(150) NOT NULL,
    order_amount DECIMAL(10, 2) NOT NULL,
    order_status VARCHAR(50) NOT NULL,
    order_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_order_amount CHECK (order_amount >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
