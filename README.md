# SQL Database Engineering

A practical SQL and database engineering repository focused on **relational database design, SQL querying, constraints, normalization, joins, aggregation, and database fundamentals** using MySQL.

The repository is designed to progress from SQL fundamentals toward **advanced database engineering, Java database integration, JPA/Hibernate, query optimization, transactions, and production-oriented database design**.

---

## 🎯 Objectives

The main objectives of this repository are to:

* Build strong SQL fundamentals.
* Understand relational database design.
* Design normalized database schemas.
* Work with primary keys and foreign keys.
* Use database constraints correctly.
* Write practical SQL queries using joins and aggregation.
* Understand `NULL` handling.
* Understand one-to-many relationships.
* Practice SQL using realistic datasets.
* Build a foundation for JDBC, JPA, and Hibernate.
* Develop database knowledge useful for backend software engineering.

---

# 📚 Current Project — Library Management System

The first project in this repository is a small **Library Management System**.

It models three core entities:

```text
┌──────────────┐
│    Books     │
└──────┬───────┘
       │
       │ 1
       │
       │ N
┌──────▼───────┐
│    Loans     │
└──────▲───────┘
       │
       │ N
       │
       │ 1
┌──────┴───────┐
│   Members    │
└──────────────┘
```

### Entities

* **Books** — stores information about books.
* **Members** — stores information about library members.
* **Loans** — stores borrowing transactions.

A member can have multiple loans, and a book can appear in multiple loan records over its lifetime.

---

# 🗄️ Database Schema

Database:

```text
library
```

Tables:

```text
library
├── books
├── members
└── loans
```

---

## 1. Books

Stores information about books available in the library.

| Column           | Type         | Constraint       | Purpose                |
| ---------------- | ------------ | ---------------- | ---------------------- |
| `book_id`        | INTEGER      | PRIMARY KEY      | Unique book identifier |
| `title`          | VARCHAR(200) | NOT NULL         | Book title             |
| `isbn`           | VARCHAR(20)  | UNIQUE, NOT NULL | Unique ISBN            |
| `author`         | VARCHAR(150) | NOT NULL         | Author name            |
| `published_year` | INTEGER      | —                | Publication year       |

---

## 2. Members

Stores information about library members.

| Column        | Type         | Constraint       | Purpose                  |
| ------------- | ------------ | ---------------- | ------------------------ |
| `member_id`   | INTEGER      | PRIMARY KEY      | Unique member identifier |
| `name`        | VARCHAR(100) | NOT NULL         | Member name              |
| `email`       | VARCHAR(150) | UNIQUE, NOT NULL | Member email             |
| `joined_date` | DATE         | NOT NULL         | Membership date          |

---

## 3. Loans

Stores borrowing transactions.

| Column        | Type    | Constraint            | Purpose                |
| ------------- | ------- | --------------------- | ---------------------- |
| `loan_id`     | INTEGER | PRIMARY KEY           | Unique loan identifier |
| `book_id`     | INTEGER | FOREIGN KEY, NOT NULL | Borrowed book          |
| `member_id`   | INTEGER | FOREIGN KEY, NOT NULL | Borrowing member       |
| `loan_date`   | DATE    | NOT NULL              | Borrowing date         |
| `due_date`    | DATE    | NOT NULL              | Expected return date   |
| `return_date` | DATE    | NULL                  | Actual return date     |

---

# 🔗 Relationships

### Members → Loans

One member can have many loan records.

```text
members.member_id
        │
        └──────────► loans.member_id
```

### Books → Loans

One book can have many loan records over its lifetime.

```text
books.book_id
      │
      └──────────► loans.book_id
```

Therefore, `loans` acts as the transaction table connecting **members** and **books**.

---

# 🔐 Database Constraints

The schema uses several important relational database constraints.

## Primary Key

Uniquely identifies each record.

```sql
PRIMARY KEY (book_id)
```

Examples:

```text
book_id
member_id
loan_id
```

---

