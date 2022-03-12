------------------------
-- Danny Ma's 8 Weeks SQL Challenge
-- Week 1
------------------------

-- Author: Nick
-- Date: Mar 2022

-- DESCription: This file contains the result queries for DM's 8WSC Week 1.

-- 1. What is the total amount each customer spent at the restaurant?
SELECT 
	A.customer_id, 
	sum(A.expenditure) AS tot_expenditure
FROM(
	SELECT 
		sales.customer_id, 
		sales.product_id, 
		menu.price, 
		(sales.product_id * menu.price) AS expenditure
	FROM dannys_diner.sales
	LEFT JOIN dannys_diner.menu ON sales.product_id = menu.product_id
  ) A
  GROUP BY A.customer_id
  ORDER BY A.customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT 
	sales.customer_id, 
	COUNT(distinct sales.order_date) AS n_dinstinct_days
FROM dannys_diner.sales
GROUP BY sales.customer_id
ORDER BY n_dinstinct_days DESC;

-- 3. What was the first item FROM the menu purchased by each customer?
SELECT customer_id, product_id
FROM(
	SELECT row_number() over(
 	PARTITION BY sales.customer_id
  	ORDER BY sales.order_date asc
  	RANGE BETWEEN 
      	UNBOUNDED PRECEDING AND 
      	UNBOUNDED FOLLOWING) row_number_ind, 
	sales.customer_id, 
	sales.product_id
FROM dannys_diner.sales) tab1
WHERE row_number_ind = 1;

-- 4. What is the most purchased item ON the menu and how many times was it purchased by all customers?
SELECT 
	sales.product_id, 
	COUNT(product_id)
FROM dannys_diner.sales
GROUP BY sales.product_id
LIMIT 1;

-- 5. Which item was the most popular for each customer?
SELECT 
	table2.customer_id, 
	table2.product_id
FROM(
	SELECT 
		table1.customer_id, 
		table1.product_id, 
		table1.product_count, 	
		row_number() over(PARTITION BY table1.customer_id) AS rnum
	FROM(
		SELECT sales.customer_id, sales.product_id, COUNT(sales.product_id) AS product_count
		FROM dannys_diner.sales 
		GROUP BY sales.customer_id, sales.product_id
		ORDER BY sales.customer_id asc, product_count DESC
    		) table1
	) table2
WHERE table2.rnum = 1;

-- 6. Which item was purchased first by the customer after they became a member?
SELECT 
	table2.customer_id, 
	table2.product_id
FROM(
  SELECT 
      table1.customer_id,
      table1.product_id,
      table1.order_date,
      table1.join_date,
      (table1.order_date - table1.join_date) AS days_FROM_join,
      row_number() over(PARTITION BY table1.customer_id) AS rownum
  FROM(
      SELECT
          sales.customer_id,
          sales.product_id,
          sales.order_date,
          members.join_date
      FROM dannys_diner.sales
      LEFT JOIN dannys_diner.members ON sales.customer_id = members.customer_id
  ) AS table1
  WHERE (table1.order_date - table1.join_date) >= 0
  ORDER BY 
      table1.customer_id DESC,
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
      (table1.order_date - table1.join_date) AS days_FROM_join,
      row_number() over(PARTITION BY table1.customer_id) AS rownum
  FROM(
      SELECT
          sales.customer_id,
          sales.product_id,
          sales.order_date,
          members.join_date
      FROM dannys_diner.sales
      LEFT JOIN dannys_diner.members ON sales.customer_id = members.customer_id
    ORDER BY sales.order_date DESC
  ) AS table1
  WHERE (table1.order_date - table1.join_date) < 0
  ORDER BY 
      table1.customer_id DESC,
      table1.order_date asc
) table2
WHERE table2.rownum = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
 SELECT 
 	table2.customer_id, 
    COUNT(DISTINCT table2.product_id) AS n_items,
    SUM(table2.product_id * menu.price) AS amount
 FROM (
   SELECT 
        table1.customer_id,
        table1.product_id,
        table1.order_date,
        table1.join_date,
        (table1.order_date - table1.join_date) AS days_FROM_join
    FROM(
        SELECT
            sales.customer_id,
            sales.product_id,
            sales.order_date,
            members.join_date
        FROM dannys_diner.sales
        LEFT JOIN dannys_diner.members ON sales.customer_id = members.customer_id
      ORDER BY sales.order_date DESC
    ) AS table1
    WHERE (table1.order_date - table1.join_date) < 0
    ORDER BY 
        table1.customer_id DESC,
        table1.order_date asc
) table2
LEFT JOIN dannys_diner.menu ON table2.product_id = menu.product_id
GROUP BY table2.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT
	sum(table2.price * table2.score_weights) as total_score,
    table2.customer_id
 FROM(
	SELECT 
        table1.customer_id,
        table1.product_id,
        table1.order_date,
        table1.join_date,
        (table1.order_date - table1.join_date) AS days_FROM_join,
        menu.product_name,
        menu.price,
        CASE 
        	WHEN menu.product_name = 'sushi' then 2
            ELSE 1 
        END AS score_weights
    FROM(
        SELECT
            sales.customer_id,
            sales.product_id,
            sales.order_date,
            members.join_date
        FROM dannys_diner.sales
        LEFT JOIN dannys_diner.members ON sales.customer_id = members.customer_id
      ORDER BY sales.order_date DESC
    ) AS table1
    LEFT JOIN dannys_diner.menu ON table1.product_id = menu.product_id
	WHERE (table1.order_date - table1.join_date) >= 0
    ORDER BY 
        table1.customer_id DESC,
        table1.order_date asc) AS table2
  GROUP BY table2.customer_id
  ORDER BY total_score desc;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points ON all items, not just sushi - how many points do customer A and B have at the end of January?
-- ATTENTION: I assume that every item gets the 2x bonus, and only sushi remains 2x afterwords.
SELECT 
	SUM(table2.price * table2.score_weights) AS total_score, 
    table2.customer_id
FROM(
	SELECT 
        table1.customer_id,
        table1.product_id,
        table1.order_date,
        table1.join_date,
        (table1.order_date - table1.join_date) AS days_FROM_join,
        menu.product_name,
        menu.price,
        CASE 
        	WHEN (table1.order_date - table1.join_date) <= 7 then 2
            ELSE CASE
            		WHEN menu.product_name = 'sushi' then 2
                    ELSE 1
                 END
        END AS score_weights
    FROM(
        SELECT
            sales.customer_id,
            sales.product_id,
            sales.order_date,
            members.join_date
        FROM dannys_diner.sales
        LEFT JOIN dannys_diner.members ON sales.customer_id = members.customer_id
        WHERE sales.order_date < '2021-02-01'
        ORDER BY sales.order_date DESC
    ) AS table1
    LEFT JOIN dannys_diner.menu ON table1.product_id = menu.product_id
	WHERE (table1.order_date - table1.join_date) >= 0
    ORDER BY 
        table1.customer_id DESC,
        table1.order_date asc
) table2
GROUP BY table2.customer_id
ORDER BY table2.customer_id ASC;