-- A. Customer Journey
-- Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
-- Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!

select 
	s.customer_id,
	s.start_date,
	p.plan_name,
	p.price 
from foodie_fi.subscriptions s
left join foodie_fi."plans" p 
on s.plan_id = p.plan_id 
where s.customer_id <=8; 

select 
	s.customer_id,
	s.start_date,
	p.plan_name,
	p.price 
from foodie_fi.subscriptions s
left join foodie_fi."plans" p 
on s.plan_id = p.plan_id 
where s.customer_id <=8 and p.plan_name ='trial'; 

select 	
	string_agg(tab1.customer_id, ' - ') as customers_ids,
	tab1.onboarding_journey
from(
select 
	cast(s.customer_id as character) as customer_id,
	string_agg(p.plan_name, ' - ') as onboarding_journey
from foodie_fi.subscriptions s
left join foodie_fi."plans" p 
on s.plan_id = p.plan_id 
where s.customer_id <=8
group by s.customer_id
order by s.customer_id
) tab1
group by tab1.onboarding_journey;

-- Incoming description:
	-- All customers entered the program via a trial subscription
	-- Customers 1 - 3 - 5 later switched to "basic monthly" program
	-- Customers 4 - 6 did the same, but then churned
	-- Customers 7 - 8 switched to "pro monthly"
	-- Customer 2 is the only customer in the sample that switched from "Trial" to "Pro annual". 

-- B. Data Analysis Questions
-- How many customers has Foodie-Fi ever had?
select
	count (distinct s.customer_id) 
from foodie_fi.subscriptions s
where s.plan_id != 0 and s.plan_id != 4; 
-- I interpret as customer only those who switched to a pay option

-- What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
select 
	cast(date_trunc('month', s.start_date) as date) as subscription_date,
	extract(day from s.start_date) as trial_day,
	count(extract(day from s.start_date))
from 
	foodie_fi.subscriptions s 
where 
	s.plan_id = 0
group by extract(day from s.start_date), cast(date_trunc('month', s.start_date) as date)
order by cast(date_trunc('month', s.start_date) as date), extract(day from s.start_date) asc;

-- What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
select 
	s.start_date,
	p.plan_name,
	count(s.customer_id)
from 
	foodie_fi.subscriptions s 
left join 
	foodie_fi."plans" p 
on s.plan_id = p.plan_id 
where 
	extract(year from s.start_date) > 2020
group by 
	p.plan_name,
	s.start_date
order by 
	s.start_date asc,
	p.plan_name asc; 

-- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
select 
	count(distinct s.customer_id) as n_customers,
	(select count(distinct s2.customer_id) from foodie_fi.subscriptions s2 where s2.plan_id = 4) as n_churners,
	round((select count(distinct s2.customer_id) from foodie_fi.subscriptions s2 where s2.plan_id = 4) / count(distinct s.customer_id)::numeric,3) * 100 as perc_churners
from 
	foodie_fi.subscriptions s;

-- How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
select 
	(select count(distinct s2.customer_id) from foodie_fi.subscriptions s2) as n_customers,
 	count(distinct tab2.customer_id) as n_straight_churners,
 	round(count(distinct tab2.customer_id) / (select count(distinct s2.customer_id) from foodie_fi.subscriptions s2)::numeric, 1) * 100 as perc_straight_churners
from(
	select 
		tab1.customer_id,
		string_agg(cast(tab1.plan_id as character), ',') as sub_history
	from(
		select 
			s.customer_id,
			s.plan_id 
		from 
			foodie_fi.subscriptions s 
		group by
			s.customer_id, s.plan_id
		order by 
			s.customer_id asc, s.plan_id asc
	) tab1
	group by tab1.customer_id
) tab2
where 
	tab2.sub_history = '0,4'; 
	
-- What is the number and percentage of customer plans after their initial free trial?
select 
	s.plan_id,
	count(s.customer_id) as n_customers,
	round(count(s.customer_id) / (select count(s2.customer_id) from foodie_fi.subscriptions s2 where s2.plan_id not in (0,4))::numeric, 3) * 100 as perc_customers
from foodie_fi.subscriptions s 
where s.plan_id not in (0, 4)
group by s.plan_id
order by s.plan_id asc;

-- What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
select
	p3.plan_name,
	tab3.n_customers_at_date
