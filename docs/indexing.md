# Day 3 — Indexing, B-Trees, and Query Optimization

## Objective
Understand how B-Tree indexes work internally in relational database engines (specifically MySQL InnoDB), measure the exact read performance gains of indexing using `EXPLAIN` and `EXPLAIN ANALYZE`, analyze the trade-offs that make "index everything" an anti-pattern (write overhead, page splits, memory footprint), and evaluate composite indexes versus single-column indexes.

---

## 1. How a B-Tree Index Actually Works

### The Analogy & The Architecture
Without an index, finding a specific record in a database table requires a **Full Table Scan ($O(N)$)**: the storage engine must read every database page from disk or the buffer pool and inspect every row sequentially.

A **B-Tree** (specifically a **B+Tree** in MySQL InnoDB) is a self-balancing, multi-way search tree optimized for systems that read and write large blocks of memory (pages).

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

### Core Characteristics of InnoDB B+Trees
1. **16 KB Page Size**: In InnoDB, disk I/O and buffer caching operate in fixed chunks of 16 Kilobytes (`innodb_page_size`).
2. **High Fan-Out**: Because intermediate nodes store only the indexed key and an 8-byte child page pointer, a single 16 KB page can hold over 1,000 pointer entries.
   - Level 1 (Root): 1 page (~1,000 entries)
   - Level 2 (Branch): 1,000 pages (~1,000,000 entries)
   - Level 3 (Leaf): 1,000,000 pages (~1,000,000,000 records)
   - **Result**: Even for a billion rows, InnoDB can reach any arbitrary key in **3 to 4 page lookups ($O(\log_B N)$)**.
3. **Doubly-Linked Leaf Nodes**: All leaf pages are linked sequentially in order (`prev_page` and `next_page` pointers). Once the starting point is found via root traversal, range scans (`WHERE order_date BETWEEN ...`) simply walk the linked list without touching intermediate nodes.

---

## 2. Clustered Index vs. Secondary Index

| Feature | Clustered Index | Secondary Index |
| :--- | :--- | :--- |
| **Creation** | Automatically created on the **Primary Key**. | Explicitly created via `CREATE INDEX`. |
| **Leaf Page Content** | Stores the **entire data row** (all columns). | Stores the **indexed key + the Primary Key value**. |
| **Count per Table** | Exactly **one** per table (the table *is* the index). | Can have **multiple** secondary indexes. |
| **Lookup Mechanism** | Direct single traversal to leaf node. | Traverses secondary tree, retrieves Primary Key, then performs a **Bookmark Lookup** in the clustered index. |

```text
Secondary Index Lookup (e.g., on customer_email):
[customer_email: 'sophia...'] ──► B-Tree Search ──► Leaf Node: ('sophia...', PK: 5432)
                                                                       │
Bookmark Lookup (Clustered Index Search):                              ▼
[order_id: 5432] ───────────────► B-Tree Search ──► Leaf Node: Entire Row Data!
```

### The Covering Index Optimization
If a query selects **only** columns present in the secondary index (or the primary key):

```sql
SELECT customer_email, order_id
FROM orders
WHERE customer_email = 'sophia.miller@example.com';
```

The optimizer reads the data directly from the secondary index leaf node and **skips the bookmark lookup entirely**. In `EXPLAIN`, this is indicated by `Using index` in the `Extra` column.

---

## 3. The Real Cost: Why "Index Everything" is Wrong

While indexes dramatically speed up read queries, they impose three major operational penalties:

### A. Write Overhead (INSERT, UPDATE, DELETE)
Every time a new row is inserted into `orders`:
1. The row is written into the Clustered Index leaf page.
2. The engine must traverse and insert an entry into **every single secondary B-tree index**.
3. If an index leaf page is full (16 KB limit reached), InnoDB must perform a **Page Split**:
   - Allocates a new 16 KB page.
   - Moves 50% of the entries from the existing page to the new page.
   - Updates the doubly-linked list pointers of surrounding pages.
   - Inserts a new routing entry into the parent branch node (which may trigger cascading splits up to the root).
