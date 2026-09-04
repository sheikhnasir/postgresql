/*
  MODULE 6 — POSTGRESQL FUNCTIONS: SETUP AND GUIDED DEMONSTRATION
  Database: techstore_db
  Prerequisite: 01_schema.sql and 02_seed_data.sql
  Run one numbered section at a time in pgAdmin Query Tool.
*/

SET search_path TO sales, public;

-- 0. PREFLIGHT CHECK
DO $$
BEGIN
    IF to_regclass('sales.products') IS NULL
       OR to_regclass('sales.customers') IS NULL
       OR to_regclass('sales.orders') IS NULL
       OR to_regclass('sales.order_items') IS NULL THEN
        RAISE EXCEPTION
            'TechStore tables are missing. Run 01_schema.sql and 02_seed_data.sql first.';
    END IF;
END;
$$;

SELECT
    (SELECT count(*) FROM sales.products) AS products,
    (SELECT count(*) FROM sales.customers) AS customers,
    (SELECT count(*) FROM sales.orders) AS orders,
    (SELECT count(*) FROM sales.order_items) AS order_items;

-- 1. SIMPLE SQL FUNCTION: RETURN ONE PRODUCT NAME
CREATE OR REPLACE FUNCTION sales.fn_product_name(p_product_id integer)
RETURNS text
LANGUAGE sql
STABLE
AS $$
    SELECT p.product_name::text
    FROM sales.products AS p
    WHERE p.product_id = p_product_id;
$$;

SELECT sales.fn_product_name(2) AS product_name;

SELECT
    oi.order_id,
    oi.product_id,
    sales.fn_product_name(oi.product_id) AS product_name,
    oi.quantity
FROM sales.order_items AS oi
WHERE oi.order_id = 1
ORDER BY oi.product_id;

-- 2. SQL AGGREGATE FUNCTION: CALCULATE ONE ORDER TOTAL
CREATE OR REPLACE FUNCTION sales.fn_order_total(p_order_id bigint)
RETURNS numeric(12,2)
LANGUAGE sql
STABLE
AS $$
    SELECT coalesce(sum(oi.line_total), 0)::numeric(12,2)
    FROM sales.order_items AS oi
    WHERE oi.order_id = p_order_id;
$$;

SELECT sales.fn_order_total(1) AS order_1_total;

SELECT
    o.order_id,
    o.order_no,
    sales.fn_order_total(o.order_id) AS order_total
FROM sales.orders AS o
ORDER BY o.order_id;

-- 3. PL/pgSQL FUNCTION: VALIDATION, VARIABLE AND CALCULATION
CREATE OR REPLACE FUNCTION sales.fn_price_after_discount(
    p_price numeric,
    p_discount_percent numeric DEFAULT 0
)
RETURNS numeric(12,2)
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    v_final_price numeric(12,2);
BEGIN
    IF p_price IS NULL OR p_price < 0 THEN
        RAISE EXCEPTION 'Price must be zero or greater';
    END IF;

    IF p_discount_percent IS NULL
       OR p_discount_percent < 0
       OR p_discount_percent > 100 THEN
        RAISE EXCEPTION 'Discount percentage must be between 0 and 100';
    END IF;

    v_final_price := p_price * (1 - p_discount_percent / 100.0);
    RETURN round(v_final_price, 2);
END;
$$;

SELECT sales.fn_price_after_discount(100.00, 10) AS discounted_price;
SELECT sales.fn_price_after_discount(100.00) AS price_without_discount;

-- Run this expected-error test separately:
-- SELECT sales.fn_price_after_discount(100.00, 110);

-- 4. PL/pgSQL FUNCTION: SELECT INTO, FOUND AND CASE
CREATE OR REPLACE FUNCTION sales.fn_product_stock_status(p_product_id integer)
RETURNS text
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_stock_qty integer;
    v_active boolean;
BEGIN
    SELECT p.stock_qty, p.active
    INTO v_stock_qty, v_active
    FROM sales.products AS p
    WHERE p.product_id = p_product_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Product ID % does not exist', p_product_id;
    END IF;

    RETURN CASE
        WHEN NOT v_active THEN 'INACTIVE'
        WHEN v_stock_qty = 0 THEN 'OUT OF STOCK'
        WHEN v_stock_qty <= 10 THEN 'LOW STOCK'
        ELSE 'IN STOCK'
    END;
END;
$$;

SELECT
    p.product_id,
    p.product_name,
    p.stock_qty,
    sales.fn_product_stock_status(p.product_id) AS stock_status
FROM sales.products AS p
ORDER BY p.product_id;

-- Run this expected-error test separately:
-- SELECT sales.fn_product_stock_status(9999);

-- 5. TABLE-RETURNING FUNCTION: ORDERS FOR ONE CUSTOMER
CREATE OR REPLACE FUNCTION sales.fn_customer_orders(p_customer_id bigint)
RETURNS TABLE (
    order_id bigint,
    order_no varchar(20),
    order_date date,
    status varchar(15),
    order_total numeric(12,2)
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM sales.customers AS c
        WHERE c.customer_id = p_customer_id
    ) THEN
        RAISE EXCEPTION 'Customer ID % does not exist', p_customer_id;
    END IF;

    RETURN QUERY
    SELECT
        o.order_id,
        o.order_no,
        o.order_date,
        o.status,
        sales.fn_order_total(o.order_id)
    FROM sales.orders AS o
    WHERE o.customer_id = p_customer_id
    ORDER BY o.order_date, o.order_id;
