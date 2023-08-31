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

-- 2.6 What is the percentage of visits which view the checkout page but do not have a purchase event?

WITH my_ds AS (
    SELECT
        e.*,
        ph.page_name AS hierarchy_page_name,
  		ei.event_name as event_identifier_event_name
    FROM
        clique_bait.events e
    LEFT JOIN
        clique_bait.page_hierarchy ph ON e.page_id = ph.page_id
    LEFT JOIN
        clique_bait.event_identifier ei ON e.event_type = ei.event_type
    -- LIMIT 10000
),
my_ds_checkout AS (
    SELECT DISTINCT
        visit_id
    FROM
        my_ds
    WHERE
        hierarchy_page_name = 'Checkout'
),
my_ds_purchase AS (
    SELECT DISTINCT
        visit_id
    FROM
        my_ds
    WHERE
        event_identifier_event_name = 'Purchase'
),
my_ds_joins AS (
    SELECT
        my_ds.*,
        CASE
            WHEN my_ds.visit_id IN (SELECT visit_id FROM my_ds_checkout) THEN 1
            ELSE 0
        END AS flag_checkout,
        CASE
            WHEN my_ds.visit_id IN (SELECT visit_id FROM my_ds_purchase) THEN 1
            ELSE 0
        END AS flag_purchase
  	FROM
        my_ds
    LEFT JOIN
        my_ds_checkout ON my_ds.visit_id = my_ds_checkout.visit_id
  	LEFT JOIN
        my_ds_purchase ON my_ds.visit_id = my_ds_purchase.visit_id
), my_ds_analysis as(
SELECT
    distinct my_ds_joins.visit_id, my_ds_joins.flag_purchase
FROM
    my_ds_joins
WHERE my_ds_joins.flag_checkout = 1
), my_ds_report AS (
SELECT
	my_ds_analysis.flag_purchase,
    COUNT(DISTINCT my_ds_analysis.visit_id) as n_visits
FROM my_ds_analysis
GROUP BY my_ds_analysis.flag_purchase)
SELECT
	my_ds_report.flag_purchase,
    round(my_ds_report.n_visits::numeric / (SELECT sum(my_ds_report.n_visits) FROM my_ds_report)::numeric, 2) * 100 as perc_visits
FROM my_ds_report;

-- 2.7 What are the top 3 pages by number of views?
WITH my_ds AS (
    select 
        e.*,
        ph.page_name AS hierarchy_page_name,
  		ei.event_name as event_identifier_event_name
    FROM
        clique_bait.events e
    LEFT JOIN
       clique_bait.page_hierarchy ph ON e.page_id = ph.page_id
    left JOIN
        clique_bait.event_identifier ei ON e.event_type = ei.event_type
)
select 
	my_ds.hierarchy_page_name,
	count(my_ds.visit_id) as n_views
from my_ds
where my_ds.event_identifier_event_name = 'Page View'
group by my_ds.hierarchy_page_name
order by count(my_ds.visit_id) desc;

-- 2.8 What is the number of views and cart adds for each product category?
WITH my_ds AS (
    select 
        e.*,
        ph.page_name AS hierarchy_page_name,
  		ei.event_name as event_identifier_event_name
    FROM
        clique_bait.events e
    LEFT JOIN
       clique_bait.page_hierarchy ph ON e.page_id = ph.page_id
    left JOIN
        clique_bait.event_identifier ei ON e.event_type = ei.event_type
)
select 
	my_ds.hierarchy_page_name,
	my_ds.event_identifier_event_name,
	count(visit_id) as n_visits
from my_ds
where my_ds.hierarchy_page_name not in ('Checkout', 'Home Page', 'Confirmation') and my_ds.event_identifier_event_name in ('Page View', 'Add to Cart')
group by my_ds.hierarchy_page_name, my_ds.event_identifier_event_name
order by count(visit_id) desc;

-- 2.9 What are the top 3 products by purchases?
WITH my_ds AS (
    select 
        e.*,
        ph.page_name AS hierarchy_page_name,
  		ei.event_name as event_identifier_event_name
    FROM
        clique_bait.events e
    LEFT JOIN
       clique_bait.page_hierarchy ph ON e.page_id = ph.page_id
    left JOIN
        clique_bait.event_identifier ei ON e.event_type = ei.event_type
), purchase_visits as (
	select 
		distinct my_ds.visit_id
	from my_ds
	where my_ds.event_identifier_event_name = 'Purchase'
)
select 
	my_ds.hierarchy_page_name,
--	my_ds.event_identifier_event_name,
	count(visit_id) as n_visits
