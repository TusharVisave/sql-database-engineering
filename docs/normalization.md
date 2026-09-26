# Database Normalization — Order Management Example

## Objective

This exercise demonstrates how an order-management database can be systematically transformed from an unnormalized design into a Third Normal Form (3NF) design.

The progression is:

```text
Unnormalized
     ↓
    1NF
     ↓
    2NF
     ↓
    3NF
```

---

## 1. Unnormalized Form (UNF)

### Concept
An unnormalized table often groups multiple values or repeating data within single rows or comma-separated columns.

### Example Table: `orders_unnormalized`
* Primary Key: `order_id`
* Non-atomic attributes: `product_ids`, `product_names`, `product_prices`, `quantities`

```text
order_id | customer_name | product_ids | product_names  | quantities
---------+---------------+-------------+----------------+-----------
1001     | Rahul Sharma  | 101,102     | Keyboard,Mouse | 1,2
1002     | Priya Patil   | 103         | Monitor        | 1
```

### Problems Identified
1. **Atomicity Violation**: Multiple values are stored in a single column (e.g., `'101,102'`).
2. **Difficult Querying**: Querying for a single product requires fragile substring matching (`LIKE '%101%'`).
3. **Update Anomalies**: Changing a product name requires modifying strings in every row containing that product.
4. **Insertion Anomalies**: Cannot record a new product without first having an order for it.
5. **Deletion Anomalies**: Deleting an order also deletes the product and customer details.

---

## 2. First Normal Form (1NF)

### 1NF Requirements
1. Every column must store **atomic** (indivisible) values.
2. No repeating groups or comma-separated lists.
3. Each row must be uniquely identifiable (primary key).

### 1NF Schema: `orders_1nf`
We expand each ordered product into its own row and define a composite primary key:
* **Composite Primary Key**: `(order_id, product_id)`
* **Columns**: `order_id`, `customer_id`, `customer_name`, `customer_email`, `product_id`, `product_name`, `product_price`, `quantity`, `order_date`

```text
order_id | customer_name | product_id | product_name | quantity
---------+---------------+------------+--------------+---------
1001     | Rahul Sharma  | 101        | Keyboard     | 1
1001     | Rahul Sharma  | 102        | Mouse        | 2
1002     | Priya Patil   | 103        | Monitor      | 1
```

### Remaining Problem: Partial Functional Dependencies
* `order_id -> customer_id, customer_name, customer_email, order_date` (depends only on part of the composite key).
* `product_id -> product_name, product_price` (depends only on part of the composite key).
* Only `quantity` depends on the full composite key `(order_id, product_id)`.

---

## 3. Second Normal Form (2NF)

### 2NF Requirements
1. Must already satisfy **1NF**.
2. Must remove all **partial dependencies** (all non-key attributes must depend on the whole candidate key).

### 2NF Decomposition
Split `orders_1nf` into three tables:

1. **`products_2nf`**:
   * Primary Key: `product_id`
   * Attributes: `product_name`, `product_price`

2. **`orders_2nf`**:
   * Primary Key: `order_id`
   * Attributes: `customer_id`, `customer_name`, `customer_email`, `order_date`

3. **`order_items_2nf`**:
   * Composite Primary Key: `(order_id, product_id)`
   * Attributes: `quantity`
   * Foreign Keys:
     * `order_id` references `orders_2nf(order_id)`
     * `product_id` references `products_2nf(product_id)`

### Remaining Problem: Transitive Functional Dependencies
In `orders_2nf`:
* `order_id -> customer_id`
* `customer_id -> customer_name, customer_email`
* Therefore: `order_id -> customer_name` is a **transitive dependency**.
* If a customer updates their email or places no orders, customer data cannot exist independently.

---

## 4. Third Normal Form (3NF)

### 3NF Requirements
1. Must already satisfy **2NF**.
2. Must remove all **transitive dependencies** (non-key attributes must depend *only* on candidate keys, not on other non-key attributes: *"the key, the whole key, and nothing but the key"*).

### Final 3NF Schema

```text
┌─────────────────┐
│  customers_3nf  │
└────────┬────────┘
         │ 1
         │
         │ N
┌────────▼────────┐       N ┌───────────────────┐ 1       ┌────────────────┐
│   orders_3nf    ├────────►│  order_items_3nf  │◄────────┤  products_3nf  │
└─────────────────┘         └───────────────────┘         └────────────────┘
```

1. **`customers_3nf`**:
   * Primary Key: `customer_id`
   * Attributes: `customer_name`, `customer_email` (UNIQUE)

2. **`orders_3nf`**:
   * Primary Key: `order_id`
   * Attributes: `customer_id` (FK), `order_date`

3. **`products_3nf`**:
   * Primary Key: `product_id`
   * Attributes: `product_name`, `product_price` (`CHECK product_price >= 0`)

4. **`order_items_3nf`**:
   * Composite Primary Key: `(order_id, product_id)`
   * Attributes: `quantity` (`CHECK quantity > 0`)
   * Foreign Keys:
     * `order_id` references `orders_3nf(order_id)`
     * `product_id` references `products_3nf(product_id)`

---

## 5. Benefits Achieved
* **Zero redundancy**: Customer names/emails and product names/prices are stored in exactly one place.
* **Elimination of anomalies**: Customers and products can exist before orders are created, and updating a price or email requires only one row update.
* **Integrity constraints**: Foreign key constraints guarantee referential integrity across orders and items.