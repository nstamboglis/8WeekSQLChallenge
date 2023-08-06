-----------------------------------
-- Data with Danny - W5

-- 1. Data cleansing

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
     end as age_band,
    segment,	
    customer_type,	
    transactions,	
    sales
FROM data_mart.weekly_sales;