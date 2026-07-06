-- ============================================================
-- 04: Core analysis queries
-- Each query answers a specific business sub-question.
-- Run them, screenshot/save interesting results, and let the
-- findings drive your dashboard design and memo.
--
-- NOTE ON MARGIN: Olist has no cost-of-goods data, so true margin
-- can't be computed. We use freight-to-price ratio as a proxy for
-- "fulfillment burden" instead — and we say so honestly in the
-- README. Adapting when data is missing is itself a skill worth
-- demonstrating.
-- ============================================================


-- ------------------------------------------------------------
-- Q1. Monthly revenue trend + month-over-month growth
-- ------------------------------------------------------------
SELECT
    order_month,
    COUNT(DISTINCT order_id)                          AS orders,
    ROUND(SUM(price), 2)                              AS revenue,
    ROUND(SUM(price) / COUNT(DISTINCT order_id), 2)   AS avg_order_value,
    ROUND(100.0 * (SUM(price) - LAG(SUM(price)) OVER (ORDER BY order_month))
          / NULLIF(LAG(SUM(price)) OVER (ORDER BY order_month), 0), 1) AS mom_growth_pct
FROM analytics.fct_sales
GROUP BY order_month
ORDER BY order_month;


-- ------------------------------------------------------------
-- Q2. Year-over-year growth by category (top 15 by revenue)
-- ------------------------------------------------------------
WITH yearly AS (
    SELECT
        category,
        EXTRACT(YEAR FROM order_purchase_timestamp)::int AS yr,
        SUM(price) AS revenue
    FROM analytics.fct_sales
    GROUP BY 1, 2
)
SELECT
    category,
    yr,
    ROUND(revenue, 2) AS revenue,
    ROUND(100.0 * (revenue - LAG(revenue) OVER (PARTITION BY category ORDER BY yr))
          / NULLIF(LAG(revenue) OVER (PARTITION BY category ORDER BY yr), 0), 1) AS yoy_growth_pct
FROM yearly
WHERE category IN (
    SELECT category FROM analytics.fct_sales
    GROUP BY category ORDER BY SUM(price) DESC LIMIT 15
)
ORDER BY category, yr;


-- ------------------------------------------------------------
-- Q3. Top / bottom categories by freight burden
--     (freight-to-price ratio = proxy for fulfillment cost drag)
-- ------------------------------------------------------------
SELECT
    category,
    ROUND(SUM(price), 2)                                   AS revenue,
    ROUND(SUM(freight_value), 2)                           AS freight,
    ROUND(100.0 * SUM(freight_value) / SUM(price), 1)      AS freight_pct_of_revenue,
    COUNT(*)                                               AS items_sold
FROM analytics.fct_sales
GROUP BY category
HAVING SUM(price) > 10000          -- ignore tiny categories
ORDER BY freight_pct_of_revenue DESC;


-- ------------------------------------------------------------
-- Q4. Revenue by state + average order value
--     (feeds the regional map on dashboard page 1)
-- ------------------------------------------------------------
SELECT
    customer_state,
    COUNT(DISTINCT order_id)                        AS orders,
    ROUND(SUM(price), 2)                            AS revenue,
    ROUND(SUM(price) / COUNT(DISTINCT order_id), 2) AS avg_order_value,
    ROUND(100.0 * SUM(price) / SUM(SUM(price)) OVER (), 1) AS pct_of_total_revenue
FROM analytics.fct_sales
GROUP BY customer_state
ORDER BY revenue DESC;


-- ------------------------------------------------------------
-- Q5. Seasonality index by month
--     (avg revenue for each calendar month vs overall monthly avg;
--      100 = average, >100 = above-average month)
-- ------------------------------------------------------------
WITH monthly AS (
    SELECT order_month,
           EXTRACT(MONTH FROM order_month)::int AS cal_month,
           SUM(price) AS revenue
    FROM analytics.fct_sales
    GROUP BY 1, 2
)
SELECT
    cal_month,
    TO_CHAR(TO_DATE(cal_month::text, 'MM'), 'Mon')          AS month_name,
    ROUND(AVG(revenue), 2)                                  AS avg_revenue,
    ROUND(100.0 * AVG(revenue) / (SELECT AVG(revenue) FROM monthly), 0) AS seasonality_index
FROM monthly
GROUP BY cal_month
ORDER BY cal_month;


-- ------------------------------------------------------------
-- Q6. New vs returning customer revenue
--     (uses customer_unique_id; customer_id changes per order)
-- ------------------------------------------------------------
WITH orders_ranked AS (
    SELECT
        order_id,
        customer_unique_id,
        order_month,
        price,
        MIN(order_month) OVER (PARTITION BY customer_unique_id) AS first_month
    FROM analytics.fct_sales
)
SELECT
    order_month,
    ROUND(SUM(price) FILTER (WHERE order_month =  first_month), 2) AS new_customer_revenue,
    ROUND(SUM(price) FILTER (WHERE order_month <> first_month), 2) AS returning_customer_revenue,
    ROUND(100.0 * SUM(price) FILTER (WHERE order_month <> first_month) / SUM(price), 1) AS returning_pct
FROM orders_ranked
GROUP BY order_month
ORDER BY order_month;


-- ------------------------------------------------------------
-- Q7. Late delivery rate by state (ties operations to revenue risk;
--     a strong "insight" candidate for the memo)
-- ------------------------------------------------------------
SELECT
    customer_state,
    COUNT(*)                                                    AS delivered_items,
    ROUND(100.0 * COUNT(*) FILTER (WHERE delivery_status = 'Late') / COUNT(*), 1) AS late_pct,
    ROUND(SUM(price) FILTER (WHERE delivery_status = 'Late'), 2)                  AS revenue_delivered_late
FROM analytics.fct_sales
WHERE delivery_status IS NOT NULL
GROUP BY customer_state
HAVING COUNT(*) > 500
ORDER BY late_pct DESC;
