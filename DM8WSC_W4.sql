-- WEEK 4 QUESTIONS

-- A. Customer Nodes Exploration
-- How many unique nodes are there on the Data Bank system?

select 
	count(distinct cn.node_id) as n_nodes 
from data_bank.customer_nodes cn;

-- What is the number of nodes per region?

select 
	r.region_name,	
	count(distinct cn.node_id) as n_nodes 
from data_bank.customer_nodes cn 
left join
	data_bank.regions r 
on cn.region_id = r.region_id 
group by r.region_name
order by r.region_name asc;

-- Check wheter single nodes are uniquely associated with individual regions (each ID is associated with all regions at a certain point in time) 
select 
	count(distinct r.region_name) as n_regions,
	cn.node_id
from data_bank.customer_nodes cn 
left join
	data_bank.regions r 
on cn.region_id = r.region_id 
group by cn.node_id 
order by cn.node_id asc;

-- Recompute the point above by date
select 
	start_end,
	node_id,
	count(distinct region_name) as n_regions
from (
	select cn2.node_id, r.region_name, test_table.dt::date as start_end
	from 
		(select 
		*,
		case 
			when  extract(year from cn.end_date) = '9999' then '2022-12-09'
			else cn.end_date 
		end as end_date_transf
		from data_bank.customer_nodes cn) cn2
	cross join  generate_series(cn2.start_date, cn2.end_date_transf, interval '1 day') as test_table(dt)
	left join data_bank.regions r on cn2.region_id = r.region_id 
	order by cn2.node_id, start_end) tquery
group by node_id, start_end
order by node_id, start_end;

-- How many customers are allocated to each region?
select 
	count(distinct cn.customer_id) as n_customers_unique,
	re.region_name
from data_bank.customer_nodes cn 
left join data_bank.regions re on cn.region_id = re.region_id
group by re.region_name;

-- Check over all dates 

select 
	start_end as bank_date,
	r.region_name,
	n_customers
from(
	select 
		count(distinct cn2.node_id) as n_customers, 
		cn2.region_id, 
		test_table.dt::date as start_end
	from 
		(select 
		*,
		case 
			when  extract(year from cn.end_date) = '9999' then '2022-12-09'
			else cn.end_date 
		end as end_date_transf
		from data_bank.customer_nodes cn) cn2
	cross join  generate_series(cn2.start_date, cn2.end_date_transf, interval '1 day') as test_table(dt)
	group by cn2.region_id, start_end) fquery
left join data_bank.regions r on fquery.region_id = r.region_id;

-- How many days on average are customers reallocated to a different node?
-- Achtung: I interpret the phrase "to a different node" as being allocated to a node not equal to the current one (ex: if user x is in node y and then gets reallocated to node y, then we have allocation continuity)
-- I also remove the date equal to '9999-12-31'
select 
	round(avg(tab2.avg_alloc_days), 1) as avg_reall_days
from(
	select 
		cn.customer_id,
		cn.node_id,
		cn.end_date - cn.start_date as n_days,
		cn.start_date,
		cn.end_date,
		sum(cn.end_date - cn.start_date) over(partition by cn.customer_id, cn.node_id, cn.region_id) as avg_alloc_days,
		lead(cn.node_id, 1) over(partition by cn.customer_id, cn.node_id, cn.region_id) as node_id_next,
		lead(cn.end_date, 1) over(partition by cn.customer_id, cn.node_id, cn.region_id) as end_date_next
	from data_bank.customer_nodes cn
	where cn.end_date != '9999-12-31') tab2
where tab2.node_id_next is NULL;
		
-- What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
select 
	tab3.region_name,
	tab3.alloc_percentile,
	round(avg(tab3.avg_alloc_days),1) as percentile_value