from(
	select 
		count(tab2.customer_id) n_customers_at_date,
		tab2.plan_id
	from(
		select 
			tab1.customer_id,
			tab1.my_date,
			s2.plan_id
		from(
			select 
				s.customer_id,
				max(s.start_date) as my_date
			from 
				foodie_fi.subscriptions s 
			left join 
				foodie_fi."plans" p 
			on s.plan_id = p.plan_id 
			where 
				s.start_date <= '2020-12-31'
			group by s.customer_id
			order by s.customer_id
		) tab1
		inner join 
			foodie_fi.subscriptions s2 
		on tab1.customer_id = s2.customer_id and tab1.my_date = s2.start_date
	) tab2
	group by 
		tab2.plan_id
	order by 	
		tab2.plan_id asc
) tab3
inner join 
	foodie_fi."plans" p3 
on tab3.plan_id = p3.plan_id; 

-- How many customers have upgraded to an annual plan in 2020?
select 
	count( tab2.customer_id)
from(
	select 
		tab1.customer_id,
		tab1.plan_id,
		tab1.start_date,
		max(tab1.customer_obs) last_plan_index
	from(
		select 
			*,
			row_number() over (partition by s.customer_id) as customer_obs
		from foodie_fi.subscriptions s
		where s.start_date <= '2020/12/31'
	) tab1
	group by tab1.customer_id, tab1.plan_id, tab1.start_date
) tab2
where tab2.plan_id = 3;

-- How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
select
	round(avg(n_days),2) as average_days
from(
	select 
		s.customer_id,
		s.start_date as annual_plan_date,
		s3.start_date as trial_date,
		s.start_date - s3.start_date as n_days
	from foodie_fi.subscriptions s
	left join(
		select
			*,
			row_number() over (partition by s2.customer_id) as customer_obs
		from foodie_fi.subscriptions s2
		where s2.plan_id = 0
	) s3
	on s.customer_id = s3.customer_id 
	where s.start_date <= '2020/12/31' and s.plan_id in (3)
) s4;

-- Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
select
	round(avg(n_days),2) as average_days,
	days_bins
from(
	select 
		s.customer_id,
		s.start_date as annual_plan_date,
		s3.start_date as trial_date,
		(s.start_date - s3.start_date) as n_days,
		(((s.start_date - s3.start_date) / 30) +1) *30 as days_bins
	from foodie_fi.subscriptions s
	left join(
		select
			*,
			row_number() over (partition by s2.customer_id) as customer_obs
		from foodie_fi.subscriptions s2
		where s2.plan_id = 0
	) s3
	on s.customer_id = s3.customer_id 
	where s.start_date <= '2020/12/31' and s.plan_id in (3)
) s4
group by days_bins
order by days_bins asc;

-- How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
select 
	count(distinct s4.customer_id)
from(
	select 
		s.customer_id,
		s.plan_id,
		s.start_date as basic_sub_date,
		s3.plan_id,
		s3.start_date as pro_annual_sub_date,
		(s.start_date - s3.start_date) as basic_to_pro_days
	from foodie_fi.subscriptions s
	left join (
		select 
			s2.customer_id,
			s2.plan_id,
			s2.start_date 
		from foodie_fi.subscriptions s2
		where s2.plan_id in (3)
	) s3
	on s.customer_id = s3.customer_id
	where s.plan_id in (1) and s3.plan_id = 3
) s4
where s4.basic_to_pro_days > 0;

-- C. Challenge Payment Question
-- The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:

-- monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
-- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
-- upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
-- once a customer churns they will no longer make payments
-- Example outputs for this table might look like the following:

-- customer_id	plan_id	plan_name	payment_date	amount	payment_order
-- 1	1	basic monthly	2020-08-08	9.90	1
-- 1	1	basic monthly	2020-09-08	9.90	2
-- 1	1	basic monthly	2020-10-08	9.90	3
-- 1	1	basic monthly	2020-11-08	9.90	4
-- 1	1	basic monthly	2020-12-08	9.90	5
-- 2	3	pro annual	2020-09-27	199.00	1

select 
	tab3.customer_id,
	tab3.plan_id,
	tab3.plan_name,
	cast(to_char(tab3.start_date  + interval '1 month' * n, 'YYYY-MM-DD') as date) AS payment_date,
	tab3.price as amount,
	row_number() over(partition by tab3.customer_id) as payment_ord
