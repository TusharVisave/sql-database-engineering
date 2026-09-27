-- ============================================================
-- DAY 4 - ISOLATION LEVELS
-- ============================================================

USE order_management;

-- Check current isolation level

SELECT @@transaction_isolation;

-- ------------------------------------------------------------
-- Available isolation levels
-- ------------------------------------------------------------

SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT @@transaction_isolation;

SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

SELECT @@transaction_isolation;

SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

SELECT @@transaction_isolation;

SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SELECT @@transaction_isolation;

-- ------------------------------------------------------------
-- Restore the normal MySQL isolation level used for this
-- learning environment.
-- ------------------------------------------------------------

SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

SELECT @@transaction_isolation;