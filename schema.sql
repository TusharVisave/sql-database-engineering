CREATE SCHEMA library;

CREATE TABLE library.books (
                               book_id INTEGER PRIMARY KEY,
                               title VARCHAR(200) NOT NULL,
                               isbn VARCHAR(20) NOT NULL UNIQUE,
                               author VARCHAR(150) NOT NULL,
                               published_year INTEGER
);

CREATE TABLE library.members (
                                 member_id INTEGER PRIMARY KEY,
                                 name VARCHAR(100) NOT NULL,
                                 email VARCHAR(150) NOT NULL UNIQUE,
                                 joined_date DATE NOT NULL
);

CREATE TABLE library.loans (
                               loan_id INTEGER PRIMARY KEY,
                               book_id INTEGER NOT NULL,
                               member_id INTEGER NOT NULL,
                               loan_date DATE NOT NULL,
                               due_date DATE NOT NULL,
                               return_date DATE,

                               CONSTRAINT fk_loan_book
                                   FOREIGN KEY (book_id)
                                       REFERENCES library.books(book_id),

                               CONSTRAINT fk_loan_member
                                   FOREIGN KEY (member_id)
                                       REFERENCES library.members(member_id),

                               CONSTRAINT chk_due_date
                                   CHECK (due_date >= loan_date),

                               CONSTRAINT chk_return_date
                                   CHECK (return_date IS NULL OR return_date >= loan_date)
);