# SQL Database Engineering — Enterprise Order Management System

A production-oriented database engineering repository presenting the architectural design, relational normalization, indexing mechanics, transactional integrity, and scalability boundaries of an enterprise **Order Management System** implemented in MySQL 8.0.

---

## 🏗️ Repository Architecture

```text
SQL Database Engineering
│
├── Database design
├── Normalization
│   ├── UNF
│   ├── 1NF
│   ├── 2NF
│   └── 3NF
│
├── Relationships
│   ├── 1:N
│   └── M:N
│       └── product_categories
│
├── Indexing & Query Optimization
│   ├── B-Tree
│   ├── EXPLAIN
│   ├── EXPLAIN ANALYZE
│   └── Before vs After benchmark
│
├── Transactions & ACID
│   ├── BEGIN
│   ├── COMMIT
│   ├── ROLLBACK
│   └── Isolation
│
└── Scalability / What Breaks First
```

---

## 🎯 Engineering Objectives

* **Schema Architecture**: Design production-grade schemas with strict data typing, referential integrity, and defensive integrity constraints (`PRIMARY KEY`, `FOREIGN KEY`, `UNIQUE`, `NOT NULL`, `CHECK`).
* **Progressive Normalization**: Decompose unnormalized data from UNF through 1NF, 2NF, and 3NF to eliminate insertion, update, and deletion anomalies.
* **Relationship Modeling**: Implement 1:1, 1:N, and M:N relationships using junction tables with cascade rules and exact data-type matching.
* **Storage & Indexing Mechanics**: Analyze InnoDB B+Tree internals (16 KB pages, fan-out, clustered vs. secondary indexes, page splits, write penalties).
* **Hardware Execution Profiling**: Evaluate query performance using `EXPLAIN FORMAT=JSON` and `EXPLAIN ANALYZE` on a 10,000-row dataset.
* **ACID Transactions**: Guarantee consistency and atomicity using transaction control statements (`START TRANSACTION`, `COMMIT`, `ROLLBACK`) and understand ANSI/ISO isolation levels.
* **Production Scalability**: Reason about database bottlenecks at scale (buffer pool saturation, row lock contention, write amplification, replication lag, and connection limits).

---

# 🗄️ 1. Database Design

The core domain modeled across this repository is an **E-Commerce Order Management System** (`order_management`). It captures customer lifecycle, product catalogs, multi-item customer orders, and multi-category taxonomies.

### Entity Relationship Model

```text
┌─────────────────┐
│  customers_3nf  │
│ (customer_id PK)│
└────────┬────────┘
         │ 1
         │
         │ N
┌────────▼────────┐       1 ┌───────────────────┐ N       ┌────────────────┐
│   orders_3nf    ├────────►│  order_items_3nf  │◄────────┤  products_3nf  │
│  (order_id PK)  │         │ (order_id PK/FK,  │         │ (product_id PK)│
└─────────────────┘         │  product_id PK/FK)│         └───────┬────────┘
                            └───────────────────┘                 │ 1
                                                                  │
                                                                  │ N
┌──────────────┐          N ┌────────────────────┐                │
│  categories  │◄───────────┤ product_categories │◄───────────────┘
│(category_id) │            │ (product_id PK/FK, │
└──────────────┘            │  category_id PK/FK)│
                            └────────────────────┘
```

---

### Core Relational Schema

#### 1. Customers (`customers_3nf`)
Stores customer accounts with uniqueness guarantees on contact records.

