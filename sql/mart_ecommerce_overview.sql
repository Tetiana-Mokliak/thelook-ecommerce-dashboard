-- BigQuery Standard SQL | Source: bigquery-public-data.thelook_ecommerce
-- Run as a query or prepend CREATE OR REPLACE VIEW `your_project.your_dataset.mart_ecommerce_overview` AS.

WITH orders_prepared AS (

    SELECT

        o.order_id,

        o.user_id AS order_user_id,

        o.status AS order_status,

        o.created_at AS order_created_at,

        o.shipped_at AS order_shipped_at,

        o.delivered_at AS order_delivered_at,

        o.returned_at AS order_returned_at,

        o.num_of_item AS declared_items_in_order,

        ROW_NUMBER() OVER (

            PARTITION BY o.user_id

            ORDER BY o.created_at, o.order_id

        ) AS customer_order_number,

        COUNT(*) OVER (

            PARTITION BY o.user_id

        ) AS customer_lifetime_orders

    FROM `bigquery-public-data.thelook_ecommerce.orders` AS o

),

order_item_counts AS (

    SELECT

        order_id,

        COUNT(*) AS actual_items_in_order

    FROM `bigquery-public-data.thelook_ecommerce.order_items`

    GROUP BY order_id

),

joined_data AS (

    SELECT

        -- =========================================================

        -- KEYS

        -- =========================================================

        oi.id AS order_item_id,

        oi.order_id,

        oi.user_id,

        oi.product_id,

        oi.inventory_item_id,

        -- Joined keys for referential-integrity checks

        op.order_id AS joined_order_id,

        op.order_user_id,

        u.id AS joined_user_id,

        p.id AS joined_product_id,

        ii.id AS joined_inventory_item_id,

        -- =========================================================

        -- STATUS

        -- =========================================================

        oi.status AS order_item_status,

        op.order_status,

        -- =========================================================

        -- CANONICAL ORDER TIMELINE

        -- =========================================================

        op.order_created_at,

        DATE(op.order_created_at) AS order_date,

        DATE_TRUNC(

            DATE(op.order_created_at),

            MONTH

        ) AS order_month,

        op.order_shipped_at,

        op.order_delivered_at,

        op.order_returned_at,

        -- =========================================================

        -- RAW ORDER-ITEM TIMESTAMPS

        -- Retained because order_items.created_at is unreliable

        -- =========================================================

        oi.created_at AS order_item_created_at,

        oi.shipped_at AS item_shipped_at,

        oi.delivered_at AS item_delivered_at,

        oi.returned_at AS item_returned_at,

        -- =========================================================

        -- ORDER SIZE

        -- =========================================================

        op.declared_items_in_order,

        oic.actual_items_in_order,

        -- =========================================================

        -- CUSTOMER

        -- =========================================================

        u.created_at AS user_created_at,

        u.age AS user_age,

        u.gender AS user_gender,

        u.country AS user_country,

        u.state AS user_state,

        u.city AS user_city,

        u.postal_code AS user_postal_code,

        u.latitude AS user_latitude,

        u.longitude AS user_longitude,

        u.traffic_source AS user_traffic_source,

        op.customer_order_number,

        op.customer_lifetime_orders,

        -- =========================================================

        -- PRODUCT

        -- =========================================================

        p.name AS product_name_raw,

        COALESCE(

            p.name,

            CONCAT(

                'Unnamed product #',

                CAST(oi.product_id AS STRING)

            )

        ) AS product_name,

        p.sku AS product_sku,

        p.category AS product_category,

        p.brand AS product_brand,

        p.department AS product_department,

        -- =========================================================

        -- PRICE AND COST

        -- =========================================================

        oi.sale_price,

        p.retail_price AS product_retail_price,

        ii.cost AS item_cost,

        p.cost AS product_standard_cost,

        -- =========================================================

        -- INVENTORY

        -- =========================================================

        ii.created_at AS inventory_created_at,

        ii.sold_at AS inventory_sold_at,

        -- =========================================================

        -- DISTRIBUTION CENTER

        -- =========================================================

        p.distribution_center_id,

        dc.name AS distribution_center_name,

        dc.latitude AS distribution_center_latitude,

        dc.longitude AS distribution_center_longitude

    FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi

    LEFT JOIN orders_prepared AS op

        ON oi.order_id = op.order_id

    LEFT JOIN order_item_counts AS oic

        ON oi.order_id = oic.order_id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.users` AS u

        ON oi.user_id = u.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.products` AS p

        ON oi.product_id = p.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.inventory_items` AS ii

        ON oi.inventory_item_id = ii.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.distribution_centers` AS dc

        ON p.distribution_center_id = dc.id

),

