-- BigQuery Standard SQL. Previous-year customers who also bought the next year.
-- Create mart_ecommerce_overview first; replace YOUR_PROJECT.YOUR_DATASET.
WITH customer_years AS (
  SELECT DISTINCT
    user_id,
    EXTRACT(YEAR FROM order_date) AS purchase_year
  FROM `YOUR_PROJECT.YOUR_DATASET.mart_ecommerce_overview`
  WHERE user_id IS NOT NULL
    AND order_status != 'Cancelled'
),
max_data_year AS (
  SELECT MAX(purchase_year) AS max_year
  FROM customer_years
),
repurchase_pairs AS (
  SELECT
    prev.purchase_year AS purchase_year,
    prev.purchase_year + 1 AS repurchase_year,
    prev.user_id,
    curr.user_id IS NOT NULL AS repurchased_next_year
  FROM customer_years AS prev
  LEFT JOIN customer_years AS curr
    ON prev.user_id = curr.user_id
    AND curr.purchase_year = prev.purchase_year + 1
)
SELECT
  purchase_year,
  repurchase_year,
  COUNT(*) AS previous_year_customers,
  COUNTIF(repurchased_next_year) AS repurchased_customers,
  SAFE_DIVIDE(COUNTIF(repurchased_next_year), COUNT(*)) AS annual_repurchase_rate,
  CASE
    WHEN SAFE_DIVIDE(COUNTIF(repurchased_next_year), COUNT(*)) < 0.40 THEN 'Acquisition-led'
    WHEN SAFE_DIVIDE(COUNTIF(repurchased_next_year), COUNT(*)) <= 0.60 THEN 'Hybrid'
    ELSE 'Loyalty-led'
  END AS ecommerce_mode,
  repurchase_year = max_year - 1 AS is_latest_complete_pair
FROM repurchase_pairs
CROSS JOIN max_data_year
GROUP BY purchase_year, repurchase_year, max_year
HAVING repurchase_year < max_year;
