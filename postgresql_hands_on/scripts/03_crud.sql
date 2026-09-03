/* MODULE 2 — CRUD, RETURNING AND UPSERT
   Run one section at a time. Demonstration rows use training-only addresses. */

-- 1. CREATE: return the generated customer_id to the application.
INSERT INTO sales.customers (full_name, email, phone, city)
VALUES ('Hands-On Student', 'student.lab@example.com', '012-7000000', 'Putrajaya')
ON CONFLICT (email) DO UPDATE
SET full_name = EXCLUDED.full_name,
    phone = EXCLUDED.phone,
    city = EXCLUDED.city
RETURNING customer_id, full_name, email, city;

-- 2. READ: aliases, derived values and NULL handling.
SELECT
    product_id,
    sku,
    product_name,
    unit_price,
    stock_qty,
    unit_price * stock_qty AS stock_value,
    CASE WHEN stock_qty < 20 THEN 'REORDER' ELSE 'OK' END AS stock_status
FROM sales.products
WHERE active = true
ORDER BY stock_value DESC;

-- 3. UPDATE: preview the target first.
SELECT * FROM sales.customers WHERE email = 'student.lab@example.com';

UPDATE sales.customers
SET city = 'Cyberjaya', phone = '012-7999999'
WHERE email = 'student.lab@example.com'
RETURNING customer_id, full_name, city, phone;

-- 4. SAFE DELETE: demonstrate and recover.
BEGIN;
DELETE FROM sales.customers
WHERE email = 'student.lab@example.com'
RETURNING *;

-- PAUSE: confirm the row is absent inside this transaction.
SELECT * FROM sales.customers WHERE email = 'student.lab@example.com';
ROLLBACK;

-- Confirm ROLLBACK restored it.
SELECT * FROM sales.customers WHERE email = 'student.lab@example.com';

-- 5. UPSERT: rerunning this statement does not create a duplicate SKU.
INSERT INTO sales.products
    (category_id, sku, product_name, unit_price, stock_qty)
VALUES
    (2, 'ACC-DOCK-08', 'USB-C Dock 8-in-1', 289.00, 10)
ON CONFLICT (sku) DO UPDATE
SET product_name = EXCLUDED.product_name,
    unit_price = EXCLUDED.unit_price,
    stock_qty = EXCLUDED.stock_qty
RETURNING product_id, sku, product_name, unit_price, stock_qty;

-- OPTIONAL ERROR DEMO: run separately, observe the check constraint, then undo/comment.
-- UPDATE sales.products SET unit_price = -10 WHERE sku = 'ACC-DOCK-08';