## Foreign Key

Maintains relationships between tables and provides referential integrity.

```sql
FOREIGN KEY (book_id)
REFERENCES books(book_id)
```

and:

```sql
FOREIGN KEY (member_id)
REFERENCES members(member_id)
```

---

## NOT NULL

Ensures that required fields cannot contain `NULL`.

Example:

```sql
title VARCHAR(200) NOT NULL
```

---

## UNIQUE

Prevents duplicate values.

Examples:

```sql
isbn VARCHAR(20) UNIQUE
```

and:

```sql
email VARCHAR(150) UNIQUE
```

---

## CHECK

Validates data based on a condition.

The schema ensures that a book cannot have a due date before its loan date:

```sql
CHECK (due_date >= loan_date)
```

It also ensures that a return date cannot be earlier than the loan date:

```sql
CHECK (
    return_date IS NULL
    OR return_date >= loan_date
)
```

---

# 🧠 Design Decisions

## Why separate books and members?

Books and members represent different entities.

Their information is therefore stored in separate tables instead of combining everything into one table.

This reduces duplication and makes the database easier to maintain.

---

## Why does `loans` store IDs instead of names?

The `loans` table stores:

```text
book_id
member_id
```

instead of:

```text
book_title
member_name
```

This avoids repeatedly storing the same information.

For example, if a member's name changes, only the `members` table needs to be updated.

---

## Why use foreign keys?

Foreign keys:

* Maintain referential integrity.
* Prevent invalid references.
* Represent relationships explicitly.
* Reduce duplicated data.
* Make joins between related entities possible.

Example:

```text
loans.member_id → members.member_id
loans.book_id   → books.book_id
```

---

# 📐 Normalization

The current schema follows basic normalization principles.

## First Normal Form — 1NF

Each column stores atomic values.

For example:

```text
name  → Rahul
email → rahul@example.com
```

A column does not contain multiple independent values.

---

## Second Normal Form — 2NF

Attributes depend on the appropriate primary key.

For example:

```text
book_id → title, isbn, author, published_year
```

and:

```text
member_id → name, email, joined_date
```

---

## Third Normal Form — 3NF

Non-key attributes depend on the key rather than on another non-key attribute.

For example, member information belongs in `members` instead of being repeatedly stored in `loans`.

---

# 👥 Multiple Authors — Future Improvement

The current schema stores one author directly in the `books` table:

```text
author
```

This becomes problematic if a book has multiple authors.

For example:

```text
Book A → Author A, Author B, Author C
```

A better design would use:

```text
books
authors
book_authors
```

The `book_authors` table would act as a bridge table and represent a **many-to-many relationship**.

```text
Books
  │
  │ M:N
  │
Book_Authors
  │
  │ M:N
  │
Authors
```

This is a planned improvement for the database as the project becomes more advanced.

---

# 📊 Sample Dataset

The following sample dataset is used to manually trace and verify the SQL queries.

## Books

| book_id | title                                 | isbn           | author               | published_year |
| ------: | ------------------------------------- | -------------- | -------------------- | -------------: |
|       1 | Clean Code                            | 978-0132350884 | Robert C. Martin     |           2008 |
|       2 | Effective Java                        | 978-0134685991 | Joshua Bloch         |           2018 |
|       3 | Database System Concepts              | 978-0078022159 | Abraham Silberschatz |           2019 |
|       4 | Designing Data-Intensive Applications | 978-1449373320 | Martin Kleppmann     |           2017 |

---

## Members

| member_id | name  | email                                         | joined_date |
| --------: | ----- | --------------------------------------------- | ----------- |
|         1 | Rahul | [rahul@example.com](mailto:rahul@example.com) | 2026-01-10  |
|         2 | Priya | [priya@example.com](mailto:priya@example.com) | 2026-02-15  |
|         3 | Amit  | [amit@example.com](mailto:amit@example.com)   | 2026-03-20  |
|         4 | Sneha | [sneha@example.com](mailto:sneha@example.com) | 2026-04-05  |

