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

-- 1.5 What is the total count of transactions for each platform
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
	my_ds.platform,
    sum(my_ds.transactions) as n_transactions
FROM my_ds
GROUP BY my_ds.platform
ORDER BY my_ds.platform;

-- 1.6 What is the percentage of sales for Retail vs Shopify for each month?
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
	tab1.year_month,
    tab1.platform,
    round((tab1.n_transactions::decimal / tab2.n_transactions_total::decimal), 2) as transactions_perc
FROM(
  SELECT
      concat(year_number, month_number) as year_month,
  	  my_ds.platform,
      sum(my_ds.transactions) as n_transactions
  FROM my_ds
  GROUP BY concat(year_number, month_number), my_ds.platform
) tab1
LEFT JOIN (SELECT
      concat(year_number, month_number) as year_month,
      sum(my_ds.transactions) as n_transactions_total
  FROM my_ds
  GROUP BY concat(year_number, month_number)
) tab2
ON tab1.year_month = tab2.year_month
ORDER BY tab1.year_month ASC, tab1.platform ASC;

-- 1.7 What is the percentage of sales by demographic for each year in the dataset?
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
	tab1.year,
    tab1.demographic,
    round((tab1.n_transactions::decimal / tab2.n_transactions_total::decimal), 2) as transactions_perc
FROM(
  SELECT
      my_ds.year,
  	  my_ds.demographic,
      sum(my_ds.transactions) as n_transactions
  FROM my_ds
  GROUP BY my_ds.year, my_ds.demographic
) tab1
LEFT JOIN (SELECT
      my_ds.year,
      sum(my_ds.transactions) as n_transactions_total
  FROM my_ds
  GROUP BY my_ds.year
) tab2
ON tab1.year = tab2.year
ORDER BY tab1.year ASC, tab1.demographic ASC;

-- 1.8 Which age_band and demographic values contribute the most to Retail sales?
WITH my_ds AS (
  SELECT 
    TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE AS week_date, 
    extract(week FROM TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE) AS week_number, 
    extract(month FROM TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE) AS month_number,
    extract(year FROM TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE) AS year,
    extract(year FROM TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE) AS year_number,
    platform,
    region,
    CASE
      WHEN segment LIKE '%1' THEN 'Young Adults'
      WHEN segment LIKE '%2' THEN 'Middle Aged'
      WHEN segment LIKE ANY(ARRAY['%3', '%4']) THEN 'Retirees'
      WHEN segment = 'null' THEN 'Unknown'
    END AS age_band,
    CASE
      WHEN segment LIKE 'C%' THEN 'Couples'
      WHEN segment LIKE 'F%' THEN 'Families'
      WHEN segment = 'null' THEN 'Unknown'
    END AS demographic,
    CASE
      WHEN segment != 'null' THEN segment
      WHEN segment = 'null' THEN 'Unknown'
    END AS segment,
    customer_type,
    transactions,
    sales,
    round((sales::numeric / transactions::numeric), 2) AS avg_transaction 
  FROM data_mart.weekly_sales
),
tab1 AS (
  SELECT
    my_ds.year,
    my_ds.demographic,
    sum(my_ds.transactions) AS n_transactions
  FROM my_ds
  WHERE my_ds.platform = 'Retail'
  GROUP BY my_ds.year, my_ds.demographic
),
tab2 AS (
  SELECT
    my_ds.year,
    sum(my_ds.transactions) AS n_transactions_total
  FROM my_ds
  WHERE my_ds.platform = 'Retail'
  GROUP BY my_ds.year
),
taba AS (
  SELECT
    my_ds.year,
    my_ds.age_band,
    sum(my_ds.transactions) AS n_transactions
  FROM my_ds
  WHERE my_ds.platform = 'Retail'
  GROUP BY my_ds.year, my_ds.age_band
),
tabb AS (
  SELECT
    my_ds.year,
    sum(my_ds.transactions) AS n_transactions_total
  FROM my_ds
  WHERE my_ds.platform = 'Retail'
  GROUP BY my_ds.year
)
SELECT 
  tab1.year,
  tab1.demographic AS group_name,
  round((tab1.n_transactions::decimal / tab2.n_transactions_total::decimal) * 100, 2) AS transactions_perc
FROM tab1
LEFT JOIN tab2 ON tab1.year = tab2.year
UNION
SELECT 
  taba.year,
  taba.age_band AS group_name,
  round((taba.n_transactions::decimal / tabb.n_transactions_total::decimal) * 100, 2) AS transactions_perc
FROM taba
LEFT JOIN tabb ON taba.year = tabb.year
ORDER BY year ASC, group_name ASC;

-- 1.9 Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

-- We cannot use the avg_transaction colum as it would imply using the mean of the mean. Instead we need to use the approach below:
WITH my_ds AS (
  SELECT 
    TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE AS week_date, 
    extract(week FROM TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE) AS week_number, 
    extract(month FROM TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE) AS month_number,
    extract(year FROM TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE) AS year_number,
    platform,	
    CASE
      WHEN segment like '%1' THEN 'Young Adults'
      WHEN segment like '%2' THEN 'Middle Aged'
      WHEN segment like ANY(ARRAY['%3', '%4']) THEN 'Retirees'
      WHEN segment IS NULL THEN 'Unknown'
    END AS age_band,
    CASE
      WHEN segment like 'C%' THEN 'Couples'
      WHEN segment like 'F%' THEN 'Families'
      WHEN segment IS NULL THEN 'Unknown'
    END AS demographic,
    CASE
      WHEN segment IS NOT NULL THEN segment
      ELSE 'Unknown'
    END AS segment,
    customer_type,	
    transactions,	
    sales,
    ROUND((sales::numeric / transactions::numeric), 2) AS avg_transaction 
  FROM data_mart.weekly_sales
),
my_ds_analysis AS (
  SELECT 
    AVG(avg_transaction) AS avg_avg_transaction,
    SUM(sales) AS total_sales,
    SUM(transactions) AS total_transactions,
    year_number, 
    platform
  FROM my_ds
  GROUP BY year_number, platform
)
SELECT
  year_number, 
  platform,
  ROUND(total_sales::numeric / total_transactions::numeric, 2) AS avg_transaction
