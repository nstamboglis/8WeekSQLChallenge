-- Author: Nick
-- Date: Mar 2022

-- Description: This file contains the queries for DM's 8WSC Week 2 cleaned databases.

-- NOTE:
-- 	1. I assume that order ID 4 of pizza_runner.customer_orders is not replicated for pizza_id 1 (the orders of the same pizzas were made at the same time). In real life I'd ask DBAs for clarification.

-- A. Pizza Metrics
-- How many pizzas were ordered?
-- NOTE: I assume that the question refers to the total number of orders (and not how many orders were not cancelled)
select 
	count(co.pizza_id) as n_orders
from pizza_runner.customer_orders co;

-- How many unique customer orders were made?
select 
	count(distinct concat(co.pizza_id, co.exclusions, co.extras)) as n_orders_unique
from pizza_runner.customer_orders co;

-- How many successful orders were delivered by each runner?
select 
	runner_orders.runner_id, count(customer_orders.order_id) as n_orders
from pizza_runner.customer_orders 
left join pizza_runner.runner_orders 
on customer_orders.order_id = runner_orders.order_id
where runner_orders.cancellation is null
group by runner_orders.runner_id
order by runner_orders.runner_id asc;

-- How many of each type of pizza was delivered?
select count(customer_orders.pizza_id) as n_orders, customer_orders.pizza_id 
from pizza_runner.customer_orders 
left join pizza_runner.runner_orders 
on customer_orders.order_id = runner_orders.order_id
where runner_orders.cancellation is null
group by customer_orders.pizza_id
order by customer_orders.pizza_id 

-- How many Vegetarian and Meatlovers were ordered by each customer?
select customer_orders.customer_id, pizza_names.pizza_name, count(customer_orders.pizza_id) as n_orders
from pizza_runner.customer_orders 
left join pizza_runner.pizza_names
on customer_orders.pizza_id  = pizza_names.pizza_id 
group by customer_orders.customer_id, pizza_names.pizza_name
order by customer_orders.customer_id, pizza_names.pizza_name;

-- What was the maximum number of pizzas delivered in a single order?
select count(customer_orders.pizza_id) as count_n_orders, customer_orders.order_id 
from pizza_runner.customer_orders
left join pizza_runner.runner_orders 
on customer_orders.order_id = runner_orders.order_id
where runner_orders.cancellation is null
group by customer_orders.order_id
order by count_n_orders desc
limit 1;

-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
-- NOTE: I assume the questions refers to the fields customers_orders.addition or customer_orders.extra. 
select count(tab1.pizza_id) as pizza_count, tab1.customer_id, tab1.changes 
from(
	select 
		customer_orders.pizza_id, 
		customer_orders.customer_id, 
		coalesce(char_length(translate(exclusions, ', ', '')), 0) as n_exclusions, 
		coalesce(char_length(translate(extras, ', ', '')), 0) as n_extras,
		coalesce(char_length(translate(exclusions, ', ', '')), 0) + coalesce(char_length(translate(extras, ', ', '')), 0) as n_changes,
		case when coalesce(char_length(translate(exclusions, ', ', '')), 0) + coalesce(char_length(translate(extras, ', ', '')), 0) > 0 then '1' else '0' end changes
	from pizza_runner.customer_orders
	left join pizza_runner.runner_orders 
	on customer_orders.order_id = runner_orders.order_id
	where runner_orders.cancellation is null) tab1
group by tab1.customer_id, tab1.changes 
order by pizza_count desc;

-- How many pizzas were delivered that had both exclusions and extras?
select count(pizza_id)
from(
	select 
		customer_orders.pizza_id, 
		customer_orders.customer_id, 
		coalesce(char_length(translate(exclusions, ', ', '')), 0) as n_exclusions, 
		coalesce(char_length(translate(extras, ', ', '')), 0) as n_extras,
		coalesce(char_length(translate(exclusions, ', ', '')), 0) + coalesce(char_length(translate(extras, ', ', '')), 0) as n_changes,
		case when coalesce(char_length(translate(exclusions, ', ', '')), 0) + coalesce(char_length(translate(extras, ', ', '')), 0) > 0 then '1' else '0' end changes
	from pizza_runner.customer_orders
	left join pizza_runner.runner_orders 
	on customer_orders.order_id = runner_orders.order_id
	where runner_orders.cancellation is null
	) tab1
where tab1.n_exclusions >0 and tab1.n_extras >0;

-- What was the total volume of pizzas ordered for each hour of the day?
select tab1.order_hour , count(tab1.pizza_id) as n_pizzas
from(
	select 
		customer_orders.pizza_id, 
		customer_orders.customer_id, 
		coalesce(char_length(translate(exclusions, ', ', '')), 0) as n_exclusions, 
		coalesce(char_length(translate(extras, ', ', '')), 0) as n_extras,
		coalesce(char_length(translate(exclusions, ', ', '')), 0) + coalesce(char_length(translate(extras, ', ', '')), 0) as n_changes,
		case when coalesce(char_length(translate(exclusions, ', ', '')), 0) + coalesce(char_length(translate(extras, ', ', '')), 0) > 0 then '1' else '0' end changes,
		extract(hour from customer_orders.order_time) as order_hour
	from pizza_runner.customer_orders
) tab1 
group by tab1.order_hour 
order by tab1.order_hour asc;

-- What was the volume of orders for each day of the week?
select tab1.order_dow, count(tab1.pizza_id) as n_pizzas
from(
	select 
		customer_orders.pizza_id, 
		customer_orders.customer_id, 
		coalesce(char_length(translate(exclusions, ', ', '')), 0) as n_exclusions, 
		coalesce(char_length(translate(extras, ', ', '')), 0) as n_extras,
		coalesce(char_length(translate(exclusions, ', ', '')), 0) + coalesce(char_length(translate(extras, ', ', '')), 0) as n_changes,
		case when coalesce(char_length(translate(exclusions, ', ', '')), 0) + coalesce(char_length(translate(extras, ', ', '')), 0) > 0 then '1' else '0' end changes,
		to_char(customer_orders.order_time, 'Day') as order_dow
	from pizza_runner.customer_orders
) tab1 
group by tab1.order_dow 
order by tab1.order_dow desc;

-- B. Runner and Customer Experience
-- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
select  
	((registration_date - date '2021-01-01') / 7)+1 as my_date, 
	count(runners.runner_id) 
from pizza_runner.runners
group by my_date
order by my_date asc;

-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
select distinct on(tab1.order_id) tab1.order_id, round( extract(epoch from (tab1.order_time_adj - tab1.order_time_dj)) /60 ::numeric,2) as minutes
from(
	select customer_orders.order_id, to_timestamp(cast(customer_orders.order_time as text), 'yyyy/mm/dd hh24:mi:ss') as order_time_adj, to_timestamp(runner_orders.pickup_time, 'yyyy/mm/dd hh24:mi:ss') as order_time_dj
	from pizza_runner.customer_orders
	left join pizza_runner.runner_orders
	on customer_orders.order_id = runner_orders.order_id
	where runner_orders.cancellation is null
) tab1
order by tab1.order_id asc;

-- Is there any relationship between the number of pizzas and how long the order takes to prepare?
select corr(tab3.minutes, tab2.n_pizzas)
from(
	select distinct on(tab1.order_id) tab1.order_id, round( extract(epoch from (tab1.order_time_adj - tab1.order_time_dj)) /60 ::numeric,2) as minutes
	from(
		select customer_orders.order_id, to_timestamp(cast(customer_orders.order_time as text), 'yyyy/mm/dd hh24:mi:ss') as order_time_adj, to_timestamp(runner_orders.pickup_time, 'yyyy/mm/dd hh24:mi:ss') as order_time_dj
		from pizza_runner.customer_orders
		left join pizza_runner.runner_orders
		on customer_orders.order_id = runner_orders.order_id
		where runner_orders.cancellation is null
	) tab1
order by tab1.order_id asc) tab3
left join (
	select customer_orders.order_id, count(customer_orders.pizza_id) as n_pizzas
	from pizza_runner.customer_orders
	left join pizza_runner.runner_orders
	on customer_orders.order_id = runner_orders.order_id
	where runner_orders.cancellation is null
	group by customer_orders.order_id
) tab2 
on tab3.order_id = tab2.order_id;

-- What was the average distance travelled for each customer?
select distinct on(customer_orders.order_id) customer_orders.customer_id, round(avg(runner_orders.distance),2) as mean_distance
from pizza_runner.customer_orders
left join pizza_runner.runner_orders
on customer_orders.order_id = runner_orders.order_id
where runner_orders.cancellation is null
group by customer_orders.customer_id, customer_orders.order_id; 

-- What was the difference between the longest and shortest delivery times for all orders?
select max(tab2.minutes) - min(tab2.minutes) as delta
from(
	select distinct on(tab1.order_id) tab1.order_id, round( extract(epoch from (tab1.order_time_dj - tab1.order_time_adj)) /60 ::numeric,2) as minutes
	from(
		select customer_orders.order_id, to_timestamp(cast(customer_orders.order_time as text), 'yyyy/mm/dd hh24:mi:ss') as order_time_adj, to_timestamp(runner_orders.pickup_time, 'yyyy/mm/dd hh24:mi:ss') as order_time_dj
		from pizza_runner.customer_orders
		left join pizza_runner.runner_orders
		on customer_orders.order_id = runner_orders.order_id
		where runner_orders.cancellation is null
	) tab1)
tab2;

-- What was the average speed for each runner for each delivery and do you notice any trend for these values?
select 
	distinct customer_orders.order_time, customer_orders.order_id, runner_orders.runner_id, 
	(runner_orders.distance / runner_orders.duration) as speed
from pizza_runner.customer_orders
left join pizza_runner.runner_orders
on customer_orders.order_id = runner_orders.order_id
where runner_orders.cancellation is null
order by customer_orders.order_id;
-- Speed always increasing for runner number 2

-- What is the successful delivery percentage for each runner?
select 
	tab1.runner_id, 
	round((tab1.n_cancellations / tab1.n_orders) *100::numeric, 2) as perc_canc
from(
	select 
		count(*)::numeric as n_orders, 
		count(runner_orders.cancellation)::numeric as n_cancellations,
		runner_orders.runner_id
	from pizza_runner.runner_orders
	group by runner_orders.runner_id
) tab1
order by perc_canc desc;

-- C. Ingredient Optimisation
-- What are the standard ingredients for each pizza?
select 
	tab4.pizza_name,
	array_to_string(array_agg(tab3.topping_name), ', ') as topping_string
	--tab3.topping_name
from(
	select 
		tab1.pizza_id, 
		tab2.topping_name 
	from(
		select pizza_id, cast(unnest(string_to_array(toppings, ',')) as int) AS my_topping
		from pizza_runner.pizza_recipes) tab1
	left join pizza_runner.pizza_toppings tab2
	on my_topping = tab2.topping_id) tab3
left join pizza_runner.pizza_names tab4
on tab3.pizza_id = tab4.pizza_id
group by tab4.pizza_name;

-- What was the most commonly added extra?
select 
	count(*) as n_times,
	extras
from (
	select 
		unnest(string_to_array(co.extras, ',')) as extras
	from pizza_runner.customer_orders co
	where co.extras is not null) tab1
group by extras
order by extras desc;

-- What was the most common exclusion?
select 
	count(*) as n_times,
	exclusions
from (
	select 
		unnest(string_to_array(co.exclusions, ',')) as exclusions
	from pizza_runner.customer_orders co
	where co.exclusions is not null) tab1
group by exclusions
order by exclusions desc;

-- Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
select
	replace(pizza_array, 'EXTRA {NULL} EXCLUDE {NULL}', '') as pizza_name_adj,
	tab3.order_id,
	tab3.customer_id,
	tab3.order_time
from(
select
	tab2.order_id,
	tab2.customer_id,
	tab2.order_time,
	concat(tab2.pizza_name, ' EXTRA ',	cast(array_agg(extras_name) as varchar(50)), ' EXCLUDE ', array_agg(exclusions_name)) as pizza_array
from(
	select 
		DISTINCT ON (tab1.order_id, tab1.customer_id, tab1.order_time, tab1.pizza_name, pt.topping_name, ptexc.topping_name)	
		tab1.order_id,
		tab1.customer_id,
		tab1.order_time,
		tab1.pizza_name,
		pt.topping_name as extras_name,
		ptexc.topping_name as exclusions_name
	from(
		select
			co.order_id,
			co.customer_id,
			co.order_time,
			pn.pizza_name,
			unnest(string_to_array(coalesce(co.extras, '0'), ',')) as extras,
			unnest(string_to_array(coalesce(co.exclusions, '0'), ',')) as exclusions
		from pizza_runner.customer_orders co 
		left join pizza_runner.pizza_names pn 
		on pn.pizza_id  = co.pizza_id
	) tab1
	left join pizza_runner.pizza_toppings pt 
	on cast(pt.topping_id as character) = tab1.extras 
	left join pizza_runner.pizza_toppings ptexc 
	on cast(ptexc.topping_id as character) = tab1.exclusions 
) tab2
group by order_id, 	tab2.customer_id, 	tab2.order_time, tab2.pizza_name
)tab3
;

-- Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
select 
	concat(tab4.pizza_name, ': ', tab4.myingredients) as order_ingredient_list
from(
select 
	tab3.order_id,
	tab3.pizza_name, 
	STRING_AGG(tab3.topping_adj, ', ') as myingredients
from(
	select 
		tab2.order_id,
		tab2.pizza_name,
		case 
			when tab2.occurences > 1 then concat(tab2.occurences, 'x', tab2.topping_name)
			else tab2.topping_name
		end as topping_adj
	from(
		select 
			tab1.order_id,
			pn.pizza_name,
			tab1.custom_toppings,
			pt.topping_name,
			sum(tab1.topping_adder) as occurences
		from(
			select 
				co.order_id,
				co.pizza_id,
				trim(unnest(string_to_array(coalesce(pr.toppings , '0'), ','))) as custom_toppings,
				1 as topping_adder
			from 
				pizza_runner.pizza_recipes pr
			right join
				pizza_runner.customer_orders co 
			on pr.pizza_id = co.pizza_id
			union all
			select 
				co.order_id ,
				co.pizza_id,
				trim(unnest(string_to_array(coalesce(co.exclusions, '0'), ','))) as custom_toppings,
				-1 as topping_adder
			from pizza_runner.customer_orders co
			union all
			select 
				co.order_id ,
				co.pizza_id,
				trim(unnest(string_to_array(coalesce(co.extras, '0'), ','))) as custom_toppings,	
				1 as topping_adder
			from pizza_runner.customer_orders co
		) tab1
		left join pizza_runner.pizza_names pn on tab1.pizza_id = pn.pizza_id 
		left join pizza_runner.pizza_toppings pt on cast(tab1.custom_toppings as numeric) = pt.topping_id 
		--left join pizza_runner.pizza_toppings pt 
		--on tab1.custom_toppings = pt.topping_id 
		where tab1.custom_toppings != '0'
		group by tab1.order_id, pn.pizza_name, tab1.custom_toppings, pt.topping_name
		order by tab1.order_id, pn.pizza_name, pt.topping_name
	) tab2
) tab3
group by tab3.order_id, tab3.pizza_name
) tab4;

-- What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
select 
	tab2.topping_name,
	sum(tab2.occurences) as occurences_aggr
from(
		select 
			tab1.order_id,
			pn.pizza_name,
			tab1.custom_toppings,
			pt.topping_name,
			sum(tab1.topping_adder) as occurences
		from(
			select 
				co.order_id,
				co.pizza_id,
				trim(unnest(string_to_array(coalesce(pr.toppings , '0'), ','))) as custom_toppings,
				1 as topping_adder
			from 
				pizza_runner.pizza_recipes pr
			right join
				pizza_runner.customer_orders co 
			on pr.pizza_id = co.pizza_id
			union all
			select 
				co.order_id ,
				co.pizza_id,
				trim(unnest(string_to_array(coalesce(co.exclusions, '0'), ','))) as custom_toppings,
				-1 as topping_adder
			from pizza_runner.customer_orders co
			union all
			select 
				co.order_id ,
				co.pizza_id,
				trim(unnest(string_to_array(coalesce(co.extras, '0'), ','))) as custom_toppings,	
				1 as topping_adder
			from pizza_runner.customer_orders co
		) tab1
		left join pizza_runner.pizza_names pn on tab1.pizza_id = pn.pizza_id 
		left join pizza_runner.pizza_toppings pt on cast(tab1.custom_toppings as numeric) = pt.topping_id 
		--left join pizza_runner.pizza_toppings pt 
		--on tab1.custom_toppings = pt.topping_id 
		where tab1.custom_toppings != '0'
		group by tab1.order_id, pn.pizza_name, tab1.custom_toppings, pt.topping_name
		order by tab1.order_id, pn.pizza_name, pt.topping_name
) tab2
group by topping_name
order by occurences_aggr desc, topping_name asc;

-- D. Pricing and Ratings
-- If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

select 	
	sum(tab1.pizza_money) as pizza_runner_total
from(
	select 
		co.order_id,
		co.pizza_id,
		pn.pizza_name,
		case 
			when pn.pizza_name = 'Meatlovers' then 12
			else 10
		end as pizza_money
	from pizza_runner.customer_orders co 
	left join pizza_runner.pizza_names pn on co.pizza_id = pn.pizza_id 
) tab1

-- What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra
select 
	sum(order_total) as total
from(
	select 
		tab_pizza_totals.order_id,
		tab_pizza_totals.pizza_total + coalesce(tab_extras.extras_tot, 0) as order_total
	from(
		select 	
			tab_pizza.order_id,
			sum(tab_pizza.pizza_money) as pizza_total
			--tab_extras.extras_tot
		from(
			select 
				co.order_id,
				co.pizza_id,
				pn.pizza_name,
				case 
					when pn.pizza_name = 'Meatlovers' then 12
					else 10
				end as pizza_money
			from pizza_runner.customer_orders co 
			left join pizza_runner.pizza_names pn on co.pizza_id = pn.pizza_id 
		) tab_pizza
		group by order_id
	) tab_pizza_totals
	left join (
		select 
			tab2.order_id,
			tab2.pizza_name,
			sum(extras_money) as extras_tot
		from(
			select 
				tab1.order_id,
				tab1.pizza_name,
				coalesce(pt.topping_name, '-') as topping_extra,
				case 
					when coalesce(pt.topping_name, '-') = '-' then 0
					when coalesce(pt.topping_name, '-') = 'Cheese' then 2
					else 1
				end as extras_money
			from(
			select 
				co.order_id,
				co.pizza_id,
				pn.pizza_name,
				trim(unnest(string_to_array(coalesce(co.extras, '0'), ','))) as custom_extras,	
				case 
					when pn.pizza_name = 'Meatlovers' then 12
					else 10
				end as pizza_money
			from pizza_runner.customer_orders co 
			left join pizza_runner.pizza_names pn on co.pizza_id = pn.pizza_id
			) tab1
			left join pizza_runner.pizza_toppings pt on cast(tab1.custom_extras as numeric) = pt.topping_id
			where tab1.custom_extras != '0'
		) tab2
		group by order_id, pizza_name
	) tab_extras
	on tab_pizza_totals.order_id = tab_extras.order_id
) tab_orders;


-- The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
DROP TABLE IF EXISTS pizza_runner.ratings;
CREATE TABLE pizza_runner.ratings (
  "order_id" INTEGER,
  "customer_id" INTEGER,
  "runner_id" INTEGER,
  "rating" INTEGER
);
INSERT INTO pizza_runner.ratings
  ("order_id", "customer_id", "runner_id", "rating")
select 
	distinct customer_orders.order_id,
	customer_orders.customer_id,
	ro.runner_id,
	cast(trunc(random() * 5 + 1) as int) as rating
from 
	pizza_runner.customer_orders
left join 
	pizza_runner.runner_orders ro 
	on  customer_orders.order_id = ro.order_id 
;

select 
	distinct customer_orders.order_id,
	customer_orders.customer_id,
	ro.runner_id,
	trunc(random() * 5 + 1) as rating
from 
	pizza_runner.customer_orders
left join 
	pizza_runner.runner_orders ro 
	on  customer_orders.order_id = ro.order_id ;

-- Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- customer_id
-- order_id
-- runner_id
-- rating
-- order_time
-- pickup_time
-- Time between order and pickup
-- Delivery duration
-- Average speed
-- Total number of pizzas

select 
	rat.order_id,
	rat.customer_id,
	rat.runner_id,
	rat.rating,
	tab_orders.order_time,
	cast(tab_speed.pickup_time as timestamp),
	cast(tab_speed.pickup_time as timestamp)-tab_orders.order_time as delta_order_pickup,
	tab_speed.deliver_duration,
	tab_speed.order_speed,
	tab_orders.n_pizzas
from 
	(select 
		rat_int.order_id,
		rat_int.customer_id,
		rat_int.runner_id,
		rat_int.rating,
		row_number(*) OVER(PARTITION BY rat_int.order_id) AS order_counter
	from 
	pizza_runner.ratings rat_int
	) rat
left join(
	select 
		count(distinct co.pizza_id) as n_pizzas,
		co.order_time,
		co.order_id 
	from pizza_runner.customer_orders co 
	group by co.order_id, co.order_time
) tab_orders
on rat.order_id = tab_orders.order_id
right join(
select 
	ro.order_id,
	ro.pickup_time,
	ro.duration as deliver_duration,
	round(ro.distance / ro.duration, 2)  as order_speed
from pizza_runner.runner_orders ro
where ro.pickup_time is not null
) tab_speed
on rat.order_id = tab_speed.order_id
where rat.order_counter = 1
order by order_id asc; 

-- If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
select 
	sum(pizza_revenue.pizza_net_revenue) as net_revenue
from(
	select 
		pizza_money1.order_id,
		sum(pizza_money1.pizza_price) as pizza_sales,
		avg(pizza_money1.order_distance) * 0.3 as runners_pay,
		sum(pizza_money1.pizza_price)-(avg(pizza_money1.order_distance) * 0.3) pizza_net_revenue
	from(
	select
		co.order_id,
		pn.pizza_name,
		case 
			when pn.pizza_name = 'Meatlovers' then 12
			else 10
		end as pizza_price,
		ro2.distance as order_distance 
	from
		pizza_runner.customer_orders co
	left join
		pizza_runner.pizza_names pn 
	on co.pizza_id = pn.pizza_id 
	left join 
		pizza_runner.runner_orders ro2 
	on co.order_id = ro2.order_id 
	where ro2.cancellation is null
	) pizza_money1
	group by pizza_money1.order_id
) as pizza_revenue;

-- E. Bonus Questions
-- If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?
INSERT INTO pizza_runner.pizza_names values
(3, 'Supreme');

INSERT INTO pizza_runner.pizza_recipes 
("pizza_id", "toppings")
select 	
	3 as pizza_id,
	string_agg(tab1.topping_id, ',') as toppings
from(
	select cast(pt.topping_id as varchar)
	from pizza_runner.pizza_toppings pt
	group by pt.topping_id
	order by pt.topping_id asc
) tab1;

-- NOTES
-- 1. I like the realism of the questions. There was some amibguity (duplicated rows? Meaning of some questions). This ambiguity is what you get in real life.
-- 2. On the pizza changes question I assume he refers to the fields customers_orders.addition or customer_orders.extra. 
-- 3. Importance of details: union vs union all