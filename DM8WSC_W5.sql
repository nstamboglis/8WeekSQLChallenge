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
SELECT
	extract(dow from tab1.week_date) as day_of_the_week,
    tab1.week_number
FROM(
  SELECT 
      TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE as week_date, 
      extract(week from TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE) as week_number
  FROM data_mart.weekly_sales
) tab1;
