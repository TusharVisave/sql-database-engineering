-- ============================================================
-- SEED DATA: LIBRARY MANAGEMENT SYSTEM
-- ============================================================

USE library;

-- ------------------------------------------------------------
-- 1. Books
-- ------------------------------------------------------------

INSERT INTO library.books (book_id, title, isbn, author, published_year)
VALUES
    (1, 'Clean Code', '978-0132350884', 'Robert C. Martin', 2008),
    (2, 'Effective Java', '978-0134685991', 'Joshua Bloch', 2018),
    (3, 'Database System Concepts', '978-0078022159', 'Abraham Silberschatz', 2019),
    (4, 'Designing Data-Intensive Applications', '978-1449373320', 'Martin Kleppmann', 2017)
ON DUPLICATE KEY UPDATE title = VALUES(title);

-- ------------------------------------------------------------
-- 2. Members
-- ------------------------------------------------------------

INSERT INTO library.members (member_id, name, email, joined_date)
VALUES
    (1, 'Rahul', 'rahul@example.com', '2026-01-10'),
    (2, 'Priya', 'priya@example.com', '2026-02-15'),
    (3, 'Amit', 'amit@example.com', '2026-03-20'),
    (4, 'Sneha', 'sneha@example.com', '2026-04-05')
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- ------------------------------------------------------------
-- 3. Loans
-- ------------------------------------------------------------

INSERT INTO library.loans (loan_id, book_id, member_id, loan_date, due_date, return_date)
VALUES
    (1, 1, 1, '2026-08-01', '2026-08-15', NULL),
    (2, 2, 1, '2026-08-05', '2026-08-19', '2026-08-15'),
    (3, 3, 2, '2026-09-01', '2026-09-15', NULL),
    (4, 4, 2, '2026-09-05', '2026-09-19', NULL)
ON DUPLICATE KEY UPDATE return_date = VALUES(return_date);