from(
	select 
		*,
		ntile(100) over(order by tab2.avg_alloc_days) as alloc_percentile	
	from(
		select 
			cn.customer_id,
			cn.node_id,
			cn.end_date - cn.start_date as n_days,
			cn.start_date,
			cn.end_date,
			r.region_name,
			sum(cn.end_date - cn.start_date) over(partition by cn.customer_id, cn.node_id, cn.region_id) as avg_alloc_days,
			lead(cn.node_id, 1) over(partition by cn.customer_id, cn.node_id, cn.region_id) as node_id_next,
			lead(cn.end_date, 1) over(partition by cn.customer_id, cn.node_id, cn.region_id) as end_date_next
		from data_bank.customer_nodes cn
		left join data_bank.regions r on cn.region_id = r.region_id
		where cn.end_date != '9999-12-31'
	) tab2
	where tab2.node_id_next is null
) tab3
where tab3.alloc_percentile in (50, 85, 90)
group by tab3.alloc_percentile, tab3.region_name
order by tab3.region_name asc, tab3.alloc_percentile asc;

-- B. Customer Transactions
-- What is the unique count and total amount for each transaction type?
select 
	ct.txn_type,
	count(*) as n_transactions,
	sum(ct.txn_amount) as tot_amount
from data_bank.customer_transactions ct
group by ct.txn_type
order by ct.txn_type asc;

-- What is the average total historical deposit counts and amounts for all customers?
select 
	round(avg(tab2.n_transactions),1) as n_transactions_avg,
	round(avg(tab2.tot_amount),1) as amount_avg
from(
	select 
		ct.customer_id,
		count(*) as n_transactions,
		sum(ct.txn_amount) as tot_amount
	from data_bank.customer_transactions ct
	group by ct.customer_id 
	order by ct.customer_id asc
) tab2;

-- For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

select 
	txn_ym,
	count(customer_id) as n_customers
from(
	select 
		tab2.customer_id,
		tab2.txn_ym,
		sum(txn_deposit) as n_deposits,
		sum(txn_purchase) as n_purchase,
		sum(txn_withdrawal) as n_withdrawal
	from(
		select 
			ct.customer_id,
			to_char(txn_date, 'YYYY_MM') as txn_ym, 
			ct.txn_type,
			case 
				when txn_type = 'deposit' then 1
				else 0
			end as txn_deposit,
			case 
				when txn_type = 'purchase' then 1
				else 0
			end as txn_purchase,
			case 
				when txn_type = 'withdrawal' then 1
				else 0
			end as txn_withdrawal
		from data_bank.customer_transactions ct) tab2
	group by customer_id, txn_ym
	order by customer_id asc, txn_ym asc) tab3
where n_deposits >1 and (n_purchase >0 or n_withdrawal >0)
group by txn_ym
order by txn_ym asc;

-- What is the closing balance for each customer at the end of the month?

with balance_raw as (
	select 
	 	tab_final.calendar_date,
	 	tab_final.customer_id,
	 	tab_final.balance,
	 	count(tab_final.balance) over (order by tab_final.customer_id, tab_final.calendar_date) as _grp
	 from(  
	 select 
	 	calendar_table.calendar_date,
	 	t1.customer_id,
	 	balance_table.balance
	 FROM(
		select 
			to_char(generate_series(min(ct.txn_date), max(ct.txn_date), '1month')::date, 'YYYY_MM') AS calendar_date 
			FROM data_bank.customer_transactions ct) calendar_table
	CROSS JOIN (SELECT DISTINCT ct2.customer_id FROM data_bank.customer_transactions ct2) t1
	left join (
		select 
			tab3.customer_id as customer_id,
			tab3.txn_ym as calendar_date,
	--		tab3.balance_delta,
			tab3.balance_delta + lag(tab3.balance_delta, 1, 0) over(order by tab3.customer_id, tab3.txn_ym) as balance
		from(
			select 
				tab2.customer_id,
				tab2.txn_ym,
				sum(tab2.balance_input) as balance_delta
			from(
				select 
					ct.customer_id,
					to_char(txn_date, 'YYYY_MM') as txn_ym, 
					ct.txn_type,
					case 
						when txn_type = 'deposit' then txn_amount 
						when txn_type = 'purchase' then -txn_amount 
						when txn_type = 'withdrawal' then -txn_amount 
						else 0
					end as balance_input
				from data_bank.customer_transactions ct) tab2
			group by tab2.customer_id, tab2.txn_ym
			order by tab2.customer_id asc, tab2.txn_ym asc) tab3) balance_table
	on balance_table.calendar_date = calendar_table.calendar_date and balance_table.customer_id = t1.customer_id
	order by customer_id, calendar_date) tab_final
	order by tab_final.customer_id, tab_final.calendar_date)
