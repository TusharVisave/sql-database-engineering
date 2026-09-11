# SQL Database Engineering

A practical SQL and database engineering repository focused on **relational database design, SQL querying, data relationships, normalization, and database fundamentals** using MySQL.

This repository is being developed progressively from SQL fundamentals toward **Java database integration, JPA/Hibernate, query optimization, transactions, and production-oriented database design**.

---

## 🎯 Objectives

The main objectives of this repository are to:

* Build strong SQL fundamentals.
* Understand relational database design.
* Design normalized database schemas.
* Work with primary keys and foreign keys.
* Write practical SQL queries using joins and aggregation.
* Understand `NULL` and relationship-based queries.
* Practice database concepts using realistic datasets.
* Build a foundation for JDBC, JPA, and Hibernate.

---

# 📚 Current Project — Library Management System

The first database project is a small **Library Management System**.

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
* **Loans** — stores book borrowing transactions.

A member can have multiple loans, while a book can appear in multiple loan records over time.

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

### Books → Loans

One book can have many loan records over its lifetime.

```text
books.book_id
      │
      └──────────► loans.book_id
```

### Members → Loans

One member can have multiple loan records.

```text
members.member_id
      │
      └──────────► loans.member_id
```

The `loans` table therefore represents the **transaction relationship** between books and members.

---

# 🔐 Database Constraints

The schema uses several important relational database constraints.

### Primary Key

Uniquely identifies each record.

```sql
PRIMARY KEY (book_id)
```

### Foreign Key

Maintains relationships between tables and provides referential integrity.

```sql
FOREIGN KEY (book_id)
REFERENCES books(book_id)
```

### NOT NULL

Prevents required fields from containing `NULL`.

```sql
title VARCHAR(200) NOT NULL
```

### UNIQUE

Prevents duplicate values.

```sql
email VARCHAR(150) UNIQUE
```

### CHECK

Validates data based on a condition.

```sql
CHECK (due_date >= loan_date)
```

---

# 🧠 Design Decisions

## Why separate books and members?

Books and members are different entities with different attributes.

Keeping them in separate tables avoids unnecessary duplication and makes the database easier to maintain.

---

## Why does loans store IDs instead of names?

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

For example, if a member changes their name, only the `members` table needs to be updated.

---

## Why use foreign keys?

Foreign keys ensure that a loan references an existing book and member.

For example:

```text
loans.book_id → books.book_id
loans.member_id → members.member_id
```

This prevents invalid relationships and maintains referential integrity.

---

# 📐 Normalization

The current schema follows basic normalization principles.

## First Normal Form — 1NF

Each column contains atomic values.

For example:

```text
name  → Rahul
email → rahul@example.com
```

A column does not contain multiple independent values.

---

## Second Normal Form — 2NF

Each non-key attribute depends on the appropriate primary key.

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

Non-key attributes depend on the key rather than on other non-key attributes.

For example, member information belongs in `members` instead of being repeatedly stored in `loans`.

---

# 👥 Multiple Authors — Future Improvement

The current design stores one author in the `books` table:

```text
author
```

This is acceptable for the initial project but does not scale well when a book has multiple authors.

For example:

```text
Book A → Author A, Author B, Author C
```

A better normalized design would introduce:

```text
books
authors
book_authors
```

where `book_authors` acts as a bridge table.

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

This represents a **many-to-many relationship** between books and authors.

---

# 📊 Sample Dataset

## Books

| ID | Title                                 | Author               |
| -: | ------------------------------------- | -------------------- |
|  1 | Clean Code                            | Robert C. Martin     |
|  2 | Effective Java                        | Joshua Bloch         |
|  3 | Database System Concepts              | Abraham Silberschatz |
|  4 | Designing Data-Intensive Applications | Martin Kleppmann     |

## Members

| ID | Name  | Email                                         |
| -: | ----- | --------------------------------------------- |
|  1 | Rahul | [rahul@example.com](mailto:rahul@example.com) |
|  2 | Priya | [priya@example.com](mailto:priya@example.com) |
|  3 | Amit  | [amit@example.com](mailto:amit@example.com)   |
|  4 | Sneha | [sneha@example.com](mailto:sneha@example.com) |

## Loans

| ID |                                  Book | Member | Loan Date  | Due Date   | Returned |
| -: | ------------------------------------: | -----: | ---------- | ---------- | -------- |
|  1 |                            Clean Code |  Rahul | 2026-08-01 | 2026-08-15 | No       |
|  2 |                        Effective Java |  Rahul | 2026-08-05 | 2026-08-19 | Yes      |
|  3 |              Database System Concepts |  Priya | 2026-09-01 | 2026-09-15 | No       |
|  4 | Designing Data-Intensive Applications |  Priya | 2026-09-05 | 2026-09-19 | No       |

---

# 🔎 SQL Queries

The repository currently contains five practical queries.

## 1. Find Overdue Loans

Uses:

* `INNER JOIN`
* `WHERE`
* `NULL` handling
* Date comparison

Finds loans where the book has not been returned and the due date has passed.

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

### Expected Result

| Member | Book       | Due Date   |
| ------ | ---------- | ---------- |
| Rahul  | Clean Code | 2026-08-15 |

---

## 2. Count Loans Per Member

Uses:

* `LEFT JOIN`
* `GROUP BY`
* `COUNT()`

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

### Expected Result

| Member | Total Loans |
| ------ | ----------: |
| Rahul  |           2 |
| Priya  |           2 |
| Amit   |           0 |
| Sneha  |           0 |

The `LEFT JOIN` ensures that members with zero loans are also included.

---

## 3. Find Members With No Loans

Uses:

* `LEFT JOIN`
* `IS NULL`

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

### Expected Result

| Member | Email                                         |
| ------ | --------------------------------------------- |
| Amit   | [amit@example.com](mailto:amit@example.com)   |
| Sneha  | [sneha@example.com](mailto:sneha@example.com) |

### Important SQL Pattern

```sql
LEFT JOIN
WHERE right_table.id IS NULL
```

This is a common pattern for finding records that **do not have a matching record**.

---

## 4. List Currently Borrowed Books

Uses:

* `INNER JOIN`
* Multiple table joins
* `IS NULL`

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

### Expected Result

| Book                                  | Member | Loan Date  | Due Date   |
| ------------------------------------- | ------ | ---------- | ---------- |
| Clean Code                            | Rahul  | 2026-08-01 | 2026-08-15 |
| Database System Concepts              | Priya  | 2026-09-01 | 2026-09-15 |
| Designing Data-Intensive Applications | Priya  | 2026-09-05 | 2026-09-19 |

---

## 5. Count Loans Per Book

Uses:

* `LEFT JOIN`
* `GROUP BY`
* `COUNT()`
* `ORDER BY`

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

### Expected Result

| Book                                  | Loan Count |
| ------------------------------------- | ---------: |
| Clean Code                            |          1 |
| Effective Java                        |          1 |
| Database System Concepts              |          1 |
| Designing Data-Intensive Applications |          1 |

---

# 🧩 SQL Concepts Practiced

| Concept        | Usage                      |
| -------------- | -------------------------- |
| `SELECT`       | Retrieve data              |
| `WHERE`        | Filter records             |
| `INNER JOIN`   | Match related records      |
| `LEFT JOIN`    | Preserve unmatched records |
| `GROUP BY`     | Group records              |
| `COUNT()`      | Aggregate records          |
| `ORDER BY`     | Sort results               |
| `IS NULL`      | Check missing values       |
| `CURRENT_DATE` | Work with current date     |
| Primary Key    | Identify records           |
| Foreign Key    | Create relationships       |
| `NOT NULL`     | Enforce required values    |
| `UNIQUE`       | Prevent duplicates         |
| `CHECK`        | Validate data              |

---

# 🛠️ Tools & Technologies

* **MySQL**
* **MySQL Workbench**
* **SQL**
* **Git**
* **GitHub**
* **IntelliJ IDEA**

---

# 📁 Project Structure

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
* Constraints
* Sample data

### `queries.sql`

Contains practical SQL queries for analyzing the library database.

### `README.md`

Contains:

* Database documentation
* Schema explanation
* Design decisions
* Normalization
* Sample data
* Query explanations
* Expected results
* SQL concepts

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
CTEs
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
Concurrency & Isolation
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

# 📌 Current Progress

### Database Fundamentals

* [x] Schema creation
* [x] Table design
* [x] Primary keys
* [x] Foreign keys
* [x] `NOT NULL`
* [x] `UNIQUE`
* [x] `CHECK` constraints
* [x] One-to-many relationships
* [x] Basic normalization

### SQL

* [x] `SELECT`
* [x] `WHERE`
* [x] `INNER JOIN`
* [x] `LEFT JOIN`
* [x] `GROUP BY`
* [x] `COUNT()`
* [x] `ORDER BY`
* [x] `NULL` handling
* [x] Date filtering
* [x] Multi-table queries

### Future

* [ ] Subqueries
* [ ] CTEs
* [ ] Window functions
* [ ] Indexing
* [ ] Query optimization
* [ ] Transactions
* [ ] ACID
* [ ] Isolation levels
* [ ] JDBC
* [ ] JPA
* [ ] Hibernate
* [ ] Advanced database design

---

# 🎯 Long-Term Goal

The goal of this repository is not only to learn SQL syntax but to develop the ability to **design, query, integrate, and reason about relational databases in real software systems**.

The progression is:

```text
Design the Database
        ↓
Write Correct SQL
        ↓
Understand Relationships
        ↓
Optimize Queries
        ↓
Handle Transactions
        ↓
Integrate with Java
        ↓
Build Database-Driven Applications
```

This repository will serve as the database foundation for future **Java backend and Spring Boot projects**.
