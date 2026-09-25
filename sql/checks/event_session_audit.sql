-- BigQuery Standard SQL. Exploratory checks from the original analysis.
-- Run each statement separately; results and CURRENT_TIMESTAMP() depend on run date.

-- Загальна цілісність

SELECT

    COUNT(*) AS event_rows,

    COUNT(DISTINCT id) AS distinct_event_ids,

    COUNT(DISTINCT session_id) AS distinct_sessions,

    COUNT(DISTINCT user_id) AS distinct_users,

    COUNTIF(id IS NULL) AS missing_event_ids,

    COUNTIF(session_id IS NULL) AS missing_session_ids,

    COUNTIF(user_id IS NULL) AS missing_user_ids,

    COUNTIF(created_at IS NULL) AS missing_created_at,

    COUNTIF(event_type IS NULL) AS missing_event_types,

    COUNTIF(created_at > CURRENT_TIMESTAMP())

        AS future_events,

    MIN(created_at) AS earliest_event_at,

    MAX(created_at) AS latest_event_at

FROM `bigquery-public-data.thelook_ecommerce.events`;

-- Які події існують

SELECT

    event_type,

    COUNT(*) AS events,

    COUNT(DISTINCT session_id) AS sessions,

    COUNT(DISTINCT user_id) AS users

FROM `bigquery-public-data.thelook_ecommerce.events`

GROUP BY event_type

ORDER BY events DESC;

-- чи одна сесія не належить кільком користувачам і чи не змінюються всередині неї основні атрибути

WITH session_profile AS (

    SELECT

        session_id,

        COUNT(*) AS event_count,

        COUNT(DISTINCT user_id) AS users_in_session,

        COUNT(DISTINCT traffic_source) AS traffic_sources_in_session,

        COUNT(DISTINCT browser) AS browsers_in_session,

        COUNT(DISTINCT state) AS states_in_session,

        MIN(created_at) AS session_started_at,

        MAX(created_at) AS session_ended_at,

        MIN(sequence_number) AS min_sequence_number,

        MAX(sequence_number) AS max_sequence_number,

        COUNT(DISTINCT sequence_number) AS distinct_sequence_numbers

    FROM `bigquery-public-data.thelook_ecommerce.events`

    WHERE session_id IS NOT NULL

    GROUP BY session_id

)

SELECT

    COUNT(*) AS sessions,

    COUNTIF(users_in_session != 1)

        AS sessions_with_multiple_or_missing_users,

    COUNTIF(traffic_sources_in_session > 1)

        AS sessions_with_multiple_traffic_sources,

    COUNTIF(browsers_in_session > 1)

        AS sessions_with_multiple_browsers,

    COUNTIF(states_in_session > 1)

        AS sessions_with_multiple_states,

    COUNTIF(min_sequence_number != 1)

        AS sessions_not_starting_at_one,

    COUNTIF(

        distinct_sequence_numbers != event_count

    ) AS sessions_with_duplicate_sequence_numbers,

    COUNTIF(

        max_sequence_number != event_count

    ) AS sessions_with_sequence_gaps,

    COUNTIF(

        session_ended_at < session_started_at

    ) AS sessions_with_invalid_time_order

FROM session_profile;

-- Тому потрібно окремо відрізнити: повністю анонімні сесії; частково анонімні; повністю ідентифіковані; сесії з кількома різними відомими користувачами.

WITH session_profile AS (

    SELECT

        session_id,

        COUNT(*) AS event_count,

        COUNTIF(user_id IS NULL) AS events_without_user_id,

        COUNTIF(user_id IS NOT NULL) AS events_with_user_id,

        COUNT(DISTINCT user_id) AS distinct_known_users,

        COUNTIF(event_type = 'product') > 0 AS has_product,

        COUNTIF(event_type = 'department') > 0 AS has_department,

        COUNTIF(event_type = 'cart') > 0 AS has_cart,

        COUNTIF(event_type = 'purchase') > 0 AS has_purchase,

        COUNTIF(event_type = 'cancel') > 0 AS has_cancel,

        COUNTIF(event_type = 'home') > 0 AS has_home

    FROM `bigquery-public-data.thelook_ecommerce.events`

    GROUP BY session_id

),

classified_sessions AS (

    SELECT

        *,

        CASE

            WHEN events_with_user_id = 0

                THEN 'Fully anonymous'

            WHEN events_without_user_id > 0

                 AND events_with_user_id > 0

                THEN 'Partially identified'

            WHEN distinct_known_users > 1

                THEN 'Multiple known users'

            ELSE 'Fully identified'

        END AS identity_status

    FROM session_profile

)

SELECT

    identity_status,

    COUNT(*) AS sessions,

    COUNTIF(has_product) AS product_sessions,

    COUNTIF(has_department) AS department_sessions,

    COUNTIF(has_cart) AS cart_sessions,

    COUNTIF(has_purchase) AS purchase_sessions,

    COUNTIF(has_cancel) AS cancel_sessions,

    COUNTIF(has_home) AS home_sessions

FROM classified_sessions

GROUP BY identity_status

ORDER BY sessions DESC;

-- найчастіші маршрути

WITH session_paths AS (

    SELECT

        session_id,

        STRING_AGG(

            event_type,

            ' > '

            ORDER BY sequence_number

        ) AS event_path

    FROM `bigquery-public-data.thelook_ecommerce.events`

    GROUP BY session_id

)

SELECT

    event_path,

    COUNT(*) AS sessions