select 
	calendar_date,
	customer_id,
--	balance,
--	_grp,
	first_value(balance) over (partition by _grp order by customer_id, calendar_date) as balance_clean
from balance_raw;

-- What is the percentage of customers who increase their closing balance by more than 5%?
with balance_clean as(
select 
	balance_raw.calendar_date,
	balance_raw.customer_id,
	count(customer_id) over(order by customer_id, calendar_date) as id_counter,
--	balance,
--	_grp,
	first_value(balance_raw.balance) over (partition by balance_raw._grp order by balance_raw.customer_id, balance_raw.calendar_date) as balance_clean
from (
	select 
	 	tab_final.calendar_date,
	 	tab_final.customer_id,
	 	tab_final.balance,
	 	count(tab_final.balance) over (order by tab_final.customer_id, tab_final.calendar_date) as _grp
	 from(  
	 select 
	 	calendar_table.calendar_date,
	 	t1.customer_id,
	 	balance_table.balance
	 FROM(
		select 
			to_char(generate_series(min(ct.txn_date), max(ct.txn_date), '1month')::date, 'YYYY_MM') AS calendar_date 
			FROM data_bank.customer_transactions ct) calendar_table
	CROSS JOIN (SELECT DISTINCT ct2.customer_id FROM data_bank.customer_transactions ct2) t1
	left join (
		select 
			tab3.customer_id as customer_id,
			tab3.txn_ym as calendar_date,
	--		tab3.balance_delta,
			tab3.balance_delta + lag(tab3.balance_delta, 1, 0) over(order by tab3.customer_id, tab3.txn_ym) as balance
		from(
			select 
				tab2.customer_id,
				tab2.txn_ym,
				sum(tab2.balance_input) as balance_delta
			from(
				select 
					ct.customer_id,
					to_char(txn_date, 'YYYY_MM') as txn_ym, 
					ct.txn_type,
					case 
						when txn_type = 'deposit' then txn_amount 
						when txn_type = 'purchase' then -txn_amount 
						when txn_type = 'withdrawal' then -txn_amount 
						else 0
					end as balance_input
				from data_bank.customer_transactions ct) tab2
			group by tab2.customer_id, tab2.txn_ym
			order by tab2.customer_id asc, tab2.txn_ym asc) tab3) balance_table
	on balance_table.calendar_date = calendar_table.calendar_date and balance_table.customer_id = t1.customer_id
	order by customer_id, calendar_date) tab_final
	order by tab_final.customer_id, tab_final.calendar_date) balance_raw)
select 
	balance_clean3.customer_id,
	balance_clean3.perc_change
from(
	select 
   	 	balance_clean2.customer_id,
		avg(balance_clean2.balance_perc_change) as perc_change
	from(
		select 
			calendar_date,
			customer_id,
			id_counter,
			balance_clean,
			case 
				when round(abs(first_value(balance_clean) over(partition by customer_id)), 2) != 0 then round((last_value(balance_clean) over(partition by customer_id) - first_value(balance_clean) over(partition by customer_id)) / round(abs(first_value(balance_clean) over(partition by customer_id)), 2), 2) * 100
				else  round((last_value(balance_clean) over(partition by customer_id) - first_value(balance_clean) over(partition by customer_id)) / 1, 2) * 100
			end as balance_perc_change
--			round((last_value(balance_clean) over(partition by customer_id) - first_value(balance_clean) over(partition by customer_id)) / round(abs(first_value(balance_clean) over(partition by customer_id)), 2), 2) * 100 as balance_perc_change
--	last_value(balance_clean) over(partition by customer_id) as balance_last	
--	first_value(balance_raw.balance) over (partition by balance_raw._grp order by balance_raw.customer_id, balance_raw.calendar_date) as balance_clean
--	last_value(balance_clean) over(customer_id, calendar_date) as balance_last
--	count(customer_id) over(order by customer_id, calendar_date)
		from balance_clean) balance_clean2
	group by balance_clean2.customer_id
	order by balance_clean2.customer_id) balance_clean3
