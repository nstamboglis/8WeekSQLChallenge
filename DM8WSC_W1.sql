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
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?