```sql
CREATE TABLE customers_3nf (
    customer_id   INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    customer_email VARCHAR(150) NOT NULL UNIQUE,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 2. Products (`products_3nf`)
Stores purchasable products with domain price validation.

```sql
CREATE TABLE products_3nf (
    product_id    INT AUTO_INCREMENT PRIMARY KEY,
    product_name  VARCHAR(150) NOT NULL,
    product_price DECIMAL(10, 2) NOT NULL,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_products_price_positive CHECK (product_price >= 0.00)
);
```

#### 3. Orders (`orders_3nf`)
Captures order placement headers linked directly to verified customers.

```sql
CREATE TABLE orders_3nf (
    order_id    INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date  DATE NOT NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers_3nf(customer_id)
        ON DELETE RESTRICT
);
```

#### 4. Order Items (`order_items_3nf`)
Represents the line items comprising an order. Uses a composite primary key with defensive quantity validation.

```sql
CREATE TABLE order_items_3nf (
    order_id   INT NOT NULL,
    product_id INT NOT NULL,
    quantity   INT NOT NULL,
    PRIMARY KEY (order_id, product_id),
    CONSTRAINT chk_order_items_quantity_positive CHECK (quantity > 0),
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES orders_3nf(order_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES products_3nf(product_id)
        ON DELETE RESTRICT
);
```

---

### Key Architectural Decisions

1. **Exact Precision for Currency (`DECIMAL(10,2)`)**: Floating point data types (`FLOAT`, `DOUBLE`) introduce binary rounding errors (e.g., $0.1 + 0.2 \neq 0.3$). Financial balances and unit prices must always use fixed-point `DECIMAL`.
2. **Surrogate Keys vs Composite Keys**: Single-column integer surrogate primary keys (`AUTO_INCREMENT`) provide compact clustered indexes and stable foreign key references, while natural composite keys (`order_id`, `product_id`) enforce exact cardinality in intersection tables.
3. **Defensive Check Constraints**: Application-level validations can be bypassed by direct database queries, migrations, or batch jobs. Engine-level constraints (`CHECK (quantity > 0)`) ensure data integrity is enforced unconditionally at the storage engine tier.
4. **Referential Action Policies**:
   * Line items are tightly bound to the order lifecycle (`ON DELETE CASCADE` on `order_id`).
   * Customers and products with active historical transaction references cannot be deleted arbitrarily (`ON DELETE RESTRICT`).

---

# 📐 2. Normalization: UNF → 1NF → 2NF → 3NF

Database normalization systematically decomposes tables to eliminate data redundancy and guard against insertion, update, and deletion anomalies.

```text
Unnormalized (UNF)
       ↓  (Ensure atomic attributes; eliminate repeating groups)
      1NF
       ↓  (Eliminate partial functional dependencies)
      2NF
       ↓  (Eliminate transitive functional dependencies)
      3NF
```

---

## 2.1 Unnormalized Form (UNF)

In an unnormalized design, multiple attributes or entities are packed into a single row, often using comma-separated lists.

### Schema: `orders_unnormalized`

```sql
CREATE TABLE orders_unnormalized (
    order_id       INT,
    customer_name  VARCHAR(100),
    customer_email VARCHAR(150),
    product_ids    VARCHAR(255), -- e.g. '101,102'
    product_names  VARCHAR(255), -- e.g. 'Keyboard,Mouse'
    product_prices VARCHAR(255), -- e.g. '49.99,19.99'
    quantities     VARCHAR(255), -- e.g. '1,2'
    order_date     DATE
);
```

```text
order_id | customer_name | product_ids | product_names  | quantities
---------+---------------+-------------+----------------+-----------
1001     | Rahul Sharma  | 101,102     | Keyboard,Mouse | 1,2
1002     | Priya Patil   | 103         | Monitor        | 1
```

### Critical Anomalies in UNF:
1. **Atomicity Violation**: Multiple independent values are conflated within individual columns (`'101,102'`).
2. **Fragile Search**: Searching for orders containing product `101` requires non-indexable substring patterns (`LIKE '%101%'`), scanning every block in the table.
3. **Update Anomaly**: If the price or name of "Keyboard" changes, every historical text string in the table must be rewritten. Any missed row creates internal data corruption.
4. **Insertion Anomaly**: A product cannot exist in the database until a customer places an order for it.
5. **Deletion Anomaly**: If order `1002` is deleted, all records of the "Monitor" product and its pricing are permanently erased.

---

## 2.2 First Normal Form (1NF)

### 1NF Requirements:
1. Every column must store **atomic** (indivisible) values.
2. Repeating groups and delimited arrays must be eliminated.
3. Each record must be uniquely identifiable via a Primary Key.

### 1NF Schema: `orders_1nf`
Each product in an order is expanded into its own row, identified by a composite primary key:

```sql
CREATE TABLE orders_1nf (
    order_id       INT NOT NULL,
    customer_id    INT NOT NULL,
    customer_name  VARCHAR(100) NOT NULL,
    customer_email VARCHAR(150) NOT NULL,
    product_id     INT NOT NULL,
    product_name   VARCHAR(150) NOT NULL,
    product_price  DECIMAL(10, 2) NOT NULL,
    quantity       INT NOT NULL,
    order_date     DATE NOT NULL,
    PRIMARY KEY (order_id, product_id)
);
```

```text
order_id | customer_name | product_id | product_name | quantity
---------+---------------+------------+--------------+---------
1001     | Rahul Sharma  | 101        | Keyboard     | 1
1001     | Rahul Sharma  | 102        | Mouse        | 2
1002     | Priya Patil   | 103        | Monitor      | 1
```

### Remaining Flaw: Partial Dependencies
The primary key is composite: `(order_id, product_id)`. Non-key attributes depend on only a subset of the candidate key:
* `order_id -> {customer_id, customer_name, customer_email, order_date}`
* `product_id -> {product_name, product_price}`
* Only `quantity` depends on the **full** key `(order_id, product_id)`.

Because non-key attributes depend on only part of the primary key, customer and product data are duplicated across every order line item.

---

## 2.3 Second Normal Form (2NF)

### 2NF Requirements:
1. Must satisfy **1NF**.
2. Must remove all **partial functional dependencies**: every non-key column must depend on the entire candidate key.

### Decomposition into 2NF:
We separate the table into three distinct relations:

1. **`products_2nf`**: Keyed by `product_id`
   ```sql
   CREATE TABLE products_2nf (
       product_id    INT PRIMARY KEY,
       product_name  VARCHAR(150) NOT NULL,
       product_price DECIMAL(10, 2) NOT NULL
   );
   ```
2. **`orders_2nf`**: Keyed by `order_id`
   ```sql
   CREATE TABLE orders_2nf (
       order_id       INT PRIMARY KEY,
       customer_id    INT NOT NULL,
       customer_name  VARCHAR(100) NOT NULL,
       customer_email VARCHAR(150) NOT NULL,
       order_date     DATE NOT NULL
   );
   ```
3. **`order_items_2nf`**: Keyed by composite `(order_id, product_id)`
   ```sql
   CREATE TABLE order_items_2nf (
       order_id   INT NOT NULL,
       product_id INT NOT NULL,
       quantity   INT NOT NULL,
       PRIMARY KEY (order_id, product_id),
       FOREIGN KEY (order_id) REFERENCES orders_2nf(order_id),
       FOREIGN KEY (product_id) REFERENCES products_2nf(product_id)
   );
   ```

### Remaining Flaw: Transitive Dependencies
In `orders_2nf`:
* `order_id -> customer_id`
* `customer_id -> {customer_name, customer_email}`
* Therefore, `order_id -> customer_name` is a **transitive dependency** ($X \rightarrow Y$ and $Y \rightarrow Z$, where $Y$ is not a candidate key).
* Customer details cannot be stored until an order is created, and updating a customer's email requires modifying every order placed by that customer.

---

## 2.4 Third Normal Form (3NF)

### 3NF Requirements:
1. Must satisfy **2NF**.
2. Must remove all **transitive dependencies**: non-key attributes must depend *only* on candidate keys (*"The key, the whole key, and nothing but the key, so help me Codd"*).

### Final 3NF Schema:
Extract customer data into its own relation, leaving `orders_3nf` with only a foreign key reference:

```text
┌─────────────────┐       1 : N       ┌─────────────────┐       1 : N       ┌───────────────────┐
│  customers_3nf  ├──────────────────►│   orders_3nf    ├──────────────────►│  order_items_3nf  │
│(customer_id PK) │                   │ (order_id PK)   │                   │ (order_id,        │
└─────────────────┘                   └─────────────────┘                   │  product_id PK)   │
                                                                            └─────────▲─────────┘
                                                                                      │ N : 1
                                                                            ┌─────────┴─────────┐
                                                                            │   products_3nf    │
                                                                            │ (product_id PK)   │
                                                                            └───────────────────┘
```

### Verification Query: Multi-Table 3NF Join
```sql
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
JOIN customers_3nf c   ON o.customer_id = c.customer_id
JOIN order_items_3nf oi ON o.order_id = oi.order_id
JOIN products_3nf p    ON oi.product_id = p.product_id
ORDER BY o.order_id, p.product_id;
```

---

# 🔗 3. Relationships

Relational database models capture real-world constraints via foreign keys and cardinality mapping.

---

## 3.1 One-to-Many (1:N)

One parent record associates with zero, one, or many child records, but each child record maps back to exactly one parent.

* **`customers_3nf` ──► `orders_3nf`**: A customer places many orders; an order belongs to one customer.
* **`orders_3nf` ──► `order_items_3nf`**: An order contains multiple line items; each line item belongs to one order.

```sql
ALTER TABLE orders_3nf
ADD CONSTRAINT fk_orders_customer
    FOREIGN KEY (customer_id)
    REFERENCES customers_3nf(customer_id)
    ON DELETE RESTRICT;
```

* **Referential Integrity**: Rejecting orphaned records at the storage level. Setting `ON DELETE RESTRICT` protects financial history from accidental customer deletion.

---

## 3.2 Many-to-Many (M:N) via Junction Tables

Direct Many-to-Many relationships cannot be modeled with single foreign keys without violating 1NF or repeating data.

* A **Product** belongs to multiple categories (*e.g., "Wireless Mouse" belongs to "Electronics" and "Accessories"*).
* A **Category** contains multiple products (*e.g., "Electronics" contains "Keyboard", "Mouse", "Monitor"*).

### Junction Table: `product_categories`

```sql
CREATE TABLE categories (
    category_id   INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description   VARCHAR(255)
);

CREATE TABLE product_categories (
    product_id  INT NOT NULL,
    category_id INT NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (product_id, category_id),
    CONSTRAINT fk_pc_product
        FOREIGN KEY (product_id)
        REFERENCES products_3nf(product_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_pc_category
        FOREIGN KEY (category_id)
        REFERENCES categories(category_id)
        ON DELETE CASCADE
);
```

### Exact Data Type Matching Rule:
In MySQL InnoDB, the foreign key column must have the **exact same data type, signedness, and character set** as the referenced parent primary key column.
* If `products_3nf.product_id` is `INT`, then `product_categories.product_id` must be `INT` (not `BIGINT` or `SMALLINT`).
* Type mismatches result in MySQL rejection: `ERROR 3780 (HY000): Referencing column and referenced column are incompatible`.

### Querying M:N Relationships

#### 1. Retrieve Products with All Assigned Categories
```sql
SELECT
    p.product_id,
    p.product_name,
    c.category_name
FROM products_3nf p
JOIN product_categories pc ON p.product_id = pc.product_id
JOIN categories c         ON pc.category_id = c.category_id
ORDER BY p.product_id;
```

#### 2. Category Aggregation (Product Count per Category)
```sql
SELECT
    c.category_id,
    c.category_name,
    COUNT(pc.product_id) AS product_count
FROM categories c
LEFT JOIN product_categories pc ON c.category_id = pc.category_id
GROUP BY c.category_id, c.category_name
ORDER BY product_count DESC;
```

---

# ⚡ 4. Indexing & Query Optimization

A deep dive into B+Tree mechanics, query execution plans (`EXPLAIN` / `EXPLAIN ANALYZE`), storage/write trade-offs, and empirical benchmarking on a 10,000-row dataset.

For the full theoretical breakdown, see [docs/indexing.md](file:///c:/Users/Commit/Desktop/sql-database-engineering/docs/indexing.md).

---

## 4.1 B-Tree Internal Mechanics

MySQL InnoDB structures tables and secondary indexes as **B+Trees** optimized for page-based storage I/O.

```text
                           ┌────────────────────────┐
                           │   Root Page (Node)     │
                           │  [email < M] | [email >= M]│
                           └────────┬───────────────┘
                                    │
            ┌───────────────────────┴───────────────────────┐
            ▼                                               ▼
┌───────────────────────┐                       ┌───────────────────────┐
│ Intermediate Page 1   │                       │ Intermediate Page 2   │
│ [email < F] | [>= F]  │                       │ [email < S] | [>= S]  │
└───────┬───────┬───────┘                       └───────┬───────┬───────┘
        │       │                                       │       │
    ┌───┘       └───┐                               ┌───┘       └───┐
    ▼               ▼                               ▼               ▼
┌──────────────┐ ┌──────────────┐               ┌──────────────┐ ┌──────────────┐
│ Leaf Page 1  │◄┤ Leaf Page 2  │◄─────────────►│ Leaf Page 3  │◄┤ Leaf Page 4  │
│ [Keys + Ptrs]│ │ [Keys + Ptrs]│               │ [Keys + Ptrs]│ │ [Keys + Ptrs]│
└──────────────┘ └──────────────┘               └──────────────┘ └──────────────┘
 └─── Doubly Linked List for Range Scans (BETWEEN, >, <, ORDER BY) ─────────────┘
```

* **16 KB Page Unit**: Storage allocation and memory caching in the `innodb_buffer_pool` happen in 16 KB pages.
* **High Fan-Out**: Intermediate index pages store only search keys and 8-byte child page pointers. A single 16 KB page holds $>1,000$ pointers.
  * A 3-level B+Tree holds up to $1,000 \times 1,000 \times 1,000 = 1,000,000,000$ leaf rows.
  * Any row in a billion-row table can be reached in **3 to 4 logical disk page lookups ($O(\log_B N)$)**.
* **Clustered vs Secondary Index**:
  * **Clustered Index**: Automatically built on the Primary Key. Leaf nodes store the **entire row data**.
  * **Secondary Index**: Leaf nodes store the secondary key plus the corresponding Primary Key value. Finding non-indexed columns requires a secondary **Bookmark Lookup** in the clustered tree.
* **Covering Index Optimization**: When all columns requested by a `SELECT` exist directly in the secondary index leaf page, InnoDB bypasses the clustered index bookmark lookup entirely (`Extra: Using index`).

---

## 4.2 The Cost of Indexing: Why "Index Everything" Fails

While indexes accelerate reads, they introduce operational costs:
1. **Write Amplification on INSERT/UPDATE/DELETE**: Every insert must update the clustered index **plus every secondary B-tree**. A table with 5 indexes executes 6 tree writes per row.
2. **Page Splits**: When inserting into a full 16 KB leaf page, InnoDB must allocate a new page, migrate 50% of the keys, rewrite sibling pointers, and insert parent pointers. This triggers intensive Redo/Undo log I/O and locks tree pages.
3. **Buffer Pool Thrashing**: Secondary index pages compete with active data pages in RAM (`innodb_buffer_pool`), evicting hot rows to disk.

---

## 4.3 Composite Indexes & The Leftmost Prefix Rule

A composite index on `(col_a, col_b)` stores a single B+tree ordered first by `col_a`, then secondarily by `col_b`.
* `WHERE col_a = ?` ✅ Uses index.
* `WHERE col_a = ? AND col_b = ?` ✅ Uses index fully.
* `WHERE col_a = ? ORDER BY col_b` ✅ Avoids filesort.
* `WHERE col_b = ?` ❌ **Cannot use index** (violates Leftmost Prefix Rule).

---

## 4.4 Empirical Benchmark: Before vs. After Indexing

### Benchmark Configuration
* **Database**: `order_management`
* **Table**: `orders` ([schema/indexing/01_orders_table.sql](file:///c:/Users/Commit/Desktop/sql-database-engineering/schema/indexing/01_orders_table.sql))
* **Dataset Volume**: **10,000 rows** generated via [seeds/generate_orders_seed.py](file:///c:/Users/Commit/Desktop/sql-database-engineering/seeds/generate_orders_seed.py)
* **Target Query**:
  ```sql
  SELECT *
  FROM orders
  WHERE customer_email = 'sophia.miller@example.com';
  ```
* **Target Row Count**: Exactly **5 matching rows** scattered throughout the 10,000 records.

---

### 📊 Performance Comparison

| Metric | Before | After |
| :--- | :--- | :--- |
| Rows examined | 10,000 | 5 |
| Access | Full table scan | B-Tree lookup |
| Optimizer cost | 1025.75 | 1.75 |
| Execution time | 7.82 ms | 0.08 ms |

---

### Detailed Benchmark Metrics Breakdown

| Metric | Without Index (Baseline) | With B-Tree Index (`idx_orders_customer_email`) | Performance Gain |
| :--- | :--- | :--- | :--- |
| **Access Type (`type`)** | `ALL` (Full Table Scan) | `ref` (Index Lookup) | **Eliminated sequential table scan** |
| **Possible Keys** | `NULL` | `idx_orders_customer_email` | Index available |
| **Selected Key** | `NULL` | `idx_orders_customer_email` | B-tree index utilized |
| **Key Length (`key_len`)** | `NULL` | `602` bytes ($150 \times 4 + 2$ bytes) | Exact utf8mb4 prefix match |
| **Rows Examined (`rows`)** | **10,000 rows** | **5 rows** | **2,000x fewer rows read** |
| **Filtered Percentage** | `10.00%` | `100.00%` | **100% precision at storage layer** |
| **Optimizer Cost Units** | `1025.75` | `1.75` | **586x lower query cost** |
| **Actual Execution Time** | **7.82 ms** | **0.08 ms** | **~97x faster execution** |

---

### Raw Query Plan Evidence

#### 1. BEFORE Indexing (Full Table Scan)

Without a secondary index, the engine scans all 10,000 rows across every InnoDB data page.

##### Tabular EXPLAIN:
```text
+----+-------------+--------+------------+------+---------------+------+---------+------+-------+----------+-------------+
| id | select_type | table  | partitions | type | possible_keys | key  | key_len | ref  | rows  | filtered | Extra       |
+----+-------------+--------+------------+------+---------------+------+---------+------+-------+----------+-------------+
|  1 | SIMPLE      | orders | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 10000 |    10.00 | Using where |
+----+-------------+--------+------------+------+---------------+------+---------+------+-------+----------+-------------+
```

##### EXPLAIN FORMAT=JSON:
```json
{
  "query_block": {
    "select_id": 1,
    "cost_info": {
      "query_cost": "1025.75"
    },
    "table": {
      "table_name": "orders",
      "access_type": "ALL",
      "rows_examined_per_scan": 10000,
      "rows_produced_per_join": 1000,
      "filtered": "10.00",
      "cost_info": {
        "read_cost": "925.75",
        "eval_cost": "100.00",
        "prefix_cost": "1025.75",
        "data_read_per_join": "1M"
      },
      "attached_condition": "(`order_management`.`orders`.`customer_email` = 'sophia.miller@example.com')"
    }
  }
}
```

##### EXPLAIN ANALYZE (Hardware Execution Profile):
```text
-> Filter: (orders.customer_email = 'sophia.miller@example.com')  (cost=1025.75 rows=1000) (actual time=0.184..7.818 rows=5 loops=1)
    -> Table scan on orders  (cost=1025.75 rows=10000) (actual time=0.042..6.950 rows=10000 loops=1)
```

---

#### 2. Index Creation

```sql
CREATE INDEX idx_orders_customer_email ON orders (customer_email);
```

---

#### 3. AFTER Indexing (Index Ref Lookup)

Root-to-leaf binary traversal pinpoints the exact 5 leaf entries and performs clustered bookmark lookups.

##### Tabular EXPLAIN:
```text
+----+-------------+--------+------------+------+---------------------------+---------------------------+---------+-------+------+----------+-------+
| id | select_type | table  | partitions | type | possible_keys             | key                       | key_len | ref   | rows | filtered | Extra |
+----+-------------+--------+------------+------+---------------------------+---------------------------+---------+-------+------+----------+-------+
|  1 | SIMPLE      | orders | NULL       | ref  | idx_orders_customer_email | idx_orders_customer_email | 602     | const |    5 |   100.00 | NULL  |
+----+-------------+--------+------------+------+---------------------------+---------------------------+---------+-------+------+----------+-------+
```

##### EXPLAIN FORMAT=JSON:
```json
{
  "query_block": {
    "select_id": 1,
    "cost_info": {
      "query_cost": "1.75"
    },
    "table": {
      "table_name": "orders",
      "access_type": "ref",
      "possible_keys": [
        "idx_orders_customer_email"
      ],
      "key": "idx_orders_customer_email",
      "used_key_parts": [
        "customer_email"
      ],
      "key_length": "602",
      "ref": [
        "const"
      ],
      "rows_examined_per_scan": 5,
      "rows_produced_per_join": 5,
      "filtered": "100.00",
      "cost_info": {
        "read_cost": "1.25",
        "eval_cost": "0.50",
        "prefix_cost": "1.75",
        "data_read_per_join": "5K"
      }
    }
  }
}
```

##### EXPLAIN ANALYZE (Hardware Execution Profile):
```text
-> Index lookup on orders using idx_orders_customer_email (customer_email='sophia.miller@example.com')  (cost=1.75 rows=5) (actual time=0.038..0.082 rows=5 loops=1)
```

---

# 🔄 5. Transactions & ACID

A transaction is a single logical unit of database work. In Order Management, placing an order requires inserting the order header and all line items atomically.

For the full conceptual guide, see [docs/transactions.md](file:///c:/Users/Commit/Desktop/sql-database-engineering/docs/transactions.md).

---

## 5.1 ACID Guarantees in Order Management

* **Atomicity**: The entire order payload (`orders_3nf` header + all `order_items_3nf` items) commits together. If inserting any item fails, the transaction is completely rolled back; no half-created orders can exist.
* **Consistency**: Transactions transition the database from one valid state to another, enforcing primary keys, foreign keys, and check constraints (`quantity > 0`).
* **Isolation**: Concurrent transactions cannot observe uncommitted intermediate states of other sessions.
* **Durability**: Once a transaction is committed, changes survive power outages, server crashes, or OS reboots via the InnoDB Write-Ahead Redo Log (`ib_logfile`).

---

## 5.2 Transaction Control: BEGIN, COMMIT, ROLLBACK

### 1. Atomic Order Commit (`01_commit_order.sql`)
```sql
USE order_management;

START TRANSACTION;

-- 1. Create order header
INSERT INTO orders_3nf (order_id, customer_id, order_date)
VALUES (9001, 1, CURRENT_DATE);

-- 2. Add line items
INSERT INTO order_items_3nf (order_id, product_id, quantity)
VALUES
    (9001, 101, 2),
    (9001, 102, 1);

-- 3. Persist atomically
COMMIT;
```

---

### 2. Transaction Rollback on Failure (`02_rollback_order.sql`)
When a constraint fails (e.g. invalid `product_id`), the transaction must be explicitly rolled back to prevent partial writes.

```sql
USE order_management;

START TRANSACTION;

-- 1. Create order header
INSERT INTO orders_3nf (order_id, customer_id, order_date)
VALUES (9002, 1, CURRENT_DATE);

-- 2. Add valid line item
INSERT INTO order_items_3nf (order_id, product_id, quantity)
VALUES (9002, 101, 2);

-- 3. Attempt invalid product insertion (Fails: Foreign Key Violation)
INSERT INTO order_items_3nf (order_id, product_id, quantity)
VALUES (9002, 999999, 1);

-- 4. Discard all operations
ROLLBACK;
```

> **Engineering Rule**: In MySQL/InnoDB, a single failed SQL statement does **NOT** automatically roll back the entire transaction. The application layer must handle the error and explicitly execute `ROLLBACK`.

---

## 5.3 Concurrency & Isolation Levels

ANSI/ISO SQL defines four isolation levels to manage concurrent read phenomena:

| Isolation Level | Dirty Read | Non-Repeatable Read | Phantom Read |
| :--- | :--- | :--- | :--- |
| **READ UNCOMMITTED** | Possible | Possible | Possible |
| **READ COMMITTED** | Prevented | Possible | Possible |
| **REPEATABLE READ** (MySQL Default) | Prevented | Prevented | Prevented (via MVCC & Next-Key Locks) |
| **SERIALIZABLE** | Prevented | Prevented | Prevented |

### Concurrency Anomalies Explained:
* **Dirty Read**: Transaction B reads uncommitted data written by Transaction A. If Transaction A rolls back, Transaction B acted on phantom data.
* **Non-Repeatable Read**: Transaction A reads a row twice, but Transaction B commits an update between the reads, returning different column values.
* **Phantom Read**: Transaction A executes a range query twice (`WHERE order_date = ?`), but Transaction B commits an insert matching that range, causing new rows to appear in the second read.

### Managing Isolation in MySQL:
```sql
-- Check current isolation level
SELECT @@transaction_isolation;

-- Set session isolation level
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
```

---

# 💥 6. Scalability / What Breaks First

When an Order Management System scales from **10,000 rows** to **100,000 rows (10x)**, **1,000,000+ rows (100x)**, and beyond under high concurrency, monolithic relational databases encounter hard architectural limits.

---

## 6.1 What Happens to This Schema at 10x and 100x Data Volume?

| Data Volume | Orders Table Size | Order Items (~3x) | B+Tree Depth | Buffer Pool Impact | Query Behavior & Bottlenecks |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Baseline (10K)** | ~1.5 MB | ~3.8 MB (30K rows) | 2 levels | 100% in RAM | Indexed queries complete in **0.08 ms**. Unindexed full table scans take **7.82 ms**. |
| **10x Volume (100K)** | ~15 MB | ~38 MB (300K rows) | 3 levels | Fits in RAM | Single-key lookups remain fast (~0.12 ms) due to 1 extra B-tree hop. However, **unindexed scans jump from 7.8 ms to ~75–100 ms**, causing CPU spikes and blocking concurrent transactions. |
| **100x Volume (1M+)** | ~160 MB | ~400 MB (3M+ rows) | 3–4 levels | Working set exceeds cache | Random I/O begins dominating. A full table scan requires reading ~10,000 disk pages (~160 MB), taking **1.5 to 4.0 seconds** per query. Joins across `orders` and `order_items` without exact composite indexes trigger disk-based temporary tables and hash joins. |

### The 10x Turning Point:
At 100,000 rows, a missing index ceases to be a mere performance inefficiency; it becomes a **system-halting incident**. An accidental full table scan holding a shared lock (`LOCK IN SHARE MODE`) or updating rows without an index (`UPDATE orders SET status = 'PROCESSED' WHERE ...`) locks entire tables via next-key locks, cascading into thread pool starvation.

---

## 6.2 Where Would You Shard? (Horizontal Partitioning Strategy)

When dataset volume and write throughput exceed the limits of vertical hardware scaling (typically >50M rows or >5,000 write ops/sec), the database must be horizontally sharded.

```text
                               ┌───────────────────────────┐
                               │   Application / ProxySQL  │
                               └─────────────┬─────────────┘
                                             │
                      Shard Key: hash(customer_id) % 3
                                             │
             ┌───────────────────────────────┼───────────────────────────────┐
             ▼                               ▼                               ▼
    ┌─────────────────┐             ┌─────────────────┐             ┌─────────────────┐
    │     Shard 1     │             │     Shard 2     │             │     Shard 3     │
    │ (customer_id    │             │ (customer_id    │             │ (customer_id    │
    │  MOD 3 = 0)     │             │  MOD 3 = 1)     │             │  MOD 3 = 2)     │
    ├─────────────────┤             ├─────────────────┤             ├─────────────────┤
    │ customers_3nf   │             │ customers_3nf   │             │ customers_3nf   │
    │ orders_3nf      │             │ orders_3nf      │             │ orders_3nf      │
    │ order_items_3nf │             │ order_items_3nf │             │ order_items_3nf │
    └─────────────────┘             └─────────────────┘             └─────────────────┘
             ▲                               ▲                               ▲
             └───────────────────────┬───────┴───────────────────────────────┘
                                     │ Broadcast Replicas
                            ┌────────┴────────┐
                            │  Global Tables  │
                            │  (products_3nf, │
                            │   categories)   │
                            └─────────────────┘
```

### 1. Selected Shard Key: `customer_id`
* **Why `customer_id`?**:
  * An e-commerce platform's transactional operations are overwhelmingly customer-centric (*"View my order history"*, *"Checkout active cart"*, *"View my past orders"*).
  * Sharding by `customer_id` co-locates `customers_3nf`, `orders_3nf`, and `order_items_3nf` for any single customer onto the **exact same physical database shard**.
  * **Critical Benefit**: Order creation (`orders_3nf` + `order_items_3nf`) executes as a **local single-shard transaction**, maintaining full ACID guarantees without expensive two-phase commit (2PC) or distributed transaction coordinators.

### 2. What Breaks When Sharding by `customer_id`?
* **Global Queries & Cross-Shard Joins**: Queries that search across customers (e.g., *"Find all orders containing product 101 placed today"*) cannot be routed to a single shard. The application or proxy must execute a **Scatter-Gather** query across all $N$ shards and merge the results in memory.
* **Hot Shards / Key Skew**: High-volume corporate or reseller accounts placing 10,000x more orders than average users create unbalanced "hot shards". Remediation requires composite sharding or salt prefixes for institutional accounts.

### 3. Handling Catalog Tables: Global Broadcast
* Tables like `products_3nf`, `categories`, and `product_categories` cannot be sharded by `customer_id`.
* **Solution**: Replicate catalog tables to every shard as **read-only broadcast tables**, or serve them exclusively from an independent catalog cluster / distributed cache.

---

## 6.3 What Would You Cache? (Caching Architecture)

In an enterprise Order Management System, 90%+ of traffic consists of read queries. Placing an in-memory cache (**Redis Cluster**) in front of MySQL shields the storage engine from redundant reads.

```text
[ Client ] ──► [ API Gateway ] ──► [ Cache Layer (Redis) ]
                                          │
                                     (Cache Miss)
                                          │
                                          ▼
                             [ Primary Database (MySQL) ]
```

### 1. What to Cache (Aggressive Caching)
* **Product Catalog (`products_3nf`)**:
  * **Read-to-Write Ratio**: $>1000 : 1$.
  * **Cache Pattern**: Cache-Aside (Lazy Loading) with key `product:{product_id}` storing JSON or Redis Hashes.
  * **TTL**: 1 hour with event-driven cache invalidation on catalog updates.
* **Category Taxonomies (`categories`, `product_categories`)**:
  * Highly static hierarchical data. Cache full category trees with long TTL (24h).
* **Hot Product Inventory**:
  * To avoid locking the `products_3nf` table during flash sales, store available stock counts in Redis as an atomic integer. Decrement stock using atomic Redis Lua scripts (`INCRBY -quantity`) before issuing database transaction requests.

### 2. What NOT to Cache
* **Active Checkout Transactions**: Inserting into `orders_3nf` and `order_items_3nf` must go directly to the primary database to enforce ACID durability.
* **High-Cardinality One-Off Filter Queries**: Caching ad-hoc customer filter permutations pollutes cache memory with near-zero hit rates.

---

## 6.4 Core Failure Points Under High Throughput

### 1. InnoDB Buffer Pool Saturation & Disk Thrashing
* **The Failure**: When total active data pages and secondary index trees exceed `innodb_buffer_pool_size`, every read query must fetch pages synchronously from NVMe/SSD storage.
* **Symptom**: Read latencies spike from 0.08 ms to 15–30 ms; `innodb_buffer_pool_read_requests` drops as `innodb_data_reads` surges.
* **Remediation**: Size buffer pool to 70–80% of system RAM; implement covering indexes (`Using index`) to avoid fetching clustered table pages.

### 2. Row Lock Contention on Hot Inventory Rows
* **The Failure**: 500 concurrent checkouts attempting to decrement inventory for the same hot product (`UPDATE products_3nf SET stock = stock - 1 WHERE product_id = 101`) serialize behind exclusive row locks (X-locks).
* **Symptom**: `Lock wait timeout exceeded (1205)`; database connection pool fills up in milliseconds.
* **Remediation**: Use optimistic locking (`UPDATE ... WHERE product_id = ? AND version = ?`), or offload inventory reservation to Redis atomic counters and Kafka message queues.

### 3. Write Amplification & Page Splits
* **The Failure**: High-speed batch inserts force simultaneous modifications across every secondary index. When 16 KB B-tree leaf pages fill up, InnoDB halts writes to allocate new pages and balance sibling pointers.
* **Symptom**: Heavy Redo log generation (`ib_logfile`), checkpoint stalls, write latency spikes.
* **Remediation**: Eliminate unused secondary indexes; use monotonically increasing sequential IDs (`AUTO_INCREMENT`) instead of random UUIDv4.

### 4. Connection Pool Starvation (`max_connections`)
* **The Failure**: Long-running or unindexed queries hold worker threads open, exhausting MySQL's `max_connections` (default 151).
* **Symptom**: `ERROR 1040 (08004): Too many connections`. Whole-system downtime across all connecting microservices.
* **Remediation**: Deploy **ProxySQL** or **MaxScale** connection pool multiplexers; tune HikariCP pool sizes ($\text{pool} = \text{cores} \times 2 + \text{disk spindles}$).

### 5. Deep Pagination Offset Degradation
* **The Failure**: `SELECT * FROM orders_3nf ORDER BY order_id LIMIT 1000000, 20` scans 1,000,020 rows, discarding the first million.
* **Symptom**: Query times scale linearly with page depth ($O(N)$).
* **Remediation**: Replace offset pagination with **Keyset (Cursor-based) pagination**:
  ```sql
  SELECT *
  FROM orders_3nf
  WHERE order_id > :last_seen_order_id
  ORDER BY order_id ASC
  LIMIT 20;
  ```

### 6. Replication Lag in Read-Write Splits
* **The Failure**: Read replicas fall behind primary when large write batches or complex DDL commands are replayed sequentially by replica SQL threads.
* **Symptom**: "Read-your-own-writes" inconsistency: customer places an order, redirects to order history, and sees an empty list.
* **Remediation**: Route critical post-write reads to the Primary; enable multi-threaded applier threads (`replica_parallel_workers = 8`); use GTID with session consistency tokens.

---

# 📁 Repository Structure

```text
sql-database-engineering/
│
├── README.md                          # Master architectural presentation
├── schema.sql                         # Legacy library baseline schema
├── queries.sql                        # Legacy analytical SQL queries
│
├── schema/
│   ├── normalization/                 # UNF → 1NF → 2NF → 3NF progression
│   │   ├── 01_unnormalized.sql        # Raw table with multi-value string columns
│   │   ├── 02_1nf.sql                 # Atomic expansion with composite PK
│   │   ├── 03_2nf.sql                 # Removal of partial dependencies
│   │   ├── 04_3nf.sql                 # Final 3NF schema (orders, items, products, customers)
│   │   └── 05_validation.sql          # Integrity queries and anomaly checks
│   │
│   ├── relationships/                 # Relational cardinality & junction patterns
│   │   ├── 01_categories.sql          # Categories taxonomy table
│   │   ├── 02_product_categories.sql  # M:N junction table with cascade constraints
│   │   └── 03_validation.sql          # Double JOIN queries and category aggregations
│   │
│   ├── indexing/                      # Indexing & execution plan benchmarks
│   │   ├── 01_orders_table.sql        # 10,000-row benchmark table definition
│   │   └── 02_indexing_benchmarks.sql # EXPLAIN, EXPLAIN ANALYZE, composite indexes
│   │
│   └── transactions/                  # ACID transaction control & isolation
│       ├── 01_commit_order.sql        # Atomic order insertion and COMMIT
│       ├── 02_rollback_order.sql      # Constraint failure handling and ROLLBACK
│       ├── 03_isolation_levels.sql    # Session isolation level configuration
│       └── 04_validation.sql          # Post-transaction state validation
│
├── docs/                              # In-depth architectural references
│   ├── normalization.md               # Normalization theory and mathematical dependencies
│   ├── relationships.md               # Foreign key rules, cascading, and M:N resolution
│   ├── indexing.md                    # B+Tree internals, page splits, write penalties
│   └── transactions.md                # ACID properties, isolation levels, interview FAQ
│
└── seeds/                             # Synthetic data generators & seed scripts
    ├── generate_orders_seed.py        # Python generator producing 10,000 batch order rows
    ├── orders_seed.sql                # 10,000-row SQL dataset for indexing benchmarks
    └── library_seed.sql               # Seed data for baseline tests
```

---

# 🛠️ Reproduction & Verification Guide

To execute and verify all components locally in MySQL 8.0+:

### 1. Database Initialization & Normalization
```bash
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS order_management;"
mysql -u root -p order_management < schema/normalization/04_3nf.sql
mysql -u root -p order_management < schema/normalization/05_validation.sql
```

### 2. Relationships & Junction Tables
```bash
mysql -u root -p order_management < schema/relationships/01_categories.sql
mysql -u root -p order_management < schema/relationships/02_product_categories.sql
mysql -u root -p order_management < schema/relationships/03_validation.sql
```

### 3. Indexing Benchmark (10,000 Rows)
```bash
mysql -u root -p order_management < schema/indexing/01_orders_table.sql
mysql -u root -p order_management < seeds/orders_seed.sql
mysql -u root -p order_management < schema/indexing/02_indexing_benchmarks.sql
```

### 4. Transactions & ACID
```bash
mysql -u root -p order_management < schema/transactions/01_commit_order.sql
mysql -u root -p order_management < schema/transactions/02_rollback_order.sql
mysql -u root -p order_management < schema/transactions/04_validation.sql
```

---

# 📈 Progression Roadmap

```text
Relational Schema Design
         ↓
Normalization (UNF → 1NF → 2NF → 3NF)
         ↓
Cardinality & Junction Tables (1:N, M:N)
         ↓
B+Tree Storage & Index Optimization
         ↓
Hardware Profiling (EXPLAIN ANALYZE)
         ↓
ACID Transactions & Isolation Levels
         ↓
Production Scalability & Failure Modes
         ↓
Java Database Integration (JDBC & Connection Pooling)
         ↓
ORM Frameworks (Hibernate / Spring Data JPA)
```
