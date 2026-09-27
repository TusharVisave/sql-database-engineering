# Transactions & ACID: Practical Implementation & Evidence

This repo demonstrates transactions using two real scenarios, not abstract examples.

Rather than treating ACID as a checklist of theoretical definitions, the implementation in [schema/transactions/](../schema/transactions/) tests transactional guarantees against the 3NF order management database (`orders_3nf`, `order_items_3nf`, and `products_3nf`).

The core of this demonstration revolves around two real lifecycle events:
1. **Order 9001 (`01_commit_order.sql`)**: An atomic commit where an order header and multiple line items are staged, inspected, and permanently committed together.
2. **Order 9002 (`02_rollback_order.sql`)**: An atomic rollback triggered by a real foreign key constraint violation (`product_id = 999999`), proving that partial writes are discarded cleanly.

---

## 1. Scenario 1: The Atomic Commit Case (`01_commit_order.sql`)

### Why Atomicity is Required for Orders
In an e-commerce database, an order cannot logically exist without items, nor can items exist without an order:
* **Order without items**: A customer is billed and an order number is created, but warehouse systems have zero line items to pack or dispatch.
* **Items without order**: Order items are inserted into a child table referencing a missing or failed parent record, creating orphan rows and unallocatable inventory.

Both cases represent critical business-data corruption. Creating an order header and its items must always execute as a single atomic unit of work.

### Walkthrough of `01_commit_order.sql`

```sql
USE order_management;

START TRANSACTION;

-- Step 1: Create the parent order header
INSERT INTO orders_3nf (
    order_id,
    customer_id,
    order_date
)
VALUES (
    9001,
    1,
    CURRENT_DATE
);

-- Step 2: Add multiple line items in the same transaction
INSERT INTO order_items_3nf (
    order_id,
    product_id,
    quantity
)
VALUES
    (9001, 101, 2),
    (9001, 102, 1);

-- Step 3: Verify staged contents inside the uncommitted transaction
SELECT
    o.order_id,
    o.customer_id,
    o.order_date,
    oi.product_id,
    oi.quantity
FROM orders_3nf o
JOIN order_items_3nf oi
    ON o.order_id = oi.order_id
WHERE o.order_id = 9001;

-- Step 4: Permanently persist the changes
COMMIT;

-- Step 5: Verify data persistence across the engine
SELECT * FROM orders_3nf WHERE order_id = 9001;
SELECT * FROM order_items_3nf WHERE order_id = 9001;
```

### Verification & Behavior
- **Before `COMMIT`**: The join query confirms that `order_id = 9001` has 2 items within the active session. Under standard isolation (`REPEATABLE READ`), other database connections cannot see these intermediate rows.
- **After `COMMIT`**: The changes are flushed to the InnoDB write-ahead redo log (`ib_logfile`), permanently persisting both the order header and the items together.

---

## 2. Scenario 2: The Atomic Rollback Case (`02_rollback_order.sql`)

### Real Foreign Key Failure (Not Simulated)
In `02_rollback_order.sql`, failure is not simulated with arbitrary `IF/ELSE` flags or mocked exceptions. Instead, it triggers a real schema constraint failure: `product_id = 999999` does not exist in `products_3nf`.

```sql
USE order_management;

-- Clean up any prior execution state
DELETE FROM order_items_3nf WHERE order_id = 9002;
DELETE FROM orders_3nf WHERE order_id = 9002;

START TRANSACTION;

-- Step 1: Insert valid parent order header
INSERT INTO orders_3nf (
    order_id,
    customer_id,
    order_date
)
VALUES (
    9002,
    1,
    CURRENT_DATE
);

-- Step 2: Insert first valid order item
INSERT INTO order_items_3nf (
    order_id,
    product_id,
    quantity
)
VALUES (
    9002,
    101,
    2
);

-- Step 3: Attempt inserting an invalid product item
-- Product 999999 DOES NOT exist in products_3nf!
INSERT INTO order_items_3nf (
    order_id,
    product_id,
    quantity
)
VALUES (
    9002,
    999999,
    1
);
-- Result: ERROR 1452 (23000): Cannot add or update a child row:
-- a foreign key constraint fails (`fk_order_items_product`)

-- Step 4: Discard all operations in this transaction
ROLLBACK;
```

### Crucial Engine Detail: Explicit Rollback Requirement
In MySQL/InnoDB, a single failed SQL statement inside a transaction does **NOT** automatically roll back the entire transaction. If an application ignores the error and issues `COMMIT`, the order header (`9002`) and the first item (`101`) would be permanently written without the second item. 

The application layer must catch the constraint error and explicitly issue `ROLLBACK`.

### Verification Evidence: Proving Atomicity
Immediately following `ROLLBACK`, the validation queries run:

```sql
SELECT * FROM orders_3nf WHERE order_id = 9002;
-- Empty set (0 rows)

SELECT * FROM order_items_3nf WHERE order_id = 9002;
-- Empty set (0 rows)
```

**The Evidence**: Even though the order header (`9002`) and the first line item (`101`) succeeded without error during Steps 1 and 2, the subsequent `ROLLBACK` evicted every trace of order 9002 from both tables. Zero orphaned headers and zero partial item records remain.