4. Each split generates extra **Undo and Redo Log (`ib_logfile`)** records, stalling concurrent write transactions.

### B. Storage & Memory Footprint
* Every index is an independent physical B-tree stored on disk. In high-column or wide-VARCHAR tables, secondary index size can easily exceed raw table data size.
* **Buffer Pool Thrashing**: MySQL's `innodb_buffer_pool_size` holds active pages in RAM. When too many indexes are queried, index pages compete with raw data pages for buffer pool space, causing frequent page evictions to disk.

### C. Optimizer Planning Overhead
Before running any query, the MySQL Cost-Based Optimizer calculates permutations of execution plans for each available index. Having dozens of redundant indexes inflates query compilation time and increases the risk of suboptimal index selection.

---

## 4. Query Execution Plans: EXPLAIN & EXPLAIN ANALYZE

MySQL provides execution inspection tools to understand how queries are executed:

### Understanding EXPLAIN Output Columns
* **`type` (Access Type - from best to worst)**:
  - `system` / `const`: Table has at most one matching row (evaluated once against constants).
  - `eq_ref`: Exactly one row is fetched from this table for each combination from previous tables (Primary Key or NOT NULL UNIQUE join).
  - `ref`: Non-unique index lookup (returns multiple rows matching a specific key).
  - `range`: Index range scan (uses index to select rows in a given range using `>`, `<`, `BETWEEN`, `IN`).
  - `index`: Full index scan (scans the entire index tree without table access).
  - `ALL`: **Full Table Scan** (reads every block in the table).
* **`possible_keys`**: List of indexes MySQL could potentially use.
* **`key`**: The specific index actually selected by the optimizer.
* **`key_len`**: The length of the key in bytes (e.g., `VARCHAR(150)` in utf8mb4 uses $150 \times 4 + 2 = 602$ bytes).
* **`rows`**: Estimated number of rows the optimizer expects to examine.
* **`filtered`**: Estimated percentage of examined rows that will satisfy the query predicates.
* **`Extra`**:
  - `Using where`: Rows filtered after being read from the storage engine.
  - `Using index`: Covering index used (no table read required).
  - `Using filesort`: MySQL must perform an extra sorting pass.
  - `Using temporary`: MySQL must create an internal temporary table.

### EXPLAIN ANALYZE (MySQL 8.0+)
Unlike standard `EXPLAIN` (which only produces static compile-time estimates), `EXPLAIN ANALYZE` **executes the query**, measures actual hardware timing in milliseconds, and prints an annotated execution tree:
* `actual time = startup_time..total_time`: Time in milliseconds to fetch first row and all rows.
* `rows = N`: Exact number of rows returned.
* `loops = N`: Number of iterations the iterator executed.

---

## 5. Before vs. After Benchmark Evidence

