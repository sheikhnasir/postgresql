/*
  MODULE 7 SETUP AND DEMONSTRATION
  Triggers, range partitioning and PostgreSQL full-text search

  Prerequisites:
    - Connect to techstore_db.
    - Run 01_schema.sql and 02_seed_data.sql first.

  This script is rerunnable. It rebuilds only the two Module 7 lab tables.
*/

-- ============================================================
-- A. TRIGGERS
-- ============================================================

-- A1. AFTER trigger: write an audit row only after a price change succeeds.
CREATE OR REPLACE FUNCTION audit.fn_log_product_price_change()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO audit.product_price_log
        (product_id, old_price, new_price, changed_at, changed_by)
    VALUES
        (OLD.product_id, OLD.unit_price, NEW.unit_price,
         current_timestamp, current_user);

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_product_price_audit ON sales.products;

CREATE TRIGGER trg_product_price_audit
AFTER UPDATE OF unit_price ON sales.products
FOR EACH ROW
WHEN (OLD.unit_price IS DISTINCT FROM NEW.unit_price)
EXECUTE FUNCTION audit.fn_log_product_price_change();

-- A2. BEFORE trigger: reject an invalid stock quantity.
CREATE OR REPLACE FUNCTION sales.fn_validate_product_stock()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.stock_qty < 0 THEN
        RAISE EXCEPTION
            'Stock cannot be negative. Product %, attempted stock %',
            NEW.product_id,
            NEW.stock_qty
            USING ERRCODE = 'check_violation';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_product_stock_guard ON sales.products;

CREATE TRIGGER trg_product_stock_guard
BEFORE INSERT OR UPDATE OF stock_qty ON sales.products
FOR EACH ROW
EXECUTE FUNCTION sales.fn_validate_product_stock();

-- A3. Inspect installed triggers.
SELECT
    event_object_schema,
    event_object_table,
    trigger_name,
    action_timing,
    event_manipulation
FROM information_schema.triggers
WHERE event_object_schema IN ('sales', 'audit')
ORDER BY event_object_table, trigger_name, event_manipulation;

-- A4. Safe audit demonstration: the data and audit row are rolled back.
BEGIN;

UPDATE sales.products
SET unit_price = unit_price + 10
WHERE product_id = 2;

SELECT
    audit_id,
    product_id,
    old_price,
    new_price,
    changed_at,
    changed_by
FROM audit.product_price_log
WHERE product_id = 2
ORDER BY audit_id DESC
LIMIT 1;

ROLLBACK;

-- The negative-stock test is intentionally left in the student lab because
-- an expected exception stops "run all" execution in many SQL clients.

-- ============================================================
-- B. RANGE PARTITIONING
-- ============================================================

DROP TABLE IF EXISTS sales.orders_partition_lab CASCADE;

CREATE TABLE sales.orders_partition_lab (
    order_id     bigint NOT NULL,
    order_no     varchar(30) NOT NULL,
    customer_id  bigint NOT NULL,
    order_date   date NOT NULL,
    status       varchar(15) NOT NULL,
    notes        text,
    order_total  numeric(12,2) NOT NULL DEFAULT 0,
    PRIMARY KEY (order_id, order_date)
) PARTITION BY RANGE (order_date);

CREATE TABLE sales.orders_partition_2026_04
PARTITION OF sales.orders_partition_lab
FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');

CREATE TABLE sales.orders_partition_2026_05
PARTITION OF sales.orders_partition_lab
FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');

CREATE TABLE sales.orders_partition_2026_06
PARTITION OF sales.orders_partition_lab
FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');

CREATE TABLE sales.orders_partition_default
PARTITION OF sales.orders_partition_lab DEFAULT;

-- Indexes are created separately on each physical partition.
CREATE INDEX idx_orders_part_2026_04_status
    ON sales.orders_partition_2026_04 (status);
CREATE INDEX idx_orders_part_2026_05_status
    ON sales.orders_partition_2026_05 (status);
CREATE INDEX idx_orders_part_2026_06_status
    ON sales.orders_partition_2026_06 (status);
CREATE INDEX idx_orders_part_default_status
    ON sales.orders_partition_default (status);

-- Copy the original April and May orders through the logical parent.
INSERT INTO sales.orders_partition_lab
    (order_id, order_no, customer_id, order_date, status, notes, order_total)
SELECT
    o.order_id,
    o.order_no,
    o.customer_id,
    o.order_date,
    o.status,
    o.notes,
    coalesce(sum(oi.line_total), 0)::numeric(12,2)
FROM sales.orders AS o
LEFT JOIN sales.order_items AS oi ON oi.order_id = o.order_id
GROUP BY
    o.order_id,
    o.order_no,
    o.customer_id,
    o.order_date,
    o.status,
    o.notes;

