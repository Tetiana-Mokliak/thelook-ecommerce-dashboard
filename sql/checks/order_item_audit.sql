-- BigQuery Standard SQL. Exploratory checks from the original analysis.
-- Run each statement separately; results and CURRENT_TIMESTAMP() depend on run date.

WITH order_items_base AS (

    SELECT

        -- Keys

        oi.id AS order_item_id,

        oi.order_id,

        oi.user_id,

        oi.product_id,

        oi.inventory_item_id,

        -- Order item

        oi.status AS order_item_status,

        oi.created_at AS order_item_created_at,

        oi.shipped_at AS item_shipped_at,

        oi.delivered_at AS item_delivered_at,

        oi.returned_at AS item_returned_at,

        oi.sale_price,

        -- Order

        o.status AS order_status,

        o.created_at AS order_created_at,

        o.shipped_at AS order_shipped_at,

        o.delivered_at AS order_delivered_at,

        o.returned_at AS order_returned_at,

        o.num_of_item AS items_in_order,

        -- User

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

        -- Product

        p.name AS product_name,

        p.sku AS product_sku,

        p.category AS product_category,

        p.brand AS product_brand,

        p.department AS product_department,

        p.retail_price AS product_retail_price,

        p.cost AS product_standard_cost,

        p.distribution_center_id,

        -- Particular inventory item

        ii.created_at AS inventory_created_at,

        ii.sold_at AS inventory_sold_at,

        ii.cost AS inventory_item_cost,

        -- Distribution center

        dc.name AS distribution_center_name,

        dc.latitude AS distribution_center_latitude,

        dc.longitude AS distribution_center_longitude

    FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.orders` AS o

        ON oi.order_id = o.order_id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.users` AS u

        ON oi.user_id = u.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.products` AS p

        ON oi.product_id = p.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.inventory_items` AS ii

        ON oi.inventory_item_id = ii.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.distribution_centers` AS dc

        ON p.distribution_center_id = dc.id

)

SELECT *

FROM order_items_base;

-- треба перевірити, чи не розмножили ми рядки

WITH mart AS (

    SELECT

        -- Keys

        oi.id AS order_item_id,

        oi.order_id,

        oi.user_id,

        oi.product_id,

        oi.inventory_item_id,

        -- Order item

        oi.status AS order_item_status,

        oi.created_at AS order_item_created_at,

        oi.shipped_at AS item_shipped_at,

        oi.delivered_at AS item_delivered_at,

        oi.returned_at AS item_returned_at,

        oi.sale_price,

        -- Order

        o.status AS order_status,

        o.created_at AS order_created_at,

        o.shipped_at AS order_shipped_at,

        o.delivered_at AS order_delivered_at,

        o.returned_at AS order_returned_at,

        o.num_of_item AS items_in_order,

        -- User

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

        -- Product

        p.name AS product_name,

        p.sku AS product_sku,

        p.category AS product_category,

        p.brand AS product_brand,

        p.department AS product_department,

        p.retail_price AS product_retail_price,

        p.cost AS product_standard_cost,

        p.distribution_center_id,

        -- Particular inventory item

        ii.created_at AS inventory_created_at,

        ii.sold_at AS inventory_sold_at,

        ii.cost AS inventory_item_cost,

        -- Distribution center

        dc.name AS distribution_center_name,

        dc.latitude AS distribution_center_latitude,

        dc.longitude AS distribution_center_longitude

    FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.orders` AS o

        ON oi.order_id = o.order_id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.users` AS u

        ON oi.user_id = u.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.products` AS p

        ON oi.product_id = p.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.inventory_items` AS ii

        ON oi.inventory_item_id = ii.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.distribution_centers` AS dc

        ON p.distribution_center_id = dc.id

)

