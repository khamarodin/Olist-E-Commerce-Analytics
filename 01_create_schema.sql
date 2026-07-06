-- ============================================================
-- Olist E-Commerce Revenue Analysis
-- 01: Schema creation (PostgreSQL)
-- Raw layer: mirrors the Kaggle CSVs exactly. No transformation here.
-- ============================================================

CREATE SCHEMA IF NOT EXISTS raw;

-- Customers
CREATE TABLE raw.customers (
    customer_id                 TEXT PRIMARY KEY,
    customer_unique_id          TEXT,
    customer_zip_code_prefix    TEXT,
    customer_city               TEXT,
    customer_state              TEXT
);

-- Orders
CREATE TABLE raw.orders (
    order_id                        TEXT PRIMARY KEY,
    customer_id                     TEXT,
    order_status                    TEXT,
    order_purchase_timestamp        TIMESTAMP,
    order_approved_at               TIMESTAMP,
    order_delivered_carrier_date    TIMESTAMP,
    order_delivered_customer_date   TIMESTAMP,
    order_estimated_delivery_date   TIMESTAMP
);

-- Order items (one row per item within an order)
CREATE TABLE raw.order_items (
    order_id            TEXT,
    order_item_id       INT,
    product_id          TEXT,
    seller_id           TEXT,
    shipping_limit_date TIMESTAMP,
    price               NUMERIC(10,2),
    freight_value       NUMERIC(10,2),
    PRIMARY KEY (order_id, order_item_id)
);

-- Payments
CREATE TABLE raw.order_payments (
    order_id            TEXT,
    payment_sequential  INT,
    payment_type        TEXT,
    payment_installments INT,
    payment_value       NUMERIC(10,2)
);

-- Reviews (review_id is NOT unique in the raw file; no PK on purpose)
CREATE TABLE raw.order_reviews (
    review_id               TEXT,
    order_id                TEXT,
    review_score            INT,
    review_comment_title    TEXT,
    review_comment_message  TEXT,
    review_creation_date    TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

-- Products
CREATE TABLE raw.products (
    product_id                  TEXT PRIMARY KEY,
    product_category_name       TEXT,
    product_name_lenght         INT,   -- (sic) column is misspelled in the source data
    product_description_lenght  INT,   -- (sic)
    product_photos_qty          INT,
    product_weight_g            INT,
    product_length_cm           INT,
    product_height_cm           INT,
    product_width_cm            INT
);

-- Sellers
CREATE TABLE raw.sellers (
    seller_id               TEXT PRIMARY KEY,
    seller_zip_code_prefix  TEXT,
    seller_city             TEXT,
    seller_state            TEXT
);

-- Category name translation (Portuguese -> English)
CREATE TABLE raw.category_translation (
    product_category_name           TEXT PRIMARY KEY,
    product_category_name_english   TEXT
);

-- Geolocation (optional; only needed for map visuals beyond state level)
CREATE TABLE raw.geolocation (
    geolocation_zip_code_prefix TEXT,
    geolocation_lat             NUMERIC,
    geolocation_lng             NUMERIC,
    geolocation_city            TEXT,
    geolocation_state           TEXT
);
