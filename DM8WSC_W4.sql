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
order by cn.node_id  asc;

-- Recompute the point above by date
select 
	cn.start_date,
	r.region_name,	
	count(distinct cn.node_id) as n_nodes 
from data_bank.customer_nodes cn 
left join
	data_bank.regions r 
on cn.region_id = r.region_id 
group by cn.start_date,  r.region_name
order by cn.start_date asc, r.region_name asc;

-- How many customers are allocated to each region?

-- Check over all dates 
select 
	r.region_name,	
	count(distinct cn.customer_id) as n_customers 
from data_bank.customer_nodes cn 
left join
	data_bank.regions r 
on cn.region_id = r.region_id 
group by r.region_name
order by r.region_name asc;

-- Check for individual start date
select 
	cn.start_date,
	r.region_name,	
	count(distinct cn.customer_id) as n_customers 
from data_bank.customer_nodes cn 
left join
	data_bank.regions r 
on cn.region_id = r.region_id 
group by cn.start_date,  r.region_name
order by cn.start_date asc, r.region_name asc;

-- How many days on average are customers reallocated to a different node?
-- Achtung: I interpret the phrase "to a different node" as being allocated to a not not equal to the current one (ex: if user x is in node y and then gets reallocated to node y, then we have allocation continuity)
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
		sum(cn.end_date - cn.start_date) over(partition by cn.customer_id, cn.node_id) as avg_alloc_days,
		lag(cn.node_id, 1) over(partition by cn.customer_id, cn.node_id) as node_id_next,
		lag(cn.end_date, 1) over(partition by cn.customer_id, cn.node_id) as end_date_next
	from data_bank.customer_nodes cn
	where cn.end_date != '9999-12-31'
) tab2
where tab2.node_id_next is NULL;
--order by cn.customer_id asc, cn.start_date asc;

-- What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
select 
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
			sum(cn.end_date - cn.start_date) over(partition by cn.customer_id, cn.node_id) as avg_alloc_days,
			lag(cn.node_id, 1) over(partition by cn.customer_id, cn.node_id) as node_id_next,
			lag(cn.end_date, 1) over(partition by cn.customer_id, cn.node_id) as end_date_next
		from data_bank.customer_nodes cn
		where cn.end_date != '9999-12-31'
	) tab2
	where tab2.node_id_next is null
) tab3
where tab3.alloc_percentile in (50, 85, 90)
group by tab3.alloc_percentile;

-- B. Customer Transactions
-- What is the unique count and total amount for each transaction type?
-- What is the average total historical deposit counts and amounts for all customers?
-- For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
-- What is the closing balance for each customer at the end of the month?
-- What is the percentage of customers who increase their closing balance by more than 5%?

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

-- D. Extra Challenge
-- Data Bank wants to try another option which is a bit more difficult to implement - they want to calculate data growth using an interest calculation, just like in a traditional savings account you might have with a bank.

-- If the annual interest rate is set at 6% and the Data Bank team wants to reward its customers by increasing their data allocation based off the interest calculated on a daily basis at the end of each day, how much data would be required for this option on a monthly basis?

-- Special notes:

-- Data Bank wants an initial calculation which does not allow for compounding interest, however they may also be interested in a daily compounding interest calculation so you can try to perform this calculation if you have the stamina!
-- Extension Request
-- The Data Bank team wants you to use the outputs generated from the above sections to create a quick Powerpoint presentation which will be used as marketing materials for both external investors who might want to buy Data Bank shares and new prospective customers who might want to bank with Data Bank.

-- Using the outputs generated from the customer node questions, generate a few headline insights which Data Bank might use to market it’s world-leading security features to potential investors and customers.

-- With the transaction analysis - prepare a 1 page presentation slide which contains all the relevant information about the various options for the data provisioning so the Data Bank management team can make an informed decision.