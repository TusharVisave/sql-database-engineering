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

| book_id | title                                 | author               | published_year |
| ------: | ------------------------------------- | -------------------- | -------------: |
|       1 | Clean Code                            | Robert C. Martin     |           2008 |
|       2 | Effective Java                        | Joshua Bloch         |           2018 |
|       3 | Database System Concepts              | Abraham Silberschatz |           2019 |
|       4 | Designing Data-Intensive Applications | Martin Kleppmann     |           2017 |

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

# 🛠️ Tools & Technologies

* **MySQL**
* **MySQL Workbench**
* **SQL**
* **Git**
* **GitHub**
* **IntelliJ IDEA**

---

# 📁 Repository Structure

```text
sql-database-engineering/
│
├── schema.sql
├── queries.sql
├── README.md
└── .gitignore
```

### `schema.sql`

Contains:

* Database creation
* Table definitions
* Primary keys
* Foreign keys
* Database constraints
* Sample data

### `queries.sql`

Contains the practical SQL queries used to analyze the library database.

### `README.md`

Contains:

* Schema documentation
* Relationships
* Design decisions
* Normalization
* Sample dataset
* Manual query walkthroughs
* Expected outputs
* SQL concepts
* Learning roadmap

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
Indexes
       ↓
Query Optimization
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
* [x] Basic normalization

## SQL

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

## Future

* [ ] Subqueries
* [ ] `HAVING`
* [ ] `CASE`
* [ ] CTEs
* [ ] Window functions
* [ ] Indexing
* [ ] Query optimization
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