FROM session_paths

GROUP BY event_path

ORDER BY sessions DESC

LIMIT 20;

-- Чи події справді йдуть у часовому порядку

WITH ordered_events AS (

    SELECT

        session_id,

        sequence_number,

        event_type,

        created_at,

        LAG(created_at) OVER (

            PARTITION BY session_id

            ORDER BY sequence_number

        ) AS previous_event_at

    FROM `bigquery-public-data.thelook_ecommerce.events`

)

SELECT

    COUNT(*) AS events,

    COUNTIF(created_at < previous_event_at)

        AS events_out_of_time_order,

    COUNTIF(created_at = previous_event_at)

        AS events_with_same_timestamp,

    MIN(

        TIMESTAMP_DIFF(

            created_at,

            previous_event_at,

            SECOND

        )

    ) AS min_gap_seconds,

    MAX(

        TIMESTAMP_DIFF(

            created_at,

            previous_event_at,

            SECOND

        )

    ) AS max_gap_seconds

FROM ordered_events;

-- Тривалість за кожним із восьми маршрутів

WITH sessions AS (

    SELECT

        session_id,

        STRING_AGG(

            event_type,

            ' > '

            ORDER BY sequence_number

        ) AS event_path,

        COUNT(*) AS event_count,

        MIN(created_at) AS session_started_at,

        MAX(created_at) AS session_ended_at,

        TIMESTAMP_DIFF(

            MAX(created_at),

            MIN(created_at),

            SECOND

        ) AS session_duration_seconds,

        COUNTIF(created_at > CURRENT_TIMESTAMP()) > 0

            AS has_future_event

    FROM `bigquery-public-data.thelook_ecommerce.events`

    GROUP BY session_id

)

SELECT

    event_path,

    event_count,

    COUNT(*) AS sessions,

    COUNT(DISTINCT session_duration_seconds)

        AS distinct_durations,

    MIN(session_duration_seconds)

        AS min_duration_seconds,

    APPROX_QUANTILES(

        session_duration_seconds,

        100

    )[OFFSET(50)] AS median_duration_seconds,

    ROUND(

        AVG(session_duration_seconds),

        1

    ) AS avg_duration_seconds,

    APPROX_QUANTILES(

        session_duration_seconds,

        100

    )[OFFSET(95)] AS p95_duration_seconds,

    MAX(session_duration_seconds)

        AS max_duration_seconds,

    COUNTIF(has_future_event)

        AS sessions_with_future_events

FROM sessions

GROUP BY

    event_path,

    event_count

ORDER BY sessions DESC;

-- Проміжки між типами подій

WITH ordered_events AS (

    SELECT

        session_id,

        sequence_number,

        event_type,

        created_at,

        LAG(event_type) OVER (

            PARTITION BY session_id

            ORDER BY sequence_number

        ) AS previous_event_type,

        LAG(created_at) OVER (

            PARTITION BY session_id

            ORDER BY sequence_number

        ) AS previous_event_at

    FROM `bigquery-public-data.thelook_ecommerce.events`

),

event_transitions AS (

    SELECT

        session_id,

        previous_event_type,

        event_type,

        TIMESTAMP_DIFF(

            created_at,

            previous_event_at,

            SECOND

        ) AS gap_seconds

    FROM ordered_events

    WHERE previous_event_type IS NOT NULL

)

SELECT

    previous_event_type,

    event_type,

    COUNT(*) AS transitions,

    COUNT(DISTINCT gap_seconds)

        AS distinct_gap_values,

    MIN(gap_seconds) AS min_gap_seconds,

    APPROX_QUANTILES(

        gap_seconds,

        100

    )[OFFSET(50)] AS median_gap_seconds,

    ROUND(

        AVG(gap_seconds),

        1

    ) AS avg_gap_seconds,

    APPROX_QUANTILES(

        gap_seconds,

        100

    )[OFFSET(95)] AS p95_gap_seconds,

    MAX(gap_seconds) AS max_gap_seconds,

    COUNTIF(gap_seconds = 0)

        AS zero_gap_transitions,

    COUNTIF(gap_seconds < 0)

        AS negative_gap_transitions

FROM event_transitions

GROUP BY

    previous_event_type,

    event_type

ORDER BY transitions DESC;

-- Additional checks

WITH ordered_events AS (

    SELECT

        session_id,

        sequence_number,

        event_type,

        created_at,

        LAG(event_type) OVER (

            PARTITION BY session_id

            ORDER BY sequence_number

        ) AS previous_event_type,

        LAG(created_at) OVER (

            PARTITION BY session_id

            ORDER BY sequence_number

        ) AS previous_event_at

    FROM `bigquery-public-data.thelook_ecommerce.events`

),

purchase_gaps AS (

    SELECT

        TIMESTAMP_DIFF(

            created_at,

            previous_event_at,

            SECOND

        ) AS gap_seconds

    FROM ordered_events

    WHERE previous_event_type = 'cart'

      AND event_type = 'purchase'

)

SELECT

    DIV(gap_seconds, 86400) AS full_days,

    MIN(MOD(gap_seconds, 86400)) AS min_remaining_seconds,

    MAX(MOD(gap_seconds, 86400)) AS max_remaining_seconds,

    COUNT(DISTINCT MOD(gap_seconds, 86400))

        AS distinct_remaining_seconds,

    COUNT(*) AS transitions

FROM purchase_gaps

GROUP BY full_days

ORDER BY full_days;
