
SELECT *
FROM sales.orders_partition_default
WHERE order_date >= DATE '2026-07-01'
  AND order_date <  DATE '2026-08-01';

--if no row return can proceed below steps'

CREATE TABLE sales.orders_partition_2026_08
PARTITION OF sales.orders_partition_lab
FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');

CREATE INDEX idx_orders_part_2026_08_status
ON sales.orders_partition_2026_08 (status);


 -- if the record already exist in the default

BEGIN;

-- Prevent new rows from being inserted during migration.
LOCK TABLE sales.orders_partition_lab
IN ACCESS EXCLUSIVE MODE;

-- 1. Create July as a normal standalone table first.
CREATE TABLE sales.orders_partition_2026_07
(
    LIKE sales.orders_partition_lab INCLUDING ALL
);

-- 2. Copy July records from the default partition.
INSERT INTO sales.orders_partition_2026_07
SELECT *
FROM sales.orders_partition_default
WHERE order_date >= DATE '2026-07-01'
  AND order_date <  DATE '2026-08-01';

-- 3. Remove the copied records from the default partition.
DELETE FROM sales.orders_partition_default
WHERE order_date >= DATE '2026-07-01'
  AND order_date <  DATE '2026-08-01';

-- 4. Confirm that the default partition contains no July records.
ALTER TABLE sales.orders_partition_default
ADD CONSTRAINT chk_default_exclude_2026_07
CHECK (
    order_date < DATE '2026-07-01'
    OR order_date >= DATE '2026-08-01'
);

-- 5. Attach the standalone table as the July partition.
ALTER TABLE sales.orders_partition_lab
ATTACH PARTITION sales.orders_partition_2026_07
FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');

-- 6. Create the status index.
CREATE INDEX idx_orders_part_2026_07_status
ON sales.orders_partition_2026_07 (status);

COMMIT;