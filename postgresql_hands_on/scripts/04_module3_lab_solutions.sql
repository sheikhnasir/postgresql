/*
  MODULE 3 LAB — INSTRUCTOR SOLUTIONS
  Prerequisite: run 01_schema.sql, 02_seed_data.sql and 03_crud.sql.
*/

-- Q1: Active product price list (8 rows)
SELECT product_name, sku, unit_price, stock_qty
FROM sales.products
WHERE active = true
ORDER BY unit_price DESC;

-- Q2: Active products priced RM200 and above (5 rows)
SELECT product_name, unit_price, stock_qty
FROM sales.products
WHERE active = true
  AND unit_price >= 200
ORDER BY unit_price DESC;

-- Q3: Active products with 20 units or fewer (4 rows)
SELECT sku, product_name, stock_qty
FROM sales.products
WHERE active = true
  AND stock_qty <= 20
ORDER BY stock_qty, product_name;

-- Q4: Case-insensitive product-name search
SELECT product_name, unit_price, stock_qty
FROM sales.products
WHERE product_name ILIKE '%wire%';

-- Q5: Non-cancelled April 2026 orders (4 rows)
SELECT order_no, order_date, status
FROM sales.orders
WHERE order_date BETWEEN DATE '2026-04-01' AND DATE '2026-04-30'
  AND status <> 'CANCELLED'
ORDER BY order_date, order_no;

-- Q6: Customers with a missing phone or city (2 rows)
SELECT full_name, phone, city
FROM sales.customers
WHERE phone IS NULL
   OR city IS NULL
ORDER BY full_name;

-- Q7: Product catalogue with category (9 rows)
SELECT
    c.category_name,
    p.product_name,
    p.sku,
    p.unit_price,
    p.active
FROM sales.products AS p
JOIN sales.categories AS c ON c.category_id = p.category_id
ORDER BY c.category_name, p.product_name;

-- Q8: Orders with customers (7 rows)
SELECT
    o.order_no,
    o.order_date,
    c.full_name,
    c.city,
    o.status
FROM sales.orders AS o
JOIN sales.customers AS c ON c.customer_id = o.customer_id
ORDER BY o.order_date, o.order_no;

-- Q9: Detailed order lines (11 rows)
SELECT
    o.order_no,
    c.full_name,
    p.product_name,
    oi.quantity,
    oi.unit_price AS selling_price,
    oi.discount,
    oi.line_total
FROM sales.orders AS o
JOIN sales.customers AS c ON c.customer_id = o.customer_id
JOIN sales.order_items AS oi ON oi.order_id = o.order_id
JOIN sales.products AS p ON p.product_id = oi.product_id
ORDER BY o.order_no, p.product_name;

-- Q10: Payments with order and customer information (4 rows)
SELECT
    p.reference_no,
    o.order_no,
    c.full_name,
    p.payment_date,
    p.method,
    p.amount
FROM sales.payments AS p
JOIN sales.orders AS o ON o.order_id = p.order_id
JOIN sales.customers AS c ON c.customer_id = o.customer_id
ORDER BY p.payment_date;

-- Q11: Customers without orders
SELECT c.customer_id, c.full_name, c.email
FROM sales.customers AS c
LEFT JOIN sales.orders AS o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL
ORDER BY c.full_name;

-- Q12: One-row-per-order summary
SELECT
    o.order_no,
    c.full_name,
    count(*) AS item_lines,
    sum(oi.quantity) AS total_units,
    sum(oi.line_total)::numeric(12,2) AS order_total
FROM sales.orders AS o
JOIN sales.customers AS c ON c.customer_id = o.customer_id
JOIN sales.order_items AS oi ON oi.order_id = o.order_id
GROUP BY o.order_id, o.order_no, c.full_name
ORDER BY order_total DESC;

-- Q13: Revenue by non-cancelled order status (4 groups)
SELECT
    o.status,
    count(DISTINCT o.order_id) AS order_count,
    sum(oi.line_total)::numeric(12,2) AS total_value
FROM sales.orders AS o
JOIN sales.order_items AS oi ON oi.order_id = o.order_id
WHERE o.status <> 'CANCELLED'
GROUP BY o.status
ORDER BY total_value DESC;

-- Q14: Non-cancelled spending for every customer (7 rows)
SELECT
    c.full_name,
    coalesce(
        sum(oi.line_total) FILTER (WHERE o.status <> 'CANCELLED'),
        0
    )::numeric(12,2) AS total_spending
