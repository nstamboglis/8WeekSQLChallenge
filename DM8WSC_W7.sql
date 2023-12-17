-----------------------------------
-- Data with Danny - W7

-- 1. High level sales analysis
with table_analysis as (select 	
	EXTRACT(YEAR FROM sales.start_txn_time) || '-' || LPAD(EXTRACT(MONTH FROM sales.start_txn_time)::text, 2, '0') AS year_month,
    sales.prod_id,
    sales.qty,
    sales.price,
    sales.discount
from balanced_tree.sales)
select
	ta.year_month,
	ta.prod_id,
	sum(ta.qty) as qty_sum,
	sum(ta.qty * ta.price) as rev_sum,
	sum((ta.qty * ta.price)*ta.discount) as discount_sum
from table_analysis ta
group by ta.year_month, ta.prod_id
order by ta.year_month desc, ta.prod_id asc;

-- 2. Total generated revenue for all products before discounts

-- 2.1 How many unique transactions were there?

with table_uniques as (select 	
	distinct s.txn_id
from balanced_tree.sales as s
) 
select
	count (distinct table_uniques.txn_id)
from table_uniques;

-- 2.2 What is the average unique products purchased in each transaction?
with table_uniques as (select 	
	s.txn_id,
	s.prod_id 
from balanced_tree.sales as s
), table_analysis as (
select
	table_uniques.txn_id,
	count (distinct table_uniques.prod_id) as average_prd_txn
from table_uniques
group by table_uniques.txn_id)
select 
	count(distinct table_analysis.txn_id), 
	avg(table_analysis.average_prd_txn) as avg_prd
from table_analysis;

-- 2.3 What are the 25th, 50th and 75th percentile values for the revenue per transaction?
with table_uniques as (select 	
	s.txn_id,
	s.prod_id,
	(s.qty * s.price) * (100-s.discount) as txn_revenue
from balanced_tree.sales as s
), table_analysis as (
select
	table_uniques.txn_id,
	count (distinct table_uniques.prod_id) as average_prd_txn,
	sum(table_uniques.txn_revenue) as txn_revenue
from table_uniques
group by table_uniques.txn_id)
select 
	count(distinct table_analysis.txn_id), 
	avg(table_analysis.average_prd_txn) as avg_prd,
	percentile_disc(0.25) within group (order by table_analysis.txn_revenue) as percent_revenue_25,
	percentile_disc(0.5) within group (order by table_analysis.txn_revenue) as percent_revenue_50,
	percentile_disc(0.75) within group (order by table_analysis.txn_revenue) as percent_revenue_75
 from table_analysis;
 
-- 2.4 Average discount value per transaction
with table_uniques as (select 	
	s.txn_id,
	s.prod_id,
	(s.qty * s.price) * (100-s.discount) as txn_revenue,
	(s.qty * s.price) * (s.discount) as discount_value
from balanced_tree.sales as s
), table_analysis as (
select
	table_uniques.txn_id,
	count (distinct table_uniques.prod_id) as average_prd_txn,
	sum(table_uniques.txn_revenue) as txn_revenue,
	sum(table_uniques.discount_value) as txn_discount_value
from table_uniques
group by table_uniques.txn_id)
select 
	count(distinct table_analysis.txn_id), 
	avg(table_analysis.average_prd_txn) as avg_prd,
	percentile_disc(0.25) within group (order by table_analysis.txn_revenue) as percent_revenue_25,
	percentile_disc(0.5) within group (order by table_analysis.txn_revenue) as percent_revenue_50,
	percentile_disc(0.75) within group (order by table_analysis.txn_revenue) as percent_revenue_75,
	round(avg(table_analysis.txn_discount_value), 0) as avg_discount_value 
 from table_analysis;
 
-- 2.5 What is the percentage split of all transactions for members vs non-members?
with table_uniques as (select 	
	s.txn_id,
	s.prod_id,
	(s.qty * s.price) * (100-s.discount) as txn_revenue,
	(s.qty * s.price) * (s.discount) as discount_value,
	s."member",
	case 
		when s."member" = 't' then 1
		when s."member" = 'f' then 0
	end as member_recoded
from balanced_tree.sales as s
), table_analysis as (
select
	table_uniques.txn_id,
	count (distinct table_uniques.prod_id) as average_prd_txn,
	sum(table_uniques.txn_revenue) as txn_revenue,
	sum(table_uniques.discount_value) as txn_discount_value,
	sum(table_uniques.txn_revenue * member_recoded) as txn_revenue_members
from table_uniques
group by table_uniques.txn_id)
select 
	count(distinct table_analysis.txn_id), 
	avg(table_analysis.average_prd_txn) as avg_prd,
	percentile_disc(0.25) within group (order by table_analysis.txn_revenue) as percent_revenue_25,
	percentile_disc(0.5) within group (order by table_analysis.txn_revenue) as percent_revenue_50,
	percentile_disc(0.75) within group (order by table_analysis.txn_revenue) as percent_revenue_75,
	round(avg(table_analysis.txn_discount_value), 0) as avg_discount_value,
	(count(distinct table_analysis.txn_id) filter (WHERE table_analysis.txn_revenue_members > 0) / count(distinct table_analysis.txn_id)::float) * 100 as perc_txn_members
--	round(AVG(table_analysis.txn_discount_value_members) FILTER (WHERE table_analysis.txn_discount_value_members > 0), 0) as txn_discount_members
 from table_analysis;
 
-- 2.6 What is the average revenue for member transactions and non-member transactions?
with table_uniques as (select 	
	s.txn_id,
	s.prod_id,
	(s.qty * s.price) * (100-s.discount) as txn_revenue,
	(s.qty * s.price) * (s.discount) as discount_value,
	s."member",
	case 
		when s."member" = 't' then 1
		when s."member" = 'f' then 0
	end as member_recoded
from balanced_tree.sales as s
), table_analysis as (
select
	table_uniques.txn_id,
	count (distinct table_uniques.prod_id) as average_prd_txn,
	sum(table_uniques.txn_revenue) as txn_revenue,
	sum(table_uniques.discount_value) as txn_discount_value,
	sum(table_uniques.txn_revenue * member_recoded) as txn_revenue_members,
	sum(table_uniques.txn_revenue * (1-member_recoded)) as txn_revenue_non_members
from table_uniques
group by table_uniques.txn_id)
select 
	count(distinct table_analysis.txn_id), 
	avg(table_analysis.average_prd_txn) as avg_prd,
	percentile_disc(0.25) within group (order by table_analysis.txn_revenue) as percent_revenue_25,
	percentile_disc(0.5) within group (order by table_analysis.txn_revenue) as percent_revenue_50,
	percentile_disc(0.75) within group (order by table_analysis.txn_revenue) as percent_revenue_75,
	round(avg(table_analysis.txn_discount_value), 0) as avg_discount_value,
	(count(distinct table_analysis.txn_id) filter (WHERE table_analysis.txn_revenue_members > 0) / count(distinct table_analysis.txn_id)::float) * 100 as perc_txn_members,
	round(AVG(table_analysis.txn_revenue) FILTER (WHERE table_analysis.txn_revenue_members > 0), 0) as avg_txn_revenue_members,
	round(AVG(table_analysis.txn_revenue) FILTER (WHERE table_analysis.txn_revenue_non_members > 0), 0) as avg_txn_revenue_non_members
 from table_analysis;
