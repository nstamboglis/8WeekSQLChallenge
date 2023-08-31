-----------------------------------
-- Data with Danny - W7

-- 1. High level analysis
with table_analysis as (select 	
	EXTRACT(YEAR FROM sales.start_txn_time) || '-' || LPAD(EXTRACT(MONTH FROM sales.start_txn_time)::text, 2, '0') AS year_month,
    sales.prod_id,
    sales.qty
from balanced_tree.sales)
select
	ta.year_month,
	ta.prod_id,
	sum(ta.qty) as qty_sum
from table_analysis ta
group by ta.year_month, ta.prod_id
order by ta.year_month desc, ta.prod_id asc;
