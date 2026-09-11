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

SELECT
    m.member_id,
    m.name,
    COUNT(l.loan_id) AS total_loans
FROM library.members m
         LEFT JOIN library.loans l
                   ON m.member_id = l.member_id
GROUP BY m.member_id, m.name;

SELECT
    m.member_id,
    m.name,
    m.email
FROM library.members m
         LEFT JOIN library.loans l
                   ON m.member_id = l.member_id
WHERE l.loan_id IS NULL;

SELECT
    b.title,
    m.name AS member_name,
    l.loan_date,
    l.due_date
FROM library.loans l
         JOIN library.books b
              ON l.book_id = b.book_id
         JOIN library.members m
              ON l.member_id = m.member_id
WHERE l.return_date IS NULL;

SELECT
    b.book_id,
    b.title,
    COUNT(l.loan_id) AS loan_count
FROM library.books b
         LEFT JOIN library.loans l
                   ON b.book_id = l.book_id
GROUP BY b.book_id, b.title
ORDER BY loan_count DESC;