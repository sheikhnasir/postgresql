/* MODULE 1/2 — LOAD A SMALL, REPEATABLE DATASET */

TRUNCATE TABLE
    audit.product_price_log,
    sales.payments,
    sales.order_items,
    sales.orders,
    sales.customers,
    sales.products,
    sales.categories
RESTART IDENTITY CASCADE;

INSERT INTO sales.categories (category_id, category_name, description) VALUES
    (1, 'Laptops',     'Portable computers'),
    (2, 'Accessories', 'Computer accessories'),
    (3, 'Networking',  'Routers, switches and adapters'),
    (4, 'Storage',     'External and internal storage');

INSERT INTO sales.products
    (product_id, category_id, sku, product_name, unit_price, stock_qty, active)
VALUES
    (1, 1, 'LAP-14-PRO', 'ProBook 14 Laptop',       3299.00, 12, true),
    (2, 2, 'ACC-MOU-01', 'Wireless Mouse',            89.90, 55, true),
    (3, 2, 'ACC-KEY-01', 'Mechanical Keyboard',       249.00, 30, true),
    (4, 3, 'NET-RTR-AX', 'AX3000 Wi-Fi 6 Router',     399.00, 18, true),
    (5, 4, 'STO-SSD-1T', 'Portable SSD 1TB',          459.00, 24, true),
    (6, 2, 'ACC-HUB-01', 'USB-C Hub',                 139.00, 40, true),
    (7, 3, 'NET-SW-08P', '8-Port Gigabit Switch',     189.00, 15, true),
    (8, 4, 'STO-HDD-2T', 'External HDD 2TB',          329.00, 20, false);

INSERT INTO sales.customers
    (customer_id, full_name, email, phone, city, registered_at)
VALUES
    (1, 'Aisyah Rahman', 'aisyah@example.com', '012-1111111', 'Kuala Lumpur', '2026-01-10 09:00+08'),
    (2, 'Daniel Lee',    'daniel@example.com', '012-2222222', 'Johor Bahru',  '2026-01-12 10:00+08'),
    (3, 'Kumar Raj',     'kumar@example.com',  '012-3333333', 'Ipoh',         '2026-02-02 11:00+08'),
    (4, 'Nurul Huda',    'nurul@example.com',  '012-4444444', 'Shah Alam',   '2026-02-14 12:00+08'),
    (5, 'Siti Aminah',   'siti@example.com',   NULL,          'Kota Bharu',  '2026-03-05 13:00+08'),
    (6, 'Farid Ahmad',   'farid@example.com',  '012-6666666', NULL,           '2026-03-18 14:00+08');

INSERT INTO sales.orders
    (order_id, order_no, customer_id, order_date, status, notes)
VALUES
    (1, 'ORD-2026-001', 1, '2026-04-01', 'PAID',       'Office setup'),
    (2, 'ORD-2026-002', 2, '2026-04-02', 'SHIPPED',    NULL),
    (3, 'ORD-2026-003', 1, '2026-04-05', 'PROCESSING', 'Deliver after 5 PM'),
    (4, 'ORD-2026-004', 3, '2026-04-06', 'PENDING',    NULL),
    (5, 'ORD-2026-005', 4, '2026-04-10', 'CANCELLED',  'Customer request'),
    (6, 'ORD-2026-006', 5, '2026-05-01', 'PAID',       NULL),
    (7, 'ORD-2026-007', 2, '2026-05-03', 'PAID',       'Collect in store');

INSERT INTO sales.order_items
    (order_id, product_id, quantity, unit_price, discount)
VALUES
    (1, 1, 1, 3299.00, 100.00),
    (1, 2, 2,   89.90,   0.00),
    (2, 4, 1,  399.00,  20.00),
    (2, 7, 2,  189.00,   0.00),
    (3, 5, 1,  459.00,   0.00),
    (3, 6, 2,  139.00,  18.00),
    (4, 3, 1,  249.00,   0.00),
    (5, 2, 1,   89.90,   0.00),
    (6, 5, 2,  459.00,  50.00),
    (7, 2, 1,   89.90,   0.00),
    (7, 3, 1,  249.00,  10.00);

INSERT INTO sales.payments
    (payment_id, order_id, payment_date, amount, method, reference_no)
VALUES
    (1, 1, '2026-04-01 10:00+08', 3378.80, 'CARD',          'PAY-1001'),
    (2, 2, '2026-04-02 15:30+08',  757.00, 'FPX',           'PAY-1002'),
    (3, 6, '2026-05-01 09:15+08',  868.00, 'EWALLET',       'PAY-1003'),
    (4, 7, '2026-05-03 14:20+08',  328.90, 'BANK_TRANSFER', 'PAY-1004');

-- Move identity sequences past the explicit seed IDs.
ALTER TABLE sales.categories ALTER COLUMN category_id RESTART WITH 5;
ALTER TABLE sales.products   ALTER COLUMN product_id  RESTART WITH 9;
ALTER TABLE sales.customers  ALTER COLUMN customer_id RESTART WITH 7;
ALTER TABLE sales.orders     ALTER COLUMN order_id    RESTART WITH 8;
ALTER TABLE sales.payments   ALTER COLUMN payment_id  RESTART WITH 5;

-- VERIFY: expected counts are 4, 8, 6, 7, 11 and 4.
SELECT 'categories' AS table_name, count(*) AS row_count FROM sales.categories
UNION ALL SELECT 'products',    count(*) FROM sales.products
UNION ALL SELECT 'customers',   count(*) FROM sales.customers
UNION ALL SELECT 'orders',      count(*) FROM sales.orders
UNION ALL SELECT 'order_items', count(*) FROM sales.order_items
UNION ALL SELECT 'payments',    count(*) FROM sales.payments;