---

## Loans

| loan_id | book_id | member_id | loan_date  | due_date   | return_date |
| ------: | ------: | --------: | ---------- | ---------- | ----------- |
|       1 |       1 |         1 | 2026-08-01 | 2026-08-15 | NULL        |
|       2 |       2 |         1 | 2026-08-05 | 2026-08-19 | 2026-08-15  |
|       3 |       3 |         2 | 2026-09-01 | 2026-09-15 | NULL        |
|       4 |       4 |         2 | 2026-09-05 | 2026-09-19 | NULL        |

---

# 🔎 SQL Queries

The repository contains five practical SQL queries.

---

## Query 1 — Find Overdue Loans

### Objective

Find loans where:

1. The book has not been returned.
2. The due date has already passed.
3. Display the member, book, and due date.

### Query

```sql
SELECT
    m.name AS member_name,
    b.title AS book_title,
    l.due_date
FROM library.loans l
JOIN library.members m
    ON l.member_id = m.member_id
JOIN library.books b
    ON l.book_id = b.book_id
WHERE l.return_date IS NULL
  AND l.due_date < CURRENT_DATE;
```

### Manual Trace

From the sample data:

```text
Loan 1
Rahul → Clean Code
Due: 2026-08-15
Returned: No
```

The current date is after `2026-08-15`, and `return_date` is `NULL`.

Therefore, Loan 1 is overdue.

Loan 2 is already returned, so it is excluded.

Loans 3 and 4 have future due dates, so they are not overdue.

### Expected Output

| member_name | book_title | due_date   |
| ----------- | ---------- | ---------- |
| Rahul       | Clean Code | 2026-08-15 |

### Concepts Practiced

* `JOIN`
* Multiple-table joins
* `WHERE`
* `IS NULL`
* Date comparison
* `CURRENT_DATE`

---

# Query 2 — Count Loans Per Member

### Objective

Find the total number of loans made by each member.

### Query

```sql
SELECT
    m.member_id,
    m.name,
    COUNT(l.loan_id) AS total_loans
FROM library.members m
LEFT JOIN library.loans l
    ON m.member_id = l.member_id
GROUP BY m.member_id, m.name;
```

### Manual Trace

From the sample data:

```text
Rahul → Loan 1, Loan 2 → 2 loans
Priya → Loan 3, Loan 4 → 2 loans
Amit  → No loans       → 0 loans
Sneha → No loans       → 0 loans
```

Because `LEFT JOIN` is used, Amit and Sneha remain in the result even though they have no matching loans.

### Expected Output

| member_id | name  | total_loans |
| --------: | ----- | ----------: |
|         1 | Rahul |           2 |
|         2 | Priya |           2 |
|         3 | Amit  |           0 |
|         4 | Sneha |           0 |

### Concepts Practiced

* `LEFT JOIN`
* `GROUP BY`
* `COUNT()`
* Aggregation

---

# Query 3 — Find Members With No Loans

### Objective

Find members who have never borrowed a book.

### Query

```sql
SELECT
    m.member_id,
    m.name,
    m.email
FROM library.members m
LEFT JOIN library.loans l
    ON m.member_id = l.member_id
WHERE l.loan_id IS NULL;
```

### Manual Trace

Start with all members:

```text
Rahul
Priya
Amit
Sneha
```

Match their loans:

```text
Rahul → Loan 1, Loan 2
Priya → Loan 3, Loan 4
Amit  → NULL
Sneha → NULL
```

The condition:

```sql
WHERE l.loan_id IS NULL
```

keeps only:

```text
Amit
Sneha
```

### Expected Output

| member_id | name  | email                                         |
| --------: | ----- | --------------------------------------------- |
|         3 | Amit  | [amit@example.com](mailto:amit@example.com)   |
|         4 | Sneha | [sneha@example.com](mailto:sneha@example.com) |

### Important Pattern

```sql
LEFT JOIN
WHERE right_table.id IS NULL
```

