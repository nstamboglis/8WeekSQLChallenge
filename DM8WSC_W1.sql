------------------------
-- Danny Ma's 8 Weeks SQL Challenge
-- Week 1
------------------------

-- Author: Nick
-- Date: Feb 2022

-- Description: This file contains the result queries for DM's 8WSC Week 1.

-- 1. What is the total amount each customer spent at the restaurant?
select A.customer_id, sum(A.expenditure) as tot_expenditure
from(
	select sales.customer_id, sales.product_id, menu.price, (sales.product_id * 	menu.price) as expenditure
	from dannys_diner.sales
	left join dannys_diner.menu on sales.product_id = menu.product_id
  ) A
  group by A.customer_id
  order by A.customer_id;

-- 2. How many days has each customer visited the restaurant?
select sales.customer_id, count(distinct sales.order_date) as n_dinstinct_days
from dannys_diner.sales
group by sales.customer_id
order by n_dinstinct_days desc;

-- 3. What was the first item from the menu purchased by each customer?
select customer_id, product_id
from(
select row_number() over(
  partition by sales.customer_id
  order by sales.order_date asc
  RANGE BETWEEN 
      UNBOUNDED PRECEDING AND 
      UNBOUNDED FOLLOWING) row_number_ind, sales.customer_id, sales.product_id
from dannys_diner.sales) tab1
where row_number_ind = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select sales.product_id, count(product_id)
from dannys_diner.sales
group by sales.product_id
limit 1;

-- 5. Which item was the most popular for each customer?
select table2.customer_id, table2.product_id
from(
	select table1.customer_id, table1.product_id, table1.product_count, 	row_number() over(partition by table1.customer_id) as rnum
	from(
	SELECT sales.customer_id, sales.product_id, count(sales.product_id) as product_count
	from dannys_diner.sales 
	group by sales.customer_id, sales.product_id
	order by sales.customer_id asc, product_count desc
    ) table1
) table2
where table2.rnum = 1;

-- 6. Which item was purchased first by the customer after they became a member?
SELECT table2.customer_id, table2.product_id
FROM(
  SELECT 
      table1.customer_id,
      table1.product_id,
      table1.order_date,
      table1.join_date,
      (table1.order_date - table1.join_date) as days_from_join,
      row_number() over(partition by table1.customer_id) as rownum
  FROM(
      SELECT
          sales.customer_id,
          sales.product_id,
          sales.order_date,
          members.join_date
      FROM dannys_diner.sales
      LEFT JOIN dannys_diner.members ON sales.customer_id = members.customer_id
  ) as table1
  WHERE (table1.order_date - table1.join_date) >= 0
  ORDER BY 
      table1.customer_id desc,
      table1.order_date asc
) table2
WHERE table2.rownum = 1;

-- 7. Which item was purchased just before the customer became a member?
 SELECT table2.customer_id, table2.product_id
 FROM (
 SELECT 
      table1.customer_id,
      table1.product_id,
      table1.order_date,
      table1.join_date,
      (table1.order_date - table1.join_date) as days_from_join,
      row_number() over(partition by table1.customer_id) as rownum
  FROM(
      SELECT
          sales.customer_id,
          sales.product_id,
          sales.order_date,
          members.join_date
      FROM dannys_diner.sales
      LEFT JOIN dannys_diner.members ON sales.customer_id = members.customer_id
    order by sales.order_date desc
  ) as table1
  WHERE (table1.order_date - table1.join_date) < 0
  ORDER BY 
      table1.customer_id desc,
      table1.order_date asc
) table2
WHERE table2.rownum = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
 SELECT 
 	table2.customer_id, 
    COUNT(DISTINCT table2.product_id) as n_items,
    SUM(table2.product_id * menu.price) as amount
 FROM (
   SELECT 
        table1.customer_id,
        table1.product_id,
        table1.order_date,
        table1.join_date,
        (table1.order_date - table1.join_date) as days_from_join
    FROM(
        SELECT
            sales.customer_id,
            sales.product_id,
            sales.order_date,
            members.join_date
        FROM dannys_diner.sales
        LEFT JOIN dannys_diner.members ON sales.customer_id = members.customer_id
      order by sales.order_date desc
    ) as table1
    WHERE (table1.order_date - table1.join_date) < 0
    ORDER BY 
        table1.customer_id desc,
        table1.order_date asc
) table2
LEFT JOIN dannys_diner.menu ON table2.product_id = menu.product_id
GROUP BY table2.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
FROM(
	SELECT 
        table1.customer_id,
        table1.product_id,
        table1.order_date,
        table1.join_date,
        (table1.order_date - table1.join_date) as days_from_join,
        menu.product_name,
        menu.price,
        CASE 
        	WHEN menu.product_name = 'sushi' then 2
            ELSE 1 
        END as score_weights
    FROM(
        SELECT
            sales.customer_id,
            sales.product_id,
            sales.order_date,
            members.join_date
        FROM dannys_diner.sales
        LEFT JOIN dannys_diner.members ON sales.customer_id = members.customer_id
      order by sales.order_date desc
    ) as table1
    LEFT JOIN dannys_diner.menu on table1.product_id = menu.product_id
	WHERE (table1.order_date - table1.join_date) >= 0
    ORDER BY 
        table1.customer_id desc,
        table1.order_date asc
  ) table2
 GROUP BY table2.customer_id
 ORDER BY scoring desc, table2.customer_id desc;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
-- ATTENTION: I assume that every item gets the 2x bonus, and only sushi remains 2x afterwords.
SELECT 
	SUM(table2.price * table2.score_weights) as total_score, 
    table2.customer_id
FROM(
	SELECT 
        table1.customer_id,
        table1.product_id,
        table1.order_date,
        table1.join_date,
        (table1.order_date - table1.join_date) as days_from_join,
        menu.product_name,
        menu.price,
        CASE 
        	WHEN (table1.order_date - table1.join_date) <= 7 then 2
            ELSE CASE
            		WHEN menu.product_name = 'sushi' then 2
                    ELSE 1
                 END
        END as score_weights
    FROM(
        SELECT
            sales.customer_id,
            sales.product_id,
            sales.order_date,
            members.join_date
        FROM dannys_diner.sales
        LEFT JOIN dannys_diner.members ON sales.customer_id = members.customer_id
        WHERE sales.order_date < '2021-02-01'
        order by sales.order_date desc
    ) as table1
    LEFT JOIN dannys_diner.menu on table1.product_id = menu.product_id
	WHERE (table1.order_date - table1.join_date) >= 0
    ORDER BY 
        table1.customer_id desc,
        table1.order_date asc
) table2
GROUP BY table2.customer_id
ORDER BY table2.customer_id ASC;