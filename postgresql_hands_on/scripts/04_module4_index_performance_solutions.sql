/*
  MODULE 4 — INSTRUCTOR SOLUTIONS: INDEXES AND PERFORMANCE

  Run 04a_performance_lab_setup.sql first to remove indexes from a prior attempt.
  Timings and exact plan choices can vary by PostgreSQL version, settings,
  operating-system cache and computer hardware.
*/

-- ============================================================
-- EXERCISE 1 — INSPECT THE DATASET
-- ============================================================

SELECT
    count(*) AS row_count,
    min(order_date) AS earliest_order,
    max(order_date) AS latest_order
FROM sales.order_search_lab;

SELECT status, count(*) AS row_count
FROM sales.order_search_lab
GROUP BY status
ORDER BY status;

SELECT
    pg_size_pretty(pg_relation_size('sales.order_search_lab')) AS table_only,
    pg_size_pretty(pg_total_relation_size('sales.order_search_lab')) AS total_relation;


-- ============================================================
-- EXERCISE 2 — SINGLE-COLUMN INDEX
-- ============================================================

-- BASELINE: normally a Seq Scan because only the primary-key index exists.
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT order_no, order_date, status, total_amount
FROM sales.order_search_lab
WHERE customer_id = 1250;

CREATE INDEX idx_lab_customer
ON sales.order_search_lab (customer_id);

ANALYZE sales.order_search_lab;

-- AFTER: commonly a Bitmap Heap Scan/Bitmap Index Scan or Index Scan.
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT order_no, order_date, status, total_amount
FROM sales.order_search_lab
WHERE customer_id = 1250;

-- Expected matching rows: 50.


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

CREATE INDEX idx_lab_customer_date
ON sales.order_search_lab (customer_id, order_date DESC);

ANALYZE sales.order_search_lab;

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT order_no, order_date, status, total_amount
FROM sales.order_search_lab
WHERE customer_id = 1250
  AND order_date >= DATE '2025-01-01'
  AND order_date <  DATE '2026-01-01'
ORDER BY order_date DESC;

/*
  customer_id comes first because it uses equality. PostgreSQL can then scan
  the matching section of the index in order_date order and apply the range.
  The index can also supply DESC order, normally avoiding a separate Sort.
*/


-- ============================================================
-- EXERCISE 4 — LEFTMOST-COLUMN RULE
-- ============================================================

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT count(*)
FROM sales.order_search_lab
WHERE order_date >= DATE '2026-01-01'
  AND order_date <  DATE '2026-02-01';

/*
  idx_lab_customer_date starts with customer_id. With no customer condition,
  it is not the natural choice for an efficient contiguous date range.
  Create the next index only if date-only searches are frequent.
*/

CREATE INDEX idx_lab_order_date
ON sales.order_search_lab (order_date);

ANALYZE sales.order_search_lab;

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT count(*)
FROM sales.order_search_lab
WHERE order_date >= DATE '2026-01-01'
  AND order_date <  DATE '2026-02-01';


-- ============================================================
-- EXERCISE 5 — LOW SELECTIVITY
-- ============================================================

SELECT
    count(*) FILTER (WHERE status = 'SHIPPED') AS shipped_rows,
    count(*) AS all_rows,
    round(
        100.0 * count(*) FILTER (WHERE status = 'SHIPPED') / count(*),
        2
    ) AS shipped_percentage
FROM sales.order_search_lab;

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT count(*)
FROM sales.order_search_lab
WHERE status = 'SHIPPED';

/*
  SHIPPED represents most rows. Reading a large portion of the table through
  an index can require many random heap accesses, so Seq Scan may be cheaper.
  A status index is not created here.
*/


-- ============================================================
-- EXERCISE 6 — PARTIAL INDEX
-- ============================================================

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT order_no, order_date, customer_id, total_amount
FROM sales.order_search_lab
WHERE status = 'PENDING'
  AND order_date >= DATE '2026-01-01'
ORDER BY order_date DESC;

CREATE INDEX idx_lab_pending_date
ON sales.order_search_lab (order_date DESC)
WHERE status = 'PENDING';

ANALYZE sales.order_search_lab;

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT order_no, order_date, customer_id, total_amount
FROM sales.order_search_lab
WHERE status = 'PENDING'
  AND order_date >= DATE '2026-01-01'
ORDER BY order_date DESC;

SELECT
    pg_size_pretty(pg_relation_size('sales.idx_lab_pending_date')) AS partial_index_size,
    pg_size_pretty(pg_relation_size('sales.order_search_lab')) AS table_size;


-- ============================================================
-- EXERCISE 7 — EXPRESSION INDEX
-- ============================================================

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT lab_order_id, order_no, status
FROM sales.order_search_lab
WHERE lower(order_no) = lower('lab-00123456');

CREATE INDEX idx_lab_order_no_lower
ON sales.order_search_lab (lower(order_no));

ANALYZE sales.order_search_lab;

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT lab_order_id, order_no, status
FROM sales.order_search_lab
WHERE lower(order_no) = lower('lab-00123456');


-- ============================================================
-- EXERCISE 8 — COVERING INDEX
-- ============================================================

/*
  This wider index overlaps idx_lab_customer and idx_lab_customer_date.
  It is created for teaching; do not automatically keep all three.
*/
CREATE INDEX idx_lab_customer_date_cover
ON sales.order_search_lab (customer_id, order_date DESC)
INCLUDE (order_no, status, total_amount);

VACUUM (ANALYZE) sales.order_search_lab;

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT order_no, order_date, status, total_amount
FROM sales.order_search_lab
WHERE customer_id = 1250
ORDER BY order_date DESC;

/*
  Key columns participate in searching and ordering. INCLUDE columns are
  payload only. An Index Only Scan is possible when PostgreSQL's visibility
  map confirms that heap pages do not require checking.
*/


-- ============================================================
-- EXERCISE 9 — INDEX INVENTORY, USAGE AND SIZE
-- ============================================================

SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'sales'
  AND tablename = 'order_search_lab'
ORDER BY indexname;

SELECT
    indexrelname AS index_name,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'sales'
  AND relname = 'order_search_lab'
ORDER BY pg_relation_size(indexrelid) DESC;

SELECT
    pg_size_pretty(pg_relation_size('sales.order_search_lab')) AS table_only,
    pg_size_pretty(pg_indexes_size('sales.order_search_lab')) AS all_indexes,
    pg_size_pretty(pg_total_relation_size('sales.order_search_lab')) AS total;

/*
  For the demonstrated customer-list query, the covering index can replace the
  two narrower customer indexes if the extra storage/write cost is justified.
  Example cleanup:
*/

-- DROP INDEX sales.idx_lab_customer;
-- DROP INDEX sales.idx_lab_customer_date;


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

-- One defensible proposal:
CREATE INDEX idx_lab_report_date_status
ON sales.order_search_lab (order_date, status)
INCLUDE (customer_id, total_amount);

ANALYZE sales.order_search_lab;

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

/*
  Instructor note:
  The query may still prefer a Seq Scan because the date/status conditions
  return a substantial part of the table. If the new index produces little or
  no benefit, the evidence-based answer is to remove it:

  DROP INDEX sales.idx_lab_report_date_status;

  This demonstrates that tuning is measurement, not merely creating indexes.
*/