This is a common SQL pattern for finding records with **no matching record**.

### Concepts Practiced

* `LEFT JOIN`
* `NULL`
* Anti-join pattern

---

# Query 4 — List Currently Borrowed Books

### Objective

Find all books that are currently borrowed and have not yet been returned.

### Query

```sql
SELECT
    b.title AS book_title,
    m.name AS member_name,
    l.loan_date,
    l.due_date
FROM library.loans l
JOIN library.books b
    ON l.book_id = b.book_id
JOIN library.members m
    ON l.member_id = m.member_id
WHERE l.return_date IS NULL;
```

### Manual Trace

Check the `return_date` column:

```text
Loan 1 → NULL
Loan 2 → 2026-08-15
Loan 3 → NULL
Loan 4 → NULL
```

Therefore, Loans 1, 3, and 4 represent currently borrowed books.

### Expected Output

| book_title                            | member_name | loan_date  | due_date   |
| ------------------------------------- | ----------- | ---------- | ---------- |
| Clean Code                            | Rahul       | 2026-08-01 | 2026-08-15 |
| Database System Concepts              | Priya       | 2026-09-01 | 2026-09-15 |
| Designing Data-Intensive Applications | Priya       | 2026-09-05 | 2026-09-19 |

### Concepts Practiced

* Multiple `JOIN`s
* `WHERE`
* `IS NULL`
* Relational data retrieval

---

# Query 5 — Count Loans Per Book

### Objective

Find how many times each book has been borrowed.

### Query

```sql
SELECT
    b.book_id,
    b.title,
    COUNT(l.loan_id) AS loan_count
FROM library.books b
LEFT JOIN library.loans l
    ON b.book_id = l.book_id
GROUP BY b.book_id, b.title
ORDER BY loan_count DESC;
```

### Manual Trace

From the sample data:

```text
Clean Code                              → 1 loan
Effective Java                          → 1 loan
Database System Concepts                → 1 loan
Designing Data-Intensive Applications   → 1 loan
```

Every book currently has exactly one loan record.

### Expected Output

| book_id | title                                 | loan_count |
| ------: | ------------------------------------- | ---------: |
|       1 | Clean Code                            |          1 |
|       2 | Effective Java                        |          1 |
|       3 | Database System Concepts              |          1 |
|       4 | Designing Data-Intensive Applications |          1 |

### Concepts Practiced

* `LEFT JOIN`
* `GROUP BY`
* `COUNT()`
* `ORDER BY`
* Aggregation

---

# 🧩 SQL Concepts Practiced

| Concept        | Purpose                          |
| -------------- | -------------------------------- |
| `SELECT`       | Retrieve data                    |
| `WHERE`        | Filter rows                      |
| `INNER JOIN`   | Match related records            |
| `LEFT JOIN`    | Preserve records without matches |
| `GROUP BY`     | Group records for aggregation    |
| `COUNT()`      | Count records                    |
| `ORDER BY`     | Sort results                     |
| `IS NULL`      | Check missing values             |
| `CURRENT_DATE` | Work with the current date       |
| Primary Key    | Uniquely identify records        |
| Foreign Key    | Create relationships             |
| `NOT NULL`     | Require a value                  |
| `UNIQUE`       | Prevent duplicate values         |
| `CHECK`        | Validate data                    |

---

# 🔑 Important SQL Patterns

## INNER JOIN

Use when only matching records are required.

```sql
SELECT *
FROM loans l
JOIN books b
    ON l.book_id = b.book_id;
```

---

## LEFT JOIN

Use when all records from the left table must be retained.

```sql
SELECT *
FROM members m
LEFT JOIN loans l
    ON m.member_id = l.member_id;
```

---

## Find Records With No Match

A common pattern:

```sql
SELECT *
FROM members m
LEFT JOIN loans l
    ON m.member_id = l.member_id
WHERE l.loan_id IS NULL;
```

---

## Aggregation

