# 🛒 Olist E-Commerce Data Pipeline & Analytics
Please note that all the information regarding the case study has been sourced from the following link:(https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce/data).

</br>

## 📚 Table of Contents
* Business Task

* Data Architecture & Batch Processing

* Data Schema Diagram

* Question and Solution

</br>

## 🎯 Business Task

The core objective of this project is to architect a robust data pipeline and perform comprehensive exploratory data analysis (EDA) on the Brazilian e-commerce platform, Olist. The business tasks are defined as follows:

#### Financial Performance: 
Calculate Total Revenue, Average Order Value (AOV), and top-performing product categories.

#### Operational Efficiency: 
Evaluate the complete order lifecycle, tracking delivery SLA times from purchase to customer fulfillment.

#### Customer & Vendor Behavior: 
Identify repeat purchasing patterns, top-earning sellers across various states, and the overall volume of users.

#### Quality Assurance: 
Correlate shipping delays and product categories with customer review scores to highlight areas needing operational improvement.

</br>

## ⚙️ Data Architecture & Batch Processing

To handle the extensive Olist datasets efficiently, a Python-based ETL (Extract, Transform, Load) pipeline was developed to bypass standard GUI import limits and ensure data integrity.

#### Dataset Examination: 
Analyzed 9 distinct localized CSV files encompassing over 100,000 orders, mapping out primary and foreign keys for dimensional modeling.

#### Database Provisioning: 
Automated the creation of a MySQL database (olist_ecommerce) using SQLAlchemy.

#### Schema Definition: 
Explicitly defined database schemas utilizing strict data typing (e.g., VARCHAR(32), DECIMAL(10,2), DATETIME) and established foundational indices (INDEX idx_customer, INDEX idx_product) to optimize downstream query performance.

#### Batch Uploading:
Utilized a chunking methodology (CHUNK_SIZE = 10_000) within a Python script to incrementally load the pandas DataFrames into the relational database. This prevents memory overflow and ensures reliable batch processing.


</br>

## 🗂️ Entity Relationship and Data Schema Diagram
<img width="2486" height="1496" alt="Data Schema" src="https://github.com/user-attachments/assets/8e0b3cce-c647-4610-b404-2c296b84b427" />


The database utilizes a snowflake schema optimized for OLAP querying. The core relationships are structured as follows:

#### Fact Tables:

stg_orders: The central hub linking to customer_id.

stg_order_items: Granular line-item data linking order_id to product_id and seller_id.


#### Dimension Tables:

stg_customers & stg_sellers: Holds demographic and geographic attributes.

stg_products & stg_product_category: Holds product specifications and English translations.

### Ancillary Tables:

stg_order_payments and stg_order_reviews connect directly back to the stg_orders table via order_id.


</br>

## 💡 Question and Solution
Below is a curated selection of complex SQL queries crafted to answer the core business questions.

</br>

### 1. How many orders, customers, and products are in the dataset?

```SQL
SELECT 
  'Orders' AS metric, COUNT(*) AS count 
FROM stg_orders
UNION ALL
SELECT 'Customers', COUNT(*) FROM stg_customers
UNION ALL
SELECT 'Products', COUNT(*) FROM stg_products;
```

Steps:

* Use COUNT(*) to calculate the total number of records in each respective table (stg_orders, stg_customers, stg_products).

* Assign a hardcoded string alias ('Orders', 'Customers', etc.) to label each count clearly.

* Use UNION ALL to vertically stack the individual results into a single, combined summary table.


Answer:
| metric | count |
| :--- | :--- |
| Orders | 99,441 |
| Customers | 99,441 |
| Products | 32,951 |

There are 99,441 total orders and customers, with 32,951 unique products available.

</br>

### 2. What is the breakdown of order statuses?

```SQL
SELECT order_status, COUNT(*) as order_count,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM stg_orders), 2) as pct
FROM stg_orders 
GROUP BY order_status 
ORDER BY order_count DESC;
```

Steps:

* Use GROUP BY to segment the dataset by order_status.

* Use COUNT(*) to find the total frequency of each status.