FROM my_ds_analysis
ORDER BY my_ds_analysis.year_number, my_ds_analysis.platform;

-- 3.1 Variation in growth 4 weeks before and after the packaging date
WITH my_ds AS (
  SELECT 
  	TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE AS week_date, 
    extract(week FROM TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE) AS week_number, 
    extract(month FROM TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE) AS month_number,
    extract(year FROM TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE) AS year_number,
    platform,	
    CASE
      WHEN segment like '%1' THEN 'Young Adults'
      WHEN segment like '%2' THEN 'Middle Aged'
      WHEN segment like ANY(ARRAY['%3', '%4']) THEN 'Retirees'
      WHEN segment IS NULL THEN 'Unknown'
    END AS age_band,
    CASE
      WHEN segment like 'C%' THEN 'Couples'
      WHEN segment like 'F%' THEN 'Families'
      WHEN segment IS NULL THEN 'Unknown'
    END AS demographic,
    CASE
      WHEN segment IS NOT NULL THEN segment
      ELSE 'Unknown'
    END AS segment,
    customer_type,	
    transactions,	
    sales,
    ROUND((sales::numeric / transactions::numeric), 2) AS avg_transaction 
  FROM data_mart.weekly_sales
),
my_ds_analysis as(SELECT 
	*,
	CASE
    	WHEN week_date >= '2020-06-15' then 'after'
        ELSE 'before'
    END as packaging_date,
    EXTRACT(WEEK FROM my_ds.week_date)- EXTRACT(WEEK FROM '2020-06-15'::date) as packaging_date_diff
FROM my_ds),
	my_ds_results as (SELECT 
	my_ds_analysis.packaging_date,
    sum(my_ds_analysis.sales) as sales
FROM my_ds_analysis
WHERE ABS(my_ds_analysis.packaging_date_diff) <= 4
GROUP BY my_ds_analysis.packaging_date
ORDER BY my_ds_analysis.packaging_date DESC)
SELECT
	my_ds_results.packaging_date,
    my_ds_results.sales,
    round(my_ds_results.sales::numeric /(SELECT my_ds_results.sales FROM my_ds_results WHERE my_ds_results.packaging_date = 'before')::numeric, 2) * 100 as sales_growth,
round(my_ds_results.sales::numeric /(SELECT sum(my_ds_results.sales) FROM my_ds_results)::numeric, 2) * 100 as sales_perc
FROM my_ds_results;

-- 3.2 Same as above, but in 12 weeks
WITH my_ds AS (
  SELECT 
  	TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE AS week_date, 
    extract(week FROM TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE) AS week_number, 
    extract(month FROM TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE) AS month_number,
    extract(year FROM TO_DATE(week_date, 'dd/mm/yy')::TIMESTAMP::DATE) AS year_number,
    platform,	
    CASE
      WHEN segment like '%1' THEN 'Young Adults'
      WHEN segment like '%2' THEN 'Middle Aged'
      WHEN segment like ANY(ARRAY['%3', '%4']) THEN 'Retirees'
      WHEN segment IS NULL THEN 'Unknown'
    END AS age_band,
    CASE
      WHEN segment like 'C%' THEN 'Couples'
      WHEN segment like 'F%' THEN 'Families'
      WHEN segment IS NULL THEN 'Unknown'
    END AS demographic,
    CASE
      WHEN segment IS NOT NULL THEN segment
      ELSE 'Unknown'
    END AS segment,
    customer_type,	
    transactions,	
    sales,
    ROUND((sales::numeric / transactions::numeric), 2) AS avg_transaction 
  FROM data_mart.weekly_sales
),
my_ds_analysis as(SELECT 
	*,
	CASE
    	WHEN week_date >= '2020-06-15' then 'after'
        ELSE 'before'
    END as packaging_date,
    EXTRACT(WEEK FROM my_ds.week_date)- EXTRACT(WEEK FROM '2020-06-15'::date) as packaging_date_diff
FROM my_ds),
	my_ds_results as (SELECT 
	my_ds_analysis.packaging_date,
    sum(my_ds_analysis.sales) as sales
FROM my_ds_analysis
WHERE ABS(my_ds_analysis.packaging_date_diff) <= 12
GROUP BY my_ds_analysis.packaging_date
ORDER BY my_ds_analysis.packaging_date DESC)
SELECT
	my_ds_results.packaging_date,
    my_ds_results.sales,
    round(my_ds_results.sales::numeric /(SELECT my_ds_results.sales FROM my_ds_results WHERE my_ds_results.packaging_date = 'before')::numeric, 2) * 100 as sales_growth,
round(my_ds_results.sales::numeric /(SELECT sum(my_ds_results.sales) FROM my_ds_results)::numeric, 2) * 100 as sales_perc
FROM my_ds_results;