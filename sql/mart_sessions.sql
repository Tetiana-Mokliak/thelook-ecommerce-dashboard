-- BigQuery Standard SQL | Source: bigquery-public-data.thelook_ecommerce
-- Run as a query or prepend CREATE OR REPLACE VIEW `your_project.your_dataset.mart_sessions` AS.

WITH ordered_events AS (

    SELECT

        e.*,

        LAG(e.event_type) OVER (

            PARTITION BY e.session_id

            ORDER BY e.sequence_number

        ) AS previous_event_type,

        LAG(e.created_at) OVER (

            PARTITION BY e.session_id

            ORDER BY e.sequence_number

        ) AS previous_event_at

    FROM `bigquery-public-data.thelook_ecommerce.events` AS e

),

events_with_gaps AS (

    SELECT

        *,

        TIMESTAMP_DIFF(

            created_at,

            previous_event_at,

            SECOND

        ) AS gap_seconds

    FROM ordered_events

),

session_base AS (

    SELECT

        -- =========================================================

        -- SESSION KEY AND USER

        -- =========================================================

        session_id,

        MAX(user_id) AS user_id,

        COUNTIF(user_id IS NOT NULL)

            AS events_with_user_id,

        COUNTIF(user_id IS NULL)

            AS events_without_user_id,

        COUNT(DISTINCT user_id)

            AS distinct_known_users,

        -- =========================================================

        -- SESSION ATTRIBUTES

        -- Verified as constant within each session

        -- =========================================================

        MAX(traffic_source) AS session_traffic_source,

        MAX(browser) AS session_browser,

        MAX(state) AS session_state,

        MAX(city) AS session_city,

        -- =========================================================

        -- SESSION TIME

        -- =========================================================

        MIN(created_at) AS session_started_at,

        MAX(created_at) AS session_ended_at,

        DATE(MIN(created_at)) AS session_date,

        DATE_TRUNC(

            DATE(MIN(created_at)),

            MONTH

        ) AS session_month,

        TIMESTAMP_DIFF(

            MAX(created_at),

            MIN(created_at),

            SECOND

        ) AS session_duration_seconds,

        -- =========================================================

        -- EVENT COUNTS

        -- =========================================================

        COUNT(*) AS event_count,

        COUNT(DISTINCT event_type) AS distinct_event_types,

        COUNTIF(event_type = 'home')

            AS home_event_count,

        COUNTIF(event_type = 'department')

            AS department_event_count,

        COUNTIF(event_type = 'product')

            AS product_event_count,

        COUNTIF(event_type = 'cart')

            AS cart_event_count,

        COUNTIF(event_type = 'purchase')

            AS purchase_event_count,

        COUNTIF(event_type = 'cancel')

            AS cancel_event_count,

        -- =========================================================

        -- FUNNEL FLAGS

        -- =========================================================

        COUNTIF(event_type = 'home') > 0

            AS has_home,

        COUNTIF(event_type = 'department') > 0

            AS has_department,

        COUNTIF(event_type = 'product') > 0

            AS has_product,

        COUNTIF(event_type = 'cart') > 0

            AS has_cart,

        COUNTIF(event_type = 'purchase') > 0

            AS has_purchase,

        COUNTIF(event_type = 'cancel') > 0

            AS has_cancel,

        -- =========================================================

        -- FULL EVENT PATH

        -- =========================================================

        STRING_AGG(

            event_type,

            ' > '

            ORDER BY sequence_number

        ) AS event_path,

        -- =========================================================

        -- SEQUENCE QUALITY

        -- =========================================================

        MIN(sequence_number) AS min_sequence_number,

        MAX(sequence_number) AS max_sequence_number,

        COUNT(DISTINCT sequence_number)

            AS distinct_sequence_numbers,

        COUNTIF(

            previous_event_at IS NOT NULL

            AND created_at < previous_event_at

        ) AS out_of_order_event_count,

        COUNTIF(

            previous_event_at IS NOT NULL

            AND gap_seconds = 0

        ) AS zero_gap_count,

        COUNTIF(

            previous_event_at IS NOT NULL

            AND gap_seconds < 0

        ) AS negative_gap_count,

        -- =========================================================

        -- PURCHASE DELAY

        -- There is one purchase event per purchase session

        -- =========================================================

        MAX(

            CASE

                WHEN previous_event_type = 'cart'

                     AND event_type = 'purchase'

                    THEN gap_seconds

            END

        ) AS purchase_gap_seconds,

        -- =========================================================

        -- TIMING-RULE CHECKS

        -- =========================================================

        -- Anonymous transitions should use whole minutes

        COUNTIF(

            previous_event_at IS NOT NULL

            AND MOD(gap_seconds, 60) != 0

        ) AS gaps_not_in_whole_minutes,

        COUNTIF(

            previous_event_at IS NOT NULL

            AND (

                gap_seconds < 0

                OR gap_seconds > 1740

            )

        ) AS gaps_outside_anonymous_range,

        -- Identified navigation transitions should use 0–179 sec

        -- Final cart → purchase is checked separately

        COUNTIF(

            previous_event_at IS NOT NULL

            AND NOT (

                previous_event_type = 'cart'

                AND event_type = 'purchase'

            )

            AND (

                gap_seconds < 0

                OR gap_seconds > 179

            )

        ) AS navigation_gaps_outside_identified_range,

        -- =========================================================

        -- FUTURE EVENTS

        -- =========================================================

        COUNTIF(

            created_at > CURRENT_TIMESTAMP()

        ) AS future_event_count

    FROM events_with_gaps

    WHERE session_id IS NOT NULL

    GROUP BY session_id

),