from my_ds
where my_ds.visit_id in (select purchase_visits.visit_id from purchase_visits)
 and my_ds.hierarchy_page_name not in ('Checkout', 'Home Page', 'Confirmation') and my_ds.event_identifier_event_name = 'Add to Cart'
group by my_ds.hierarchy_page_name, my_ds.event_identifier_event_name
order by count(visit_id) desc;

-- 3. Product funnel analysis
-- Create single table to verify: product views, product add to chart, product added but abandoned, product purchased

WITH my_ds AS (
    select 
        e.*,
        ph.page_name AS hierarchy_page_name,
  		ei.event_name as event_identifier_event_name
    FROM
        clique_bait.events e
    LEFT JOIN
       clique_bait.page_hierarchy ph ON e.page_id = ph.page_id
    left JOIN
        clique_bait.event_identifier ei ON e.event_type = ei.event_type
), purchase_visits as (
	select 
		distinct my_ds.visit_id
	from my_ds
	where my_ds.event_identifier_event_name = 'Purchase'
), my_ds_analysis as (
	select  
		my_ds.visit_id,
		my_ds.hierarchy_page_name,
		my_ds.event_identifier_event_name,
		case 
			when my_ds.event_identifier_event_name = 'Page View' then 1
			else 0
		end flag_view,
		case 
			when my_ds.event_identifier_event_name = 'Add to Cart' then 1
			else 0
		end flag_add,
		case 
			when my_ds.event_identifier_event_name = 'Add to Cart' and (my_ds.visit_id not in (select purchase_visits.visit_id from purchase_visits)) then 1
			else 0
		end flag_add_abandoned,
		case 
			when my_ds.event_identifier_event_name = 'Add to Cart' and (my_ds.visit_id in (select purchase_visits.visit_id from purchase_visits)) then 1
			else 0
		end flag_add_purchased
	from my_ds
)
select 
	my_ds_analysis.hierarchy_page_name,
	sum(my_ds_analysis.flag_view) as n_views,
	sum(my_ds_analysis.flag_add) as n_adds,
	sum(my_ds_analysis.flag_add_abandoned) as n_abandons,
	sum(my_ds_analysis.flag_add_purchased) as n_purchases
from my_ds_analysis
where my_ds_analysis.hierarchy_page_name not in ('Home Page', 'All Products', 'Confirmation', 'Checkout')
group by my_ds_analysis.hierarchy_page_name
order by my_ds_analysis.hierarchy_page_name;

-- 3.B Same as above but by product category

WITH my_ds AS (
    select 
        e.*,
        ph.product_category AS hierarchy_product_category,
  		ei.event_name as event_identifier_event_name
    FROM
        clique_bait.events e
    LEFT JOIN
       clique_bait.page_hierarchy ph ON e.page_id = ph.page_id
    left JOIN
        clique_bait.event_identifier ei ON e.event_type = ei.event_type
), purchase_visits as (
	select 
		distinct my_ds.visit_id
	from my_ds
	where my_ds.event_identifier_event_name = 'Purchase'
), my_ds_analysis as (
	select  
		my_ds.visit_id,
		my_ds.hierarchy_product_category,
		my_ds.event_identifier_event_name,
		case 
			when my_ds.event_identifier_event_name = 'Page View' then 1
			else 0
		end flag_view,
		case 
			when my_ds.event_identifier_event_name = 'Add to Cart' then 1
			else 0
		end flag_add,
		case 
			when my_ds.event_identifier_event_name = 'Add to Cart' and (my_ds.visit_id not in (select purchase_visits.visit_id from purchase_visits)) then 1
			else 0
		end flag_add_abandoned,
		case 
			when my_ds.event_identifier_event_name = 'Add to Cart' and (my_ds.visit_id in (select purchase_visits.visit_id from purchase_visits)) then 1
			else 0
		end flag_add_purchased
	from my_ds
)
select 
	my_ds_analysis.hierarchy_product_category,
	sum(my_ds_analysis.flag_view) as n_views,
	sum(my_ds_analysis.flag_add) as n_adds,
	sum(my_ds_analysis.flag_add_abandoned) as n_abandons,
	sum(my_ds_analysis.flag_add_purchased) as n_purchases
from my_ds_analysis
where my_ds_analysis.hierarchy_product_category is not null
group by my_ds_analysis.hierarchy_product_category
order by my_ds_analysis.hierarchy_product_category;

-- 3.C 