### Dataset
* Table: `order_management.orders`
* Volume: **10,000 rows** generated via [seeds/generate_orders_seed.py](file:///c:/Users/Commit/Desktop/sql-database-engineering/seeds/generate_orders_seed.py).
* Target Customer: `sophia.miller@example.com` (5 matching order records scattered across 10,000 rows).

### Benchmark Query
```sql
SELECT *
FROM orders
WHERE customer_email = 'sophia.miller@example.com';
```

### Metrics Comparison Table

| Metric | Before Index (Baseline) | After Index (`idx_orders_customer_email`) | Performance Delta |
| :--- | :--- | :--- | :--- |
| **Access Type (`type`)** | `ALL` (Full Table Scan) | `ref` (Non-Unique Index Lookup) | **Eliminated table scan** |
| **Possible Keys** | `NULL` | `idx_orders_customer_email` | Index available |
| **Selected Key** | `NULL` | `idx_orders_customer_email` | Index utilized |
| **Key Length (`key_len`)** | `NULL` | `602` bytes ($150 \times 4 + 2$) | Exact key matched |
| **Rows Examined (`rows`)**| **10,000 rows** | **5 rows** | **2,000x fewer rows read** |
| **Filtering (`filtered`)**| `10.00%` | `100.00%` | **100% precision at storage layer** |
| **Optimizer Cost** | `1025.75` | `1.75` | **586x lower optimizer cost** |
| **Execution Time** | **7.82 ms** | **0.08 ms** | **~97x faster execution** |

---

### Raw Evidence: BEFORE Indexing

#### 1. Standard EXPLAIN
```text
+----+-------------+--------+------------+------+---------------+------+---------+------+-------+----------+-------------+
| id | select_type | table  | partitions | type | possible_keys | key  | key_len | ref  | rows  | filtered | Extra       |
+----+-------------+--------+------------+------+---------------+------+---------+------+-------+----------+-------------+
|  1 | SIMPLE      | orders | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 10000 |    10.00 | Using where |
+----+-------------+--------+------------+------+---------------+------+---------+------+-------+----------+-------------+
```

#### 2. EXPLAIN FORMAT=JSON
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

#### 3. EXPLAIN ANALYZE
```text
-> Filter: (orders.customer_email = 'sophia.miller@example.com')  (cost=1025.75 rows=1000) (actual time=0.184..7.818 rows=5 loops=1)
    -> Table scan on orders  (cost=1025.75 rows=10000) (actual time=0.042..6.950 rows=10000 loops=1)
```
*Analysis*: The storage engine was forced to load and iterate over all 10,000 rows (`actual time=0.042..6.950 ms`), discarding 9,995 rows in CPU evaluation before returning the 5 matching rows.

---

### Raw Evidence: AFTER Indexing

#### Index Creation
```sql
CREATE INDEX idx_orders_customer_email ON orders (customer_email);
```

#### 1. Standard EXPLAIN
```text
+----+-------------+--------+------------+------+---------------------------+---------------------------+---------+-------+------+----------+-------+
| id | select_type | table  | partitions | type | possible_keys             | key                       | key_len | ref   | rows | filtered | Extra |
+----+-------------+--------+------------+------+---------------------------+---------------------------+---------+-------+------+----------+-------+
|  1 | SIMPLE      | orders | NULL       | ref  | idx_orders_customer_email | idx_orders_customer_email | 602     | const |    5 |   100.00 | NULL  |
+----+-------------+--------+------------+------+---------------------------+---------------------------+---------+-------+------+----------+-------+
```

#### 2. EXPLAIN FORMAT=JSON
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

#### 3. EXPLAIN ANALYZE
```text
-> Index lookup on orders using idx_orders_customer_email (customer_email='sophia.miller@example.com')  (cost=1.75 rows=5) (actual time=0.038..0.082 rows=5 loops=1)
```
*Analysis*: Root-to-leaf B-tree navigation reached the target entries in under **0.038 ms**. The 5 matching rows were read through direct bookmark lookups, finishing the entire query in **0.082 ms** (97x reduction in wall-clock latency).

---

## 6. Interview Questions & Deep Dives

### Question 1: Why does adding an index speed up reads but slow down writes — what's actually happening on insert?

#### Read Mechanism ($O(\log N)$ Speedup)
Without an index, the storage engine reads all pages sequentially from disk/RAM ($O(N)$). When a secondary B-Tree index exists, the database performs a binary/tree traversal starting at the root page, following child page pointers down to the exact leaf page in $O(\log_B N)$ operations. For a 10,000,000-row table, this transforms a scan of ~100,000 data blocks into just 3 or 4 page lookups.

#### Insert Mechanism (Write Penalty Breakdown)
When executing `INSERT INTO orders (...)`:
1. **Clustered Index Insertion**:
   - The engine traverses the primary key B-Tree to find the appropriate leaf page.
   - The record data is written to the leaf page.
2. **Secondary Index Traversals**:
   - For **every secondary index defined on the table**, the engine must initiate a separate B-Tree search to locate the correct sorted position for the new key.
   - If the index has a `UNIQUE` constraint, the engine must perform a synchronous read to verify no duplicate key exists.
3. **Page Allocation & Page Splits**:
   - Leaf pages have a fixed size (16 KB in InnoDB).
   - If an insert lands in a leaf page that is already 100% full, the database cannot simply append the row. It triggers a **Page Split**:
     - Allocates a brand-new 16 KB page from the tablespace.
     - Moves approximately 50% of the entries from the current page to the new page to maintain balance.
     - Updates the physical doubly-linked pointers (`prev_page` / `next_page`) on the neighboring pages.
     - Inserts a new routing pointer in the parent branch page. If the branch page is also full, the split cascades upward, potentially adding a new level to the tree.
4. **Transaction Logging**:
   - Each page modification generates **Redo Log** entries (for ACID crash recovery) and **Undo Log** entries (for MVCC rollback capabilities).
5. **Buffer Pool Dirtying**:
   - Modifying $K$ indexes turns $K + 1$ clean pages in the InnoDB Buffer Pool into **dirty pages**, placing additional load on the background flusher threads and I/O subsystem.

> **Key Rule**: A table with 1 primary key and 5 secondary indexes executes **6 distinct tree insertions** for every single `INSERT` statement.

---

### Question 2: If a table is queried constantly on two different columns, when does a composite index help vs. two separate indexes?

#### A. Mechanics of a Composite Index `(col_a, col_b)`
A composite index stores a **single B-Tree** where the keys are ordered hierarchically:
1. Ordered primarily by `col_a`.
2. For rows where `col_a` values are identical, ordered secondarily by `col_b`.

```text
Composite Index Tree (customer_email, order_date):
['alice@example.com', '2026-01-10'] -> PK 101
['alice@example.com', '2026-03-15'] -> PK 245
['bob@example.com',   '2026-02-01'] -> PK 189
```

#### B. The Leftmost Prefix Rule
A composite index on `(col_a, col_b)` can satisfy:
* `WHERE col_a = ?` ✅ (Uses `col_a` part of index)
* `WHERE col_a = ? AND col_b = ?` ✅ (Uses full composite index)
* `WHERE col_a = ? ORDER BY col_b` ✅ (Avoids filesort)
* `WHERE col_b = ?` ❌ **Cannot be used!** (Because the tree is sorted primarily by `col_a`; `col_b` without `col_a` is unsorted across the tree).

#### C. Composite Index vs. Two Separate Indexes Comparison

| Feature | Composite Index `(col_a, col_b)` | Two Separate Indexes `(col_a)` and `(col_b)` |
| :--- | :--- | :--- |
| **Query `WHERE col_a = ? AND col_b = ?`** | **Optimal**: Directly locates matching rows in a single B-tree traversal. | **Suboptimal**: Optimizer chooses *one* index and filters the second column in memory, or performs an **Index Merge**. |
| **Query `WHERE col_a = ?` alone** | **Supported**: Satisfied via the leftmost prefix. | **Supported**: Uses index on `col_a`. |
| **Query `WHERE col_b = ?` alone** | ❌ **Unsupported**: Requires full table scan. | **Supported**: Uses index on `col_b`. |
| **Range Filter + Equality (`col_a = ? AND col_b >= ?`)** | **Optimal**: `col_a` narrows exact leaf node, `col_b` performs range scan on leaf chain. | Requires post-read filtering. |
| **Index Merge Overhead** | Zero merge overhead. | MySQL scans both trees, buffers row pointers in memory, sorts and intersects them (`Using intersect(idx_a, idx_b)`), adding CPU and memory overhead. |
| **Write & Storage Overhead** | **1 index structure** to maintain on INSERT/UPDATE. | **2 separate index structures** to maintain on INSERT/UPDATE. |

#### Decision Framework:
1. **Choose a Composite Index `(col_a, col_b)` when**:
   - The majority of queries filter on **both columns together** (`col_a` AND `col_b`).
   - One column is equality and the other is range/order (`col_a = ? ORDER BY col_b`).
   - You want a **Covering Index** for both columns without maintaining two separate trees.
2. **Choose Two Separate Indexes when**:
   - Queries frequently filter on `col_a` independently, **and** other queries frequently filter on `col_b` independently.
   - *Note*: If queries filter on both *and* independently on `col_b`, the optimal strategy is often a composite index `(col_a, col_b)` plus a single index on `col_b`.
3. **Column Ordering in Composite Index**:
   - Place the column with **higher cardinality** (more distinct values) or the column queried with **equality (`=`)** first.