from(
	select
	tab2.customer_id,
	tab2.plan_id,
	tab2.plan_name,
	tab2.start_date,
	tab2.end_date,
	EXTRACT(year FROM age(tab2.end_date, tab2.start_date))*12 + extract(month from age(tab2.end_date, tab2.start_date)) as months_to_end,
	tab2.price
	from(
		select
			tab1.customer_id,
			tab1.plan_id,
			tab1.plan_name,
			tab1.start_date,
			tab1.price,
			LEAD (tab1.start_date, 1) OVER (partition by tab1.customer_id) as next_date,
			case 
				when LEAD (tab1.start_date, 1) OVER (partition by tab1.customer_id) is null then case 
					when tab1.plan_id = 4 then tab1.start_date
					else current_date
				end
				else LEAD (tab1.start_date, 1) OVER (partition by tab1.customer_id)
			end as end_date
		from(
			select
				s.customer_id,
				s.plan_id,
				p.plan_name,
				s.start_date,
				p.price
			from foodie_fi.subscriptions s 
			left join
			foodie_fi."plans" p 
			on s.plan_id = p.plan_id
			where s.plan_id != 0
			order by s.customer_id asc, s.start_date asc
		) tab1
	) tab2
	where tab2.plan_id != 4
) tab3,
generate_series(0, tab3.months_to_end - 1) AS x(n);

-- D. Outside The Box Questions
-- The following are open ended questions which might be asked during a technical interview for this case study - there are no right or wrong answers, but answers that make sense from both a technical and a business perspective make an amazing impression!

-- How would you calculate the rate of growth for Foodie-Fi?
-- One simple option is to compute the monthly rate of growth in revenue
select 
	tab_sales1.my_date,
	tab_sales1.revenue as current_revenue,
	lag(tab_sales1.revenue, 1) over(order by tab_sales1.my_date) as prev_month_sale,
	round(100*(tab_sales1.revenue - lag(tab_sales1.revenue, 1) over(order by tab_sales1.my_date)) / (lag(tab_sales1.revenue, 1) over(order by tab_sales1.my_date)),2)  as revenue_month_variation,
	round(100 * (tab_sales1.revenue - first_value(tab_sales1.revenue) over(order by tab_sales1.my_date)) / (first_value(tab_sales1.revenue) over (order by tab_sales1.my_date)), 2) as revenue_index_variation
from(
	select 
		to_char(tab4.payment_date, 'YYYY-MM') my_date,
		sum(tab4.amount) as revenue
	from(
		select 
			tab3.customer_id,
			tab3.plan_id,
			tab3.plan_name,
			cast(to_char(tab3.start_date  + interval '1 month' * n, 'YYYY-MM-DD') as date) AS payment_date,
			tab3.price as amount,
			row_number() over(partition by tab3.customer_id) as payment_ord
		from(
			select
			tab2.customer_id,
			tab2.plan_id,
			tab2.plan_name,
			tab2.start_date,
			tab2.end_date,
			EXTRACT(year FROM age(tab2.end_date, tab2.start_date))*12 + extract(month from age(tab2.end_date, tab2.start_date)) as months_to_end,
			tab2.price
			from(
				select
					tab1.customer_id,
					tab1.plan_id,
					tab1.plan_name,
					tab1.start_date,
					tab1.price,
					LEAD (tab1.start_date, 1) OVER (partition by tab1.customer_id) as next_date,
					case 
						when LEAD (tab1.start_date, 1) OVER (partition by tab1.customer_id) is null then case 
							when tab1.plan_id = 4 then tab1.start_date
							else current_date
						end
						else LEAD (tab1.start_date, 1) OVER (partition by tab1.customer_id)
					end as end_date
				from(
					select
						s.customer_id,
						s.plan_id,
						p.plan_name,
						s.start_date,
						p.price
					from foodie_fi.subscriptions s 
					left join
					foodie_fi."plans" p 
					on s.plan_id = p.plan_id
					where s.plan_id != 0
					order by s.customer_id asc, s.start_date asc
				) tab1
			) tab2
			where tab2.plan_id != 4
		) tab3,
		generate_series(0, tab3.months_to_end - 1) AS x(n)
	) tab4
	group by my_date
	order by my_date asc
) tab_sales1;

-- What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?
-- What are some key customer journeys or experiences that you would analyse further to improve customer retention?
-- If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?
-- What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?