* Implement a scalar subquery (SELECT COUNT(*) FROM stg_orders) to act as the denominator for calculating the exact percentage (pct).

* Use ROUND() to format the percentage output to two decimal places and ORDER BY to list the highest occurrences first.


Answer:
| order_status | order_count | pct |
| :--- | :--- | :--- |
| delivered | 96,478 | 97.02 |
| shipped | 1,107 | 1.11 |
| canceled | 625 | 0.63 |

The vast majority (97.02%) of orders are successfully delivered.

</br>

### 3. Which are the Top 5 states by order volume?

```SQL
SELECT c.customer_state, COUNT(DISTINCT o.order_id) as order_count
FROM stg_orders o
JOIN stg_customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY order_count DESC
LIMIT 5;
```

Steps:

* Use an INNER JOIN to link the order records (stg_orders) with the customer demographics (stg_customers) via the customer_id.

* Use COUNT(DISTINCT o.order_id) to ensure accurate counting of unique orders per state.

* GROUP BY the state, arrange in descending order, and apply a LIMIT 5 to isolate the top geographic performers.


Answer:
| customer_state | order_count |
| :--- | :--- |
| SP | 41,746 |
| RJ | 12,852 |
| MG | 11,635 |

São Paulo (SP) is the leading state for order volume, followed by Rio de Janeiro (RJ).

</br>

### 4. What is the Average Order Value (AOV) and the pricing spread?

```SQL
SELECT 
  ROUND(AVG(payment_value), 2) as avg_order_value,
  ROUND(MIN(payment_value), 2) as min_order_value,
  ROUND(MAX(payment_value), 2) as max_order_value
FROM stg_order_payments;
```

Steps:

* Target the stg_order_payments table to capture final checkout values.

* Apply aggregate functions AVG, MIN, and MAX to the payment_value column to calculate the mean and the extreme ranges of customer spending.

* ROUND all financial outputs to 2 decimal places.


Answer:
| avg_order_value | min_order_value | max_order_value |
| :--- | :--- | :--- |
| 154.10 | 0.00 | 13664.08 |

The average order value on the platform is $154.10.

</br>

### 5. What is the average review score segmented by order status?

```SQL
SELECT o.order_status, 
       ROUND(AVG(r.review_score), 2) as avg_score,
       COUNT(r.review_id) as review_count
FROM stg_orders o
LEFT JOIN stg_order_reviews r ON o.order_id = r.order_id
GROUP BY o.order_status
ORDER BY avg_score DESC;
```

Steps:

* Perform a LEFT JOIN from orders to reviews to ensure all orders are categorized, even if a customer did not leave a review.

* Calculate the AVG review score and COUNT the total reviews submitted per status.

* GROUP BY the order status to analyze how fulfillment success dictates customer satisfaction.


Answer:
| order_status | avg_score | review_count |
| :--- | :--- | :--- |
| delivered | 4.15 | 96,351 |
| canceled | 1.80 | 602 |

Delivered orders receive an average rating of 4.15, while canceled orders drop drastically to 1.80.

</br>

### 6. What is the distribution of payment types?

```SQL
SELECT payment_type, 
       COUNT(*) as payment_count,
       ROUND(SUM(payment_value), 2) as total_value
FROM stg_order_payments
GROUP BY payment_type
ORDER BY payment_count DESC;
```

Steps:

* Query the stg_order_payments table and GROUP BY the specific payment_type.

* Use COUNT(*) to track the transaction frequency and SUM(payment_value) to track the total revenue driven by each method.

* Order the results in descending order of frequency.

Answer:
| payment_type | payment_count | total_value |
| :--- | :--- | :--- |
| credit_card | 76,795 | 12542084.19 |
| boleto | 19,784 | 2869361.27 |

Credit cards are the dominant payment method, capturing over 76,000 transactions.

</br>

### 7. Which are the Top 5 products by total revenue?

```SQL
SELECT p.product_id, p.product_category_name,
       ROUND(SUM(oi.price), 2) as total_revenue,
       COUNT(oi.order_id) as order_count
FROM stg_order_items oi
JOIN stg_products p ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_category_name
ORDER BY total_revenue DESC
LIMIT 5;
```

