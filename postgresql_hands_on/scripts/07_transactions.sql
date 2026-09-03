/* MODULE 6 — TRANSACTIONS, SAVEPOINTS AND ROW LOCKING */

-- 1. Atomic stock transfer demonstration. Nothing is retained.
BEGIN;

UPDATE sales.products SET stock_qty = stock_qty - 3 WHERE product_id = 2;
UPDATE sales.products SET stock_qty = stock_qty + 3 WHERE product_id = 6;

SELECT product_id, product_name, stock_qty
FROM sales.products
WHERE product_id IN (2, 6)
ORDER BY product_id;

ROLLBACK;

-- 2. SAVEPOINT: retain earlier work but undo a later business decision.
BEGIN;

UPDATE sales.products SET stock_qty = stock_qty + 5 WHERE product_id = 2;
SAVEPOINT after_mouse_restock;

UPDATE sales.products SET stock_qty = stock_qty - 5 WHERE product_id = 6;

-- PAUSE: decide that the second change should not be retained.
ROLLBACK TO SAVEPOINT after_mouse_restock;

SELECT product_id, product_name, stock_qty
FROM sales.products
WHERE product_id IN (2, 6)
ORDER BY product_id;

-- Use ROLLBACK for repeatable classroom delivery.
-- Replace with COMMIT only when the result has been validated and should persist.
ROLLBACK;

/*
  3. TWO-SESSION LOCKING DEMO

  Session A:
    BEGIN;
    SELECT product_id, stock_qty
    FROM sales.products
    WHERE product_id = 2
    FOR UPDATE;
    -- Keep the transaction open briefly.

  Session B:
    BEGIN;
    UPDATE sales.products
    SET stock_qty = stock_qty - 1
    WHERE product_id = 2;
    -- This waits until Session A commits or rolls back.

  Session A:
    COMMIT;

  Session B:
    COMMIT;
*/

-- 4. Inspect current sessions and transaction state (visibility depends on privileges).
SELECT pid, usename, state, wait_event_type, wait_event, query
FROM pg_stat_activity
WHERE datname = current_database()
ORDER BY pid;

-- TRY: Cancel an order and return all quantities to stock in one transaction.
-- Test using order_id = 4. Validate the rows, then ROLLBACK for a repeatable lab.

