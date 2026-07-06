-- ============================================================
-- 03: Analytics layer
-- Clean, joined views that Power BI will connect to.
-- Business rules are documented inline — interviewers ask
-- about these choices, so keep the comments.
-- ============================================================

CREATE SCHEMA IF NOT EXISTS analytics;

-- ------------------------------------------------------------
-- KPI DEFINITIONS (document these — this is the "semantic layer")
--  Revenue        = SUM(order_items.price) for delivered orders.
--                   Freight is excluded (it's a pass-through cost,
--                   not merchandise revenue).
--  Order          = counted once, on order_purchase_timestamp.
--  Delivered only = order_status = 'delivered'. Canceled and
--                   unavailable orders are excluded from revenue.
-- ------------------------------------------------------------

CREATE OR REPLACE VIEW analytics.fct_order_items AS
SELECT
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    oi.price,
    oi.freight_value,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    DATE_TRUNC('month', o.order_purchase_timestamp)::date AS order_month,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    c.customer_state,
    c.customer_city,
    c.customer_unique_id,
    COALESCE(ct.product_category_name_english,
             p.product_category_name,
             'unknown')                                    AS category,
    -- Delivery performance (useful drill-down dimension)
    CASE
        WHEN o.order_delivered_customer_date IS NULL THEN NULL
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 'On time'
        ELSE 'Late'
    END AS delivery_status
FROM raw.order_items oi
JOIN raw.orders     o  ON o.order_id = oi.order_id
JOIN raw.customers  c  ON c.customer_id = o.customer_id
LEFT JOIN raw.products p ON p.product_id = oi.product_id
LEFT JOIN raw.category_translation ct
       ON ct.product_category_name = p.product_category_name;

-- Delivered-only convenience view (the default for revenue analysis)
CREATE OR REPLACE VIEW analytics.fct_sales AS
SELECT * FROM analytics.fct_order_items
WHERE order_status = 'delivered';