final_mart AS (

    SELECT

        -- =========================================================

        -- IDENTIFIERS

        -- =========================================================

        order_item_id,

        order_id,

        user_id,

        product_id,

        inventory_item_id,

        -- =========================================================

        -- CUSTOMER

        -- =========================================================

        user_created_at,

        user_age,

        user_gender,

        user_country,

        user_state,

        user_city,

        user_postal_code,

        user_latitude,

        user_longitude,

        user_traffic_source,

        customer_order_number,

        customer_lifetime_orders,

        customer_order_number = 1

            AS is_first_order,

        customer_order_number > 1

            AS is_repeat_order,

        -- =========================================================

        -- ORDER

        -- =========================================================

        order_status,

        order_item_status,

        order_created_at,

        order_date,

        order_month,

        order_shipped_at,

        order_delivered_at,

        order_returned_at,

        declared_items_in_order,

        actual_items_in_order,

        -- =========================================================

        -- STATUS FLAGS

        -- =========================================================

        order_item_status = 'Cancelled'

            AS is_cancelled,

        order_item_status = 'Processing'

            AS is_processing,

        order_item_status = 'Shipped'

            AS is_shipped,

        order_item_status = 'Complete'

            AS is_complete,

        order_item_status = 'Returned'

            AS is_returned,

        order_item_status NOT IN ('Cancelled', 'Returned')

            AS is_non_cancelled_non_returned,

        -- =========================================================

        -- PRODUCT

        -- =========================================================

        product_name_raw,

        product_name,

        product_sku,

        product_category,

        product_brand,

        product_department,

        -- =========================================================

        -- FINANCIAL FIELDS

        -- =========================================================

        sale_price,

        product_retail_price,

        item_cost,

        product_standard_cost,

        sale_price

            AS gross_revenue,

        sale_price - item_cost

            AS gross_profit,

        SAFE_DIVIDE(

            sale_price - item_cost,

            sale_price

        ) AS gross_margin_rate,

        CASE

            WHEN order_item_status IN ('Cancelled', 'Returned')

                THEN 0

            ELSE sale_price

        END AS net_revenue,

        CASE

            WHEN order_item_status IN ('Cancelled', 'Returned')

                THEN 0

            ELSE sale_price - item_cost

        END AS net_profit,

        -- =========================================================

        -- LOGISTICS

        -- Calculated from canonical order-level timestamps

        -- =========================================================

        TIMESTAMP_DIFF(

            order_shipped_at,

            order_created_at,

            HOUR

        ) AS hours_to_ship,

        TIMESTAMP_DIFF(

            order_delivered_at,

            order_shipped_at,

            HOUR

        ) AS hours_to_deliver,

        TIMESTAMP_DIFF(

            order_delivered_at,

            order_created_at,

            HOUR

        ) AS hours_order_to_delivery,

        TIMESTAMP_DIFF(

            order_returned_at,

            order_delivered_at,

            HOUR

        ) AS hours_delivery_to_return,

        -- =========================================================

        -- INVENTORY AND DISTRIBUTION

        -- =========================================================

        inventory_created_at,

        inventory_sold_at,

        distribution_center_id,

        distribution_center_name,

        distribution_center_latitude,

        distribution_center_longitude,

        -- =========================================================

        -- RAW ITEM TIMESTAMPS FOR AUDIT

        -- =========================================================

        order_item_created_at,

        item_shipped_at,

        item_delivered_at,

        item_returned_at,

        -- =========================================================

        -- DATA QUALITY: REFERENTIAL INTEGRITY

        -- =========================================================

        joined_order_id IS NULL

            AS is_missing_order,

        joined_user_id IS NULL

            AS is_missing_user,

        joined_product_id IS NULL

            AS is_missing_product,

        joined_inventory_item_id IS NULL

            AS is_missing_inventory_item,

        CASE

            WHEN joined_order_id IS NULL THEN FALSE

            ELSE user_id IS DISTINCT FROM order_user_id

        END AS has_user_id_mismatch,

        -- =========================================================

        -- DATA QUALITY: PRODUCT ATTRIBUTES

        -- =========================================================

        product_name_raw IS NULL

            AS is_product_name_missing,

        product_sku IS NULL

            AS is_product_sku_missing,

        -- =========================================================

        -- DATA QUALITY: STATUS AND ORDER SIZE

        -- =========================================================

        CASE

            WHEN joined_order_id IS NULL THEN FALSE

            ELSE order_status IS DISTINCT FROM order_item_status

        END AS has_status_mismatch,

        CASE

            WHEN joined_order_id IS NULL THEN FALSE

            ELSE declared_items_in_order

                 IS DISTINCT FROM actual_items_in_order

        END AS has_order_item_count_mismatch,

        -- =========================================================

        -- DATA QUALITY: PRICE

        -- =========================================================

        CASE

            WHEN sale_price IS NULL

                 OR product_retail_price IS NULL

                THEN TRUE

            ELSE ABS(

                sale_price - product_retail_price

            ) > 0.01

        END AS has_price_mismatch,

        -- =========================================================

        -- DATA QUALITY: COST

        -- =========================================================

        CASE

            WHEN item_cost IS NULL

                 OR product_standard_cost IS NULL

                THEN TRUE

            ELSE ABS(

                item_cost - product_standard_cost

            ) > 0.01

        END AS has_cost_mismatch,

        -- =========================================================

        -- DATA QUALITY: ORDER-ITEM CREATION TIME

        -- =========================================================

        order_item_created_at < order_created_at

            AS is_item_created_before_order,

        CASE

            WHEN order_shipped_at IS NULL THEN FALSE

            ELSE order_item_created_at > order_shipped_at

        END AS is_item_created_after_shipping,

        CASE

            WHEN order_item_created_at < order_created_at

                THEN TRUE

            WHEN order_shipped_at IS NOT NULL

                 AND order_item_created_at > order_shipped_at

                THEN TRUE

            ELSE FALSE

        END AS has_invalid_item_creation_time,

        -- =========================================================

        -- DATA QUALITY: CANONICAL ORDER TIMELINE

        -- =========================================================

        COALESCE(

            order_shipped_at < order_created_at,

            FALSE

        ) AS is_shipped_before_order_created,

        COALESCE(

            order_delivered_at < order_shipped_at,

            FALSE

        ) AS is_delivered_before_shipping,

        COALESCE(

            order_returned_at < order_delivered_at,

            FALSE

        ) AS is_returned_before_delivery,

        (

            COALESCE(

                order_shipped_at < order_created_at,

                FALSE

            )

            OR COALESCE(

                order_delivered_at < order_shipped_at,

                FALSE

            )

            OR COALESCE(

                order_returned_at < order_delivered_at,

                FALSE

            )

        ) AS has_invalid_order_date_sequence,

        -- =========================================================

        -- DATA QUALITY: STATUS-DATE CONSISTENCY

        -- Checks which dates should exist for every status

        -- =========================================================

        CASE

            WHEN order_item_status IN ('Cancelled', 'Processing')

                THEN

                    order_shipped_at IS NOT NULL

                    OR order_delivered_at IS NOT NULL

                    OR order_returned_at IS NOT NULL

            WHEN order_item_status = 'Shipped'

                THEN

                    order_shipped_at IS NULL

                    OR order_delivered_at IS NOT NULL

                    OR order_returned_at IS NOT NULL

            WHEN order_item_status = 'Complete'

                THEN

                    order_shipped_at IS NULL

                    OR order_delivered_at IS NULL

                    OR order_returned_at IS NOT NULL

            WHEN order_item_status = 'Returned'

                THEN

                    order_shipped_at IS NULL

                    OR order_delivered_at IS NULL

                    OR order_returned_at IS NULL

            ELSE TRUE

        END AS has_status_date_mismatch,

        -- =========================================================

        -- DATA QUALITY: FUTURE TIMESTAMPS

        -- =========================================================

        -- The order itself did not yet exist

        COALESCE(

            order_created_at > CURRENT_TIMESTAMP(),

            FALSE

        ) AS has_future_order_creation,

        -- Unreliable synthetic order-item creation timestamp

        COALESCE(

            order_item_created_at > CURRENT_TIMESTAMP(),

            FALSE

        ) AS has_future_item_creation,

        -- Status reflects a logistics event that has not happened yet

        (

            COALESCE(

                order_shipped_at > CURRENT_TIMESTAMP(),

                FALSE

            )

            OR COALESCE(

                order_delivered_at > CURRENT_TIMESTAMP(),

                FALSE

            )

            OR COALESCE(

                order_returned_at > CURRENT_TIMESTAMP(),

                FALSE

            )

        ) AS has_future_lifecycle_event,

        -- Inventory timestamps are checked separately

        (

            COALESCE(

                inventory_created_at > CURRENT_TIMESTAMP(),

                FALSE

            )

            OR COALESCE(

                inventory_sold_at > CURRENT_TIMESTAMP(),

                FALSE

            )

        ) AS has_future_inventory_timestamp,

        -- General future-date flag

        (

            COALESCE(

                order_created_at > CURRENT_TIMESTAMP(),

                FALSE

            )

            OR COALESCE(

                order_item_created_at > CURRENT_TIMESTAMP(),

                FALSE

            )

            OR COALESCE(

                order_shipped_at > CURRENT_TIMESTAMP(),

                FALSE

            )

            OR COALESCE(

                order_delivered_at > CURRENT_TIMESTAMP(),

                FALSE

            )

            OR COALESCE(

                order_returned_at > CURRENT_TIMESTAMP(),

                FALSE

            )

            OR COALESCE(

                inventory_created_at > CURRENT_TIMESTAMP(),

                FALSE

            )

            OR COALESCE(

                inventory_sold_at > CURRENT_TIMESTAMP(),

                FALSE

            )

        ) AS has_any_future_timestamp,

        -- Time at which dynamic quality checks were evaluated

        CURRENT_TIMESTAMP() AS quality_check_at

    FROM joined_data

)

SELECT *,

MAX(order_date) OVER () AS data_as_of

FROM final_mart