FROM sales.customers AS c
LEFT JOIN sales.orders AS o ON o.customer_id = c.customer_id
LEFT JOIN sales.order_items AS oi ON oi.order_id = o.order_id
GROUP BY c.customer_id, c.full_name
ORDER BY total_spending DESC, c.full_name;

-- Q15: Non-cancelled units sold for every product (9 rows)
SELECT
    p.product_name,
    coalesce(
        sum(oi.quantity) FILTER (WHERE o.status <> 'CANCELLED'),
        0
    ) AS units_sold
FROM sales.products AS p
LEFT JOIN sales.order_items AS oi ON oi.product_id = p.product_id
LEFT JOIN sales.orders AS o ON o.order_id = oi.order_id
GROUP BY p.product_id, p.product_name
ORDER BY units_sold DESC, p.product_name;

-- Q16: Customers with at least two non-cancelled orders
SELECT
    c.full_name,
    count(o.order_id) AS order_count
FROM sales.customers AS c
JOIN sales.orders AS o ON o.customer_id = c.customer_id
WHERE o.status <> 'CANCELLED'
GROUP BY c.customer_id, c.full_name
HAVING count(o.order_id) >= 2
ORDER BY order_count DESC, c.full_name;

-- Q17: Orders worth at least RM500 (4 rows)
SELECT
    o.order_no,
    c.full_name,
    o.status,
    sum(oi.line_total)::numeric(12,2) AS order_total
FROM sales.orders AS o
JOIN sales.customers AS c ON c.customer_id = o.customer_id
JOIN sales.order_items AS oi ON oi.order_id = o.order_id
GROUP BY o.order_id, o.order_no, c.full_name, o.status
HAVING sum(oi.line_total) >= 500
ORDER BY order_total DESC;

-- Q18: Management report (6 rows)
SELECT
    o.order_no,
    c.full_name,
    o.order_date,
    count(DISTINCT oi.product_id) AS distinct_products,
    sum(oi.quantity) AS total_units,
    sum(oi.line_total)::numeric(12,2) AS order_value,
    CASE
        WHEN coalesce(pay.amount_paid, 0) >= sum(oi.line_total)
            THEN 'PAID IN FULL'
        WHEN coalesce(pay.amount_paid, 0) > 0
            THEN 'PARTIALLY PAID'
        ELSE 'UNPAID'
    END AS payment_status
FROM sales.orders AS o
JOIN sales.customers AS c ON c.customer_id = o.customer_id
JOIN sales.order_items AS oi ON oi.order_id = o.order_id
LEFT JOIN (
    SELECT order_id, sum(amount) AS amount_paid
    FROM sales.payments
    GROUP BY order_id
) AS pay ON pay.order_id = o.order_id
WHERE o.status <> 'CANCELLED'
GROUP BY
    o.order_id,
    o.order_no,
    c.full_name,
    o.order_date,
    pay.amount_paid
HAVING sum(oi.line_total) >= 200
ORDER BY o.order_date, o.order_no;

-- Q19: Non-cancelled revenue for every category
SELECT
    c.category_name,
    coalesce(
        sum(oi.line_total) FILTER (WHERE o.status <> 'CANCELLED'),
        0
    )::numeric(12,2) AS revenue
FROM sales.categories AS c
LEFT JOIN sales.products AS p ON p.category_id = c.category_id
LEFT JOIN sales.order_items AS oi ON oi.product_id = p.product_id
LEFT JOIN sales.orders AS o ON o.order_id = oi.order_id
GROUP BY c.category_id, c.category_name
ORDER BY revenue DESC, c.category_name;

-- Q20: Payment reconciliation for non-cancelled orders
SELECT
    o.order_no,
    sum(oi.line_total)::numeric(12,2) AS order_total,
    coalesce(pay.amount_paid, 0)::numeric(12,2) AS amount_paid,
    (
        sum(oi.line_total) - coalesce(pay.amount_paid, 0)
    )::numeric(12,2) AS outstanding_balance
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

-- BONUS: Keep unsold products by moving the status filter into FILTER.
SELECT
    p.product_name,
    coalesce(
        sum(oi.quantity) FILTER (WHERE o.status <> 'CANCELLED'),
        0
    ) AS units_sold
FROM sales.products AS p
LEFT JOIN sales.order_items AS oi ON oi.product_id = p.product_id
LEFT JOIN sales.orders AS o ON o.order_id = oi.order_id
GROUP BY p.product_id, p.product_name
ORDER BY units_sold DESC, p.product_name;

