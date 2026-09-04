/*
  MODULE 4 — STUDENT LAB: INDEXES AND QUERY PERFORMANCE

  Prerequisite:
  Run 04a_performance_lab_setup.sql first.

  Instructions:
  - Run one exercise at a time.
  - Run each measured SELECT twice and record the second result.
  - Complete each TODO before looking at the instructor solution.
  - Actual timing varies; compare scan types, buffers and rows as well.
*/

-- ============================================================
-- EXERCISE 1 — INSPECT THE DATASET
-- ============================================================

-- TODO 1A: Count the rows and find the minimum/maximum order dates.

-- TODO 1B: Count rows by status.

-- TODO 1C: Show table-only and total relation sizes.


-- ============================================================
-- EXERCISE 2 — SINGLE-COLUMN INDEX
-- ============================================================

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT order_no, order_date, status, total_amount
FROM sales.order_search_lab
WHERE customer_id = 1250;

-- TODO 2A: Record scan type, actual rows, buffers and execution time.
-- TODO 2B: Create idx_lab_customer on customer_id.
-- TODO 2C: Run ANALYZE and repeat the query.


-- ============================================================
-- EXERCISE 3 — COMPOSITE INDEX
-- ============================================================

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT order_no, order_date, status, total_amount
FROM sales.order_search_lab
WHERE customer_id = 1250
  AND order_date >= DATE '2025-01-01'
  AND order_date <  DATE '2026-01-01'
ORDER BY order_date DESC;

-- TODO 3A: Create an index supporting customer, date range and ordering.
-- TODO 3B: Repeat EXPLAIN and check whether a Sort node remains.
-- TODO 3C: Explain the selected column order.


-- ============================================================
-- EXERCISE 4 — LEFTMOST-COLUMN RULE
-- ============================================================

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT count(*)
FROM sales.order_search_lab
WHERE order_date >= DATE '2026-01-01'
  AND order_date <  DATE '2026-02-01';

-- TODO 4A: Does the customer-first composite index fully support this query?
-- TODO 4B: If date-only searches are frequent, propose a suitable index.


-- ============================================================
-- EXERCISE 5 — LOW SELECTIVITY
-- ============================================================

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT count(*)
FROM sales.order_search_lab
WHERE status = 'SHIPPED';

-- TODO 5A: Calculate the percentage of rows that are SHIPPED.
-- TODO 5B: Explain why a normal status index may not be selected.


-- ============================================================
-- EXERCISE 6 — PARTIAL INDEX
-- ============================================================

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT order_no, order_date, customer_id, total_amount
FROM sales.order_search_lab
WHERE status = 'PENDING'
  AND order_date >= DATE '2026-01-01'
ORDER BY order_date DESC;

-- TODO 6A: Create idx_lab_pending_date containing only PENDING rows.
-- TODO 6B: Repeat EXPLAIN and inspect the partial-index size.


-- ============================================================
-- EXERCISE 7 — EXPRESSION INDEX
-- ============================================================

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT lab_order_id, order_no, status
FROM sales.order_search_lab
WHERE lower(order_no) = lower('lab-00123456');

-- TODO 7A: Create an index on lower(order_no).
-- TODO 7B: Repeat EXPLAIN and explain the change.


-- ============================================================
-- EXERCISE 8 — COVERING INDEX
-- ============================================================

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT order_no, order_date, status, total_amount
FROM sales.order_search_lab
WHERE customer_id = 1250
ORDER BY order_date DESC;

-- TODO 8A: Create a customer/date index that INCLUDEs the output columns.
-- TODO 8B: Run VACUUM (ANALYZE), repeat the query and check for
--          Index Only Scan and Heap Fetches.


-- ============================================================
-- EXERCISE 9 — INDEX INVENTORY, USAGE AND SIZE
-- ============================================================

-- TODO 9A: List all indexes on order_search_lab using pg_indexes.
-- TODO 9B: Show idx_scan using pg_stat_user_indexes.
-- TODO 9C: Show each index size with pg_relation_size(indexrelid).
-- TODO 9D: Identify overlapping indexes.


-- ============================================================
-- EXERCISE 10 — FINAL TUNING CHALLENGE
-- ============================================================

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT customer_id,
       count(*) AS order_count,
       sum(total_amount) AS total_sales
FROM sales.order_search_lab
WHERE order_date >= DATE '2026-01-01'
  AND order_date <  DATE '2026-07-01'
  AND status IN ('PAID', 'SHIPPED')
GROUP BY customer_id
HAVING sum(total_amount) >= 20000
ORDER BY total_sales DESC;

-- TODO 10A: Propose and create no more than one index.
-- TODO 10B: Measure again.
-- TODO 10C: Keep or drop it, and justify the decision with plan evidence.