SELECT

    COUNT(*) AS row_count,

    COUNT(DISTINCT order_item_id) AS distinct_order_items,

    COUNT(*) - COUNT(DISTINCT order_item_id) AS duplicated_rows,

    COUNTIF(order_id IS NULL) AS missing_orders,

    COUNTIF(user_id IS NULL) AS missing_users,

    COUNTIF(product_name IS NULL) AS missing_products,

    COUNTIF(inventory_item_cost IS NULL) AS missing_inventory_items

FROM mart;

-- шукаємо зниклі продукти

WITH mart AS (

    SELECT

        -- Keys

        oi.id AS order_item_id,

        oi.order_id,

        oi.user_id,

        oi.product_id,

        oi.inventory_item_id,

        -- Order item

        oi.status AS order_item_status,

        oi.created_at AS order_item_created_at,

        oi.shipped_at AS item_shipped_at,

        oi.delivered_at AS item_delivered_at,

        oi.returned_at AS item_returned_at,

        oi.sale_price,

        -- Order

        o.status AS order_status,

        o.created_at AS order_created_at,

        o.shipped_at AS order_shipped_at,

        o.delivered_at AS order_delivered_at,

        o.returned_at AS order_returned_at,

        o.num_of_item AS items_in_order,

        -- User

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

        -- Product

        p.name AS product_name_raw,

COALESCE(

    p.name,

    CONCAT('Unnamed product #', CAST(p.id AS STRING))

) AS product_name,

p.name IS NULL AS is_product_name_missing,

        p.sku AS product_sku,

        p.category AS product_category,

        p.brand AS product_brand,

        p.department AS product_department,

        p.retail_price AS product_retail_price,

        p.cost AS product_standard_cost,

        p.distribution_center_id,

        -- Particular inventory item

        ii.created_at AS inventory_created_at,

        ii.sold_at AS inventory_sold_at,

        ii.cost AS inventory_item_cost,

        -- Distribution center

        dc.name AS distribution_center_name,

        dc.latitude AS distribution_center_latitude,

        dc.longitude AS distribution_center_longitude

    FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.orders` AS o

        ON oi.order_id = o.order_id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.users` AS u

        ON oi.user_id = u.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.products` AS p

        ON oi.product_id = p.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.inventory_items` AS ii

        ON oi.inventory_item_id = ii.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.distribution_centers` AS dc

        ON p.distribution_center_id = dc.id

)

SELECT

    order_item_id,

    order_id,

    product_id,

    inventory_item_id,

    product_name,

    inventory_item_cost

FROM mart

WHERE product_name IS NULL

ORDER BY product_id;

-- перевіряємо статуси

WITH order_items_base AS (

    SELECT

        -- Keys

        oi.id AS order_item_id,

        oi.order_id,

        oi.user_id,

        oi.product_id,

        oi.inventory_item_id,

        -- Order item

        oi.status AS order_item_status,

        oi.created_at AS order_item_created_at,

        oi.shipped_at AS item_shipped_at,

        oi.delivered_at AS item_delivered_at,

        oi.returned_at AS item_returned_at,

        oi.sale_price,

        -- Order

        o.status AS order_status,

        o.created_at AS order_created_at,

        o.shipped_at AS order_shipped_at,

        o.delivered_at AS order_delivered_at,

        o.returned_at AS order_returned_at,

        o.num_of_item AS items_in_order,

        -- User

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

        -- Product

        p.name AS product_name_raw,

COALESCE(

    p.name,

    CONCAT('Unnamed product #', CAST(p.id AS STRING))

) AS product_name,

p.name IS NULL AS is_product_name_missing,

        p.sku AS product_sku,

        p.category AS product_category,

        p.brand AS product_brand,

        p.department AS product_department,

        p.retail_price AS product_retail_price,

        p.cost AS product_standard_cost,

        p.distribution_center_id,

        -- Particular inventory item

        ii.created_at AS inventory_created_at,

        ii.sold_at AS inventory_sold_at,

        ii.cost AS inventory_item_cost,

        -- Distribution center

        dc.name AS distribution_center_name,

        dc.latitude AS distribution_center_latitude,

        dc.longitude AS distribution_center_longitude

    FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.orders` AS o

        ON oi.order_id = o.order_id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.users` AS u

        ON oi.user_id = u.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.products` AS p

        ON oi.product_id = p.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.inventory_items` AS ii

        ON oi.inventory_item_id = ii.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.distribution_centers` AS dc

        ON p.distribution_center_id = dc.id

)