Steps:

* JOIN the granular stg_order_items table with the stg_products dimension table.

* Use SUM(price) to calculate the total gross revenue generated by each unique item.

* GROUP BY both the product ID and its category to retain descriptive context.

* Apply a LIMIT 5 to highlight only the absolute highest earners.


Answer:
| product_id | product_category_name | total_revenue | order_count |
| :--- | :--- | :--- | :--- |
| bb50f2e2... | beleza_saude | 63885.00 | 195 |

The top-earning individual product belongs to the health/beauty category, generating $63,885.

</br>

### 8. Which are the Top 5 sellers by total revenue?

```SQL
SELECT s.seller_id, s.seller_state,
       ROUND(SUM(oi.price + oi.freight_value), 2) as total_revenue,
       COUNT(DISTINCT oi.order_id) as orders
FROM stg_order_items oi
JOIN stg_sellers s ON oi.seller_id = s.seller_id
GROUP BY s.seller_id, s.seller_state
ORDER BY total_revenue DESC
LIMIT 5;
```

Steps:

* JOIN the order items to the stg_sellers table.

* Calculate true gross revenue by adding price and freight_value inside the SUM() function.

* Track the volume of distinct orders processed by each seller.

* GROUP BY the seller and their state, isolating the top 5 earners.


Answer:
| seller_id | seller_state | total_revenue | orders |
| :--- | :--- | :--- | :--- |
| 4869f7a5... | SP | 229472.63 | 1156 |

The top seller is based in SP, managing over 1,150 orders for a combined revenue of $229,472.

</br>

### 9. What is the average number of delivery days by order status?

```SQL
SELECT order_status,
       ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 2) as avg_days
FROM stg_orders
WHERE order_delivered_customer_date IS NOT NULL
GROUP BY order_status
ORDER BY avg_days;
```

Steps:

* Utilize the DATEDIFF() function to calculate the time gap between the purchase timestamp and the final customer delivery date.

* Filter out incomplete records utilizing the WHERE IS NOT NULL clause on the delivery date.

* AVG the differences and group them by the order status.


Answer:
| order_status | avg_days |
| :--- | :--- |
| delivered | 12.09 |
| canceled | 15.33 |

Successfully delivered orders take an average of 12 days to reach the customer.

</br>

### 10. What is the volume of orders generated per month?

```SQL
SELECT DATE_FORMAT(order_purchase_timestamp, '%Y-%m') as month,
       COUNT(*) as order_count
FROM stg_orders
GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
ORDER BY month;
```

Steps:

* Use the DATE_FORMAT() function to extract a clean Year-Month (%Y-%m) string from the granular timestamp.

* Count the total number of orders that fall into each monthly bucket.

* GROUP BY and ORDER BY the formatted month to create a chronological time-series view.


Answer:
| month | order_count |
| :--- | :--- |
| 2017-01 | 800 |
| 2017-02 | 1,780 |

Order volume scales chronologically, starting with 800 orders in January 2017.

</br>

### 11. What percentage of the user base are repeat customers?

```SQL
SELECT 
  ROUND(AVG(repeat_orders), 2) as avg_orders_per_customer,
  ROUND(SUM(repeat_customers)*100.0/COUNT(*), 2) as pct_repeat_customers
FROM (
  SELECT customer_unique_id,
         COUNT(DISTINCT order_id) as repeat_orders,
         CASE WHEN COUNT(DISTINCT order_id) > 1 THEN 1 ELSE 0 END as repeat_customers
  FROM stg_orders o
  JOIN stg_customers c ON o.customer_id = c.customer_id
  GROUP BY customer_unique_id
) t;
```

Steps:

* Create an inner query (Derived Table t) that groups data by the actual customer_unique_id.

* Inside the subquery, use a CASE WHEN statement to flag users with > 1 order as a "1" (repeat) or "0" (one-time).

* In the outer query, calculate the overall averages and percentage of repeat customers based on the binary flags.


