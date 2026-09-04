/*
  MODULE 4 — INDEX AND PERFORMANCE LAB SETUP

  Purpose:
  - Create a sufficiently large, deterministic dataset for query-plan testing.
  - Keep the original TechStore sales.orders table unchanged.

  Expected runtime depends on the computer. The script creates 250,000 rows.
*/

DROP TABLE IF EXISTS sales.order_search_lab;

CREATE TABLE sales.order_search_lab (
    lab_order_id bigint PRIMARY KEY,
    order_no     varchar(20) NOT NULL,
    customer_id  integer NOT NULL,
    order_date   date NOT NULL,
    status       varchar(15) NOT NULL,
    total_amount numeric(12,2) NOT NULL,
    reference_no varchar(30) NOT NULL,
    notes        text
);

INSERT INTO sales.order_search_lab
    (lab_order_id, order_no, customer_id, order_date, status,
     total_amount, reference_no, notes)
SELECT
    gs::bigint,
    'LAB-' || lpad(gs::text, 8, '0'),
    ((gs * 37) % 5000 + 1)::integer,
    DATE '2024-01-01' + ((gs * 13) % 900)::integer,
    CASE
        WHEN gs % 20 = 0 THEN 'PENDING'
        WHEN gs % 20 = 1 THEN 'CANCELLED'
        WHEN gs % 5 = 0  THEN 'PAID'
        ELSE 'SHIPPED'
    END,
    round((50 + ((gs * 19) % 200000) / 100.0)::numeric, 2),
    'PAY-' || lpad(((gs * 7919) % 100000000)::text, 8, '0'),
    CASE
        WHEN gs % 10 = 0 THEN 'Priority web order'
        WHEN gs % 7 = 0  THEN 'Collect in store'
        ELSE NULL
    END
FROM generate_series(1, 250000) AS gs;

-- Supply planner statistics and visibility information for repeatable plans.
VACUUM (ANALYZE) sales.order_search_lab;

-- VERIFY
SELECT
    count(*) AS row_count,
    min(order_date) AS earliest_order,
    max(order_date) AS latest_order,
    count(DISTINCT customer_id) AS distinct_customers
FROM sales.order_search_lab;

SELECT status, count(*) AS row_count
FROM sales.order_search_lab
GROUP BY status
ORDER BY status;

SELECT
    pg_size_pretty(pg_relation_size('sales.order_search_lab')) AS table_only,
    pg_size_pretty(pg_total_relation_size('sales.order_search_lab')) AS total_with_primary_key;

