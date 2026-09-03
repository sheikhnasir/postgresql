/* MODULE 7 — EXPLAIN, INDEXES AND LEAST PRIVILEGE */

-- 1. Establish a query plan before adding indexes.
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT o.order_no, o.order_date, o.status
FROM sales.orders AS o
WHERE o.customer_id = 1
  AND o.order_date >= DATE '2026-04-01'
ORDER BY o.order_date DESC;

-- 2. Index predicates and ordering used together by a real query.
CREATE INDEX IF NOT EXISTS idx_orders_customer_date
ON sales.orders (customer_id, order_date DESC);

CREATE INDEX IF NOT EXISTS idx_order_items_product
ON sales.order_items (product_id);

CREATE INDEX IF NOT EXISTS idx_products_active_category
ON sales.products (category_id)
WHERE active = true;

-- 3. Refresh planner statistics, then compare the plan.
ANALYZE sales.orders;
ANALYZE sales.order_items;
ANALYZE sales.products;

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT o.order_no, o.order_date, o.status
FROM sales.orders AS o
WHERE o.customer_id = 1
  AND o.order_date >= DATE '2026-04-01'
ORDER BY o.order_date DESC;

-- DISCUSS: a sequential scan can still be best for seven rows.
-- Never claim an index improvement without measuring representative data.

-- 4. Find defined indexes.
SELECT schemaname, tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'sales'
ORDER BY tablename, indexname;

-- 5. Inspect table/index sizes.
SELECT
    relname,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size
FROM pg_catalog.pg_statio_user_tables
WHERE schemaname = 'sales'
ORDER BY pg_total_relation_size(relid) DESC;

/*
  6. OPTIONAL SECURITY LAB — requires database-owner privileges.
  Run this section only when each learner has an isolated lab database.

  Group roles do not log in. Login roles/users are granted membership separately.
*/

-- CREATE ROLE techstore_readonly NOLOGIN;
-- CREATE ROLE techstore_app NOLOGIN;

-- GRANT CONNECT ON DATABASE techstore_db TO techstore_readonly, techstore_app;
-- GRANT USAGE ON SCHEMA sales TO techstore_readonly, techstore_app;

-- GRANT SELECT ON ALL TABLES IN SCHEMA sales TO techstore_readonly;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA sales TO techstore_app;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA sales TO techstore_app;
-- GRANT EXECUTE ON ALL ROUTINES IN SCHEMA sales TO techstore_app;

-- Ensure future tables follow the same policy (run as the object-creating owner).
-- ALTER DEFAULT PRIVILEGES IN SCHEMA sales
--   GRANT SELECT ON TABLES TO techstore_readonly;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA sales
--   GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO techstore_app;

-- Example membership after an administrator creates a login role:
-- GRANT techstore_readonly TO analyst_login;

-- VERIFY (after optional grants):
-- SELECT grantee, table_schema, table_name, privilege_type
-- FROM information_schema.role_table_grants
-- WHERE grantee IN ('techstore_readonly', 'techstore_app')
-- ORDER BY grantee, table_name, privilege_type;
