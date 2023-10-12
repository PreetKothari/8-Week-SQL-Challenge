USE dannys_diner;

SELECT * FROM sales;
SELECT * FROM menu;
SELECT * FROM members;

/*1. What is the total amount each customer spent at the restaurant?*/
SELECT 
	s.customer_id, 
    SUM(m.price) AS total_money_spent 
FROM dannys_diner.sales s
INNER JOIN dannys_diner.menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;

/*2.How many days has each customer visited the restaurant?*/
SELECT 
	customer_id, 
    COUNT(DISTINCT order_date) AS visit_count 
FROM dannys_diner.sales
GROUP BY customer_id;

/*3. What was the first item from the menu purchased by each customer?*/

# Solution 1 - Subquery
SELECT 
	o.customer_id, 
    o.product_name 
FROM (SELECT 
		m.product_name, 
        s.customer_id, 
        s.order_date, 
		DENSE_RANK() OVER (PARTITION BY s.customer_id 
						   ORDER BY s.order_date) AS order_rank 
	   FROM dannys_diner.menu m
	   JOIN dannys_diner.sales s ON m.product_id = s.product_id) AS o
WHERE o.order_rank = 1
GROUP BY o.customer_id, o.product_name;  

# Solution 2 - Common Table Expression (CTE)
WITH ordered_sales AS (
SELECT
	m.product_name,
    s.customer_id, 
    s.order_date,
    DENSE_RANK() OVER (PARTITION BY s.customer_id 
					   ORDER BY s.order_date) AS order_rank 
FROM dannys_diner.menu m
INNER JOIN dannys_diner.sales s ON m.product_id = s.product_id)
SELECT 
	customer_id, 
    product_name 
FROM ordered_sales
WHERE order_rank = 1
GROUP BY customer_id, product_name;

/*4. What is the most purchased item on the menu and how many times was it purchased by 
all customers?*/
SELECT 
	m.product_name AS most_purchased_item, 
    COUNT(s.product_id) AS no_of_purchases 
FROM dannys_diner.menu m
INNER JOIN dannys_diner.sales s ON m.product_id = s.product_id
GROUP BY m.product_name
ORDER BY no_of_purchases DESC
LIMIT 1;

/*5. Which item was the most popular for each customer?*/
WITH popular_sales AS (
SELECT 
	s.customer_id, 
    m.product_name, 
    COUNT(s.product_id) AS no_of_purchases,
    DENSE_RANK() OVER (PARTITION BY s.customer_id
					   ORDER BY COUNT(s.customer_id) DESC) AS item_popularity 
FROM dannys_diner.sales s
INNER JOIN dannys_diner.menu m ON s.product_id = m.product_id
GROUP BY m.product_name, s.customer_id)
SELECT 
	customer_id, 
    product_name, 
    no_of_purchases 
FROM popular_sales
WHERE item_popularity = 1;

/*6. Which item was purchased first by the customer after they became a member?*/
WITH joined_as_member AS (
SELECT 
	mm.customer_id, s.product_id,
	mm.join_date, s.order_date,
	ROW_NUMBER() OVER (PARTITION BY mm.customer_id 
					   ORDER BY s.order_date) AS row_num
FROM dannys_diner.members mm
INNER JOIN dannys_diner.sales s ON s.customer_id = mm.customer_id 
								   AND s.order_date >= mm.join_date)
SELECT 
	j.customer_id, 
    mn.product_name 
FROM joined_as_member j
INNER JOIN dannys_diner.menu mn ON j.product_id = mn.product_id 
								   AND j.row_num = 1
ORDER BY j.customer_id;

/* Works but a bit unprofessional
SELECT mm.customer_id, mn.product_name FROM dannys_diner.members mm
INNER JOIN dannys_diner.sales s ON s.customer_id = mm.customer_id AND s.order_date >= mm.join_date
INNER JOIN dannys_diner.menu mn ON mn.product_id = s.product_id
GROUP BY mm.customer_id
ORDER BY mm.customer_id, s.order_date;
*/

/*7. Which item was purchased just before the customer became a member?*/
WITH before_joined_as_member AS (
SELECT 
	mm.customer_id, s.product_id,
	mm.join_date, s.order_date,
	RANK() OVER (PARTITION BY mm.customer_id 
				 ORDER BY s.order_date DESC) AS row_num
FROM dannys_diner.members mm
INNER JOIN dannys_diner.sales s ON s.customer_id = mm.customer_id 
							 AND s.order_date < mm.join_date)
