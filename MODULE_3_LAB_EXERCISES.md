# Module 3 Lab Exercise — Querying TechStore Business Data

## Learning outcomes

By the end of this lab, participants should be able to:

- retrieve selected columns with clear aliases;
- filter data using `WHERE`, `AND`, `OR`, `IN`, `BETWEEN`, `IS NULL` and `ILIKE`;
- combine related tables using `INNER JOIN` and `LEFT JOIN`;
- calculate business totals using aggregate functions;
- apply `GROUP BY` and `HAVING`; and
- produce a complete order and sales report.

## Preparation

Run these scripts in order before starting:

1. `01_schema.sql`
2. `02_seed_data.sql`
3. `03_crud.sql`

Expected starting data:

| Table | Expected rows |
|---|---:|
| `sales.categories` | 4 |
| `sales.products` | 9 |
| `sales.customers` | 7 |
| `sales.orders` | 7 |
| `sales.order_items` | 11 |
| `sales.payments` | 4 |

Use this verification query:

```sql
SELECT 'products' AS table_name, count(*) AS row_count FROM sales.products
UNION ALL
SELECT 'customers', count(*) FROM sales.customers
UNION ALL
SELECT 'orders', count(*) FROM sales.orders
UNION ALL
SELECT 'order_items', count(*) FROM sales.order_items
UNION ALL
SELECT 'payments', count(*) FROM sales.payments;
```

> Complete the questions without changing the data. Save each query and its result.

---

## Part A — SELECT, filtering and sorting

### Question 1 — Product price list

The sales team needs a price list of all active products. Display the product
name, SKU, unit price and stock quantity. Sort from the highest to the lowest
unit price.

**Expected rows:** 8

### Question 2 — Products priced RM200 and above

Find active products with a unit price of at least RM200. Display
`product_name`, `unit_price` and `stock_qty`. Sort by unit price from highest to
lowest.

**Expected rows:** 5

### Question 3 — Low-stock products

Find active products with 20 units or fewer in stock. Display the SKU, product
name and stock quantity. Show the lowest stock first.

**Expected rows:** 4

### Question 4 — Text search

Use a case-insensitive search to find products whose names contain the word
`wire`.

**Expected match:** `Wireless Mouse`

### Question 5 — April orders

List orders placed from 1 April 2026 through 30 April 2026, excluding cancelled
orders. Display the order number, date and status. Sort by order date.

**Expected rows:** 4

### Question 6 — Missing customer information

Find customers whose phone number or city is missing. Display the customer
name, phone and city.

**Expected rows:** 2

---

## Part B — Joining related tables

### Question 7 — Product catalogue with categories

Show every product together with its category. Display the category name,
product name, SKU, unit price and active status. Sort by category name and then
product name.

**Expected rows:** 9

### Question 8 — Order and customer list

Show each order together with the customer who placed it. Display the order
number, order date, customer name, city and order status.

**Expected rows:** 7

### Question 9 — Detailed order lines

Create a detailed report that shows the order number, customer name, product
name, quantity, selling price, discount and line total. Sort by order number and
product name.

**Expected rows:** 11

### Question 10 — Payment details

Show each payment together with its order number and customer name. Display the
payment reference, payment date, method and amount.

**Expected rows:** 4

### Question 11 — Customers without orders

Find customers who have never placed an order. Use a `LEFT JOIN` and test the
right-side key for `NULL`.

**Expected customers:** `Farid Ahmad` and `Hands-On Student`

---

## Part C — Aggregation and business summaries

### Question 12 — Total for each order

Produce one row per order showing the order number, customer name, number of
item lines, total units and order total after discounts. Sort from the highest
to the lowest order total.

**Check:** `ORD-2026-001` should total **RM3,378.80**.

### Question 13 — Revenue by order status

Calculate total sales value for each order status. Exclude cancelled orders.
Display the status, number of orders and total value. Show the highest value
first.

**Expected groups:** 4

### Question 14 — Customer spending

Calculate total spending per customer from non-cancelled orders. Include
customers with no orders and show their spending as `0.00`. Sort from highest
to lowest spending and then by customer name.

**Expected rows:** 7

### Question 15 — Units sold per product

Calculate the total quantity sold for every product. Exclude quantities from
cancelled orders, but retain products that have never been sold. Display zero
instead of `NULL` and sort from most units to least units.

**Expected rows:** 9

### Question 16 — Repeat customers

Find customers who have at least two non-cancelled orders. Use `HAVING` rather
than `WHERE` for the order-count condition.

**Expected customers:** `Aisyah Rahman` and `Daniel Lee`

---

## Part D — Integrated business challenges

### Question 17 — High-value orders

Find orders worth at least RM500 after discounts. Display the order number,
customer name, status and total. Sort from highest to lowest total.

**Expected orders:** 4

### Question 18 — Management order report

Create a report with the order number, customer name, order date, number of
distinct products, total units, order value and payment status.

Derive `payment_status` using:

- `PAID IN FULL` when payments are equal to or greater than the order value;
- `PARTIALLY PAID` when payments are greater than zero but below the order value;
- `UNPAID` when no payment exists.

Exclude cancelled orders and show only orders worth at least RM200.

**Expected rows:** 6

### Question 19 — Revenue by category

Calculate non-cancelled sales revenue for every category. Categories must remain
visible even when their revenue is zero. Display the category name and revenue,
sorted from highest to lowest revenue.

**Expected result check:**

- Laptops: RM3,199.00
- Storage: RM1,327.00
- Accessories: RM1,017.70
- Networking: RM757.00

### Question 20 — Payment reconciliation

For every non-cancelled order, show the order number, order total, amount paid
and outstanding balance. Use `0.00` when an order has no payment.

**Expected unpaid balances:**

- `ORD-2026-003`: RM719.00
- `ORD-2026-004`: RM249.00

---

## Bonus debugging question

The following query is intended to show all products, including products with
no completed sales:

```sql
SELECT p.product_name, sum(oi.quantity) AS units_sold
FROM sales.products AS p
LEFT JOIN sales.order_items AS oi ON oi.product_id = p.product_id
LEFT JOIN sales.orders AS o ON o.order_id = oi.order_id
WHERE o.status <> 'CANCELLED'
GROUP BY p.product_id, p.product_name;
```

It incorrectly removes products with no orders. Explain why, then rewrite it so
every product remains visible and unsold products display zero.

## Submission checklist

- [ ] One labelled SQL query for each question
- [ ] Result evidence for each query
- [ ] Meaningful column aliases
- [ ] Qualified column names in multi-table queries
- [ ] Correct join conditions
- [ ] Currency totals rounded or cast to two decimal places
- [ ] No changes made to the supplied data