---

## 3. Mapping ACID Properties to This Scenario

Rather than abstract definitions, each ACID property maps directly to the evidence produced by orders 9001 and 9002:

* **Atomicity** &rarr; **The 9002 rollback**: Either all rows commit or none do. When line item insertion failed on `product_id = 999999`, the subsequent `ROLLBACK` purged both the parent `orders_3nf` row and the valid first item from `order_items_3nf`, leaving zero partial data.
* **Consistency** &rarr; **The foreign key constraint (`fk_order_items_product`)**: The relational constraint is what triggered the rollback in the first place, ensuring the database could never transition into an invalid state containing orders for non-existent inventory.
* **Isolation** &rarr; **Session visibility boundaries**: Staged rows for order 9001 and 9002 remain invisible to other concurrent connections until explicitly committed.
* **Durability** &rarr; **The 9001 commit**: Once `COMMIT` executes for order 9001, an immediate power loss or database server crash cannot lose that order, because InnoDB writes the transaction to disk in the write-ahead redo log (`ib_logfile`) before reporting success.

### Concurrency & Isolation Levels

ANSI/ISO SQL defines four isolation levels to manage concurrent read and write phenomena:

| Isolation Level | Dirty Read | Non-Repeatable Read | Phantom Read |
| :--- | :--- | :--- | :--- |
| **READ UNCOMMITTED** | Possible | Possible | Possible |
| **READ COMMITTED** | Prevented | Possible | Possible |
| **REPEATABLE READ** (InnoDB Default) | Prevented | Prevented | Prevented (via MVCC & Next-Key Locks) |
| **SERIALIZABLE** | Prevented | Prevented | Prevented |

#### Tying Isolation to This Schema
If two customers attempt to place overlapping orders against the same `product_id` stock concurrently under `READ COMMITTED`, both sessions could read the exact same available inventory before either writes, resulting in oversold stock unless explicit row locks (`SELECT ... FOR UPDATE`) are applied; under `SERIALIZABLE`, concurrent reads acquire shared locks and writes acquire exclusive range locks, preventing race conditions at the expense of higher lock wait timeouts and reduced throughput.

---

## 4. End-to-End Validation (`04_validation.sql`)

The repository includes [schema/transactions/04_validation.sql](../schema/transactions/04_validation.sql) to run regression checks against the transaction state:

```sql
-- 1. Verify committed order 9001 exists with both line items
SELECT * FROM orders_3nf WHERE order_id = 9001;       -- Returns 1 row
SELECT * FROM order_items_3nf WHERE order_id = 9001;  -- Returns 2 rows

-- 2. Verify rolled-back order 9002 is absent from both tables
SELECT * FROM orders_3nf WHERE order_id = 9002;       -- Returns 0 rows
SELECT * FROM order_items_3nf WHERE order_id = 9002;  -- Returns 0 rows

-- 3. Verify no orphaned order items exist anywhere in the schema
SELECT oi.*
FROM order_items_3nf oi
LEFT JOIN orders_3nf o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;                             -- Returns 0 rows (Referential integrity intact)

-- 4. Verify domain quantity checks
SELECT *
FROM order_items_3nf
WHERE quantity <= 0;                                  -- Returns 0 rows
```

---

## 5. What This Doesn't Cover Yet (Future Scope)

Honesty about scope boundaries and testing limits is critical engineering practice:

1. **Stock-Quantity Decrementing**:
   The current transaction scripts validate atomic creation of order headers and items, but do not yet decrement a stock balance on `products_3nf` (e.g., checking `stock_quantity >= quantity` and updating it). In production systems, order placement requires decrementing stock within the same transaction to guarantee inventory accuracy.
2. **Isolation-Level Testing Under Real Concurrency**:
   While isolation levels can be inspected and altered (`03_isolation_levels.sql`), this repository has not yet load-tested concurrent write collisions across two simultaneous sessions (such as simulating deadlocks, phantom inserts, or dirty reads under load). Demonstrating atomicity and consistency directly is fully covered here; load-testing isolation under concurrent multi-session writes is the natural next step.

---

## 6. Interview Talking Points

* **"Does a failed SQL statement automatically roll back a transaction in MySQL?"**  
  No. InnoDB aborts the single failing statement, but leaves the transaction open with previous statements still pending. The application must catch the exception and issue `ROLLBACK`.
* **"How do you prove Atomicity in a database?"**  
  By executing a multi-statement transaction where one step fails on a real constraint (e.g. order 9002 failing on `fk_order_items_product`), issuing `ROLLBACK`, and querying both parent and child tables to prove zero records were written.
* **"What is the difference between Consistency and Atomicity?"**  
  Atomicity ensures that all steps succeed or fail as a single unit (Order 9002 leaving no partial rows). Consistency guarantees that all database invariants and constraints (such as the foreign key rejecting `product_id = 999999`) are enforced throughout the transition.
* **"How does MySQL achieve Durability?"**  
  Via Write-Ahead Logging (WAL). When `COMMIT` is executed on Order 9001, InnoDB writes the changes sequentially to the redo log buffer and flushes them to disk (`ib_logfile`), guaranteeing recovery even if memory is lost immediately afterward.