where balance_clean3.perc_change > 5;

-- C. Data Allocation Challenge
-- To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:

-- 	Option 1: data is allocated based off the amount of money at the end of the previous month
--  Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
--  Option 3: data is updated real-time
-- For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:

-- running customer balance column that includes the impact each transaction
-- customer balance at the end of each month
-- minimum, average and maximum values of the running balance for each customer
-- Using all of the data available - how much data would have been required for each option on a monthly basis?

-- SOLUTION: Let's compare the options 
-- Option 1: running customer balance column that includes the impact each transaction
select 
	tab2.customer_id,
	tab2.txn_ym,
	sum(tab2.balance_input) as running_balance
from(
	select 
		ct.customer_id,
		to_char(txn_date, 'YYYY_MM') as txn_ym, 
		ct.txn_type,
		case 
			when txn_type = 'deposit' then txn_amount 
			when txn_type = 'purchase' then -txn_amount 
			when txn_type = 'withdrawal' then -txn_amount 
			else 0
		end as balance_input,
		row_number() over (partition by ct.customer_id) as customer_transaction_id
		from data_bank.customer_transactions ct) tab2
group by tab2.customer_id, tab2.txn_ym, customer_transaction_id
order by tab2.customer_id asc, tab2.txn_ym asc;

-- Option 2: customer balance at the end of each month
select 
	tab2.customer_id,
	tab2.txn_ym,
	sum(tab2.balance_input) as running_balance
from(
	select 
		ct.customer_id,
		to_char(txn_date, 'YYYY_MM') as txn_ym, 
		ct.txn_type,
		case 
			when txn_type = 'deposit' then txn_amount 
			when txn_type = 'purchase' then -txn_amount 
			when txn_type = 'withdrawal' then -txn_amount 
			else 0
		end as balance_input,
		row_number() over (partition by ct.customer_id) as customer_transaction_id
		from data_bank.customer_transactions ct) tab2
group by tab2.customer_id, tab2.txn_ym
order by tab2.customer_id asc, tab2.txn_ym asc;
	
-- Option 3: minimum, average and maximum values of the running balance for each customer
with running_table as (
	select 
		tab3.customer_id,
		tab3.txn_ym,
		tab3.running_balance,
		row_number() over (partition by tab3.customer_id) as running_balance_id	
	from(
		select 
			tab2.customer_id,
			tab2.txn_ym,
			sum(tab2.balance_input) as running_balance
		from(
			select 
				ct.customer_id,
				to_char(txn_date, 'YYYY_MM') as txn_ym, 
				ct.txn_type,
				case 
					when txn_type = 'deposit' then txn_amount 
					when txn_type = 'purchase' then -txn_amount 
					when txn_type = 'withdrawal' then -txn_amount 
					else 0
				end as balance_input,
				row_number() over (partition by ct.customer_id) as customer_transaction_id
				from data_bank.customer_transactions ct) tab2
		group by tab2.customer_id, tab2.txn_ym, customer_transaction_id
		order by tab2.customer_id asc, tab2.txn_ym asc) tab3)
select 
	running_table.customer_id,
	running_table.txn_ym,
--	running_table.running_balance_id,
--	running_table.running_balance,
	min(running_table.running_balance) over(order by running_table.customer_id, running_table.txn_ym, running_table.running_balance_id) as running_min,
	round(avg(running_table.running_balance) over(order by running_table.customer_id, running_table.txn_ym, running_table.running_balance_id), 2) as running_avg,
	max(running_table.running_balance) over(order by running_table.customer_id, running_table.txn_ym, running_table.running_balance_id) as running_max
