/*
  MODULE 6 — STUDENT LAB: POSTGRESQL FUNCTIONS
  Complete every TODO. Run 01_schema.sql and 02_seed_data.sql first.
  Do not open the instructor solution until instructed.
*/

SET search_path TO sales, public;

-- TASK 1 — CALL A SCALAR FUNCTION
-- Display product_id, product_name, quantity and line_total for order ID 1.
-- Obtain product_name by calling sales.fn_product_name(product_id).
-- TODO:


-- TASK 2 — USE A FUNCTION FOR EVERY ORDER
-- Display order_no and calculated order_total for every order.
-- Call sales.fn_order_total and sort from highest to lowest total.
-- TODO:


-- TASK 3 — CREATE A SIMPLE SQL FUNCTION
-- Create sales.fn_customer_order_count(p_customer_id bigint).
-- It must return bigint and count the customer's rows in sales.orders.
-- Mark it STABLE.
-- TODO:

-- Test: customer 1 should have 2 orders.
-- SELECT sales.fn_customer_order_count(1);


-- TASK 4 — CALL THE DISCOUNT FUNCTION
-- Show product_id, product_name, original price and price after a 15% discount
-- for every active product.
-- TODO:


-- TASK 5 — DEFAULT PARAMETER
-- Call fn_price_after_discount with only the price 250.00.
-- Explain why the result remains 250.00.
-- TODO:


-- TASK 6 — STOCK STATUS REPORT
-- Display product name, stock quantity and fn_product_stock_status for all
-- products. Sort by stock quantity ascending.
-- TODO:


-- TASK 7 — TEST VALIDATION
-- Run this separately. Record the error message, then correct the input.
-- SELECT sales.fn_price_after_discount(200, -5);
-- TODO corrected call:


-- TASK 8 — USE A TABLE-RETURNING FUNCTION
-- Return all orders for customer 2 by using fn_customer_orders in FROM.
-- TODO:


-- TASK 9 — JOIN TO A TABLE-RETURNING FUNCTION
-- Display customer name together with the order columns returned by
-- fn_customer_orders for customer 1. Hint: use CROSS JOIN LATERAL.
-- TODO:


-- TASK 10 — CUSTOMER SALES SUMMARY
-- Call fn_customer_sales_summary for customers 1 and 6.
-- What is different between their results?
-- TODO:


-- TASK 11 — CREATE A PL/pgSQL CLASSIFICATION FUNCTION
-- Create sales.fn_order_value_category(p_order_id bigint), returning text.
-- Use fn_order_total to obtain the total, then return:
--   HIGH   when total >= 1000
--   MEDIUM when total >= 500
--   LOW    otherwise
-- Mark the function STABLE.
-- TODO:

-- Test it for every order.
-- TODO:


-- TASK 12 — SAFE DATA-CHANGING FUNCTION TEST
-- Begin a transaction, create an order for customer 3 containing three units
-- of product 6, display the new order and remaining stock, then ROLLBACK.
-- Verify after rollback that no ORD-LAB row remains.
-- TODO:


-- BONUS — FUNCTION METADATA
-- Query pg_proc and pg_namespace to list all functions in the sales schema.
-- Include function name, arguments and return type.
-- TODO:

