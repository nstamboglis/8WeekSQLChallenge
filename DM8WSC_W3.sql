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
-- What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
-- What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
-- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
-- How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
-- What is the number and percentage of customer plans after their initial free trial?
-- What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
-- How many customers have upgraded to an annual plan in 2020?
-- How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
-- Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
-- How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

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

-- D. Outside The Box Questions
-- The following are open ended questions which might be asked during a technical interview for this case study - there are no right or wrong answers, but answers that make sense from both a technical and a business perspective make an amazing impression!

-- How would you calculate the rate of growth for Foodie-Fi?
-- What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?
-- What are some key customer journeys or experiences that you would analyse further to improve customer retention?
-- If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?
-- What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?
