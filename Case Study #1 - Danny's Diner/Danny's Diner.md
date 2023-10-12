# 🍜 Case Study #1: Danny's Diner 
<img src="https://github.com/PreetKothari/8-Week-SQL-Challenge/assets/87279526/166763a7-6f57-4bde-98a9-d6f1183c326d" alt="Image" width="500" height="520">

## 📚 Table of Contents
- [Business Task](#business-task)
- [Entity Relationship Diagram](#entity-relationship-diagram)
- [Question and Solution](#question-and-solution)

Please note that all the information regarding the case study has been sourced from the following link: [here](https://8weeksqlchallenge.com/case-study-1/). 

***

## Business Task
Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. 

***

## Entity Relationship Diagram

![image](https://user-images.githubusercontent.com/81607668/127271130-dca9aedd-4ca9-4ed8-b6ec-1e1920dca4a8.png)

***

## Question and Solution

I have executed the following queries using MySQL on MySQL Workbench. I have also uploaded a script to `CREATE DATABASE dannys_diner` with the `sales`, `menu`, and `members` tables. 

If you have any questions, you can reach out to me on [LinkedIn](www.linkedin.com/in/preet-kothari-a9884b172).

**Lets set the current Database as `dannys_diner`**
````sql
USE dannys_diner;
````

**1. What is the total amount each customer spent at the restaurant?**

````sql
SELECT 
    s.customer_id, 
    SUM(m.price) AS total_money_spent 
FROM dannys_diner.sales s
INNER JOIN dannys_diner.menu m ON s.product_id = m.product_id
GROUP BY s.customer_id; 
````

*Note:- `dannys_dinner.table_name t` = `dannys_dinner.table_name AS t`
	I will be using this in nearly all my queries involving JOINs.*

#### Steps:
- Use **JOIN** to merge `dannys_diner.sales` and `dannys_diner.menu` tables as `sales.customer_id` and `menu.price` are from both tables.
- Use **SUM** to calculate the total money spent by each customer.
- Group the aggregated results by `sales.customer_id`. 

#### Answer:
| customer_id | total_money_spent |
| ----------- | ----------- |
| A           | 76          |
| B           | 74          |
| C           | 36          |

- Customer A spent $76.
- Customer B spent $74.
- Customer C spent $36.

***

**2. How many days has each customer visited the restaurant?**

````sql
SELECT 
    customer_id, 
    COUNT(DISTINCT order_date) AS visit_count
FROM dannys_diner.sales
GROUP BY customer_id;
````

#### Steps:
- To determine the unique number of visits for each customer, utilize **COUNT(DISTINCT `order_date`)**.
- It's important to apply the **DISTINCT** keyword while calculating the visit count to avoid duplicate counting of days. For instance, Customer A visited the restaurant twice on '2021–01–01', counting without **DISTINCT** would result in 2 days instead of the accurate count of 1 day.

#### Answer:
| customer_id | visit_count |
| ----------- | ----------- |
| A           | 4           |
| B           | 6           |
| C           | 2           |

- Customer A visited 4 times.
- Customer B visited 6 times.
- Customer C visited 2 times.

***

**3. What was the first item from the menu purchased by each customer?**

````sql
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
````

#### Steps: 
- Create a Common Table Expression (CTE) named `ordered_sales`. Within the CTE, create a new column `order_rank` and calculate the row number using **DENSE_RANK()** window function. The **PARTITION BY** clause divides the data by `customer_id`, and the **ORDER BY** clause orders the rows within each partition by `order_date`.
- In the outer query, select the appropriate columns and apply a filter in the **WHERE** clause to retrieve only the rows where the `order_rank` column equals 1, which represents the first row within each `customer_id` partition.
- Use the GROUP BY clause to group the result by `customer_id` and `product_name`.

#### Answer:
| customer_id | product_name | 
| ----------- | -----------  |
| A           | curry        | 
| A           | sushi        | 
| B           | curry        | 
| C           | ramen        |

- Customer A placed an order for both curry and sushi simultaneously, making them the first items in the order.
- Customer B's first order is curry.
- Customer C's first order is ramen.

We have used `DENSE_RANK()` instead of `ROW_NUMBER()` for determining the "first order" in this question. because since the `order_date` does not have a timestamp, it is impossible to determine the exact sequence of items ordered by the customer. 

Therefore, it would be inaccurate to conclude that curry is the customer's first order purely based on the alphabetical order of the product names. For this reason, we should use `DENSE_RANK()` and consider both curry and sushi as Customer A's first order.

***

**4. What is the most purchased item on the menu and how many times was it purchased by all customers?**

````sql
SELECT 
    m.product_name AS most_purchased_item, 
    COUNT(s.product_id) AS no_of_purchases 
FROM dannys_diner.menu m
INNER JOIN dannys_diner.sales s ON m.product_id = s.product_id
GROUP BY m.product_name
ORDER BY no_of_purchases DESC
LIMIT 1;
````

#### Steps:
- Perform a **COUNT** aggregation on the `product_id` column and **ORDER BY** the result in descending order using `no_of_purchases` field.
- Apply the **LIMIT** 1 clause to filter and retrieve the highest number of purchased items.

#### Answer:
| most_purchased_item | no_of_purchases | 
| ----------- | ----------- |
| ramen      | 8 |


- Most purchased item on the menu is ramen which is 8 times. Yummy!

***

**5. Which item was the most popular for each customer?**

````sql
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
````

*Each user may have more than 1 favourite item.*

#### Steps:
- Create a CTE named `popular_sales` and within the CTE, join the `menu` table and `sales` table using the `product_id` column.
- Group results by `sales.customer_id` and `menu.product_name` and calculate the count of `sales.product_id` occurrences for each group. 
- Utilize the **DENSE_RANK()** window function to calculate the ranking of each `sales.customer_id` partition based on the count of orders **COUNT(`sales.customer_id`)** in descending order.
- In the outer query, select the appropriate columns and apply a filter in the **WHERE** clause to retrieve only the rows where the `item_popularity` column equals 1, representing the rows with the highest order count for each customer.

#### Answer:
| customer_id | product_name | order_count |
| ----------- | ---------- |------------  |
| A           | ramen        |  3   |
| B           | sushi        |  2   |
| B           | curry        |  2   |
| B           | ramen        |  2   |
| C           | ramen        |  3   |

- Customer A and C's favourite item is ramen.
- Customer B enjoys all items on the menu. He/she is a true foodie, sounds like me.

***

**6. Which item was purchased first by the customer after they became a member?**

```sql
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
```

#### Steps:
- Create a CTE named `joined_as_member` and within the CTE, select the appropriate columns and calculate the row number using the **ROW_NUMBER()** window function. The **PARTITION BY** clause divides the data by `members.customer_id` and the **ORDER BY** clause orders the rows within each `members.customer_id` partition by `sales.order_date`.
- Join tables `dannys_diner.members` and `dannys_diner.sales` on `customer_id` column. Additionally, apply a condition to only include sales that occurred *from* the member's `join_date` (`sales.order_date >= members.join_date`).
- In the outer query, join the `joined_as_member` CTE with the `dannys_diner.menu` on the `product_id` column.
- In the **WHERE** clause, filter to retrieve only the rows where the `row_num` column equals 1, representing the first row within each `customer_id` partition.
- Order result by `customer_id` in ascending order.

#### Answer:
| customer_id | product_name |
| ----------- | ---------- |
| A           | curry        |
| B           | sushi        |

- Customer A's first order as a member is curry, on the same day they became a member.
- Customer B's first order as a member is sushi.

***

**7. Which item was purchased just before the customer became a member?**

````sql
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
````

#### Steps:
- Create a CTE called `before_joined_as_member`. 
- In the CTE, select the appropriate columns and calculate the rank using the **RANK()** window function. The rank is determined based on the order dates of the sales in descending order within each customer's group.
- Join `dannys_diner.members` table with `dannys_diner.sales` table based on the `customer_id` column, only including sales that occurred *before* the customer joined as a member (`sales.order_date < members.join_date`).
- Join `before_joined_as_member` CTE with `dannys_diner.menu` table based on `product_id` column.
- Filter the result set to include only the rows where the rank is 1, representing the earliest purchase made by each customer before they became a member.
- Sort the result by `customer_id` in ascending order.

#### Answer:
| customer_id | product_name |
| ----------- | ---------- |
| A           | sushi        |
| A           | curry        |
| B           | sushi        |

- Customer A placed an order for both curry and sushi simultaneously, before they became a member.
- Customer B's order brfore joining as a member was curry.

We have used `RANK()` instead of `ROW_NUMBER()` for determining the "first order" in this question. because a customer may have ordered multiple items on a single date and since the `ROW_NUMBER()` ranks each row consecutively without considering duplicates as same rank. 

Therefore, it would be inaccurate to conclude that curry is the customer's only order purely based on the alphabetical order of the product names. For this reason, we should use `RANK()` and consider both curry and sushi as Customer A's order.

***

**8. What is the total items and amount spent for each member before they became a member?**

```sql
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
```

#### Steps:
- Select the columns `members.customer_id` and calculate the count of `sales.product_id` as total_items for each customer and the sum of `menu.price` as total_sales.
- From `dannys_diner.members` table, join `dannys_diner.sales` table on `customer_id` column, ensuring that `sales.order_date` is earlier than `members.join_date` (`sales.order_date < members.join_date`).
- Then, join `dannys_diner.menu` table to `dannys_diner.sales` table on `product_id` column.
- Group the results by `members.customer_id`.
- Order the result by `members.customer_id` in ascending order.

#### Answer:
| customer_id | total_items | total_sales |
| ----------- | ---------- |----------  |
| A           | 2 |  25       |
| B           | 3 |  40       |

Before becoming members,
- Customer A spent $25 on 2 items.
- Customer B spent $40 on 3 items.

***

**9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have?**

```sql
WITH spends AS (
SELECT
    s.customer_id,
    m.product_name,
    s.product_id,
    COUNT(s.product_id),
    SUM(m.price) AS total_spent_on_item 
FROM dannys_diner.sales s
INNER JOIN dannys_diner.menu m ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name
ORDER BY s.customer_id)
SELECT
    customer_id,
    SUM(CASE
	    WHEN product_id = 1 THEN total_spent_on_item*10*2
	    ELSE total_spent_on_item*10
	END) AS total_points
FROM spends
GROUP BY customer_id;
```

#### Steps:
Let's break down the question to understand the point calculation for each customer's purchases.
- Each $1 spent = 10 points. However, `product_id` 1 sushi gets 2x points, so each $1 spent = 20 points.
- Here's how the calculation is performed using a conditional CASE statement:
	- If product_id = 1, multiply every $1 by 20 points.
	- Otherwise, multiply $1 by 10 points.
- Then, calculate the total points for each customer.

#### Answer:
| customer_id | total_points | 
| ----------- | ---------- |
| A           | 860 |
| B           | 940 |
| C           | 360 |

- Total points for Customer A is 860.
- Total points for Customer B is 940.
- Total points for Customer C is 360.

***

**10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi — how many points do customer A and B have at the end of January?**

```sql
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
		   		AND s.order_date < '2021-02-01'
INNER JOIN dannys_diner.members mm ON mm.customer_id = s.customer_id
ORDER BY s.customer_id, s.order_date)
SELECT
    m.customer_id,
    SUM(p.purcahse_points) AS total_points
FROM dannys_diner.members m
INNER JOIN points p ON m.customer_id = p.customer_id
GROUP BY m.customer_id
ORDER BY m.customer_id;
```

#### Assumptions:
- On Day -X to Day 1 (the day a customer becomes a member), each $1 spent earns 10 points. However, for sushi, each $1 spent earns 20 points.
- From Day 1 to Day 7 (the first week of membership), each $1 spent for any items earns 20 points.
- From Day 8 to the last day of January 2021, each $1 spent earns 10 points. However, sushi continues to earn double the points at 20 points per $1 spent.

#### Steps:
- Create a CTE called `points`. 
- In the CTE, select the appropriate columns and calculate the points as `purchase_points` by using a `CASE` statement to determine the points based on our assumptions above.
	- If purchase is made anytime from `join_date` to 7 days from `join_date` (`s.order_date >= mm.join_date AND s.order_date <= DATE_SUB(mm.join_date, INTERVAL -6 DAY)`) then multiply the price of all the items by 10 and then by 2 as the first week member bonus.
	- Else if purchase is made before `join_date` or after 7 days from `join_date` till the last day of January 2021, then
 		- If the `product_id` is 1 (for 'sushi'), multiply the price by 2 and then by 10.
   		- Else for all other products, multiply the price by 10.
- From `dannys_diner.menu` table, join `dannys_diner.sales` on `product_id` column, ensuring that `sales.order_date` is earlier than '2021-01-31' (`sales.order_date < '2021-01-31'`).
- Then, join `dannys_diner.members` table based on the `customer_id` column.
- Order the result by `sales.customer_id` & `sales.order_date` in ascending order.
- In the outer query, select the columns `members.customer_id` and calculate the sum of `points.purchase_points` as total_points.
- Then, join `points` CTE with `dannys_diner.members` table based on `customer_id` column.
- Group the results by `members.customer_id`.
- Order the result by `members.customer_id` in ascending order.

#### Answer:
| customer_id | total_points | 
| ----------- | ---------- |
| A           | 1370 |
| B           | 820 |

- Total points for Customer A is 1,370.
- Total points for Customer B is 820.

***

## BONUS QUESTIONS

**Join All The Things**

**Recreate the table with: customer_id, order_date, product_name, price, member (Y/N)**

```sql
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
```
 
#### Answer: 
| customer_id | order_date | product_name | price | member |
| ----------- | ---------- | -------------| ----- | ------ |
| A           | 2021-01-01 | curry        | 15    | N      |
| A           | 2021-01-01 | sushi        | 10    | N      |
| A           | 2021-01-07 | curry        | 15    | Y      |
| A           | 2021-01-10 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| B           | 2021-01-01 | curry        | 15    | N      |
| B           | 2021-01-02 | curry        | 15    | N      |
| B           | 2021-01-04 | sushi        | 10    | N      |
| B           | 2021-01-11 | sushi        | 10    | Y      |
| B           | 2021-01-16 | ramen        | 12    | Y      |
| B           | 2021-02-01 | ramen        | 12    | Y      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-07 | ramen        | 12    | N      |

***

**Rank All The Things**

**Danny also requires further information about the ```ranking``` of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ```ranking``` values for the records when customers are not yet part of the loyalty program.**

```sql
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
```

#### Answer: 
| customer_id | order_date | product_name | price | member_status | ranking | 
| ----------- | ---------- | -------------| ----- | ------ |-------- |
| A           | 2021-01-01 | curry        | 15    | N      | NULL    |
| A           | 2021-01-01 | sushi        | 10    | N      | NULL    |
| A           | 2021-01-07 | curry        | 15    | Y      | 1       |
| A           | 2021-01-10 | ramen        | 12    | Y      | 2       |
| A           | 2021-01-11 | ramen        | 12    | Y      | 3       |
| A           | 2021-01-11 | ramen        | 12    | Y      | 3       |
| B           | 2021-01-01 | curry        | 15    | N      | NULL    |
| B           | 2021-01-02 | curry        | 15    | N      | NULL    |
| B           | 2021-01-04 | sushi        | 10    | N      | NULL    |
| B           | 2021-01-11 | sushi        | 10    | Y      | 1       |
| B           | 2021-01-16 | ramen        | 12    | Y      | 2       |
| B           | 2021-02-01 | ramen        | 12    | Y      | 3       |
| C           | 2021-01-01 | ramen        | 12    | N      | NULL    |
| C           | 2021-01-01 | ramen        | 12    | N      | NULL    |
| C           | 2021-01-07 | ramen        | 12    | N      | NULL    |

***
