-- Author: Nick
-- Date: Mar 2022

-- Description: This file contains the data cleaning for DM's 8WSC Week 2 databases.

-- DATA PREP
-- Before you start writing your SQL queries however - you might want to investigate the data, 
-- you may want to do something with some of those null values and data types in the customer_orders and runner_orders tables!

-- Fix nulls in pizza_runner.customer_orders column .exclusions 
 UPDATE pizza_runner.customer_orders  
SET exclusions = null
WHERE exclusions = 'null' or exclusions = '';
-- Fix customer_order.extras column.extras
UPDATE pizza_runner.customer_orders  
SET extras = null
WHERE extras = 'null' or extras = '';

-- Fix nulls in pizza_runner.runner_orders 
UPDATE pizza_runner.runner_orders   
SET pickup_time  = null
WHERE pickup_time = 'null' or pickup_time = '';

UPDATE pizza_runner.runner_orders   
SET distance  = null
WHERE distance = 'null' or distance = '';

-- Fix runner_orders.distance to numeric and NULLS fix
UPDATE pizza_runner.runner_orders   
SET distance  = translate(distance,'km','');

ALTER TABLE pizza_runner.runner_orders ALTER COLUMN distance TYPE numeric(10,1) USING cast(distance as numeric);

UPDATE pizza_runner.runner_orders   
SET cancellation  = null
WHERE cancellation = 'null' or cancellation = '';

-- Fix runner_orders.drationsistance to numeric and NULLS fix
UPDATE pizza_runner.runner_orders   
SET duration  = null
WHERE duration = 'null';

UPDATE pizza_runner.runner_orders   
SET duration  = translate(
						translate(
							translate(duration, 'minutes',''),
									'mins', ''),
								'minute', '');

ALTER TABLE pizza_runner.runner_orders 
	ALTER COLUMN duration TYPE numeric(10,1) 
		USING duration::numeric(10,1);