Use `GROUP BY` with aggregate functions such as `COUNT()`.

```sql
SELECT
    member_id,
    COUNT(loan_id)
FROM loans
GROUP BY member_id;
```

---

## NULL Handling

Correct:

```sql
WHERE return_date IS NULL;
```

Incorrect:

```sql
WHERE return_date = NULL;
```

`NULL` represents missing or unknown data and must be checked using `IS NULL` or `IS NOT NULL`.

---


---

# ⚡ Day 3 — Indexing & Query Optimization

A deep dive into **B-Tree indexing mechanics, query execution plans (`EXPLAIN` and `EXPLAIN ANALYZE`), storage/write trade-offs, and composite indexes** using a 10,000-row `orders` dataset.

For the full theoretical and internal architectural breakdown, see [docs/indexing.md](file:///c:/Users/Commit/Desktop/sql-database-engineering/docs/indexing.md).

---

## 🔬 Benchmark Setup

* **Database**: `order_management`
* **Table**: `orders` ([schema/indexing/01_orders_table.sql](file:///c:/Users/Commit/Desktop/sql-database-engineering/schema/indexing/01_orders_table.sql))
* **Dataset Size**: **10,000 rows** generated via [seeds/generate_orders_seed.py](file:///c:/Users/Commit/Desktop/sql-database-engineering/seeds/generate_orders_seed.py) (stored in [seeds/orders_seed.sql](file:///c:/Users/Commit/Desktop/sql-database-engineering/seeds/orders_seed.sql))
* **Target Query**:
  ```sql
  SELECT *
  FROM orders
  WHERE customer_email = 'sophia.miller@example.com';
  ```
* **Target Row Count**: Exactly **5 matching rows** scattered throughout the 10,000 records.

---

## 📊 Before vs. After Performance Comparison

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

## 🔍 Query Plan Evidence (Raw Outputs)

### 1. BEFORE Indexing (Full Table Scan)

Without a secondary index on `customer_email`, the storage engine must load and scan all 10,000 rows sequentially across every data page in InnoDB.

#### Standard EXPLAIN (Tabular)
```text
+----+-------------+--------+------------+------+---------------+------+---------+------+-------+----------+-------------+
| id | select_type | table  | partitions | type | possible_keys | key  | key_len | ref  | rows  | filtered | Extra       |
+----+-------------+--------+------------+------+---------------+------+---------+------+-------+----------+-------------+
|  1 | SIMPLE      | orders | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 10000 |    10.00 | Using where |
+----+-------------+--------+------------+------+---------------+------+---------+------+-------+----------+-------------+
```

#### EXPLAIN FORMAT=JSON
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
      "used_columns": [
        "order_id",
        "customer_id",
        "customer_name",
        "customer_email",
        "order_amount",
        "order_status",
        "order_date",
        "created_at"
      ],
      "attached_condition": "(`order_management`.`orders`.`customer_email` = 'sophia.miller@example.com')"
    }
  }
}
```

#### EXPLAIN ANALYZE (Hardware Execution Profile)
```text
-> Filter: (orders.customer_email = 'sophia.miller@example.com')  (cost=1025.75 rows=1000) (actual time=0.184..7.818 rows=5 loops=1)
    -> Table scan on orders  (cost=1025.75 rows=10000) (actual time=0.042..6.950 rows=10000 loops=1)
```

---

### 2. Adding the Index

```sql
CREATE INDEX idx_orders_customer_email ON orders (customer_email);
```

This constructs a secondary B+Tree where each leaf page stores the sorted `customer_email` keys paired with their corresponding clustered index primary key (`order_id`).

---

### 3. AFTER Indexing (Index Ref Lookup)

With the B-Tree in place, MySQL performs a root-to-leaf binary search to pinpoint the 5 matching entries, fetching each row via a clustered index bookmark lookup.

#### Standard EXPLAIN (Tabular)
```text
+----+-------------+--------+------------+------+---------------------------+---------------------------+---------+-------+------+----------+-------+
| id | select_type | table  | partitions | type | possible_keys             | key                       | key_len | ref   | rows | filtered | Extra |
+----+-------------+--------+------------+------+---------------------------+---------------------------+---------+-------+------+----------+-------+
|  1 | SIMPLE      | orders | NULL       | ref  | idx_orders_customer_email | idx_orders_customer_email | 602     | const |    5 |   100.00 | NULL  |
+----+-------------+--------+------------+------+---------------------------+---------------------------+---------+-------+------+----------+-------+
```

#### EXPLAIN FORMAT=JSON
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
      },
      "used_columns": [
        "order_id",
        "customer_id",
        "customer_name",
        "customer_email",
        "order_amount",
        "order_status",
        "order_date",
        "created_at"
      ]
    }
  }
}
```

#### EXPLAIN ANALYZE (Hardware Execution Profile)
```text
-> Index lookup on orders using idx_orders_customer_email (customer_email='sophia.miller@example.com')  (cost=1.75 rows=5) (actual time=0.038..0.082 rows=5 loops=1)
```

---

## 💡 Engineering Takeaways

### 1. Why "Index Everything" is Wrong: The Cost of Indexing
* **Write Penalty**: For every `INSERT`, MySQL must insert the record into the primary clustered index **plus every secondary B-Tree**. A table with 6 indexes requires 7 distinct tree modifications per insert.
* **Page Splits**: When an insert hits a full 16 KB leaf page, InnoDB must allocate a new page, migrate ~50% of the keys, update sibling doubly-linked pointers, and insert parent pointers. This generates heavy Redo/Undo logging and stalls concurrency.
* **Memory & Storage**: Secondary indexes consume significant disk space and compete for space in the `innodb_buffer_pool`. Excess index pages evict active table data pages, causing cache thrashing.

### 2. Composite Index vs. Two Separate Indexes
* **Composite Index `(customer_email, order_date)`**: Single B-tree sorted first by `customer_email`, then by `order_date`. Best when queries filter on both columns (`WHERE customer_email = ? AND order_date >= ?`). Follows the **Leftmost Prefix Rule** (can also satisfy queries filtering on `customer_email` alone).
* **Two Separate Indexes**: Necessary when queries frequently filter on `customer_email` independently **and** on `order_date` independently. When queried together, MySQL must pick one index or perform an expensive **Index Merge** (`Using intersect`).

---

# 🛠️ Tools & Technologies

* **MySQL 8.0**
* **MySQL Workbench**
* **SQL**
* **Git**
* **GitHub**
* **IntelliJ IDEA**
* **Python 3** (Data generation scripts)

---

# 📁 Repository Structure

```text
sql-database-engineering/
│
├── schema.sql
├── queries.sql
├── seeds/
│   ├── library_seed.sql
│   ├── generate_orders_seed.py
│   └── orders_seed.sql
│
├── schema/
│   ├── indexing/
│   │   ├── 01_orders_table.sql
│   │   └── 02_indexing_benchmarks.sql
│   ├── normalization/
│   │   ├── 01_unnormalized.sql
│   │   ├── 02_1nf.sql
│   │   ├── 03_2nf.sql
│   │   ├── 04_3nf.sql
│   │   └── 05_validation.sql
│   └── relationships/
│       ├── 01_categories.sql
│       ├── 02_product_categories.sql
│       └── 03_validation.sql
│
├── docs/
│   ├── indexing.md
│   ├── normalization.md
│   └── relationships.md
│
├── README.md
└── .gitignore
```

### `schema.sql`
Contains:
* Library database creation (`library`)
* Table definitions (`books`, `members`, `loans`)
* Primary keys, foreign keys, and CHECK constraints
* Sample seed data

### `queries.sql`
Contains 5 practical SQL analytical queries on the library database (overdue loans, loan counts, member activity, null filtering).

### `seeds/`
Contains standalone SQL and programmatic seed scripts:
* `library_seed.sql` — Populates sample books, members, and loans.
* `generate_orders_seed.py` — Python script generating 10,000 synthetic order records in batch inserts.
* `orders_seed.sql` — 10,000-row batch dataset for indexing and query plan profiling.

### `schema/`
Contains modular SQL exercises:
* **`indexing/`**:
  - `01_orders_table.sql`: 10,000-row orders schema without secondary indexes.
  - `02_indexing_benchmarks.sql`: Query plans, index creation, composite index tests, covering indexes, and storage metrics.
* **`normalization/`**: Demonstrates decomposing an order management schema through UNF → 1NF → 2NF → 3NF along with full integrity validation queries.
* **`relationships/`**: Demonstrates resolving Many-to-Many relationships via junction tables (`product_categories`), foreign key cascades, and category aggregations.

### `docs/`
Contains conceptual deep-dives and design documentation:
* `indexing.md` — B-Tree internals, clustered vs secondary indexes, write penalties, page splits, execution plans, and interview solutions.
* `normalization.md` — Normalization theory, anomaly prevention, and 1NF–3NF progression.
* `relationships.md` — Cardinality (1:1, 1:N, M:N), junction tables, cascading foreign keys, and join queries.

### `README.md`
Contains comprehensive schema documentation, design decisions, query traces, benchmark results, and learning roadmaps.

---

# 🚀 Learning Roadmap

The repository will progressively move from SQL fundamentals toward database engineering.

```text
SQL Fundamentals
       ↓
Relational Database Design
       ↓
Joins & Aggregations
       ↓
Normalization
       ↓
Indexes & Execution Plans (Day 3)
       ↓
Subqueries
       ↓
HAVING
       ↓
CASE Expressions
       ↓
Common Table Expressions
       ↓
Window Functions
       ↓
Transactions
       ↓
ACID Properties
       ↓
Isolation Levels
       ↓
Concurrency
       ↓
JDBC
       ↓
Java + MySQL
       ↓
JPA / Hibernate
       ↓
Production Database Design
```

---

# 📈 Current Progress

## Database Fundamentals

* [x] Schema creation
* [x] Table design
* [x] Primary keys
* [x] Foreign keys
* [x] `NOT NULL`
* [x] `UNIQUE`
* [x] `CHECK` constraints
* [x] One-to-many relationships
* [x] Many-to-many relationships (junction tables)
* [x] Basic normalization (1NF, 2NF, 3NF)
* [x] Indexing (B-Tree, Clustered, Secondary, Composite)

## SQL & Performance

* [x] `SELECT`
* [x] `WHERE`
* [x] `INNER JOIN`
* [x] `LEFT JOIN`
* [x] `GROUP BY`
* [x] `COUNT()`
* [x] `ORDER BY`
* [x] `IS NULL`
* [x] Date filtering
* [x] Multi-table queries
* [x] Aggregation
* [x] Anti-join pattern
* [x] Execution Plan Analysis (`EXPLAIN` & `EXPLAIN ANALYZE`)
* [x] Index Optimization (Full Table Scan → B-Tree Index Lookup)

## Future

* [ ] Subqueries
* [ ] `HAVING`
* [ ] `CASE`
* [ ] CTEs
* [ ] Window functions
* [ ] Transactions
* [ ] ACID properties
* [ ] Isolation levels
* [ ] Concurrency
* [ ] JDBC
* [ ] JPA
* [ ] Hibernate
* [ ] Advanced database design

---

# 🎯 Long-Term Goal

The goal of this repository is not only to learn SQL syntax but to develop the ability to **design, query, analyze, integrate, and reason about relational databases used in real software systems**.

The progression is:

```text
Design the Database
        ↓
Write Correct SQL
        ↓
Understand Relationships
        ↓
Analyze Data
        ↓
Optimize Queries
        ↓
Understand Transactions
        ↓
Integrate with Java
        ↓
Build Database-Driven Applications
```

This repository will serve as the database foundation for future **Java backend and Spring Boot projects**.