SELECT 
	bm.customer_id, 
    mn.product_name 
FROM before_joined_as_member bm
INNER JOIN dannys_diner.menu mn ON bm.product_id = mn.product_id
								   AND bm.row_num = 1
ORDER BY bm.customer_id; 

/*8. What is the total items and amount spent for each member before they became a member?*/
SELECT 
	mm.customer_id, 
    COUNT(s.product_id) AS total_items,
	SUM(mn.price) AS total_sales
FROM dannys_diner.members mm
INNER JOIN dannys_diner.sales s ON s.customer_id = mm.customer_id 
							 AND s.order_date < mm.join_date
INNER JOIN dannys_diner.menu mn ON mn.product_id = s.product_id
GROUP BY mm.customer_id
ORDER BY mm.customer_id;

/*9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many 
points would each customer have?*/
WITH spends AS (
SELECT s.customer_id, m.product_name, s.product_id, 
	   COUNT(s.product_id), 
	   SUM(m.price) AS total_spent_on_item 
FROM dannys_diner.sales s
INNER JOIN dannys_diner.menu m ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name
ORDER BY s.customer_id)
SELECT customer_id, 
	   SUM(CASE
			WHEN product_id = 1 THEN total_spent_on_item*10*2
			ELSE total_spent_on_item*10
		   END) AS total_points
FROM spends
GROUP BY customer_id;

# Alternate Solution
WITH points_cte AS (
SELECT product_id, 
    CASE
      WHEN product_id = 1 THEN price * 20
      ELSE price * 10 
	END AS points
FROM dannys_diner.menu)
SELECT s.customer_id, 
	   SUM(p.points) AS total_points
FROM dannys_diner.sales s
INNER JOIN points_cte p
  ON s.product_id = p.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;

/*10. In the first week after a customer joins the program (including their join date) 
they earn 2x points on all items, not just sushi - how many points do customer A 
and B have at the end of January?*/
WITH points AS (
SELECT 
	s.customer_id, 
	s.order_date, 
    mn.product_id, 
    mn.product_name,
    CASE
      WHEN s.order_date >= mm.join_date 
		   AND s.order_date <= DATE_SUB(mm.join_date, INTERVAL -6 DAY) 
           THEN mn.price*20
	  ELSE (CASE
			  WHEN mn.product_id = 1 THEN price*20
			  ELSE mn.price*10 
			END)
	END AS purcahse_points
FROM dannys_diner.menu mn
INNER JOIN dannys_diner.sales s ON s.product_id = mn.product_id 
								AND s.order_date < '2021-01-31'
INNER JOIN dannys_diner.members mm ON mm.customer_id = s.customer_id
ORDER BY s.customer_id, s.order_date)
SELECT 
	m.customer_id, 
    SUM(p.purcahse_points) AS total_points
FROM dannys_diner.members m
INNER JOIN points p ON m.customer_id = p.customer_id
GROUP BY m.customer_id
ORDER BY m.customer_id;

-- Bonus Question --

/*1. Join All The Things - Create the table with: customer_id, order_date, product_name, price, 
member (Y/N)*/
SELECT 
	s.customer_id,
    s.order_date,
    mn.product_name,
    mn.price,
    CASE
	  WHEN s.order_date >= mm.join_date THEN 'Y'
	  ELSE 'N'
	END AS 'member'
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.members mm ON mm.customer_id = s.customer_id
INNER JOIN dannys_diner.menu mn ON mn.product_id = s.product_id
ORDER BY s.customer_id, s.order_date, mn.product_name;

/*2. Rank All The Things - Danny also requires further information about the ranking of 
customer products, but he purposely does not need the ranking for non-member purchases so he 
expects null ranking values for the records when customers are not yet part of the loyalty 
program.*/
WITH customer_data AS (
SELECT
	s.customer_id,
    s.order_date,
    mn.product_name,
    mn.price,
    CASE 
	  WHEN s.order_date >= mm.join_date THEN 'Y'
      ELSE 'N'
	END AS member_status
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.members mm ON mm.customer_id = s.customer_id
INNER JOIN dannys_diner.menu mn ON mn.product_id = s.product_id
ORDER BY s.customer_id, s.order_date, mn.product_name)
SELECT 
	cd.*,
    CASE
	  WHEN cd.member_status = "N" THEN NULL
	  ELSE RANK() OVER (PARTITION BY cd.customer_id, cd.member_status 
						ORDER BY cd.order_date)
	END AS ranking
FROM customer_data cd;