from running_table;

-- Using all of the data available - how much data would have been required for each option on a monthly basis?

-- ANSWER: I answer by setting up a temp table for every answer

CREATE TEMPORARY TABLE solution_1 AS select 
	tab2.customer_id,
	tab2.txn_ym,
	sum(tab2.balance_input) as running_balance
from(
	select 
		ct.customer_id,
		to_char(txn_date, 'YYYY_MM') as txn_ym, 
		ct.txn_type,
		case 
			when txn_type = 'deposit' then txn_amount 
			when txn_type = 'purchase' then -txn_amount 
			when txn_type = 'withdrawal' then -txn_amount 
			else 0
		end as balance_input,
		row_number() over (partition by ct.customer_id) as customer_transaction_id
		from data_bank.customer_transactions ct) tab2
group by tab2.customer_id, tab2.txn_ym, customer_transaction_id
order by tab2.customer_id asc, tab2.txn_ym asc;

create temporary table solution_2 as select 
	tab2.customer_id,
	tab2.txn_ym,
	sum(tab2.balance_input) as running_balance
from(
	select 
		ct.customer_id,
		to_char(txn_date, 'YYYY_MM') as txn_ym, 
		ct.txn_type,
		case 
			when txn_type = 'deposit' then txn_amount 
			when txn_type = 'purchase' then -txn_amount 
			when txn_type = 'withdrawal' then -txn_amount 
			else 0
		end as balance_input,
		row_number() over (partition by ct.customer_id) as customer_transaction_id
		from data_bank.customer_transactions ct) tab2
group by tab2.customer_id, tab2.txn_ym
order by tab2.customer_id asc, tab2.txn_ym asc;

create temporary table solution_3 as with running_table as (
	select 
		tab3.customer_id,
		tab3.txn_ym,
		tab3.running_balance,
		row_number() over (partition by tab3.customer_id) as running_balance_id	
	from(
		select 
			tab2.customer_id,
			tab2.txn_ym,
			sum(tab2.balance_input) as running_balance
		from(
			select 
				ct.customer_id,
				to_char(txn_date, 'YYYY_MM') as txn_ym, 
				ct.txn_type,
				case 
					when txn_type = 'deposit' then txn_amount 
					when txn_type = 'purchase' then -txn_amount 
					when txn_type = 'withdrawal' then -txn_amount 
					else 0
				end as balance_input,
				row_number() over (partition by ct.customer_id) as customer_transaction_id
				from data_bank.customer_transactions ct) tab2
		group by tab2.customer_id, tab2.txn_ym, customer_transaction_id
		order by tab2.customer_id asc, tab2.txn_ym asc) tab3)
select 
	running_table.customer_id,
	running_table.txn_ym,
--	running_table.running_balance_id,
--	running_table.running_balance,
	min(running_table.running_balance) over(order by running_table.customer_id, running_table.txn_ym, running_table.running_balance_id) as running_min,
	round(avg(running_table.running_balance) over(order by running_table.customer_id, running_table.txn_ym, running_table.running_balance_id), 2) as running_avg,
	max(running_table.running_balance) over(order by running_table.customer_id, running_table.txn_ym, running_table.running_balance_id) as running_max
from running_table;

SELECT 
	pg_total_relation_size('solution_1') as size_sol1, 
	pg_total_relation_size('solution_2') as size_sol2,
	pg_total_relation_size('solution_3') as size_sol3;
-- Solution 2 requires less space

-- D. Extra Challenge
-- Data Bank wants to try another option which is a bit more difficult to implement - they want to calculate data growth using an interest calculation, just like in a traditional savings account you might have with a bank.