-- First I create query for an analytical table
WITH my_ds AS (
    select 
        e.*,
        ph.page_name AS hierarchy_page_name,
  		ei.event_name as event_identifier_event_name
    FROM
        clique_bait.events e
    LEFT JOIN
       clique_bait.page_hierarchy ph ON e.page_id = ph.page_id
    left JOIN
        clique_bait.event_identifier ei ON e.event_type = ei.event_type
), purchase_visits as (
	select 
		distinct my_ds.visit_id
	from my_ds
	where my_ds.event_identifier_event_name = 'Purchase'
), my_ds_analysis as (
	select  
		my_ds.visit_id,
		my_ds.hierarchy_page_name,
		my_ds.event_identifier_event_name,
		case 
			when my_ds.event_identifier_event_name = 'Page View' then 1
			else 0
		end flag_view,
		case 
			when my_ds.event_identifier_event_name = 'Add to Cart' then 1
			else 0
		end flag_add,
		case 
			when my_ds.event_identifier_event_name = 'Add to Cart' and (my_ds.visit_id not in (select purchase_visits.visit_id from purchase_visits)) then 1
			else 0
		end flag_add_abandoned,
		case 
			when my_ds.event_identifier_event_name = 'Add to Cart' and (my_ds.visit_id in (select purchase_visits.visit_id from purchase_visits)) then 1
			else 0
		end flag_add_purchased
	from my_ds
), my_ds_report as(
	select 
		my_ds_analysis.hierarchy_page_name,
		sum(my_ds_analysis.flag_view) as n_views,
		sum(my_ds_analysis.flag_add) as n_adds,
		sum(my_ds_analysis.flag_add_abandoned) as n_abandons,
		sum(my_ds_analysis.flag_add_purchased) as n_purchases
	from my_ds_analysis
	where my_ds_analysis.hierarchy_page_name not in ('Home Page', 'All Products', 'Confirmation', 'Checkout')
	group by my_ds_analysis.hierarchy_page_name
	order by my_ds_analysis.hierarchy_page_name)
select *
from my_ds_report
order by my_ds_report.n_views desc;

-- Then I create a temp table with the results of the query
CREATE TEMPORARY TABLE product_results as (
WITH my_ds AS (
    select 
        e.*,
        ph.page_name AS hierarchy_page_name,
  		ei.event_name as event_identifier_event_name
    FROM
        clique_bait.events e
    LEFT JOIN
       clique_bait.page_hierarchy ph ON e.page_id = ph.page_id
    left JOIN
        clique_bait.event_identifier ei ON e.event_type = ei.event_type
), purchase_visits as (
	select 
		distinct my_ds.visit_id
	from my_ds
	where my_ds.event_identifier_event_name = 'Purchase'
), my_ds_analysis as (
	select  
		my_ds.visit_id,
		my_ds.hierarchy_page_name,
		my_ds.event_identifier_event_name,
		case 
			when my_ds.event_identifier_event_name = 'Page View' then 1
			else 0
		end flag_view,
		case 
			when my_ds.event_identifier_event_name = 'Add to Cart' then 1
			else 0
		end flag_add,
		case 
			when my_ds.event_identifier_event_name = 'Add to Cart' and (my_ds.visit_id not in (select purchase_visits.visit_id from purchase_visits)) then 1
			else 0
		end flag_add_abandoned,
		case 
			when my_ds.event_identifier_event_name = 'Add to Cart' and (my_ds.visit_id in (select purchase_visits.visit_id from purchase_visits)) then 1
			else 0
		end flag_add_purchased
	from my_ds
), my_ds_report as(
	select 
		my_ds_analysis.hierarchy_page_name,
		sum(my_ds_analysis.flag_view) as n_views,
		sum(my_ds_analysis.flag_add) as n_adds,
		sum(my_ds_analysis.flag_add_abandoned) as n_abandons,
		sum(my_ds_analysis.flag_add_purchased) as n_purchases
	from my_ds_analysis
	where my_ds_analysis.hierarchy_page_name not in ('Home Page', 'All Products', 'Confirmation', 'Checkout')
	group by my_ds_analysis.hierarchy_page_name
	order by my_ds_analysis.hierarchy_page_name)
select *
from my_ds_report);

select *
from product_results;

-- Then I compute the results from the analysis table

-- Which product had the most views, cart adds and purchases?
select *
from product_results
order by product_results.n_views desc;

-- Which product was most likely to be abandoned?

select
	product_results.hierarchy_page_name,
	round(product_results.n_abandons::numeric / product_results.n_adds::numeric * 100, 2) as abandon_rate
from product_results
order by round(product_results.n_abandons::numeric / product_results.n_adds::numeric * 100, 2) desc;

-- Which product had the highest view to purchase percentage?
select 
	product_results.hierarchy_page_name,
	round(product_results.n_purchases::numeric / product_results.n_views::numeric * 100, 2) as purchase_to_view_rate
from product_results
order by round(product_results.n_purchases::numeric / product_results.n_views::numeric * 100, 2) desc;

