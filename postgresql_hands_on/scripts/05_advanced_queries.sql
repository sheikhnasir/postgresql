/* MODULE 4 — SUBQUERIES, CTEs, SET OPERATIONS AND WINDOWS */

-- 1. Scalar subquery: products above the average active-product price.
SELECT product_name, unit_price
FROM sales.products
WHERE active = true
  AND unit_price > (
      SELECT avg(unit_price)
      FROM sales.products
      WHERE active = true
  )
ORDER BY unit_price DESC;

-- 2. Correlated EXISTS: customers who have at least one paid order.
SELECT c.customer_id, c.full_name, c.email
FROM sales.customers AS c
WHERE EXISTS (
    SELECT 1
    FROM sales.orders AS o
    WHERE o.customer_id = c.customer_id
      AND o.status = 'PAID'
)
ORDER BY c.full_name;

-- 3. CTE pipeline: customer revenue excluding cancelled orders.
WITH order_totals AS (
    SELECT o.order_id, o.customer_id, sum(oi.line_total) AS order_total
    FROM sales.orders AS o
    JOIN sales.order_items AS oi ON oi.order_id = o.order_id
    WHERE o.status <> 'CANCELLED'
    GROUP BY o.order_id, o.customer_id
),
customer_totals AS (
    SELECT customer_id, count(*) AS orders, sum(order_total) AS revenue
    FROM order_totals
    GROUP BY customer_id
)
SELECT c.full_name, ct.orders, ct.revenue
FROM customer_totals AS ct
JOIN sales.customers AS c ON c.customer_id = ct.customer_id
ORDER BY ct.revenue DESC;

-- 4. Set operation: all cities represented by customers or order notes marker.
SELECT city AS value, 'CUSTOMER CITY' AS source
FROM sales.customers
WHERE city IS NOT NULL
UNION
SELECT 'Has notes', 'ORDER ATTRIBUTE'
FROM sales.orders
WHERE notes IS NOT NULL
ORDER BY source, value;

-- 5. Window ranking: products by revenue within category.
WITH product_sales AS (
    SELECT
        c.category_name,
        p.product_name,
        coalesce(sum(oi.line_total) FILTER (WHERE o.status <> 'CANCELLED'), 0) AS revenue
    FROM sales.products AS p
    JOIN sales.categories AS c ON c.category_id = p.category_id
    LEFT JOIN sales.order_items AS oi ON oi.product_id = p.product_id
    LEFT JOIN sales.orders AS o ON o.order_id = oi.order_id
    GROUP BY c.category_name, p.product_id, p.product_name
)
SELECT
    category_name,
    product_name,
    revenue,
    dense_rank() OVER (PARTITION BY category_name ORDER BY revenue DESC) AS category_rank
FROM product_sales
ORDER BY category_name, category_rank, product_name;

-- 6. Running revenue by date.
WITH daily_sales AS (
    SELECT o.order_date, sum(oi.line_total) AS daily_revenue
    FROM sales.orders AS o
    JOIN sales.order_items AS oi ON oi.order_id = o.order_id
    WHERE o.status <> 'CANCELLED'
    GROUP BY o.order_date
)
SELECT
    order_date,
    daily_revenue,
    sum(daily_revenue) OVER (ORDER BY order_date) AS running_revenue
FROM daily_sales
ORDER BY order_date;

-- 7. Customer contribution to total revenue.
WITH spend AS (
    SELECT c.customer_id, c.full_name, coalesce(sum(oi.line_total), 0) AS total_spend
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

