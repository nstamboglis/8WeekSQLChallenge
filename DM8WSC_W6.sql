-----------------------------------
-- Data with Danny - W6

-- 1. DB Schema

-- The lines below create a DB Schema on https://dbdiagram.io/d

// 8Weeks SQL Challenge - W6 - DB Schema
// Docs: https://dbml.dbdiagram.io/docs

Table clique_bait.event_identifier {
  event_type integer
  event_name varchar
}

Table clique_bait.campaign_identifier {
  campaign_id INTEGER
  products VARCHAR(3)
  campaign_name VARCHAR(33)
  start_date TIMESTAMP
  end_date TIMESTAMP
}

Table clique_bait.page_hierarchy {
  page_id INTEGER
  page_name VARCHAR(14)
  product_category VARCHAR(9)
  product_id INTEGER
}

Table clique_bait.users {
  user_id INTEGER
  cookie_id VARCHAR(6)
  start_date TIMESTAMP
}

Table clique_bait.events {
  visit_id VARCHAR(6)
  cookie_id VARCHAR(6)
  page_id INTEGER
  event_type INTEGER
  sequence_number INTEGER
  event_time TIMESTAMP
}

Ref: clique_bait.event_identifier.event_type - clique_bait.events.event_type // one-to-one

Ref: clique_bait.page_hierarchy.page_id - clique_bait.events.page_id // one-to-one

Ref: clique_bait.users.cookie_id - clique_bait.events.cookie_id // one-to-one

Ref: clique_bait.campaign_identifier.products > clique_bait.page_hierarchy.product_id // one-to-one

-- 2. Digital Analysis

-- 2.1 How many users are there?
SELECT
	COUNT(DISTINCT u.user_id)
FROM clique_bait.users u;

-- 2.2 How many cookies does each user have on average?
SELECT
	ROUND(COUNT(DISTINCT u.cookie_id)::numeric / COUNT(DISTINCT u.user_id)::numeric, 2)
FROM clique_bait.users u;

-- 2.3 What is the unique number of visits by all users per month?
SELECT
    TO_CHAR(e.event_time, 'YYYY-MM') as event_ym,
    COUNT(DISTINCT e.visit_id) as distinct_visits
FROM clique_bait.events e
GROUP BY TO_CHAR(e.event_time, 'YYYY-MM')
ORDER BY TO_CHAR(e.event_time, 'YYYY-MM') ASC;

-- 2.4 What is the number of events for each event type?
SELECT
    ei.event_name,
    COUNT(e.visit_id) as n_events
FROM clique_bait.events e
LEFT JOIN clique_bait.event_identifier ei ON (e.event_type = ei.event_type)
GROUP BY ei.event_name
ORDER BY COUNT(e.visit_id) DESC;

-- 2.5 What is the percentage of visits which have a purchase event?
WITH my_ds AS (
    SELECT
        *,
        CASE
            WHEN e.event_type = 3 THEN 'purchase'
            ELSE 'no purchase'
        END AS flag_purchase
    FROM
        clique_bait.events e
),
my_ds_flag AS (
    SELECT
        flag_purchase,
        COUNT(DISTINCT visit_id) AS n_visits_unique
    FROM
        my_ds
    GROUP BY
        flag_purchase
),
total_visits AS (
    SELECT
        SUM(n_visits_unique) AS total
    FROM
        my_ds_flag
)
SELECT
    mdf.flag_purchase,
    round(mdf.n_visits_unique::numeric / tv.total::numeric, 2) AS visit_percentage
FROM
    my_ds_flag AS mdf
CROSS JOIN
    total_visits AS tv;