-- If the annual interest rate is set at 6% and the Data Bank team wants to reward its customers by increasing their data allocation based off the interest calculated on a daily basis at the end of each day, 
-- how much data would be required for this option on a monthly basis?
-- NOTE: The solution below assumes that customers won't pay negative interest
with balance_table as (
	select 
		balance_raw.calendar_date,
		balance_raw.customer_id,
		count(customer_id) over(order by customer_id, calendar_date) as id_counter,
	--	balance,
	--	_grp,
		coalesce(first_value(balance_raw.balance) over (partition by balance_raw._grp order by balance_raw.customer_id, balance_raw.calendar_date), 0) as balance_clean
	from (
		select 
		 	tab_final.calendar_date,
		 	tab_final.customer_id,
		 	tab_final.balance,
		 	count(tab_final.balance) over (order by tab_final.customer_id, tab_final.calendar_date) as _grp
		 from(  
		 select 
		 	calendar_table.calendar_date,
		 	t1.customer_id,
		 	balance_table.balance
		 FROM(
			select 
				to_char(generate_series(min(ct.txn_date), max(ct.txn_date), '1day')::date, 'YYYY_MM_DD') AS calendar_date 
				FROM data_bank.customer_transactions ct) calendar_table
		CROSS JOIN (SELECT DISTINCT ct2.customer_id FROM data_bank.customer_transactions ct2) t1
		left join (
			select 
				tab3.customer_id as customer_id,
				tab3.txn_ym as calendar_date,
		--		tab3.balance_delta,
				tab3.balance_delta + lag(tab3.balance_delta, 1, 0) over(order by tab3.customer_id, tab3.txn_ym) as balance
			from(
				select 
					tab2.customer_id,
					tab2.txn_ym,
					sum(tab2.balance_input) as balance_delta
				from(
					select 
						ct.customer_id,
						to_char(txn_date, 'YYYY_MM_DD') as txn_ym, 
						ct.txn_type,
						case 
							when txn_type = 'deposit' then txn_amount 
							when txn_type = 'purchase' then -txn_amount 
							when txn_type = 'withdrawal' then -txn_amount 
							else 0
						end as balance_input
					from data_bank.customer_transactions ct) tab2
				group by tab2.customer_id, tab2.txn_ym
				order by tab2.customer_id asc, tab2.txn_ym asc) tab3) balance_table
		on balance_table.calendar_date = calendar_table.calendar_date and balance_table.customer_id = t1.customer_id
		order by customer_id, calendar_date) tab_final
		order by tab_final.customer_id, tab_final.calendar_date) balance_raw)
select 
	tab2.calendar_date,
	tab2.customer_id,
	tab2.balance_clean + tab2.balance_int_adj as balance_clean
from (
	select 
		tab1.calendar_date,
		tab1.customer_id,
		tab1.balance_clean,
		case 
			when tab1.balance_int >0 then balance_int
			when tab1.balance_int <= 0 then 0
		end as balance_int_adj
	from(	
		select 
			balance_table.calendar_date,
			balance_table.customer_id,
			balance_table.id_counter,
			row_number() over(partition by customer_id) as customer_days,
			balance_table.balance_clean,
			coalesce(balance_table.balance_clean - lag(balance_table.balance_clean, 1) over (partition by customer_id), 0) as balance_delta,
			balance_table.balance_clean * 6/365 * row_number() over(partition by customer_id) as balance_int
		from balance_table	
	) tab1
) tab2;

-- add days from zero
-- add variation on balance		
		
	




-- Special notes:

-- Data Bank wants an initial calculation which does not allow for compounding interest, however they may also be interested in a daily compounding interest calculation so you can try to perform this calculation if you have the stamina!
-- Extension Request
-- The Data Bank team wants you to use the outputs generated from the above sections to create a quick Powerpoint presentation which will be used as marketing materials for both external investors who might want to buy Data Bank shares and new prospective customers who might want to bank with Data Bank.

-- Using the outputs generated from the customer node questions, generate a few headline insights which Data Bank might use to market it’s world-leading security features to potential investors and customers.

-- With the transaction analysis - prepare a 1 page presentation slide which contains all the relevant information about the various options for the data provisioning so the Data Bank management team can make an informed decision.