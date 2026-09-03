/* MODULE 5 — VIEWS, FUNCTIONS, PROCEDURES AND TRIGGERS */

-- 1. VIEW: reusable order summary.
CREATE OR REPLACE VIEW sales.v_order_summary AS
SELECT
    o.order_id,
    o.order_no,
    o.order_date,
    o.status,
    c.customer_id,
    c.full_name AS customer_name,
    count(oi.product_id) AS product_lines,
    coalesce(sum(oi.quantity), 0) AS total_units,
    coalesce(sum(oi.line_total), 0)::numeric(12,2) AS order_total
FROM sales.orders AS o
JOIN sales.customers AS c ON c.customer_id = o.customer_id
LEFT JOIN sales.order_items AS oi ON oi.order_id = o.order_id
GROUP BY o.order_id, o.order_no, o.order_date, o.status,
         c.customer_id, c.full_name;

SELECT * FROM sales.v_order_summary ORDER BY order_date, order_no;

-- 2. SQL FUNCTION: one calculated value.
CREATE OR REPLACE FUNCTION sales.fn_order_total(p_order_id bigint)
RETURNS numeric(12,2)
LANGUAGE sql
STABLE
AS $$
    SELECT coalesce(sum(line_total), 0)::numeric(12,2)
    FROM sales.order_items
    WHERE order_id = p_order_id;
$$;

SELECT order_no, sales.fn_order_total(order_id) AS total
FROM sales.orders
ORDER BY order_no;

-- 3. PROCEDURE: controlled stock replenishment.
CREATE OR REPLACE PROCEDURE sales.sp_restock_product(
    p_product_id integer,
    p_quantity integer
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Restock quantity must be positive';
    END IF;

    UPDATE sales.products
    SET stock_qty = stock_qty + p_quantity
    WHERE product_id = p_product_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Product % does not exist', p_product_id;
    END IF;
END;
$$;

-- Demonstrate inside a transaction so the seed state remains unchanged.
BEGIN;
CALL sales.sp_restock_product(2, 10);
SELECT product_id, product_name, stock_qty FROM sales.products WHERE product_id = 2;
ROLLBACK;

-- 4. PL/pgSQL FUNCTION: place a complete order atomically from JSON.
-- Example items: '[{"product_id":2,"quantity":2},{"product_id":6,"quantity":1}]'
CREATE OR REPLACE FUNCTION sales.fn_place_order(
    p_customer_id bigint,
    p_items jsonb
)
RETURNS bigint
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id bigint;
    v_bad_product integer;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM sales.customers WHERE customer_id = p_customer_id
    ) THEN
        RAISE EXCEPTION 'Customer % does not exist', p_customer_id;
    END IF;

    IF p_items IS NULL
       OR jsonb_typeof(p_items) <> 'array'
       OR jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'At least one order item is required';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM jsonb_to_recordset(p_items)
             AS x(product_id integer, quantity integer)
        WHERE product_id IS NULL
           OR quantity IS NULL
           OR quantity <= 0
    ) THEN
        RAISE EXCEPTION 'Every item requires a product_id and a positive quantity';
    END IF;

    -- Lock existing requested products until this transaction finishes.
    PERFORM p.product_id
    FROM sales.products AS p
    JOIN (
        SELECT product_id
        FROM jsonb_to_recordset(p_items)
             AS x(product_id integer, quantity integer)
        GROUP BY product_id
    ) AS r ON r.product_id = p.product_id
    FOR UPDATE OF p;

    -- Reject missing, inactive, non-positive or insufficient-stock products.
    WITH requested AS (
        SELECT product_id, sum(quantity)::integer AS quantity
        FROM jsonb_to_recordset(p_items)
             AS x(product_id integer, quantity integer)
        GROUP BY product_id
    )
    SELECT r.product_id
    INTO v_bad_product
    FROM requested AS r
    LEFT JOIN sales.products AS p ON p.product_id = r.product_id
    WHERE p.product_id IS NULL
       OR p.active = false
       OR p.stock_qty < r.quantity
    LIMIT 1;

    IF v_bad_product IS NOT NULL THEN
        RAISE EXCEPTION 'Invalid, inactive or insufficient-stock product: %', v_bad_product;
    END IF;

    -- Explicitly reserve the next identity value so it can form the order number.
    SELECT nextval(pg_get_serial_sequence('sales.orders', 'order_id'))
    INTO v_order_id;

    INSERT INTO sales.orders (order_id, order_no, customer_id, status)
    VALUES (
        v_order_id,
        format('ORD-LAB-%s', lpad(v_order_id::text, 6, '0')),
        p_customer_id,
        'PENDING'
    );

    INSERT INTO sales.order_items
        (order_id, product_id, quantity, unit_price, discount)
    SELECT
        v_order_id,
        p.product_id,
        r.quantity,
        p.unit_price,
        0
    FROM (
        SELECT product_id, sum(quantity)::integer AS quantity
        FROM jsonb_to_recordset(p_items)
             AS x(product_id integer, quantity integer)
        GROUP BY product_id
    ) AS r
    JOIN sales.products AS p ON p.product_id = r.product_id;

    UPDATE sales.products AS p
    SET stock_qty = p.stock_qty - r.quantity
    FROM (
        SELECT product_id, sum(quantity)::integer AS quantity
        FROM jsonb_to_recordset(p_items)
             AS x(product_id integer, quantity integer)
        GROUP BY product_id
    ) AS r
    WHERE p.product_id = r.product_id;

    RETURN v_order_id;
END;
$$;

-- Safe demonstration: create and inspect an order, then roll it back.
BEGIN;
SELECT sales.fn_place_order(
    1,
    '[{"product_id":2,"quantity":2},{"product_id":6,"quantity":1}]'::jsonb
) AS new_order_id;

SELECT * FROM sales.orders WHERE order_no LIKE 'ORD-LAB-%' ORDER BY order_id DESC;
ROLLBACK;

-- 5. TRIGGER: audit every product price change.
CREATE OR REPLACE FUNCTION audit.fn_log_product_price_change()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO audit.product_price_log (product_id, old_price, new_price)
    VALUES (OLD.product_id, OLD.unit_price, NEW.unit_price);
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_product_price_audit ON sales.products;
CREATE TRIGGER trg_product_price_audit
AFTER UPDATE OF unit_price ON sales.products
FOR EACH ROW
WHEN (OLD.unit_price IS DISTINCT FROM NEW.unit_price)
EXECUTE FUNCTION audit.fn_log_product_price_change();

-- Demonstrate and keep the audit entry.
UPDATE sales.products
SET unit_price = unit_price + 1
WHERE product_id = 2;

SELECT * FROM audit.product_price_log ORDER BY changed_at DESC;

-- Restore the original price. This intentionally creates a second audit row.
UPDATE sales.products
SET unit_price = unit_price - 1
WHERE product_id = 2;
