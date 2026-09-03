# Instructor Lesson Plan — PostgreSQL for Developers Hands-On

## Case study

TechStore sells computer accessories. Customers place orders containing one or more products, and payments are recorded against orders. Participants will build the database and progressively turn it into a developer-ready solution.

## Suggested delivery

Total guided hands-on time: approximately **7 hours 15 minutes**, distributed across the two-day course. Each lab includes demonstration, learner practice, and review.

| Lab | Duration | Outcome |
|---|---:|---|
| 1. Build the database | 60 min | Create schemas, tables, keys, checks and relationships |
| 2. Load and maintain data | 55 min | Use INSERT, UPDATE, DELETE, RETURNING and UPSERT |
| 3. Query business data | 75 min | Apply filters, joins, grouping and HAVING |
| 4. Write advanced reports | 70 min | Use subqueries, CTEs and window functions |
| 5. Add database logic | 75 min | Create views, functions, procedures and triggers |
| 6. Protect a business transaction | 45 min | Use BEGIN, COMMIT, ROLLBACK and SAVEPOINT |
| 7. Tune and secure access | 55 min | Read EXPLAIN output, add indexes and grant privileges |
| Final challenge | 60 min | Solve an integrated reporting and development task |

---

## Lab 1 — Build the database

**Scripts:** `00_create_database.sql`, `01_schema.sql`, `02_seed_data.sql`

### Objectives

- Distinguish a database, schema, table, row and column.
- Select suitable PostgreSQL data types.
- Implement primary keys, foreign keys, unique constraints and checks.
- Understand why `orders` and `products` require the junction table `order_items`.

### Instructor flow

1. Introduce the case study and sketch the five main entities.
2. Run the database creation script while connected to `postgres`.
3. Reconnect to `techstore_db`.
4. Build `categories` and `products` first; ask participants to identify the parent table.
5. Build the remaining tables and inspect them in pgAdmin.
6. Load seed data and run the verification queries at the end.

### Learner activity

Add a product called `USB-C Dock 8-in-1` in the Accessories category. Choose sensible values and verify that a negative price is rejected.

### Check for understanding

- Why is money stored as `numeric(10,2)` rather than `real`?
- What would happen if a category referenced by a product were deleted?
- Why is `(order_id, product_id)` the primary key of `order_items`?

---

## Lab 2 — Maintain data with CRUD

**Script:** `03_crud.sql`

### Objectives

- Insert a row and retrieve the generated key with `RETURNING`.
- Update only intended rows.
- Delete safely inside a transaction.
- Use `ON CONFLICT` for an idempotent upsert.

### Instructor flow

1. Demonstrate INSERT with an explicit column list.
2. Before UPDATE or DELETE, first run the same predicate as a SELECT.
3. Use `BEGIN` and `ROLLBACK` to recover from a deliberate broad update.
4. Demonstrate the difference between `DO NOTHING` and `DO UPDATE`.

### Learner activity

Create a customer, change the customer's city, then perform a safe test delete that is rolled back.

### Check for understanding

- Why should production code avoid `INSERT INTO table VALUES (...)` without columns?
- What does `RETURNING` save the application from doing?
- When is UPSERT preferable to checking and then inserting?

---

## Lab 3 — Query business data

**Script:** `04_queries.sql`

### Objectives

- Select, alias, filter and sort data.
- Join tables without producing accidental Cartesian products.
- Summarise data using aggregates, GROUP BY and HAVING.
- Preserve unmatched rows with LEFT JOIN.

### Instructor flow

Build one report gradually: orders → customer → items → products. At each join, ask learners to predict whether the row count will increase, decrease or remain the same.

### Learner activity

Produce a report showing order number, customer, order date, number of distinct products, and order value. Display only orders worth at least RM200.

### Check for understanding

- Why can one order appear several times after joining to `order_items`?
- What is the difference between WHERE and HAVING?
- Why is LEFT JOIN needed for products that have never been sold?

---

## Lab 4 — Advanced reporting

**Script:** `05_advanced_queries.sql`

### Objectives

- Choose between a subquery and a CTE for clarity.
- Build multi-stage reports using CTEs.
- Rank products and calculate running totals with window functions.
- Understand that window functions retain detail rows.

### Instructor flow

1. Find products priced above the overall average with a scalar subquery.
2. Refactor an order-total report into named CTE stages.
3. Compare GROUP BY output with window-function output.
4. Demonstrate `ROW_NUMBER`, `RANK` and `DENSE_RANK` using tied values.

### Learner activity

Rank customers by total spending and show the percentage contribution of each customer to total revenue.

---

## Lab 5 — Add database logic

**Script:** `06_programmability.sql`

### Objectives

- Hide report complexity behind a view.
- Write a SQL function and a PL/pgSQL function.
- Use a stored procedure for a controlled update.
- Enforce an audit rule with a trigger.

### Instructor flow

1. Create `sales.v_order_summary` and query it like a table.
2. Create `sales.fn_order_total` and call it for several orders.
3. Walk through validation and exceptions in `sales.fn_place_order`.
4. Create the price-audit trigger and demonstrate the audit row.

### Learner activity

Call the order-placement function with valid input. Then try a quantity larger than available stock and explain the exception.

### Safety note

Trigger logic is powerful but less visible to application developers. Keep triggers focused on integrity or auditing and document them clearly.

---

## Lab 6 — Transactions

**Script:** `07_transactions.sql`

### Objectives

- Treat related statements as one atomic unit.
- Use savepoints for partial recovery.
- Understand the lost-update problem and row locks.
- Know that transaction control belongs at an application service boundary.

### Instructor flow

1. Transfer stock between two products and roll it back.
2. Repeat and commit only after validating both rows.
3. Use a savepoint to undo one invalid step.
4. If two database sessions are available, demonstrate `SELECT ... FOR UPDATE`.

### Learner activity

Write a transaction that cancels an order and returns its item quantities to product stock. Test with ROLLBACK before using COMMIT.

---

## Lab 7 — Performance and security

**Script:** `08_performance_security.sql`

### Objectives

- Interpret scan, cost, estimated rows and actual time in EXPLAIN ANALYZE.
- Create indexes that support real predicates and joins.
- Recognise the write and storage cost of indexes.
- Apply least privilege using group roles.

### Instructor flow

1. Explain why a tiny table may correctly use a sequential scan.
2. Run the supplied data expansion only if a larger demonstration is desired.
3. Compare the query plan before and after indexes.
4. Create NOLOGIN group roles and grant only required privileges.

### Learner activity

Choose one query from Lab 3, propose an index, and justify the column order. Verify with EXPLAIN ANALYZE instead of assuming improvement.

---

## Final integrated challenge

**Script:** `09_student_challenges.sql`

Participants have 40 minutes to work and 20 minutes for walkthrough. Award one point per correct task plus one point for readable formatting and one point for safe transaction handling.

Expected evidence:

- Correct joins and null handling.
- Accurate totals after discount.
- A CTE or window function used appropriately.
- One reusable database object.
- Transaction protected by validation before commit.
- An index justified by a query pattern.

## Common mistakes to watch

- Running `00_create_database.sql` while connected to `techstore_db`.
- Executing demonstration scripts in one click and missing the pause points.
- Omitting join conditions.
- Filtering a nullable right-side column in WHERE after a LEFT JOIN.
- Using `COMMIT` before checking affected rows.
- Expecting an index to speed up every query on a very small table.

