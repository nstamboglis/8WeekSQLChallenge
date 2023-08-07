-----------------------------------
-- Data with Danny - W5

-- 0. Data cleansing

SELECT 
	TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE as week_date, 
    extract(week from TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE) as week_number, 
    extract(month from TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE) as month_number,
    extract(year from TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE) as year_number,
    platform,	
    case
    	when segment like '%1' then 'Young Adults'
        when segment like '%2' then 'Middle Aged'
        when segment like ANY(ARRAY['%3', '%4']) then 'Retirees'
        when segment = 'null' then 'Unknown'
     end as age_band,
    case
    	when segment like 'C%' then 'Couples'
        when segment like 'F%' then 'Families'
        when segment = 'null' then 'Unknown'
     end as demographic,
    case
    	when segment != 'null' then segment
        when segment = 'null' then 'Unknown'
    end as segment,
    customer_type,	
    transactions,	
    sales,
    round((sales::numeric / transactions::numeric), 2) as avg_transaction 
FROM data_mart.weekly_sales;

-- 1. Data exploration

-- 1.1 Date of the week
-- Check DOW for each week
SELECT
	distinct tab1.week_number,
    extract(dow from tab1.week_date) as day_of_the_week
FROM(
  SELECT 
      TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE as week_date, 
      extract(week from TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE) as week_number
  FROM data_mart.weekly_sales
) tab1
order by tab1.week_number asc;

-- Check unique DOW
SELECT
    distinct extract(dow from tab1.week_date) as day_of_the_week
FROM(
  SELECT 
      TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE as week_date, 
      extract(week from TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE) as week_number
  FROM data_mart.weekly_sales
) tab1;

-- 1.2 Range of missing weeks
SELECT 
	*
FROM(
	SELECT * FROM GENERATE_SERIES(1, 52) AS weeks_in_a_year
) tab_year
WHERE (tab_year.weeks_in_a_year NOT IN (SELECT
	distinct tab1.week_number
FROM(
  SELECT 
      TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE as week_date, 
      extract(week from TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE) as week_number
  FROM data_mart.weekly_sales
) tab1));

-- 1.3 Total transactions per year
with my_ds as (
  SELECT 
      extract(year from TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE) as year_number,
      transactions 
  FROM data_mart.weekly_sales)
SELECT
	my_ds.year_number,
    sum(my_ds.transactions)
FROM my_ds
GROUP BY my_ds.year_number
ORDER BY my_ds.year_number;

-- 1.4 Total sales per region per month
with my_ds as (
  SELECT 
	TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE as week_date, 
    extract(week from TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE) as week_number, 
    extract(month from TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE) as month_number,
  	extract(year from TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE) as year,
    extract(year from TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE) as year_number,
    platform,	
  	region,
    case
    	when segment like '%1' then 'Young Adults'
        when segment like '%2' then 'Middle Aged'
        when segment like ANY(ARRAY['%3', '%4']) then 'Retirees'
        when segment = 'null' then 'Unknown'
     end as age_band,
    case
    	when segment like 'C%' then 'Couples'
        when segment like 'F%' then 'Families'
        when segment = 'null' then 'Unknown'
     end as demographic,
    case
    	when segment != 'null' then segment
        when segment = 'null' then 'Unknown'
    end as segment,
    customer_type,	
    transactions,	
    sales,
    round((sales::numeric / transactions::numeric), 2) as avg_transaction 
FROM data_mart.weekly_sales)
SELECT
	CONCAT(cast(my_ds.year as varchar), '-', cast(my_ds.month_number as character)) as year_month,
    my_ds.region,
    sum(my_ds.transactions)
FROM my_ds
GROUP BY CONCAT(cast(my_ds.year as varchar), '-', cast(my_ds.month_number as character)), my_ds.region
ORDER BY CONCAT(cast(my_ds.year as varchar), '-', cast(my_ds.month_number as character)), my_ds.region;