sessions_with_users AS (

    SELECT

        sb.*,

        -- =========================================================

        -- IDENTITY CLASSIFICATION

        -- =========================================================

        CASE

            WHEN sb.events_with_user_id = 0

                THEN 'Fully anonymous'

            WHEN sb.events_without_user_id > 0

                 AND sb.events_with_user_id > 0

                THEN 'Partially identified'

            WHEN sb.distinct_known_users > 1

                THEN 'Multiple known users'

            ELSE 'Fully identified'

        END AS identity_status,

        -- =========================================================

        -- USER PROFILE

        -- Available only for identified purchase sessions

        -- =========================================================

        u.id AS joined_user_id,

        u.created_at AS user_created_at,

        u.age AS user_age,

        u.gender AS user_gender,

        u.country AS user_country,

        u.state AS user_state,

        u.city AS user_city,

        u.postal_code AS user_postal_code,

        u.latitude AS user_latitude,

        u.longitude AS user_longitude,

        u.traffic_source AS user_traffic_source

    FROM session_base AS sb

    LEFT JOIN `bigquery-public-data.thelook_ecommerce.users` AS u

        ON sb.user_id = u.id

),

classified_sessions AS (

    SELECT

        *,

        -- =========================================================

        -- PATH CLASSIFICATION

        -- =========================================================

        CASE

            WHEN event_path = 'product'

                THEN 'Anonymous: product only'

            WHEN event_path = 'department > product'

                THEN 'Anonymous: category and product'

            WHEN event_path = 'department > product > cart'

                THEN 'Anonymous: cart abandoned'

            WHEN event_path = 'product > cart > cancel'

                THEN 'Anonymous: cart cancelled'

            WHEN has_purchase AND has_home

                THEN 'Purchase: direct journey'

            WHEN has_purchase

                THEN CONCAT(

                    'Purchase: ',

                    CAST(

                        DIV(event_count - 1, 3)

                        AS STRING

                    ),

                    ' browsing cycles'

                )

            ELSE 'Other path'

        END AS path_type,

        -- =========================================================

        -- IDENTIFIED-SESSION NUMBER

        -- Anonymous sessions cannot be linked across visits

        -- =========================================================

        CASE

            WHEN user_id IS NULL THEN NULL

            ELSE ROW_NUMBER() OVER (

                PARTITION BY user_id

                ORDER BY session_started_at, session_id

            )

        END AS identified_session_number,

        CASE

            WHEN user_id IS NULL THEN NULL

            ELSE COUNT(*) OVER (

                PARTITION BY user_id

            )

        END AS identified_user_session_count

    FROM sessions_with_users

),