Answer:
| avg_orders_per_customer | pct_repeat_customers |
| :--- | :--- |
| 1.03 | 3.12 |

Brand loyalty is low; only 3.12% of the user base has made more than one purchase.

</br>

### 12. Which are the Top 5 overall categories by revenue?

```SQL
SELECT p.product_category_name,
       ROUND(SUM(oi.price), 2) as revenue,
       COUNT(*) as items_sold
FROM stg_order_items oi
JOIN stg_products p ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY revenue DESC
LIMIT 5;
```

Steps:

* JOIN order items to products to access the product_category_name.

* Sum the price of all items sold within each category.

* GROUP BY the category name, sort descending by total revenue, and limit the output to the top 5 macro categories.


Answer:
| product_category_name | revenue | items_sold |
| :--- | :--- | :--- |
| beleza_saude | 1258681.34 | 9670 |
| relogios_presentes | 1205005.68 | 5991 |

Health & Beauty is the highest-grossing product category overall.

</br>

### 13. What is the average impact of shipping costs relative to item prices?

```SQL
SELECT 
  ROUND(AVG(price), 2) as avg_price,
  ROUND(AVG(freight_value), 2) as avg_freight,
  ROUND(AVG(freight_value/NULLIF(price,0))*100, 2) as freight_pct
FROM stg_order_items;
```

Steps:

* Extract the core averages for item price and freight_value directly from the stg_order_items table.

* Calculate the per-item percentage cost of freight by dividing freight by price.

* Use NULLIF(price, 0) to prevent the query from throwing a "division by zero" error on free/zero-cost items.


Answer:
| avg_price | avg_freight | freight_pct |
| :--- | :--- | :--- |
| 120.65 | 19.99 | 22.50 |

On average, shipping costs represent roughly 22.5% of the actual item price.

</br>

### 14. Which categories possess the highest average customer reviews?

```SQL
SELECT p.product_category_name,
       ROUND(AVG(r.review_score), 2) as avg_score,
       COUNT(r.review_id) as reviews
FROM stg_order_items oi
JOIN stg_products p ON oi.product_id = p.product_id
JOIN stg_order_reviews r ON oi.order_id = r.order_id
GROUP BY p.product_category_name
HAVING COUNT(r.review_id) > 50
ORDER BY avg_score DESC
LIMIT 3;
```

Steps:

* Perform a multi-table JOIN linking items, products, and reviews to map score to category.

* GROUP BY the category name and calculate the AVG(review_score).

* Apply a HAVING clause to filter out categories with fewer than 50 reviews, ensuring the top ranking is based on a statistically significant sample size.


Answer:
| product_category_name | avg_score | reviews |
| :--- | :--- | :--- |
| cds_dvds_musicais | 4.64 | 63 |
| livros_interesse_geral | 4.45 | 553 |

CDs and General Interest Books maintain the highest consumer satisfaction scores.

</br>

### 15. What is the summary of delays across the order lifecycle?

```SQL
SELECT 
  COUNT(*) as total_orders,
  ROUND(AVG(DATEDIFF(order_approved_at, order_purchase_timestamp)), 2) as approval_delay,
  ROUND(AVG(DATEDIFF(order_delivered_carrier_date, order_approved_at)), 2) as carrier_delay,
  ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_delivered_carrier_date)), 2) as delivery_delay
FROM stg_orders
WHERE order_delivered_customer_date IS NOT NULL;
```

Steps:

* Calculate the day-deltas (DATEDIFF) between three critical stages: Purchase to Approval, Approval to Carrier dispatch, and Carrier to Final Customer delivery.

* Enforce a WHERE clause ensuring the customer delivery date is populated to only measure completed order lifecycles.

* AVG these distinct phases to pinpoint operational bottlenecks.


Answer:
| total_orders | approval_delay | carrier_delay | delivery_delay |
| :--- | :--- | :--- | :--- |
| 96,470 | 0.27 | 2.75 | 9.09 |

The bulk of the fulfillment time is spent in the last-mile delivery phase (Carrier to Customer), averaging 9 days.
