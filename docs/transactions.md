# Transactions & ACID

## 1. What is a Transaction?

A transaction is a logical unit of database work that should be
completed completely or not applied at all.

In the order-management schema, creating an order and its order
items can be treated as one transaction.

## 2. Why Transactions Matter

Without transactions, a multi-step operation can leave the database
in an incomplete state.

Example:

Create Order
→ Create Item 1
→ Create Item 2 fails

Without rollback:

Order exists
Item 1 exists
Item 2 does not exist

This creates an inconsistent business state.

With a transaction:

START TRANSACTION
→ Create Order
→ Create Item 1
→ Item 2 fails
→ ROLLBACK

All changes are discarded.

## 3. ACID

### Atomicity

All operations in a transaction succeed together or the transaction
is rolled back.

Example:

Creating an order and its order items.

### Consistency

A successful transaction must leave the database satisfying its
constraints.

Examples in this repository:

- Foreign keys
- Primary keys
- UNIQUE constraints
- CHECK constraints

### Isolation

Concurrent transactions should not incorrectly interfere with
each other's intermediate states.

The main isolation levels are:

- READ UNCOMMITTED
- READ COMMITTED
- REPEATABLE READ
- SERIALIZABLE

### Durability

After COMMIT, the database must preserve the committed changes even
if the application session ends or the system restarts.

## 4. COMMIT

COMMIT permanently saves the changes made by the transaction.

## 5. ROLLBACK

ROLLBACK discards the uncommitted changes in the current transaction.

## 6. Transaction Failure

A failed SQL statement does not necessarily mean the entire
transaction is automatically rolled back.

Application or transaction logic must explicitly decide whether to
continue, recover, or execute ROLLBACK.

## 7. Isolation Levels

| Isolation Level | Dirty Read | Non-repeatable Read | Phantom Read |
|---|---|---|---|
| READ UNCOMMITTED | Possible | Possible | Possible |
| READ COMMITTED | No | Possible | Possible |
| REPEATABLE READ | No | No | DB-specific behavior |
| SERIALIZABLE | No | No | No |

For MySQL/InnoDB, isolation behavior should be verified using
actual concurrent sessions rather than relying only on textbook
definitions.

## 8. Repository Implementation

- `01_commit_order.sql` — successful transaction and COMMIT
- `02_rollback_order.sql` — failed operation and ROLLBACK
- `03_isolation_levels.sql` — isolation-level configuration
- `04_validation.sql` — validation of committed and rolled-back data

## 9. Interview Questions

### What is a transaction?

### Why is rollback required?

### What is ACID?

### What is a dirty read?

### What is a non-repeatable read?

### What is a phantom read?

### What is the difference between COMMIT and ROLLBACK?

### Does a failed SQL statement automatically rollback the transaction?

### Why does an application need transactions when creating an order?