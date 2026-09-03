/* INSTRUCTOR SOLUTIONS — FINAL HANDS-ON CHALLENGE */

-- TASK 1
SELECT
    c.category_name,
    p.sku,
    p.product_name,
    p.unit_price,
    p.stock_qty,
    p.unit_price * p.stock_qty AS stock_value
FROM sales.products AS p
JOIN sales.categories AS c ON c.category_id = p.category_id
WHERE p.active = true
ORDER BY stock_value DESC, p.product_name;

-- TASK 2
SELECT
    o.order_no,
    o.order_date,
    c.full_name,
    o.status,
    coalesce(sum(oi.line_total), 0)::numeric(12,2) AS order_total
FROM sales.orders AS o
JOIN sales.customers AS c ON c.customer_id = o.customer_id
LEFT JOIN sales.order_items AS oi ON oi.order_id = o.order_id
GROUP BY o.order_id, o.order_no, o.order_date, c.full_name, o.status
ORDER BY o.order_date, o.order_no;

-- TASK 3
SELECT p.product_id, p.sku, p.product_name
FROM sales.products AS p
WHERE NOT EXISTS (
    SELECT 1
    FROM sales.order_items AS oi
    JOIN sales.orders AS o ON o.order_id = oi.order_id
    WHERE oi.product_id = p.product_id
      AND o.status <> 'CANCELLED'
)
ORDER BY p.product_name;

-- TASK 4
SELECT
    c.category_name,
    coalesce(sum(oi.quantity) FILTER (WHERE o.status <> 'CANCELLED'), 0) AS units_sold,
    coalesce(sum(oi.line_total) FILTER (WHERE o.status <> 'CANCELLED'), 0) AS revenue
FROM sales.categories AS c
LEFT JOIN sales.products AS p ON p.category_id = c.category_id
LEFT JOIN sales.order_items AS oi ON oi.product_id = p.product_id
LEFT JOIN sales.orders AS o ON o.order_id = oi.order_id
GROUP BY c.category_id, c.category_name
ORDER BY revenue DESC, c.category_name;

-- TASK 5
WITH spend AS (
    SELECT
        c.customer_id,
        c.full_name,
        coalesce(sum(oi.line_total), 0) AS total_spend
    FROM sales.customers AS c
    LEFT JOIN sales.orders AS o
      ON o.customer_id = c.customer_id AND o.status <> 'CANCELLED'
    LEFT JOIN sales.order_items AS oi ON oi.order_id = o.order_id
    GROUP BY c.customer_id, c.full_name
)
SELECT
    full_name,
    total_spend,
    dense_rank() OVER (ORDER BY total_spend DESC) AS spend_rank,
    round(100 * total_spend / nullif(sum(total_spend) OVER (), 0), 2) AS revenue_pct
FROM spend
ORDER BY spend_rank, full_name;

-- TASK 6
CREATE OR REPLACE VIEW sales.v_low_stock_products AS
SELECT
    c.category_name,
    p.sku,
    p.product_name,
    p.stock_qty,
    p.unit_price
FROM sales.products AS p
JOIN sales.categories AS c ON c.category_id = p.category_id
WHERE p.active = true
  AND p.stock_qty < 20;

SELECT * FROM sales.v_low_stock_products ORDER BY stock_qty, product_name;

-- TASK 7
BEGIN;

DO $$
DECLARE
    v_status varchar(15);
BEGIN
    SELECT status INTO v_status
    FROM sales.orders
    WHERE order_id = 4
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Order 4 does not exist';
    ELSIF v_status = 'CANCELLED' THEN
        RAISE EXCEPTION 'Order 4 is already cancelled';
    END IF;
END;
$$;

UPDATE sales.products AS p
SET stock_qty = p.stock_qty + oi.quantity
FROM sales.order_items AS oi
WHERE oi.order_id = 4
  AND p.product_id = oi.product_id;

UPDATE sales.orders
SET status = 'CANCELLED'
WHERE order_id = 4;

SELECT order_id, order_no, status FROM sales.orders WHERE order_id = 4;
SELECT p.product_id, p.product_name, p.stock_qty
FROM sales.products AS p
JOIN sales.order_items AS oi ON oi.product_id = p.product_id
WHERE oi.order_id = 4;

ROLLBACK;

-- TASK 8
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_no, order_date, status
FROM sales.orders
WHERE customer_id = 2
  AND status IN ('PAID', 'SHIPPED')
ORDER BY order_date DESC;

CREATE INDEX IF NOT EXISTS idx_orders_customer_status_date
ON sales.orders (customer_id, status, order_date DESC);

ANALYZE sales.orders;

EXPLAIN (ANALYZE, BUFFERS)
SELECT order_no, order_date, status
FROM sales.orders
WHERE customer_id = 2
  AND status IN ('PAID', 'SHIPPED')
ORDER BY order_date DESC;

-- BONUS
BEGIN;
SELECT sales.fn_place_order(
    3,
    '[{"product_id":3,"quantity":1},{"product_id":7,"quantity":2}]'::jsonb
) AS new_order_id;

SELECT *
FROM sales.v_order_summary
WHERE order_no LIKE 'ORD-LAB-%'
ORDER BY order_id DESC
LIMIT 1;
SELECT product_id, product_name, stock_qty
FROM sales.products WHERE product_id IN (3, 7);
ROLLBACK;