SELECT

    order_status,

    order_item_status,

    COUNT(*) AS order_items,

    COUNT(DISTINCT order_id) AS orders

FROM order_items_base

GROUP BY

    order_status,

    order_item_status

ORDER BY

    order_status,

    order_item_status;

-- порахуємо кількість розбіжностей

WITH order_items_base AS (

    SELECT

        -- Keys

        oi.id AS order_item_id,

        oi.order_id,

        oi.user_id,

        oi.product_id,

        oi.inventory_item_id,

        -- Order item

        oi.status AS order_item_status,

        oi.created_at AS order_item_created_at,

        oi.shipped_at AS item_shipped_at,

        oi.delivered_at AS item_delivered_at,

        oi.returned_at AS item_returned_at,

        oi.sale_price,

        -- Order

        o.status AS order_status,

        o.created_at AS order_created_at,

        o.shipped_at AS order_shipped_at,

        o.delivered_at AS order_delivered_at,

        o.returned_at AS order_returned_at,

        o.num_of_item AS items_in_order,

        -- User

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

        -- Product

        p.name AS product_name_raw,

COALESCE(

    p.name,

    CONCAT('Unnamed product #', CAST(p.id AS STRING))

) AS product_name,

p.name IS NULL AS is_product_name_missing,

        p.sku AS product_sku,

        p.category AS product_category,

        p.brand AS product_brand,

        p.department AS product_department,

        p.retail_price AS product_retail_price,

        p.cost AS product_standard_cost,

        p.distribution_center_id,

        -- Particular inventory item

        ii.created_at AS inventory_created_at,

        ii.sold_at AS inventory_sold_at,

        ii.cost AS inventory_item_cost,

        -- Distribution center

        dc.name AS distribution_center_name,

        dc.latitude AS distribution_center_latitude,

        dc.longitude AS distribution_center_longitude

    FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.orders` AS o

        ON oi.order_id = o.order_id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.users` AS u

        ON oi.user_id = u.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.products` AS p

        ON oi.product_id = p.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.inventory_items` AS ii

        ON oi.inventory_item_id = ii.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.distribution_centers` AS dc

        ON p.distribution_center_id = dc.id

)

SELECT

    COUNT(*) AS total_order_items,

    COUNTIF(order_status = order_item_status)

        AS matching_statuses,

    COUNTIF(order_status != order_item_status)

        AS different_statuses,

    COUNTIF(order_status IS NULL OR order_item_status IS NULL)

        AS missing_statuses

FROM order_items_base;

-- чи збігається собівартість конкретного інвентарного екземпляра із собівартістю в каталозі

WITH order_items_base AS (

    SELECT

        -- Keys

        oi.id AS order_item_id,

        oi.order_id,

        oi.user_id,

        oi.product_id,

        oi.inventory_item_id,

        -- Order item

        oi.status AS order_item_status,

        oi.created_at AS order_item_created_at,

        oi.shipped_at AS item_shipped_at,

        oi.delivered_at AS item_delivered_at,

        oi.returned_at AS item_returned_at,

        oi.sale_price,

        -- Order

        o.status AS order_status,

        o.created_at AS order_created_at,

        o.shipped_at AS order_shipped_at,

        o.delivered_at AS order_delivered_at,

        o.returned_at AS order_returned_at,

        o.num_of_item AS items_in_order,

        -- User

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

        -- Product

        p.name AS product_name_raw,

COALESCE(

    p.name,

    CONCAT('Unnamed product #', CAST(p.id AS STRING))

) AS product_name,

p.name IS NULL AS is_product_name_missing,

        p.sku AS product_sku,

        p.category AS product_category,

        p.brand AS product_brand,

        p.department AS product_department,

        p.retail_price AS product_retail_price,

        p.cost AS product_standard_cost,

        p.distribution_center_id,

        -- Particular inventory item

        ii.created_at AS inventory_created_at,

        ii.sold_at AS inventory_sold_at,

        ii.cost AS inventory_item_cost,

        -- Distribution center

        dc.name AS distribution_center_name,

        dc.latitude AS distribution_center_latitude,

        dc.longitude AS distribution_center_longitude

    FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.orders` AS o

        ON oi.order_id = o.order_id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.users` AS u

        ON oi.user_id = u.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.products` AS p

        ON oi.product_id = p.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.inventory_items` AS ii

        ON oi.inventory_item_id = ii.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.distribution_centers` AS dc

        ON p.distribution_center_id = dc.id

)

