/* MODULE 6 — INSTRUCTOR SOLUTIONS: POSTGRESQL FUNCTIONS */

SET search_path TO sales, public;

-- TASK 1
SELECT
    oi.product_id,
    sales.fn_product_name(oi.product_id) AS product_name,
    oi.quantity,
    oi.line_total
FROM sales.order_items AS oi
WHERE oi.order_id = 1
ORDER BY oi.product_id;

-- TASK 2
SELECT
    o.order_no,
    sales.fn_order_total(o.order_id) AS order_total
FROM sales.orders AS o
ORDER BY order_total DESC, o.order_no;

-- TASK 3
CREATE OR REPLACE FUNCTION sales.fn_customer_order_count(p_customer_id bigint)
RETURNS bigint
LANGUAGE sql
STABLE
AS $$
    SELECT count(*)
    FROM sales.orders AS o
    WHERE o.customer_id = p_customer_id;
$$;

SELECT sales.fn_customer_order_count(1) AS customer_1_orders;

-- TASK 4
SELECT
    p.product_id,
    p.product_name,
    p.unit_price AS original_price,
    sales.fn_price_after_discount(p.unit_price, 15) AS discounted_price
FROM sales.products AS p
WHERE p.active
ORDER BY p.product_id;

-- TASK 5
SELECT sales.fn_price_after_discount(250.00) AS unchanged_price;
-- p_discount_percent has a default value of 0.

-- TASK 6
SELECT
    p.product_name,
    p.stock_qty,
    sales.fn_product_stock_status(p.product_id) AS stock_status
FROM sales.products AS p
ORDER BY p.stock_qty, p.product_name;

-- TASK 7
-- Expected to fail when run separately:
-- SELECT sales.fn_price_after_discount(200, -5);

SELECT sales.fn_price_after_discount(200, 5) AS corrected_result;

-- TASK 8
SELECT *
FROM sales.fn_customer_orders(2);

-- TASK 9
SELECT
    c.full_name AS customer_name,
    fo.order_id,
    fo.order_no,
    fo.order_date,
    fo.status,
    fo.order_total
FROM sales.customers AS c
CROSS JOIN LATERAL sales.fn_customer_orders(c.customer_id) AS fo
WHERE c.customer_id = 1
ORDER BY fo.order_date, fo.order_id;

-- TASK 10
SELECT * FROM sales.fn_customer_sales_summary(1);
SELECT * FROM sales.fn_customer_sales_summary(6);
-- Customer 1 has orders and sales; customer 6 remains in the result with
-- zero orders and zero sales because the function uses LEFT JOIN.

-- TASK 11
CREATE OR REPLACE FUNCTION sales.fn_order_value_category(p_order_id bigint)
RETURNS text
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_order_total numeric(12,2);
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM sales.orders AS o
        WHERE o.order_id = p_order_id
    ) THEN
        RAISE EXCEPTION 'Order ID % does not exist', p_order_id;
    END IF;

    v_order_total := sales.fn_order_total(p_order_id);

    RETURN CASE
        WHEN v_order_total >= 1000 THEN 'HIGH'
        WHEN v_order_total >= 500 THEN 'MEDIUM'
        ELSE 'LOW'
    END;
END;
$$;

SELECT
    o.order_no,
    sales.fn_order_total(o.order_id) AS order_total,
    sales.fn_order_value_category(o.order_id) AS value_category
FROM sales.orders AS o
ORDER BY o.order_id;

-- TASK 12
BEGIN;

SELECT sales.fn_create_single_item_order(3, 6, 3) AS new_order_id;

SELECT
    o.order_id,
    o.order_no,
    o.customer_id,
    sales.fn_order_total(o.order_id) AS order_total
FROM sales.orders AS o
WHERE o.order_no LIKE 'ORD-LAB-%'
ORDER BY o.order_id DESC;

SELECT product_id, product_name, stock_qty
FROM sales.products
WHERE product_id = 6;

ROLLBACK;

SELECT count(*) AS lab_orders_after_rollback
FROM sales.orders
WHERE order_no LIKE 'ORD-LAB-%';

-- BONUS
SELECT
    p.proname AS function_name,
    pg_get_function_identity_arguments(p.oid) AS arguments,
    pg_get_function_result(p.oid) AS return_type
FROM pg_proc AS p
JOIN pg_namespace AS n ON n.oid = p.pronamespace
WHERE n.nspname = 'sales'
ORDER BY p.proname;

