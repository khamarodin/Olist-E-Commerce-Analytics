-- ============================================================
-- 02: Load Kaggle CSVs into raw tables
-- Run from psql. Adjust the path to wherever you unzipped the
-- Kaggle download ("Brazilian E-Commerce Public Dataset by Olist").
--
--   psql -d olist -f sql/02_load_data.sql
--
-- \copy runs client-side, so it works without superuser rights.
-- ============================================================

\copy raw.customers            FROM 'data/olist_customers_dataset.csv'                 WITH (FORMAT csv, HEADER true);
\copy raw.orders               FROM 'data/olist_orders_dataset.csv'                    WITH (FORMAT csv, HEADER true);
\copy raw.order_items          FROM 'data/olist_order_items_dataset.csv'               WITH (FORMAT csv, HEADER true);
\copy raw.order_payments       FROM 'data/olist_order_payments_dataset.csv'            WITH (FORMAT csv, HEADER true);
\copy raw.order_reviews        FROM 'data/olist_order_reviews_dataset.csv'             WITH (FORMAT csv, HEADER true);
\copy raw.products             FROM 'data/olist_products_dataset.csv'                  WITH (FORMAT csv, HEADER true);
\copy raw.sellers              FROM 'data/olist_sellers_dataset.csv'                   WITH (FORMAT csv, HEADER true);
\copy raw.category_translation FROM 'data/product_category_name_translation.csv'       WITH (FORMAT csv, HEADER true);
\copy raw.geolocation          FROM 'data/olist_geolocation_dataset.csv'               WITH (FORMAT csv, HEADER true);

-- ---- Sanity checks (expected approximate row counts) ----
-- customers        ~99,441
-- orders           ~99,441
-- order_items      ~112,650
-- order_payments   ~103,886
-- order_reviews    ~99,224  (100k rows incl. duplicates in some versions)
-- products         ~32,951
-- sellers          ~3,095

SELECT 'customers' AS tbl,       COUNT(*) FROM raw.customers
UNION ALL SELECT 'orders',        COUNT(*) FROM raw.orders
UNION ALL SELECT 'order_items',   COUNT(*) FROM raw.order_items
UNION ALL SELECT 'order_payments',COUNT(*) FROM raw.order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM raw.order_reviews
UNION ALL SELECT 'products',      COUNT(*) FROM raw.products
UNION ALL SELECT 'sellers',       COUNT(*) FROM raw.sellers;