-- Add rows that demonstrate the June and default partitions.
INSERT INTO sales.orders_partition_lab
    (order_id, order_no, customer_id, order_date, status, notes, order_total)
VALUES
    (9001, 'ORD-PART-9001', 1, DATE '2026-06-15',
     'PAID', 'June partition example', 599.00),
    (9002, 'ORD-PART-9002', 2, DATE '2026-07-05',
     'PENDING', 'Default partition example', 249.00);

ANALYZE sales.orders_partition_lab;

-- Verify row routing.
SELECT
    tableoid::regclass AS physical_partition,
    count(*) AS row_count,
    min(order_date) AS earliest_date,
    max(order_date) AS latest_date
FROM sales.orders_partition_lab
GROUP BY tableoid
ORDER BY physical_partition::text;

-- Observe pruning: only the May partition is relevant.
EXPLAIN (ANALYZE, COSTS OFF)
SELECT *
FROM sales.orders_partition_lab
WHERE order_date >= DATE '2026-05-01'
  AND order_date <  DATE '2026-06-01';

-- ============================================================
-- C. FULL-TEXT SEARCH
-- ============================================================

DROP TABLE IF EXISTS sales.product_search_lab;

CREATE TABLE sales.product_search_lab (
    product_id       integer PRIMARY KEY,
    sku              varchar(20) NOT NULL,
    product_name     varchar(120) NOT NULL,
    category_name    varchar(80) NOT NULL,
    description      text,
    unit_price       numeric(10,2) NOT NULL,
    search_vector    tsvector GENERATED ALWAYS AS (
        setweight(
            to_tsvector(
                'english'::regconfig,
                coalesce(product_name, '')
            ),
            'A'
        )
        ||
        setweight(
            to_tsvector(
                'english'::regconfig,
                coalesce(category_name, '') || ' ' ||
                coalesce(description, '')
            ),
            'B'
        )
    ) STORED
);

INSERT INTO sales.product_search_lab
    (product_id, sku, product_name, category_name, description, unit_price)
SELECT
    p.product_id,
    p.sku,
    p.product_name,
    c.category_name,
    c.description,
    p.unit_price
FROM sales.products AS p
JOIN sales.categories AS c ON c.category_id = p.category_id;

-- Add richer descriptions for meaningful search combinations.
UPDATE sales.product_search_lab
SET description = CASE product_id
    WHEN 1 THEN 'Portable professional computer for office productivity'
    WHEN 2 THEN 'Wireless ergonomic pointing device for laptop users'
    WHEN 3 THEN 'Mechanical USB keyboard for developers and gaming'
    WHEN 4 THEN 'Fast wireless router with Wi-Fi 6 networking'
    WHEN 5 THEN 'Portable solid state storage with one terabyte capacity'
    WHEN 6 THEN 'USB-C multiport adapter for laptop connectivity'
    WHEN 7 THEN 'Eight-port wired gigabit networking switch'
    WHEN 8 THEN 'External magnetic disk storage with two terabyte capacity'
    ELSE description
END;

CREATE INDEX idx_product_search_vector_gin
    ON sales.product_search_lab
    USING GIN (search_vector);

ANALYZE sales.product_search_lab;

-- Inspect how PostgreSQL normalizes the document.
SELECT product_name, search_vector
FROM sales.product_search_lab
ORDER BY product_id;

-- Search using web-style syntax.
SELECT
    product_name,
    category_name,
    ts_rank(
        search_vector,
        websearch_to_tsquery('english', 'wireless router')
    ) AS rank
FROM sales.product_search_lab
WHERE search_vector
      @@ websearch_to_tsquery('english', 'wireless router')
ORDER BY rank DESC, product_name;

-- Ranked search with a query calculated once.
WITH q AS (
    SELECT websearch_to_tsquery('english', 'portable storage') AS query
)
SELECT
    p.product_name,
    p.category_name,
    p.unit_price,
    ts_rank(p.search_vector, q.query) AS rank
FROM sales.product_search_lab AS p
CROSS JOIN q
WHERE p.search_vector @@ q.query
ORDER BY rank DESC, p.product_name;

-- Because this classroom table is tiny, PostgreSQL may prefer a sequential
-- scan. SET enable_seqscan = off is used only to demonstrate index capability.
SET enable_seqscan = off;

EXPLAIN (COSTS OFF)
SELECT product_name
FROM sales.product_search_lab
WHERE search_vector @@ to_tsquery('english', 'wireless');

RESET enable_seqscan;

-- Final object check.
SELECT 'partition rows' AS check_name, count(*) AS result
FROM sales.orders_partition_lab
UNION ALL
SELECT 'search rows', count(*)
FROM sales.product_search_lab;
