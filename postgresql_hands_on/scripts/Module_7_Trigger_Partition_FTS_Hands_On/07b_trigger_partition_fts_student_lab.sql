/*
  MODULE 7 STUDENT LAB
  Triggers, partitioning and full-text search

  Run 07a_trigger_partition_fts_setup.sql first.
  Complete each TODO before checking the instructor solution.
*/

-- ============================================================
-- PART A — TRIGGERS
-- ============================================================

-- Q1. List every trigger on sales.products.
-- Show trigger name, timing and event.
-- TODO:


-- Q2. Increase product 3's price by RM5.00 inside a transaction.
-- Display its newest audit row, then ROLLBACK so the seed price is unchanged.
-- TODO:


-- Q3. Update only product 3's product_name inside a transaction.
-- Prove that the price-audit row count does not increase, then ROLLBACK.
-- TODO:


-- Q4. Test the stock guard by attempting to set product 2's stock_qty to -5.
-- Run BEGIN first. After the expected error, run ROLLBACK separately.
-- TODO:


-- Q5. Written answer:
-- In an UPDATE trigger, what do OLD.unit_price and NEW.unit_price represent?
-- ANSWER:


-- ============================================================
-- PART B — PARTITIONING
-- ============================================================

-- Q6. List the parent table and all its partitions using pg_inherits.
-- Show parent_table and partition_table.
-- TODO:


-- Q7. Count rows in every physical partition.
-- Hint: tableoid::regclass identifies the physical table.
-- TODO:


-- Q8. Insert these rows into the PARENT table inside a transaction:
--   (9101, 'ORD-STUDENT-MAY', 1, '2026-05-20', 'PAID', 100.00)
--   (9102, 'ORD-STUDENT-JUL', 1, '2026-07-20', 'PENDING', 200.00)
-- Query tableoid::regclass to show where each row went, then ROLLBACK.
-- TODO:


-- Q9. Use EXPLAIN (ANALYZE, COSTS OFF) to retrieve orders from June 2026.
-- Which partition appears in the execution plan?
-- TODO:


-- Q10. Written answer:
-- Why is PRIMARY KEY (order_id, order_date) used instead of PRIMARY KEY
-- (order_id) on this range-partitioned table?
-- ANSWER:


-- ============================================================
-- PART C — FULL-TEXT SEARCH
-- ============================================================

-- Q11. Display product_name and search_vector for products 2 and 4.
-- TODO:


-- Q12. Find products matching the word "wireless".
-- Use @@ and plainto_tsquery('english', ...).
-- TODO:


-- Q13. Find products matching either "mouse" or "keyboard".
-- Use websearch_to_tsquery and web-search OR syntax.
-- TODO:


-- Q14. Search for "portable storage".
-- Display product_name, category_name and ts_rank; highest rank first.
-- Calculate the tsquery once in a CTE.
-- TODO:


-- Q15. Use EXPLAIN (COSTS OFF) on the "wireless" full-text query.
-- For this tiny table, PostgreSQL may choose a sequential scan. Temporarily
-- use SET enable_seqscan = off to demonstrate that the GIN index can support
-- the query, then RESET enable_seqscan.
-- TODO:


-- BONUS. Search for storage but exclude HDD.
-- Hint: websearch_to_tsquery understands the minus sign.
-- TODO:
