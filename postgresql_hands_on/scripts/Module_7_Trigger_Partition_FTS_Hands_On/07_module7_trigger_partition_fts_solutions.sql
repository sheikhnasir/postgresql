/*
  MODULE 7 INSTRUCTOR SOLUTIONS
  Run scripts/07a_trigger_partition_fts_setup.sql first.
*/

-- ============================================================
-- PART A — TRIGGERS
-- ============================================================

-- A1.
SELECT
    trigger_name,
    action_timing,
    event_manipulation
FROM information_schema.triggers
WHERE event_object_schema = 'sales'
  AND event_object_table = 'products'
ORDER BY trigger_name, event_manipulation;

-- A2.
BEGIN;

UPDATE sales.products
SET unit_price = unit_price + 5
WHERE product_id = 3;

SELECT
    audit_id,
    product_id,
    old_price,
    new_price,
    changed_at,
    changed_by
FROM audit.product_price_log
WHERE product_id = 3
ORDER BY audit_id DESC
LIMIT 1;

ROLLBACK;

-- A3. Expected: before_count equals after_count.
BEGIN;

CREATE TEMP TABLE audit_count_before AS
SELECT count(*) AS row_count
FROM audit.product_price_log
WHERE product_id = 3;

UPDATE sales.products
SET product_name = product_name || ' Demo'
WHERE product_id = 3;

SELECT
    b.row_count AS before_count,
    count(a.*) AS after_count
FROM audit_count_before AS b
LEFT JOIN audit.product_price_log AS a
    ON a.product_id = 3
GROUP BY b.row_count;

ROLLBACK;

-- A4. Run these statements separately in pgAdmin.
BEGIN;

UPDATE sales.products
SET stock_qty = -5
WHERE product_id = 2;

-- Expected error:
-- Stock cannot be negative. Product 2, attempted stock -5
ROLLBACK;

-- A5.
-- OLD.unit_price is the value stored before the UPDATE.
-- NEW.unit_price is the value proposed/stored by the UPDATE.

-- ============================================================
-- PART B — PARTITIONING
-- ============================================================

-- B6.
SELECT
    parent_ns.nspname || '.' || parent.relname AS parent_table,
    child_ns.nspname || '.' || child.relname AS partition_table
FROM pg_inherits AS i
JOIN pg_class AS parent ON parent.oid = i.inhparent
JOIN pg_namespace AS parent_ns ON parent_ns.oid = parent.relnamespace
JOIN pg_class AS child ON child.oid = i.inhrelid
JOIN pg_namespace AS child_ns ON child_ns.oid = child.relnamespace
WHERE parent_ns.nspname = 'sales'
  AND parent.relname = 'orders_partition_lab'
ORDER BY partition_table;

-- B7.
SELECT
    tableoid::regclass AS physical_partition,
    count(*) AS row_count
FROM sales.orders_partition_lab
GROUP BY tableoid
ORDER BY physical_partition::text;

-- B8.
BEGIN;

INSERT INTO sales.orders_partition_lab
    (order_id, order_no, customer_id, order_date, status, order_total)
VALUES
    (9101, 'ORD-STUDENT-MAY', 1, DATE '2026-05-20', 'PAID', 100.00),
    (9102, 'ORD-STUDENT-JUL', 1, DATE '2026-07-20', 'PENDING', 200.00);

SELECT
    order_no,
    order_date,
    tableoid::regclass AS physical_partition
FROM sales.orders_partition_lab
WHERE order_id IN (9101, 9102)
ORDER BY order_id;

ROLLBACK;

-- Expected:
-- ORD-STUDENT-MAY -> sales.orders_partition_2026_05
-- ORD-STUDENT-JUL -> sales.orders_partition_default

-- B9.
EXPLAIN (ANALYZE, COSTS OFF)
SELECT *
FROM sales.orders_partition_lab
WHERE order_date >= DATE '2026-06-01'
  AND order_date <  DATE '2026-07-01';

-- Expected partition: sales.orders_partition_2026_06.

-- B10.
-- PostgreSQL cannot enforce uniqueness across independent partitions unless
-- the unique/primary-key columns include the partition key. Including
-- order_date allows uniqueness to be enforced locally within each partition.

-- ============================================================
-- PART C — FULL-TEXT SEARCH
-- ============================================================

-- C11.
SELECT product_name, search_vector
FROM sales.product_search_lab
WHERE product_id IN (2, 4)
ORDER BY product_id;

-- C12.
SELECT product_name, category_name
FROM sales.product_search_lab
WHERE search_vector @@ plainto_tsquery('english', 'wireless')
ORDER BY product_name;

-- C13.
SELECT product_name, category_name
FROM sales.product_search_lab
WHERE search_vector
      @@ websearch_to_tsquery('english', 'mouse OR keyboard')
ORDER BY product_name;

-- C14.
WITH q AS (
    SELECT websearch_to_tsquery('english', 'portable storage') AS query
)
SELECT
    p.product_name,
    p.category_name,
    ts_rank(p.search_vector, q.query) AS rank
FROM sales.product_search_lab AS p
CROSS JOIN q
WHERE p.search_vector @@ q.query
ORDER BY rank DESC, p.product_name;

-- C15.
SET enable_seqscan = off;

EXPLAIN (COSTS OFF)
SELECT product_name
FROM sales.product_search_lab
WHERE search_vector @@ to_tsquery('english', 'wireless');

RESET enable_seqscan;

-- BONUS.
SELECT product_name, category_name
FROM sales.product_search_lab
WHERE search_vector
      @@ websearch_to_tsquery('english', 'storage -HDD')
ORDER BY product_name;
