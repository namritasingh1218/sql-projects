# 🍕 Domino’s Pizza Store Analysis SQL Project

![dominoz pizza](https://github.com/namritasingh1218/sql-projects/blob/main/Dominos_sql_project/dominos%20logo.png)

## Project Overview

**Project Title**: Domino’s Pizza Store Analysis  
**Database**: `p1_dominos_db`

This project demonstrates SQL techniques used by analysts to explore, clean, and analyze pizza sales and customer data. The analysis focuses on understanding order patterns, revenue, customer behavior, and menu performance to support business decision-making.

---

## Objectives

1. **Set up a Domino’s pizza database**: Create and populate the database with orders, pizzas, and customers.  
2. **Data Cleaning**: Identify and remove null or inconsistent records.  
3. **Exploratory Data Analysis (EDA)**: Understand customer behavior, order trends, and menu performance.  
4. **Business Analysis**: Answer stakeholder-driven questions to derive actionable insights.

---

## Database Structure

**Tables**:

- `orders`: Contains order-level information (order_id, custId, order_date, order_time).  
- `order_details`: Contains details of each order (order_detail_id, order_id, pizza_id, quantity).  
- `pizzas`: Contains pizza information (pizza_id, pizza_type_id, size, price).  
- `pizza_types`: Contains pizza type info (pizza_type_id, name, category).  
- `customers`: Contains customer info (custId, first_name, last_name).

---

## Data Cleaning & Exploration

- Verify total records in each table.  
- Check for null or missing values in critical columns.  
- Remove incomplete or inconsistent records.

---

## Schema

```sql
CREATE TABLE customers (
    custid INT NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone BIGINT NOT NULL,
    address VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(10) NOT NULL,
    postal_code INT NOT NULL
);
```

```sql
BULK INSERT customers
FROM 'C:\Temp\customers.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0d0a',
    TABLOCK,
    CODEPAGE = '65001'
);
```

```sql
CREATE TABLE pizza_types (
    pizza_type_id VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    ingredients VARCHAR(MAX) NOT NULL
);
```

```sql
BULK INSERT pizza_types
FROM 'C:\Temp\pizza_types.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0d0a',
    TABLOCK
);
```

```sql
CREATE TABLE pizzas (
    pizza_id     VARCHAR(20) NOT NULL,
    pizza_type_id VARCHAR(20) NOT NULL,
    size         VARCHAR(5)  NOT NULL,
    price        DECIMAL(5,2) NOT NULL
);
```

```sql
BULK INSERT pizzas
FROM 'C:\Temp\pizzas.csv'
WITH (
    FIRSTROW = 2,                 -- skip header
    FIELDTERMINATOR = ',',         -- comma separated
    ROWTERMINATOR = '0x0d0a',      -- Windows line ending
    CODEPAGE = '65001',            -- UTF-8
    TABLOCK
);
```

```sql
CREATE TABLE orders (
    order_id INT NOT NULL,
    order_date DATE NOT NULL,
    order_time TIME(0) NOT NULL,
    custid INT NOT NULL,
    status VARCHAR(20) NOT NULL
);
```

```sql
BULK INSERT orders
FROM 'C:\Temp\orders.csv'
WITH (
    FIRSTROW = 2,              -- skip header
    FIELDTERMINATOR = ',',     -- comma separated
    ROWTERMINATOR = '0x0d0a',  -- Windows line ending
    TABLOCK,
    CODEPAGE = '65001'         -- UTF-8
);
```

```sql
CREATE TABLE order_details (
    order_details_id INT NOT NULL,
    order_id INT NOT NULL,
    pizza_id VARCHAR(14) NOT NULL,
    quantity INT NOT NULL
);
```

```sql
BULK INSERT order_details
FROM 'C:\Temp\order_details.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0d0a',   -- Windows line ending
    CODEPAGE = '65001',        -- UTF-8
    TABLOCK
);
```

## Alter Tables

```sql
ALTER TABLE pizza_types
ALTER COLUMN pizza_type_id VARCHAR(50) NOT NULL;

ALTER TABLE pizzas
ALTER COLUMN pizza_id VARCHAR(20) NOT NULL;

ALTER TABLE pizzas
ALTER COLUMN pizza_type_id VARCHAR(50) NOT NULL;

ALTER TABLE order_details
ALTER COLUMN pizza_id VARCHAR(20) NOT NULL;

ALTER TABLE orders
ALTER COLUMN custid INT NOT NULL;
```

```sql
ALTER TABLE pizza_types
ADD CONSTRAINT pk_pizza_types PRIMARY KEY (pizza_type_id);

ALTER TABLE pizzas
ADD CONSTRAINT pk_pizzas PRIMARY KEY (pizza_id);

ALTER TABLE customers
ADD CONSTRAINT pk_customers PRIMARY KEY (custid);

ALTER TABLE orders
ADD CONSTRAINT pk_orders PRIMARY KEY (order_id);

ALTER TABLE order_details
ADD CONSTRAINT pk_order_details PRIMARY KEY (order_details_id);
```

```sql
ALTER TABLE pizzas
ADD CONSTRAINT fk_pizzas_pizza_types
FOREIGN KEY (pizza_type_id)
REFERENCES pizza_types (pizza_type_id);

ALTER TABLE orders
ADD CONSTRAINT fk_orders_customers
FOREIGN KEY (custid)
REFERENCES customers (custid);

ALTER TABLE order_details
ADD CONSTRAINT fk_order_details_pizzas
FOREIGN KEY (pizza_id)
REFERENCES pizzas (pizza_id);

ALTER TABLE order_details
ADD CONSTRAINT fk_order_details_orders
FOREIGN KEY (order_id)
REFERENCES orders (order_id);
```


## Analysis & Queries

### 1. Orders Volume Analysis
- Total unique orders, month-over-month, year-over-year, peak and off-peak ordering days, day-of-week analysis, repeat customers, average orders per customer, cumulative order trend.

```sql
SELECT COUNT (DISTINCT order_id) FROM orders;
```

```sql
WITH monthly_orders AS (
    SELECT
        DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1) AS month,
        COUNT(order_id) AS order_count
    FROM orders
    GROUP BY DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1)
)
SELECT
    month,
    order_count,
    LAG(order_count) OVER (ORDER BY month) AS prev_month_orders,
    CAST(
        100.0 * (order_count - LAG(order_count) OVER (ORDER BY month)) /
        NULLIF(LAG(order_count) OVER (ORDER BY month), 0)
        AS DECIMAL(5,2)
    ) AS mom_growth_percent
FROM monthly_orders
ORDER BY month;
```

```sql
WITH yearly_orders AS (
    SELECT
        YEAR(order_date) AS year,
        COUNT(order_id) AS order_count
    FROM orders
    GROUP BY YEAR(order_date)
)
SELECT
    year,
    order_count,
    LAG(order_count) OVER (ORDER BY year) AS prev_year_orders,
    CAST(
        100.0 * (order_count - LAG(order_count) OVER (ORDER BY year)) /
        NULLIF(LAG(order_count) OVER (ORDER BY year), 0)
        AS DECIMAL(5,2)
    ) AS yoy_growth_percent
FROM yearly_orders
ORDER BY year;
```

```sql
WITH daily_orders AS (
    SELECT
        DATENAME(WEEKDAY, order_date) AS day_name,
        DATEPART(WEEKDAY, order_date) AS day_number,
        COUNT(order_id) AS order_count
    FROM orders
    GROUP BY
        DATENAME(WEEKDAY, order_date),
        DATEPART(WEEKDAY, order_date)
)
SELECT
    day_name,
    order_count,
    CASE
        WHEN order_count = MAX(order_count) OVER () THEN 'Peak Day'
        WHEN order_count = MIN(order_count) OVER () THEN 'Off-Peak Day'
        ELSE 'Normal Day'
    END AS day_category
FROM daily_orders
ORDER BY day_number;
```

```sql
SELECT
    CASE
        WHEN DATENAME(WEEKDAY, order_date) IN ('Saturday', 'Sunday')
            THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY
    CASE
        WHEN DATENAME(WEEKDAY, order_date) IN ('Saturday', 'Sunday')
            THEN 'Weekend'
        ELSE 'Weekday'
    END;
```

```sql
SELECT
    c.custid,
    c.first_name,
    c.last_name,
    COUNT(o.order_id) AS total_orders
FROM orders o
JOIN customers c
    ON o.custid = c.custid
GROUP BY
    c.custid,
    c.first_name,
    c.last_name
HAVING COUNT(o.order_id) > 1
ORDER BY total_orders DESC;
```

```sql
SELECT
    CAST(
        COUNT(order_id) * 1.0 / COUNT(DISTINCT custid)
        AS DECIMAL(10,2)
    ) AS avg_orders_per_customer
FROM orders;
```

```sql
WITH monthly_orders AS (
    SELECT
        DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1) AS month,
        COUNT(order_id) AS order_count
    FROM orders
    GROUP BY DATEFROMPARTS(YEAR(order_date), MONTH(order_date), 1)
)
SELECT
    month,
    order_count,
    LAG(order_count) OVER (ORDER BY month) AS prev_month_orders,
    CAST(
        100.0 * (order_count - LAG(order_count) OVER (ORDER BY month)) /
        NULLIF(LAG(order_count) OVER (ORDER BY month), 0)
        AS DECIMAL(5,2)
    ) AS mom_growth_percent
FROM monthly_orders
ORDER BY month;

select order_date,
count(order_id) as daily_orders,
SUM(COUNT (order_id) ) OVER(ORDER BY order_date) as cumlative_orders
FROM orders
GROUP BY order_date
order by order_date;
```


### 2. Total Revenue from Pizza Sales
- Calculate total revenue from all pizza sales.

```sql
SELECT SUM(od.quantity * p.price) AS total_revenue
FROM order_details od
JOIN pizzas p 
     ON od.pizza_id = p.pizza_id;
```

### 3. Highest-Priced Pizza
- Identify the most expensive pizza on the menu.

```sql
SELECT
pt.name,
p.size,
CONCAT ('$', p.price) AS price
FROM pizzas p
JOIN pizza_types pt 
     ON p.pizza_type_id = pt.pizza_type_id
ORDER BY p.price DESC;
```

### 4. Most Common Pizza Size Ordered
- Determine the most frequently ordered pizza size.

```sql
SELECT TOP 1 
     p.size, 
     COUNT(*) AS total_orders
FROM order_details od
JOIN pizzas p 
      ON od.pizza_id = p.pizza_Id
JOIN pizza_types pt 
      ON p.pizza_type_id = pt.pizza_type_id
GROUP BY p.size
ORDER BY total_orders DESC;
```

### 5. Top 5 Most Ordered Pizza Types
- Find the top 5 pizza types based on quantity sold.

```sql
SELECT TOP 5
    pt.pizza_type_id ,
    SUM(od.quantity) AS total_units_sold
FROM order_details od
JOIN pizzas p 
      ON od.pizza_id = p.pizza_id
JOIN pizza_types pt 
      ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.pizza_type_id
ORDER BY total_units_sold DESC;
```

### 6. Total Quantity by Pizza Category
- Calculate total pizzas sold in each category.

```sql
SELECT
pt.category,
SUM(od.quantity) AS total_qty
FROM order_details od
JOIN pizzas p 
     ON od.pizza_id = p.pizza_id
JOIN pizza_types pt 
     ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category;
```

### 7. Orders by Hour of the Day
- Understand peak ordering hours to optimize staffing.

```sql
SELECT
    DATEPART(HOUR, order_time) AS order_hour,
    COUNT(*) AS order_count
FROM orders
GROUP BY DATEPART(HOUR, order_time)
ORDER BY order_hour;
```

```sql
SELECT
    CASE
        WHEN DATEPART(HOUR, order_time) BETWEEN 12 AND 14 THEN 'Lunch (12–2 PM)'
        WHEN DATEPART(HOUR, order_time) BETWEEN 18 AND 21 THEN 'Evening (6–9 PM)'
        WHEN DATEPART(HOUR, order_time) BETWEEN 22 AND 23
          OR DATEPART(HOUR, order_time) BETWEEN 0 AND 5 THEN 'Late Night'
        ELSE 'Other Hours'
    END AS time_slot,
    COUNT(*) AS total_orders
FROM orders
GROUP BY
    CASE
        WHEN DATEPART(HOUR, order_time) BETWEEN 12 AND 14 THEN 'Lunch (12–2 PM)'
        WHEN DATEPART(HOUR, order_time) BETWEEN 18 AND 21 THEN 'Evening (6–9 PM)'
        WHEN DATEPART(HOUR, order_time) BETWEEN 22 AND 23
          OR DATEPART(HOUR, order_time) BETWEEN 0 AND 5 THEN 'Late Night'
        ELSE 'Other Hours'
    END
ORDER BY total_orders DESC;
```

### 8. Category-Wise Pizza Distribution
- Analyze category-wise sales and percentage share.

```sql
WITH category_orders AS (
    SELECT
        pt.category,
        SUM(od.quantity) AS total_orders
    FROM order_details od
    JOIN pizzas p
        ON od.pizza_id = p.pizza_id
    JOIN pizza_types pt
        ON p.pizza_type_id = pt.pizza_type_id
    GROUP BY pt.category
)
SELECT
    category,
    total_orders,
    CAST(
        100.0 * total_orders / SUM(total_orders) OVER ()
        AS DECIMAL(5,2)
    ) AS percentage_share
FROM category_orders
ORDER BY total_orders DESC;
```

### 9. Average Pizzas Ordered per Day
- Measure daily pizza demand consistency.

```sql
WITH daily_pizzas AS (
    SELECT
        order_date,
        SUM(od.quantity) AS pizzas_per_day
    FROM orders o
    JOIN order_details od
        ON o.order_id = od.order_id
    GROUP BY order_date
)
SELECT
    CAST(AVG(pizzas_per_day * 1.0) AS DECIMAL(10,2)) AS avg_pizzas_per_day
FROM daily_pizzas;
```

### 10. Top 3 Pizzas by Revenue
- Identify pizzas generating the highest revenue.

```sql
WITH pizza_revenue AS (
    SELECT
        pt.name,
        SUM(od.quantity * p.price) AS revenue,
        RANK() OVER (
            ORDER BY SUM(od.quantity * p.price) DESC
        ) AS revenue_rank
    FROM order_details od
    JOIN pizzas p
        ON od.pizza_id = p.pizza_id
    JOIN pizza_types pt
        ON p.pizza_type_id = pt.pizza_type_id
    GROUP BY pt.name
)
SELECT
    name,
    revenue
FROM pizza_revenue
WHERE revenue_rank <= 3;
```

### 11. Revenue Contribution per Pizza
- Percentage contribution of each pizza to total revenue.

```sql
WITH pizza_revenue AS (
    SELECT
        pt.name,
        SUM(od.quantity * p.price) AS revenue
    FROM order_details od
    JOIN pizzas p
        ON od.pizza_id = p.pizza_id
    JOIN pizza_types pt
        ON p.pizza_type_id = pt.pizza_type_id
    GROUP BY pt.name
)
SELECT
    name,
    revenue,
    CAST(
        100.0 * revenue / SUM(revenue) OVER ()
        AS DECIMAL(5,2)
    ) AS revenue_percentage
FROM pizza_revenue
ORDER BY revenue_percentage DESC;
```

### 12. Cumulative Revenue Over Time
- Monthly cumulative revenue trend since launch.

```sql
WITH monthly_revenue AS (
    SELECT
        DATEFROMPARTS(YEAR(o.order_date), MONTH(o.order_date), 1) AS month,
        SUM(od.quantity * p.price) AS monthly_revenue
    FROM orders o
    JOIN order_details od
        ON o.order_id = od.order_id
    JOIN pizzas p
        ON od.pizza_id = p.pizza_id
    GROUP BY DATEFROMPARTS(YEAR(o.order_date), MONTH(o.order_date), 1)
)
SELECT
    month,
    monthly_revenue,
    SUM(monthly_revenue) OVER (
        ORDER BY month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue
FROM monthly_revenue
ORDER BY month;
```

### 13. Top 3 Pizzas by Category (Revenue-Based)
- Top 3 pizzas by revenue in each category.

```sql
WITH cat_rank AS (
     SELECT pt.category, pt.name,
     SUM(od.quantity * p.price) AS revenue,
     RANK() OVER (PARTITION BY pt.category ORDER BY SUM(od.quantity * p.price) DESC) AS rnk
     FROM order_details od
     JOIN pizzas p ON od.pizza_id = p.pizza_id
     JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
     GROUP BY pt.category, pt.name
)
SELECT category, name, revenue
FROM cat_rank
WHERE rnk <= 3;
```

### 14. Top 10 Customers by Spending
- Identify the highest-spending customers.

```sql
SELECT TOP 10
    c.custid,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    SUM(od.quantity * p.price) AS total_spent
FROM customers c
JOIN orders o
    ON c.custid = o.custid
JOIN order_details od
    ON o.order_id = od.order_id
JOIN pizzas p
    ON od.pizza_id = p.pizza_id
GROUP BY
    c.custid,
    CONCAT(c.first_name, ' ', c.last_name)
ORDER BY total_spent DESC;
```

### 15. Average Order Size
- Calculate average number of pizzas per order.

```sql
WITH order_pizza_count AS (
    SELECT
        order_id,
        SUM(quantity) AS pizzas_per_order
    FROM order_details
    GROUP BY order_id
)
SELECT
    CAST(AVG(pizzas_per_order * 1.0) AS DECIMAL(5,2)) AS avg_pizzas_per_order
FROM order_pizza_count;
```

### 16. Seasonal Trends
- Analyze sales patterns by month and holidays.

```sql
SELECT
    MONTH(order_date) AS month,
    COUNT(*) AS total_orders
FROM orders
GROUP BY MONTH(order_date)
ORDER BY month;
```

### 17. Customer Segmentation
- Classify customers as High Value or Regular based on spend.

```sql
WITH customer_segment AS (
    SELECT
        c.custid,
        CASE
            WHEN SUM(od.quantity * p.price) >= 5000 THEN 'High Value'
            ELSE 'Regular'
        END AS customer_type
    FROM customers c
    JOIN orders o 
        ON c.custid = o.custid
    JOIN order_details od 
        ON o.order_id = od.order_id
    JOIN pizzas p 
        ON od.pizza_id = p.pizza_id
    GROUP BY c.custid
)
SELECT
    cs.customer_type,
    pt.category,
    COUNT(*) AS total_orders
FROM customer_segment cs
JOIN orders o 
    ON cs.custid = o.custid
JOIN order_details od 
    ON o.order_id = od.order_id
JOIN pizzas p 
    ON od.pizza_id = p.pizza_id
JOIN pizza_types pt 
    ON p.pizza_type_id = pt.pizza_type_id
GROUP BY
    cs.customer_type,
    pt.category
ORDER BY
    cs.customer_type,
    total_orders DESC;
```

### 18. Repeat Customer Rate
- Percentage of repeat customers versus one-time buyers.

```sql
WITH customer_orders AS (
    SELECT
        custid,
        COUNT(order_id) AS order_count
    FROM orders
    GROUP BY custid
)
SELECT
    customer_type,
    COUNT(*) AS customer_count,
    CAST(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER ()
        AS DECIMAL(5,2)
    ) AS percentage_share
FROM (
    SELECT
        custid,
        CASE
            WHEN order_count > 1 THEN 'Repeat Customer'
            ELSE 'One-Time Customer'
        END AS customer_type
    FROM customer_orders
) t
GROUP BY customer_type;
```

---

## Key Findings

- **Customer Behavior**: High-value and repeat customers identified.  
- **Order Trends**: Peak hours, weekends, and seasonal patterns discovered.  
- **Menu Insights**: Top-selling pizzas, revenue contributors, and popular sizes identified.  
- **Revenue Analysis**: Monthly revenue, cumulative trends, and category-wise contributions analyzed.  
- **Operational Insights**: Average order size, daily pizzas, and staffing optimization recommendations provided.