SELECT

    COUNT(*) AS total_order_items,

    COUNTIF(product_standard_cost = inventory_item_cost)

        AS matching_costs,

    COUNTIF(product_standard_cost != inventory_item_cost)

        AS different_costs,

    COUNTIF(

        product_standard_cost IS NULL

        OR inventory_item_cost IS NULL

    ) AS missing_costs,

    MAX(ABS(product_standard_cost - inventory_item_cost))

        AS max_absolute_difference

FROM order_items_base;

-- перевірка цін

WITH order_items_base AS (

    SELECT

        -- Keys

        oi.id AS order_item_id,

        oi.order_id,

        oi.user_id,

        oi.product_id,

        oi.inventory_item_id,

        -- Order item

        oi.status AS order_item_status,

        oi.created_at AS order_item_created_at,

        oi.shipped_at AS item_shipped_at,

        oi.delivered_at AS item_delivered_at,

        oi.returned_at AS item_returned_at,

        oi.sale_price,

        -- Order

        o.status AS order_status,

        o.created_at AS order_created_at,

        o.shipped_at AS order_shipped_at,

        o.delivered_at AS order_delivered_at,

        o.returned_at AS order_returned_at,

        o.num_of_item AS items_in_order,

        -- User

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

        -- Product

        p.name AS product_name_raw,

COALESCE(

    p.name,

    CONCAT('Unnamed product #', CAST(p.id AS STRING))

) AS product_name,

p.name IS NULL AS is_product_name_missing,

        p.sku AS product_sku,

        p.category AS product_category,

        p.brand AS product_brand,

        p.department AS product_department,

        p.retail_price AS product_retail_price,

        p.cost AS product_standard_cost,

        p.distribution_center_id,

        -- Particular inventory item

        ii.created_at AS inventory_created_at,

        ii.sold_at AS inventory_sold_at,

        ii.cost AS inventory_item_cost,

        -- Distribution center

        dc.name AS distribution_center_name,

        dc.latitude AS distribution_center_latitude,

        dc.longitude AS distribution_center_longitude

    FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.orders` AS o

        ON oi.order_id = o.order_id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.users` AS u

        ON oi.user_id = u.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.products` AS p

        ON oi.product_id = p.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.inventory_items` AS ii

        ON oi.inventory_item_id = ii.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.distribution_centers` AS dc

        ON p.distribution_center_id = dc.id

)

SELECT

    COUNT(*) AS total_order_items,

    COUNTIF(sale_price = product_retail_price)

        AS matching_prices,

    COUNTIF(sale_price < product_retail_price)

        AS discounted_items,

    COUNTIF(sale_price > product_retail_price)

        AS above_retail_items,

    COUNTIF(

        sale_price IS NULL

        OR product_retail_price IS NULL

    ) AS missing_prices,

    MIN(sale_price - product_retail_price)

        AS min_price_difference,

    MAX(sale_price - product_retail_price)

        AS max_price_difference

FROM order_items_base;

-- Перевіримо, чи дати йдуть у логічному порядку і як вони залежать від статусів

WITH order_items_base AS (

   SELECT

        -- Keys

        oi.id AS order_item_id,

        oi.order_id,

        oi.user_id,

        oi.product_id,

        oi.inventory_item_id,

        -- Order item

        oi.status AS order_item_status,

        oi.created_at AS order_item_created_at,

        oi.shipped_at AS item_shipped_at,

        oi.delivered_at AS item_delivered_at,

        oi.returned_at AS item_returned_at,

        oi.sale_price,

        -- Order

        o.status AS order_status,

        o.created_at AS order_created_at,

        o.shipped_at AS order_shipped_at,

        o.delivered_at AS order_delivered_at,

        o.returned_at AS order_returned_at,

        o.num_of_item AS items_in_order,

        -- User

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

        -- Product

        p.name AS product_name_raw,

COALESCE(

    p.name,

    CONCAT('Unnamed product #', CAST(p.id AS STRING))

) AS product_name,

p.name IS NULL AS is_product_name_missing,

        p.sku AS product_sku,

        p.category AS product_category,

        p.brand AS product_brand,

        p.department AS product_department,

        p.retail_price AS product_retail_price,

        p.cost AS product_standard_cost,

        p.distribution_center_id,

        -- Particular inventory item

        ii.created_at AS inventory_created_at,

        ii.sold_at AS inventory_sold_at,

        ii.cost AS inventory_item_cost,

        -- Distribution center

        dc.name AS distribution_center_name,

        dc.latitude AS distribution_center_latitude,

        dc.longitude AS distribution_center_longitude

    FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.orders` AS o

        ON oi.order_id = o.order_id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.users` AS u

        ON oi.user_id = u.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.products` AS p

        ON oi.product_id = p.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.inventory_items` AS ii

        ON oi.inventory_item_id = ii.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.distribution_centers` AS dc

        ON p.distribution_center_id = dc.id

)