-- What is the average conversion rate from view to cart add?
select 
	product_results.hierarchy_page_name,
	round(product_results.n_adds::numeric / product_results.n_views::numeric * 100, 2) as add_to_view_rate
from product_results
order by round(product_results.n_adds::numeric / product_results.n_views::numeric * 100, 2) desc;

-- What is the average conversion rate from cart add to purchase?
select 
	product_results.hierarchy_page_name,
	round(product_results.n_purchases::numeric / product_results.n_adds::numeric * 100, 2) as add_to_purcase_rate
from product_results
order by round(product_results.n_purchases::numeric / product_results.n_adds::numeric * 100, 2) desc;

-- 4. Campaigns Analysis

-- user_id
-- visit_id
-- visit_start_time: the earliest event_time for each visit
-- page_views: count of page views for each visit
-- cart_adds: count of product cart add events for each visit
-- purchase: 1/0 flag if a purchase event exists for each visit
-- campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
-- impression: count of ad impressions for each visit
-- click: count of ad clicks for each visit
-- (Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)

with page_views as (
	select 
		e.visit_id, 
		count(*) as n_views
	from clique_bait.events e
	where e.event_type = 1
	group by e.visit_id
), chart_adds as (
	select 
		e.visit_id, 
		count(*) as n_chart_adds
	from clique_bait.events e
	where e.event_type = 2
	group by e.visit_id
), purchase_visits as (
	select distinct
		e.visit_id,
		1 as flag_purchase
	from clique_bait.events e
	where e.event_type = 3
), impression_visits as (
	select 
		e.visit_id, 
		count(*) as n_impressions
	from clique_bait.events e
	where e.event_type = 4
	group by e.visit_id
), click_visits as (
	select 
		e.visit_id, 
		count(*) as n_visits
	from clique_bait.events e
	where e.event_type = 5
	group by e.visit_id
)
select distinct 
	u.user_id,
	e.visit_id,
	min(e.event_time) over (partition by e.visit_id) as visit_time,
	page_views.n_views,
	coalesce(chart_adds.n_chart_adds, 0) as chart_adds,
	coalesce(purchase_visits.flag_purchase, 0) as flag_purchase,
	coalesce(ci.campaign_name, 'No Campaign') as campaign_name,
	coalesce(impression_visits.n_impressions, 0) as n_impressions,
	coalesce(click_visits.n_visits, 0) as n_clicks	
from clique_bait.events e
left join clique_bait.users u on e.cookie_id = u.cookie_id 
left join page_views on e.visit_id = page_views.visit_id
left join chart_adds on e.visit_id = chart_adds.visit_id
left join purchase_visits on e.visit_id = purchase_visits.visit_id
left join clique_bait.campaign_identifier ci on e.event_time between ci.start_date and ci.end_date 
left join impression_visits on e.visit_id = impression_visits.visit_id
left join click_visits on e.visit_id = click_visits.visit_id;

-- Coincise version of the query above
WITH visit_metrics AS (
    SELECT 
        e.visit_id,
        COUNT(*) FILTER (WHERE e.event_type = 1) AS n_views,
        COUNT(*) FILTER (WHERE e.event_type = 2) AS n_chart_adds,
        MAX(CASE WHEN e.event_type = 3 THEN 1 ELSE 0 END) AS flag_purchase,
        COUNT(*) FILTER (WHERE e.event_type = 4) AS n_impressions,
        COUNT(*) FILTER (WHERE e.event_type = 5) AS n_clicks
    FROM 
        clique_bait.events e
    GROUP BY 
        e.visit_id
)
SELECT DISTINCT 
    u.user_id,
    e.visit_id,
    MIN(e.event_time) OVER (PARTITION BY e.visit_id) AS visit_time,
    vm.n_views,
    vm.n_chart_adds,
    vm.flag_purchase,
    COALESCE(ci.campaign_name, 'No Campaign') AS campaign_name,
    vm.n_impressions,
    vm.n_clicks	
FROM 
    clique_bait.events e
LEFT JOIN 
    clique_bait.users u ON e.cookie_id = u.cookie_id 
LEFT JOIN 
    visit_metrics vm ON e.visit_id = vm.visit_id
LEFT JOIN 
    clique_bait.campaign_identifier ci ON e.event_time BETWEEN ci.start_date AND ci.end_date;

-- Campaing analysis
-- What I'd analyse: 
-- 1. Overall effectiveness of campaigns based on views and purchase
-- 2. Whether impressions and clicks are associated with purchase
-- 3. Churn of chart adds
-- 4. At what time of the day do people buy more 
-- 5. Recurrent buyers
