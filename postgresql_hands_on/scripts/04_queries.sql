/* MODULE 3 — SELECT, FILTERS, JOINS AND AGGREGATION */

-- 1. Filter and sort. PostgreSQL ILIKE is case-insensitive.
SELECT product_name, unit_price, stock_qty
FROM sales.products
WHERE active = true
  AND product_name ILIKE '%wire%'
ORDER BY unit_price DESC;

-- 2. Range and list predicates.
SELECT order_no, order_date, status
FROM sales.orders
WHERE order_date BETWEEN DATE '2026-04-01' AND DATE '2026-04-30'
  AND status IN ('PAID', 'PROCESSING', 'SHIPPED')
ORDER BY order_date, order_no;

-- 3. INNER JOIN: orders with their customers.
SELECT o.order_no, o.order_date, c.full_name, c.city, o.status
FROM sales.orders AS o
JOIN sales.customers AS c ON c.customer_id = o.customer_id
ORDER BY o.order_date;

-- 4. Multi-table detail report.
SELECT
    o.order_no,
    c.full_name,
    p.product_name,
    oi.quantity,
    oi.unit_price,
    oi.discount,
    oi.line_total
FROM sales.orders AS o
JOIN sales.customers AS c  ON c.customer_id = o.customer_id
JOIN sales.order_items AS oi ON oi.order_id = o.order_id
JOIN sales.products AS p   ON p.product_id = oi.product_id
ORDER BY o.order_no, p.product_name;

-- 5. GROUP BY: one row per order.
SELECT
    o.order_no,
    c.full_name,
    count(*) AS item_lines,
    sum(oi.quantity) AS units,
    sum(oi.line_total) AS order_total
FROM sales.orders AS o
JOIN sales.customers AS c ON c.customer_id = o.customer_id
JOIN sales.order_items AS oi ON oi.order_id = o.order_id
GROUP BY o.order_id, o.order_no, c.full_name
ORDER BY order_total DESC;

-- 6. HAVING filters groups after aggregation.
SELECT c.full_name, count(o.order_id) AS order_count
FROM sales.customers AS c
JOIN sales.orders AS o ON o.customer_id = c.customer_id
WHERE o.status <> 'CANCELLED'
GROUP BY c.customer_id, c.full_name
HAVING count(o.order_id) >= 2
ORDER BY order_count DESC, c.full_name;

-- 7. LEFT JOIN preserves products with no sales.
SELECT
    p.product_name,
    coalesce(sum(oi.quantity) FILTER (WHERE o.status <> 'CANCELLED'), 0) AS units_sold
FROM sales.products AS p
LEFT JOIN sales.order_items AS oi ON oi.product_id = p.product_id
LEFT JOIN sales.orders AS o ON o.order_id = oi.order_id
GROUP BY p.product_id, p.product_name
ORDER BY units_sold DESC, p.product_name;

-- 8. Payment reconciliation.
SELECT
    o.order_no,
    sum(oi.line_total) AS order_total,
    coalesce(pay.amount_paid, 0) AS amount_paid,
    sum(oi.line_total) - coalesce(pay.amount_paid, 0) AS balance
FROM sales.orders AS o
JOIN sales.order_items AS oi ON oi.order_id = o.order_id
LEFT JOIN (
    SELECT order_id, sum(amount) AS amount_paid
    FROM sales.payments
    GROUP BY order_id
) AS pay ON pay.order_id = o.order_id
WHERE o.status <> 'CANCELLED'
GROUP BY o.order_id, o.order_no, pay.amount_paid
ORDER BY o.order_no;

-- TRY: Show order number, customer, distinct products and total for orders >= RM200.