END;
$$;

SELECT * FROM sales.fn_customer_orders(1);
SELECT * FROM sales.fn_customer_orders(6);

-- 6. TABLE-RETURNING SQL FUNCTION: CUSTOMER SALES SUMMARY
CREATE OR REPLACE FUNCTION sales.fn_customer_sales_summary(p_customer_id bigint)
RETURNS TABLE (
    customer_id bigint,
    customer_name text,
    total_orders bigint,
    total_sales numeric(12,2)
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        c.customer_id,
        c.full_name::text,
        count(DISTINCT o.order_id),
        coalesce(sum(oi.line_total), 0)::numeric(12,2)
    FROM sales.customers AS c
    LEFT JOIN sales.orders AS o
        ON o.customer_id = c.customer_id
       AND o.status <> 'CANCELLED'
    LEFT JOIN sales.order_items AS oi
        ON oi.order_id = o.order_id
    WHERE c.customer_id = p_customer_id
    GROUP BY c.customer_id, c.full_name;
$$;

SELECT * FROM sales.fn_customer_sales_summary(1);

-- 7. ADVANCED PL/pgSQL FUNCTION: CREATE ONE ORDER ATOMICALLY
CREATE OR REPLACE FUNCTION sales.fn_create_single_item_order(
    p_customer_id bigint,
    p_product_id integer,
    p_quantity integer
)
RETURNS bigint
LANGUAGE plpgsql
VOLATILE
AS $$
DECLARE
    v_order_id bigint;
    v_unit_price numeric(10,2);
    v_stock_qty integer;
    v_active boolean;
BEGIN
    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        RAISE EXCEPTION 'Quantity must be greater than zero';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM sales.customers AS c
        WHERE c.customer_id = p_customer_id
    ) THEN
        RAISE EXCEPTION 'Customer ID % does not exist', p_customer_id;
    END IF;

    SELECT p.unit_price, p.stock_qty, p.active
    INTO v_unit_price, v_stock_qty, v_active
    FROM sales.products AS p
    WHERE p.product_id = p_product_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Product ID % does not exist', p_product_id;
    END IF;

    IF NOT v_active THEN
        RAISE EXCEPTION 'Product ID % is inactive', p_product_id;
    END IF;

    IF v_stock_qty < p_quantity THEN
        RAISE EXCEPTION
            'Insufficient stock for product %. Available: %, requested: %',
            p_product_id, v_stock_qty, p_quantity;
    END IF;

    SELECT nextval(pg_get_serial_sequence('sales.orders', 'order_id'))
    INTO v_order_id;

    INSERT INTO sales.orders
        (order_id, order_no, customer_id, order_date, status)
    VALUES (
        v_order_id,
        format('ORD-LAB-%s', lpad(v_order_id::text, 6, '0')),
        p_customer_id,
        current_date,
        'PENDING'
    );

    INSERT INTO sales.order_items
        (order_id, product_id, quantity, unit_price, discount)
    VALUES
        (v_order_id, p_product_id, p_quantity, v_unit_price, 0);

    UPDATE sales.products
    SET stock_qty = stock_qty - p_quantity
    WHERE product_id = p_product_id;

    RETURN v_order_id;
END;
$$;

-- Demonstrate without permanently changing the sample data.
BEGIN;

SELECT sales.fn_create_single_item_order(1, 2, 2) AS new_order_id;

SELECT
    o.order_id,
    o.order_no,
    o.customer_id,
    o.status,
    sales.fn_order_total(o.order_id) AS order_total
FROM sales.orders AS o
WHERE o.order_no LIKE 'ORD-LAB-%'
ORDER BY o.order_id DESC;

SELECT product_id, product_name, stock_qty
FROM sales.products
WHERE product_id = 2;

ROLLBACK;

-- 8. LIST THE FUNCTIONS CREATED IN THIS LAB
SELECT
    n.nspname AS function_schema,
    p.proname AS function_name,
    pg_get_function_identity_arguments(p.oid) AS arguments,
    pg_get_function_result(p.oid) AS return_type,
    l.lanname AS language,
    CASE p.provolatile
        WHEN 'i' THEN 'IMMUTABLE'
        WHEN 's' THEN 'STABLE'
        ELSE 'VOLATILE'
    END AS volatility
FROM pg_proc AS p
JOIN pg_namespace AS n ON n.oid = p.pronamespace
JOIN pg_language AS l ON l.oid = p.prolang
WHERE n.nspname = 'sales'
  AND p.proname LIKE 'fn_%'
ORDER BY p.proname;

/* OPTIONAL CLEANUP — uncomment only when required.
DROP FUNCTION IF EXISTS sales.fn_create_single_item_order(bigint, integer, integer);
DROP FUNCTION IF EXISTS sales.fn_customer_sales_summary(bigint);
DROP FUNCTION IF EXISTS sales.fn_customer_orders(bigint);
DROP FUNCTION IF EXISTS sales.fn_product_stock_status(integer);
DROP FUNCTION IF EXISTS sales.fn_price_after_discount(numeric, numeric);
DROP FUNCTION IF EXISTS sales.fn_order_total(bigint);
DROP FUNCTION IF EXISTS sales.fn_product_name(integer);
*/
