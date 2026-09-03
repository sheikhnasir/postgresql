/* FINAL HANDS-ON CHALLENGE — TECHSTORE
   Write each answer below its task. Avoid looking at the solution file first. */

-- TASK 1 — Product catalogue
-- List active products with category, price and stock value.
-- Sort from highest to lowest stock value.


-- TASK 2 — Customer order report
-- Show order number, date, customer, status and order total.
-- Include all orders and display zero when an order has no items.


-- TASK 3 — Unsold products
-- Find products with no quantity sold in non-cancelled orders.
-- Do not use NOT IN.


-- TASK 4 — Category performance
-- Show category, units sold and revenue from non-cancelled orders.
-- Include categories with zero sales.


-- TASK 5 — Customer ranking
-- Rank customers by non-cancelled lifetime spend.
-- Show customer, spend, rank and percentage of all revenue.


-- TASK 6 — Reusable report object
-- Create a view named sales.v_low_stock_products containing active products
-- with stock below 20. Include category, SKU, product, stock and unit price.


-- TASK 7 — Safe transaction
-- In one transaction, cancel order_id 4 and return every ordered quantity to
-- product stock. Lock the order first, reject an already-cancelled order,
-- inspect the result, and use ROLLBACK so the lab remains repeatable.


-- TASK 8 — Index design
-- A dashboard repeatedly runs the query below. Propose and create an index.
-- Use EXPLAIN ANALYZE before and after. Explain why a tiny lab table may still
-- use a sequential scan.
SELECT order_no, order_date, status
FROM sales.orders
WHERE customer_id = 2
  AND status IN ('PAID', 'SHIPPED')
ORDER BY order_date DESC;


-- BONUS — Function call
-- Use sales.fn_place_order to create a two-item order for customer 3 inside a
-- transaction. Inspect the order total and stock, then roll it back.

