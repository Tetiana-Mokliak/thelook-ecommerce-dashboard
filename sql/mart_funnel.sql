-- BigQuery Standard SQL. One row per reached funnel step per session.
-- Create mart_sessions first and replace YOUR_PROJECT.YOUR_DATASET below.
SELECT
  s.session_id,
  s.session_date,
  f.step_order,
  f.funnel_step
FROM `YOUR_PROJECT.YOUR_DATASET.mart_sessions` AS s
CROSS JOIN UNNEST([
  STRUCT(1 AS step_order, 'Product View' AS funnel_step, s.has_product AS reached),
  STRUCT(2 AS step_order, 'Add to Cart' AS funnel_step, s.has_cart AS reached),
  STRUCT(3 AS step_order, 'Purchase' AS funnel_step, s.has_purchase AS reached)
]) AS f
WHERE f.reached IS TRUE;