final_mart AS (

    SELECT

        -- =========================================================

        -- SESSION

        -- =========================================================

        session_id,

        user_id,

        session_started_at,

        session_ended_at,

        session_date,

        session_month,

        session_duration_seconds,

        SAFE_DIVIDE(

            session_duration_seconds,

            60.0

        ) AS session_duration_minutes,

        session_traffic_source,

        session_browser,

        session_state,

        session_city,

        -- =========================================================

        -- USER

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

        identity_status,

        identified_session_number,

        identified_user_session_count,

        identified_session_number = 1

            AS is_first_identified_session,

        identified_session_number > 1

            AS is_repeat_identified_session,

        -- =========================================================

        -- EVENT COUNTS

        -- =========================================================

        event_count,

        distinct_event_types,

        home_event_count,

        department_event_count,

        product_event_count,

        cart_event_count,

        purchase_event_count,

        cancel_event_count,

        -- =========================================================

        -- FUNNEL

        -- =========================================================

        has_home,

        has_department,

        has_product,

        has_cart,

        has_purchase,

        has_cancel,

        -- =========================================================

        -- PATH

        -- =========================================================

        event_path,

        path_type,

        COUNT(*) OVER (

            PARTITION BY event_path

        ) AS sessions_with_same_path,

        -- =========================================================

        -- PURCHASE DELAY

        -- =========================================================

        purchase_gap_seconds,

        CASE

            WHEN purchase_gap_seconds IS NULL THEN NULL

            ELSE DIV(purchase_gap_seconds, 86400)

        END AS purchase_delay_full_days,

        CASE

            WHEN purchase_gap_seconds IS NULL THEN NULL

            ELSE MOD(purchase_gap_seconds, 86400)

        END AS purchase_delay_remaining_seconds,

        -- =========================================================

        -- DATA QUALITY: USER IDENTIFICATION

        -- =========================================================

        events_with_user_id,

        events_without_user_id,

        distinct_known_users,

        distinct_known_users > 1

            AS has_multiple_known_users,

        (

            events_with_user_id > 0

            AND events_without_user_id > 0

        ) AS has_mixed_user_identification,

        (

            user_id IS NULL

            AND joined_user_id IS NULL

        ) AS is_anonymous_session,

        (

            user_id IS NOT NULL

            AND joined_user_id IS NULL

        ) AS is_missing_user_record,

        -- Found generation rule:

        -- identified if and only if the session has purchase

        (

            (user_id IS NOT NULL AND has_purchase)

            OR

            (user_id IS NULL AND NOT has_purchase)

        ) AS matches_identity_purchase_rule,

        -- Session and user acquisition sources are conceptually

        -- different, so this is descriptive rather than an error

        CASE

            WHEN user_id IS NULL THEN NULL

            ELSE session_traffic_source = user_traffic_source

        END AS does_session_source_match_user_source,

        CASE

            WHEN user_id IS NULL THEN NULL

            ELSE session_state = user_state

        END AS does_session_state_match_user_state,

        -- =========================================================

        -- DATA QUALITY: EVENT SEQUENCE

        -- =========================================================

        min_sequence_number != 1

            AS does_not_start_at_sequence_one,

        distinct_sequence_numbers != event_count

            AS has_duplicate_sequence_numbers,

        max_sequence_number != event_count

            AS has_sequence_gaps,

        out_of_order_event_count > 0

            AS has_events_out_of_time_order,

        negative_gap_count > 0

            AS has_negative_gap,

        zero_gap_count > 0

            AS has_zero_gap,

        zero_gap_count,

        negative_gap_count,

        out_of_order_event_count,

        -- =========================================================

        -- SYNTHETIC TIMING RULES

        -- =========================================================

        CASE

            WHEN identity_status != 'Fully anonymous'

                THEN NULL

            WHEN event_count = 1

                THEN NULL

            ELSE

                gaps_not_in_whole_minutes = 0

                AND gaps_outside_anonymous_range = 0

        END AS matches_anonymous_minute_rule,

        CASE

            WHEN identity_status != 'Fully identified'

                THEN NULL

            ELSE

                navigation_gaps_outside_identified_range = 0

        END AS matches_identified_navigation_rule,

        CASE

            WHEN NOT has_purchase

                THEN NULL

            ELSE

                purchase_gap_seconds BETWEEN 0 AND 345779

                AND MOD(purchase_gap_seconds, 86400)

                    BETWEEN 0 AND 179

        END AS matches_purchase_delay_rule,

        gaps_not_in_whole_minutes,

        gaps_outside_anonymous_range,

        navigation_gaps_outside_identified_range,

        -- =========================================================

        -- DATA QUALITY: FUTURE EVENTS

        -- =========================================================

        future_event_count,

        future_event_count > 0

            AS has_future_event,

        CURRENT_TIMESTAMP() AS quality_check_at

    FROM classified_sessions

)

SELECT *

FROM final_mart
