# Module 6 Hands-On: PostgreSQL Functions

## Case study

Students work with the existing **TechStore Order Management** database and the
`sales` schema. The activities progress from a simple scalar SQL function to a
data-changing PL/pgSQL function with validation and exception handling.

## Duration

Approximately **150 minutes**.

| Part | Topic | Time |
|---|---|---:|
| A | Function concepts and syntax | 15 min |
| B | Scalar SQL functions | 25 min |
| C | PL/pgSQL, variables and decisions | 30 min |
| D | Functions that return tables | 25 min |
| E | Exception handling | 20 min |
| F | Transactional order function | 25 min |
| G | Student challenge and review | 10 min |

## Learning outcomes

By the end of this lab, students can:

1. Create and replace PostgreSQL functions.
2. Pass parameters and return scalar values.
3. Choose between `LANGUAGE sql` and `LANGUAGE plpgsql`.
4. Declare variables and use `IF`, `CASE`, `SELECT INTO` and `FOUND`.
5. Return multiple rows with `RETURNS TABLE` and `RETURN QUERY`.
6. Raise useful exceptions for invalid input.
7. call functions from `SELECT`, joins and reports.
8. Create a data-changing function that completes one business operation.

## Prerequisites

Connect to `techstore_db`, then run these existing files if the sample database
has not yet been prepared:

1. `scripts/01_schema.sql`
2. `scripts/02_seed_data.sql`

Run `scripts/06a_functions_setup_demo.sql` one section at a time. Use
`scripts/06b_functions_student_lab.sql` for the student activity and compare it
with `solutions/06_module6_functions_solutions.sql` after completion.

## Key concepts for the trainer

### SQL function or PL/pgSQL function?

| Use | Best starting choice |
|---|---|
| One query or one expression | `LANGUAGE sql` |
| Variables, decisions, loops or exception handling | `LANGUAGE plpgsql` |
| Return one value | `RETURNS data_type` |
| Return many rows and columns | `RETURNS TABLE (...)` |

### Function volatility

| Label | Meaning | Example in this lab |
|---|---|---|
| `IMMUTABLE` | Same inputs always produce the same result | Discount calculation |
| `STABLE` | Can read database data but does not change it | Order total lookup |
| `VOLATILE` | May change data or produce changing results | Create-order function |

Do not label a function more strictly than its behaviour. PostgreSQL assumes
`VOLATILE` when no label is supplied.

## Guided teaching sequence

### Part A — Check the sample database

Run the preflight section. It stops immediately with a clear message when the
schema or seed data is missing.

### Part B — Scalar SQL functions

Create `sales.fn_product_name` and `sales.fn_order_total`. Show that functions
can be called for one value or once per row:

```sql
SELECT sales.fn_product_name(2);

SELECT
    order_no,
    sales.fn_order_total(order_id) AS order_total
FROM sales.orders
ORDER BY order_id;
```

Discuss why `COALESCE` makes an order without items return `0.00` instead of
`NULL`.

### Part C — PL/pgSQL and decisions

Create the discount function and stock-status function. Point out:

- parameters use the `p_` prefix;
- local variables use the `v_` prefix;
- `SELECT ... INTO` assigns a query result to variables;
- `IF NOT FOUND` checks whether `SELECT INTO` found a row;
- `RAISE EXCEPTION` rejects invalid inputs.

### Part D — Return a result set

Run `sales.fn_customer_orders(1)` and compare it with an ordinary table query.
The function becomes a table source and therefore appears in `FROM`:

```sql
SELECT * FROM sales.fn_customer_orders(1);
```

### Part E — Test exception handling safely

Execute each failing example separately. In pgAdmin, if a statement fails inside
an explicit transaction, run `ROLLBACK;` before continuing.

### Part F — Complete business operation

`sales.fn_create_single_item_order` locks the selected product, validates the
customer and product, creates the order, creates its item and reduces stock. Run
the demonstration inside `BEGIN ... ROLLBACK` so the seed data is unchanged.

## Student deliverables

Students submit:

1. Completed `06b_functions_student_lab.sql`.
2. Screenshot showing the results of Tasks 3, 6, 9 and 12.
3. A short answer: why is `fn_create_single_item_order` `VOLATILE` while
   `fn_order_total` is `STABLE`?

## Expected checks

- `sales.fn_order_total(1)` returns `3378.80` on the original seed data.
- Customer 1 has two orders.
- A 10% discount on `100.00` returns `90.00`.
- Product 2 initially reports `IN STOCK` with the original seed data.
- Customer 6 has no orders, so `fn_customer_orders(6)` returns zero rows.
- The order-creation test reduces stock only until the demonstration is rolled
  back.

## Common errors

| Error | Likely cause | Fix |
|---|---|---|
| `relation sales.products does not exist` | Schema setup was not run | Run scripts `01` and `02` in `techstore_db` |
| `function ... does not exist` | Incorrect argument type or function not created | Check `\df sales.*` in psql or query `pg_proc` |
| `column reference ... is ambiguous` | Output-column name conflicts with a table column | Qualify table columns with aliases |
| `current transaction is aborted` | An earlier test raised an exception | Run `ROLLBACK;` |
| Function returns old definition | Only the test query was selected in pgAdmin | Execute the full `CREATE OR REPLACE FUNCTION` statement |

## Cleanup

The lab functions are safe to keep. To remove only Module 6 functions, run the
cleanup section at the bottom of the setup script after uncommenting it.

