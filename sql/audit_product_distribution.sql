-- BigQuery Standard SQL. Counts order-item rows by product_id, across all statuses.
-- Products with zero order items are absent from this distribution.
WITH items_per_product AS (
  SELECT
    product_id,
    COUNT(*) AS item_count
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  GROUP BY product_id
)
SELECT
  item_count,
  COUNT(*) AS product_count
FROM items_per_product
GROUP BY item_count
ORDER BY item_count;
