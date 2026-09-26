# Day 2 — Relationships, Foreign Keys, and Constraints

## Objective
Understand relational database relationships, foreign key constraints, cascading actions, and how to resolve Many-to-Many (M:N) mappings in MySQL.

---

## 1. Relationship Types

### 1. One-to-One (1:1)
One record in Table A relates to at most one record in Table B, and vice-versa.

**Example**: `customers` ↔ `customer_profiles`
```text
┌──────────────┐          ┌──────────────────────┐
│  customers   ├──────────┤  customer_profiles   │
│ (customer_id)│   1 : 1  │ (profile_id, cust_id)│
└──────────────┘          └──────────────────────┘
```
* **Implementation**: Foreign key placed on either side with a `UNIQUE` constraint.

---

### 2. One-to-Many (1:N)
One record in Table A relates to many records in Table B, but each record in Table B relates to only one record in Table A.

**Example**: `customers` ↔ `orders`
```text
┌──────────────┐          ┌──────────────────────┐
│  customers   │  1       │        orders        │
│ (customer_id)├─────────►│(order_id, cust_id FK)│
└──────────────┘        N └──────────────────────┘
```
* **Implementation**: The foreign key `customer_id` is placed in the child table (`orders`).

---

### 3. Many-to-Many (M:N)
One record in Table A relates to multiple records in Table B, and one record in Table B relates to multiple records in Table A.

**Example**: `products_3nf` ↔ `categories`
* A product (e.g., *Wireless Keyboard*) can belong to multiple categories (*Electronics*, *Accessories*).
* A category (e.g., *Electronics*) can contain multiple products (*Keyboard*, *Mouse*, *Monitor*).

```text
┌────────────────┐          ┌────────────────────┐          ┌──────────────┐
│  products_3nf  │ 1      N │ product_categories │ N      1 │  categories  │
│  (product_id)  ├─────────►│ (product_id FK,    │◄─────────┤(category_id) │
│                │          │  category_id FK)   │          │              │
└────────────────┘          └────────────────────┘          └──────────────┘
```

* **Resolution**: Relational databases resolve M:N relationships by introducing an intermediate **junction (bridge/associative) table**:
  - `product_categories` holds pairs of foreign keys.
  - The composite primary key `(product_id, category_id)` prevents duplicate associations.

---

## 2. Foreign Key Rules & Referential Integrity

### Exact Data Type Matching
In MySQL (and standard SQL engines), the foreign key column must have the **exact same data type** as the referenced primary key column:
* `products_3nf.product_id` is `INT` → `product_categories.product_id` must be `INT`.
* `categories.category_id` is `BIGINT` → `product_categories.category_id` must be `BIGINT`.

Mismatched types (such as `BIGINT` referencing `INT`) result in MySQL error `ERROR 3780 (HY000)`.

### Cascade Deletion (`ON DELETE CASCADE`)
```sql
CONSTRAINT fk_product_categories_product
    FOREIGN KEY (product_id)
    REFERENCES products_3nf(product_id)
    ON DELETE CASCADE
```
* If a product or category is deleted, all corresponding links in `product_categories` are automatically removed.
* This avoids leaving orphan foreign key records in the junction table.

---

## 3. Querying Many-to-Many Relationships

### Joining Products with Categories
To retrieve each product along with its categories:

```sql
SELECT
    p.product_id,
    p.product_name,
    c.category_name
FROM products_3nf p
JOIN product_categories pc
    ON p.product_id = pc.product_id
JOIN categories c
    ON pc.category_id = c.category_id
ORDER BY p.product_id;
```

### Aggregating: Product Counts by Category
To count how many products exist in each category (including empty categories):

```sql
SELECT
    c.category_name,
    COUNT(pc.product_id) AS product_count
FROM categories c
LEFT JOIN product_categories pc
    ON c.category_id = pc.category_id
GROUP BY c.category_id, c.category_name
ORDER BY product_count DESC;
```