SELECT

    order_item_status,

    COUNT(*) AS order_items,

    COUNTIF(item_shipped_at IS NOT NULL) AS has_shipped_at,

    COUNTIF(item_delivered_at IS NOT NULL) AS has_delivered_at,

    COUNTIF(item_returned_at IS NOT NULL) AS has_returned_at,

    COUNTIF(item_shipped_at < order_item_created_at)

        AS shipped_before_created,

    COUNTIF(item_delivered_at < item_shipped_at)

        AS delivered_before_shipped,

    COUNTIF(item_returned_at < item_delivered_at)

        AS returned_before_delivered

FROM order_items_base

GROUP BY order_item_status

ORDER BY order_item_status;

-- яку саме дату створення порушено: товарної позиції чи всього замовлення

WITH order_items_base AS (

   SELECT

        -- Keys

        oi.id AS order_item_id,

        oi.order_id,

        oi.user_id,

        oi.product_id,

        oi.inventory_item_id,

        -- Order item

        oi.status AS order_item_status,

        oi.created_at AS order_item_created_at,

        oi.shipped_at AS item_shipped_at,

        oi.delivered_at AS item_delivered_at,

        oi.returned_at AS item_returned_at,

        oi.sale_price,

        -- Order

        o.status AS order_status,

        o.created_at AS order_created_at,

        o.shipped_at AS order_shipped_at,

        o.delivered_at AS order_delivered_at,

        o.returned_at AS order_returned_at,

        o.num_of_item AS items_in_order,

        -- User

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

        -- Product

        p.name AS product_name_raw,

COALESCE(

    p.name,

    CONCAT('Unnamed product #', CAST(p.id AS STRING))

) AS product_name,

p.name IS NULL AS is_product_name_missing,

        p.sku AS product_sku,

        p.category AS product_category,

        p.brand AS product_brand,

        p.department AS product_department,

        p.retail_price AS product_retail_price,

        p.cost AS product_standard_cost,

        p.distribution_center_id,

        -- Particular inventory item

        ii.created_at AS inventory_created_at,

        ii.sold_at AS inventory_sold_at,

        ii.cost AS inventory_item_cost,

        -- Distribution center

        dc.name AS distribution_center_name,

        dc.latitude AS distribution_center_latitude,

        dc.longitude AS distribution_center_longitude

    FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.orders` AS o

        ON oi.order_id = o.order_id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.users` AS u

        ON oi.user_id = u.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.products` AS p

        ON oi.product_id = p.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.inventory_items` AS ii

        ON oi.inventory_item_id = ii.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.distribution_centers` AS dc

        ON p.distribution_center_id = dc.id

)

SELECT

    COUNTIF(item_shipped_at < order_item_created_at)

        AS shipped_before_item_created,

    COUNTIF(order_shipped_at < order_created_at)

        AS order_shipped_before_order_created,

    COUNTIF(order_item_created_at < order_created_at)

        AS item_created_before_order,

    COUNTIF(item_shipped_at != order_shipped_at)

        AS different_shipping_timestamps,

    MIN(

        TIMESTAMP_DIFF(

            item_shipped_at,

            order_item_created_at,

            HOUR

        )

    ) AS min_hours_from_item_creation_to_shipping,

    MAX(

        TIMESTAMP_DIFF(

            item_shipped_at,

            order_item_created_at,

            HOUR

        )

    ) AS max_hours_from_item_creation_to_shipping

FROM order_items_base;

-- Additional checks

WITH order_items_base AS (

    SELECT

        -- Keys

        oi.id AS order_item_id,

        oi.order_id,

        oi.user_id,

        oi.product_id,

        oi.inventory_item_id,

        -- Order item

        oi.status AS order_item_status,

        oi.created_at AS order_item_created_at,

        oi.shipped_at AS item_shipped_at,

        oi.delivered_at AS item_delivered_at,

        oi.returned_at AS item_returned_at,

        oi.sale_price,

        -- Order

        o.status AS order_status,

        o.created_at AS order_created_at,

        o.shipped_at AS order_shipped_at,

        o.delivered_at AS order_delivered_at,

        o.returned_at AS order_returned_at,

        o.num_of_item AS items_in_order,

        -- User

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

        -- Product

        p.name AS product_name_raw,

COALESCE(

    p.name,

    CONCAT('Unnamed product #', CAST(p.id AS STRING))

) AS product_name,

p.name IS NULL AS is_product_name_missing,

        p.sku AS product_sku,

        p.category AS product_category,

        p.brand AS product_brand,

        p.department AS product_department,

        p.retail_price AS product_retail_price,

        p.cost AS product_standard_cost,

        p.distribution_center_id,

        -- Particular inventory item

        ii.created_at AS inventory_created_at,

        ii.sold_at AS inventory_sold_at,

        ii.cost AS inventory_item_cost,

        -- Distribution center

        dc.name AS distribution_center_name,

        dc.latitude AS distribution_center_latitude,

        dc.longitude AS distribution_center_longitude

    FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.orders` AS o

        ON oi.order_id = o.order_id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.users` AS u

        ON oi.user_id = u.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.products` AS p

        ON oi.product_id = p.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.inventory_items` AS ii

        ON oi.inventory_item_id = ii.id

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.distribution_centers` AS dc

        ON p.distribution_center_id = dc.id

)

SELECT

    COUNTIF(order_shipped_at < order_created_at)

        AS shipped_before_order,

    COUNTIF(order_delivered_at < order_shipped_at)

        AS delivered_before_shipping,

    COUNTIF(order_returned_at < order_delivered_at)

        AS returned_before_delivery,

    MIN(TIMESTAMP_DIFF(order_shipped_at, order_created_at, HOUR))

        AS min_hours_to_ship,

    MAX(TIMESTAMP_DIFF(order_shipped_at, order_created_at, HOUR))

        AS max_hours_to_ship,

    MIN(TIMESTAMP_DIFF(order_delivered_at, order_shipped_at, HOUR))

        AS min_hours_to_deliver,

    MAX(TIMESTAMP_DIFF(order_delivered_at, order_shipped_at, HOUR))

        AS max_hours_to_deliver

FROM order_items_base;
