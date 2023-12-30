# 🍕 Case Study #2 Pizza Runner

<img src="https://github.com/PreetKothari/8-Week-SQL-Challenge/assets/87279526/bdf02db3-ad4e-4288-b657-6c7a1aa46764" alt="Image" width="500" height="520">

## 📚 Table of Contents
- [Business Task](#business-task)
- [Entity Relationship Diagram](#entity-relationship-diagram)
- Solution
  - [Data Cleaning and Transformation](#-data-cleaning--transformation)
  - [A. Pizza Metrics](#a-pizza-metrics)
  - [B. Runner and Customer Experience](#b-runner-and-customer-experience)
  - [C. Ingredient Optimisation](#c-ingredient-optimisation)
  - [D. Pricing and Ratings](#d-pricing-and-ratings)

***

## Business Task
Danny is expanding his new Pizza Empire, and at the same time, he wants to Uberize it, so Pizza Runner was launched!

Danny started by recruiting “runners” to deliver fresh pizza from Pizza Runner Headquarters (otherwise known as Danny’s house) and also maxed out his credit card to pay freelance developers to build a mobile app to accept orders from customers. 

## Entity Relationship Diagram

Because Danny had a few years of experience as a data scientist - he was very aware that data collection was going to be critical for his business’ growth.

He has prepared for us an entity relationship diagram of his database design but requires further assistance to clean his data and apply some basic calculations so he can better direct his runners and optimize Pizza Runner’s operations.

![Entity Relationship Diagram](https://github.com/PreetKothari/8-Week-SQL-Challenge/assets/87279526/e7648e46-99e4-46f5-933e-d54bbf0013b6)

## 🧼 Data Cleaning & Transformation

### 🔨 Table: customer_orders

Looking at the `customer_orders` table below, we can see that there are missing data/blank spaces " " and "null" values in the -
- `exclusions` column
- `extras` column

Also, we can see that some order ids are being repeated thus making the `order_id` column non-unique.

![customer_orders_uncleaned](https://github.com/PreetKothari/8-Week-SQL-Challenge/assets/87279526/fa51a7f4-b0e6-461b-8b1a-d504c36cb454)

Our course of action to clean the table:
- Create a temporary table with all the columns.
- Remove "null" values in the `exclusions` and the `extras` columns and replace them with `Null` values.
- Add another column named `record_id` to provide a unique number to each record in the table.

````sql
DROP TEMPORARY TABLE IF EXISTS customer_orders_temp;
CREATE TEMPORARY TABLE customer_orders_temp
SELECT 
	order_id, 
	customer_id, 
	pizza_id,
	CASE 
		WHEN exclusions = '' OR exclusions LIKE '%null%' THEN NULL
		ELSE exclusions
	END AS exclusions,
	CASE 
		WHEN extras = '' OR extras LIKE '%null%' THEN NULL
		ELSE extras
	END AS extras,
	order_time,
	ROW_NUMBER() OVER (ORDER BY order_id) AS record_id
FROM pizza_runner.customer_orders;
`````

This is what the clean `customer_orders_temp` table looks like, and we will use this table to run all our queries.

![customer_orders_temp_cleaned](https://github.com/PreetKothari/8-Week-SQL-Challenge/assets/87279526/3f28ceed-d665-4b73-84d5-1fe5600bddcc)

***

### 🔨 Temporary Tables for Extras & Exclusions

Looking at the `customer_orders_temp` table created above, we can notice that some orders have multiple extras or exclusions and instead of reporting them separately they have been grouped in a string separated with a `,`. This is going to pose a problem during our analysis. 

Our course of action to make the exclusions & extras easier to call:
- Create temporary tables for each `exclusions` and `extras`.
- Ungroup the rows with multiple values in `exclusions` and `extras` columns and add separate rows for each.

````sql
DROP TEMPORARY TABLE IF EXISTS customer_orders_exclusions_temp;
CREATE TEMPORARY TABLE customer_orders_exclusions_temp
WITH RECURSIVE unwound_exclusions AS (
SELECT 
	order_id, 
	pizza_id, 
    	exclusions,
    	record_id
FROM pizza_runner.customer_orders_temp
UNION ALL
SELECT
	order_id,
	pizza_id, 
	REGEXP_REPLACE(REPLACE(exclusions," ",""), '^[^,]*,', '') AS exclusions,
    	record_id
FROM unwound_exclusions
WHERE exclusions LIKE '%,%')
SELECT 
	order_id,
	pizza_id,
   	CAST(REGEXP_REPLACE(exclusions, ',.*', '') AS UNSIGNED) AS exclusions_topping_id,
    	record_id
FROM unwound_exclusions
ORDER BY order_id, pizza_id;
````
The ungrouped `customer_orders_exclusions_temp` table looks like this:

![customer_orders_exclusions](https://github.com/PreetKothari/8-Week-SQL-Challenge/assets/87279526/bd9f6fc0-eae3-4253-a10f-3b7e482b58dc)

````sql
DROP TEMPORARY TABLE IF EXISTS customer_orders_extras_temp;
CREATE TEMPORARY TABLE customer_orders_extras_temp
WITH RECURSIVE unwound_extras AS (
SELECT 
	order_id, 
    	pizza_id, 
    	extras,
   	record_id
FROM pizza_runner.customer_orders_temp
UNION ALL
SELECT
	order_id,
	pizza_id, 
	REGEXP_REPLACE(REPLACE(extras," ",""), '^[^,]*,', '') AS extras,
    	record_id
FROM unwound_extras
WHERE extras LIKE '%,%')
SELECT 
	order_id,
	pizza_id,
    	CAST(REGEXP_REPLACE(extras, ',.*', '') AS UNSIGNED) AS extras_topping_id,
    	record_id
FROM unwound_extras
ORDER BY order_id, pizza_id;
````
The ungrouped `customer_orders_extras_temp` table looks like this:

![customer_orders_extras](https://github.com/PreetKothari/8-Week-SQL-Challenge/assets/87279526/492a73f3-2ddd-435e-8841-945db9507f18)

***

### 🔨 Table: runner_orders

Looking at the `runner_orders` table below, we can see that in the -
- `pickup_time`, `distance`, `duration`, and `cancellation` columns there are missing data/blank spaces " " and "null" values.
- `distance` column has "km" after some of the entries.
- `duration` column has "mins", "minute" or "minutes" after some of the entries.

![runner_orders_uncleaned](https://github.com/PreetKothari/8-Week-SQL-Challenge/assets/87279526/e4ac1f63-a854-4488-b9db-3957a810ca8f)

Our course of action to clean the table:
- In `pickup_time`, `distance`, `duration`, and `cancellation` columns, remove "null" and replace them with `Null`.
- In `distance` column, remove "km".
- In `duration` column, remove "minutes", "minute" and "mins".

````sql
DROP TEMPORARY TABLE IF EXISTS runner_orders_temp;
CREATE TEMPORARY TABLE runner_orders_temp
SELECT
	order_id,
	runner_id, 
	CASE 
		WHEN pickup_time LIKE '%null%' THEN NULL
        	ELSE pickup_time
    	END AS pickup_time,
   	CASE 
		WHEN distance LIKE '%null%' THEN NULL
        	WHEN distance LIKE '%km' THEN RTRIM(SUBSTR(distance,1,POSITION("k" IN distance)-1))
        	ELSE distance
    	END AS distance,
    	CASE 
		WHEN duration LIKE '%null%' THEN NULL
        	WHEN duration LIKE '%mins' OR duration LIKE '%minutes' OR duration LIKE '%minute' 
				THEN RTRIM(SUBSTR(duration,1,POSITION("m" IN duration)-1))
        	ELSE duration
    	END AS duration,
    	CASE 
		WHEN cancellation = '' OR cancellation LIKE '%null%' THEN NULL
        	ELSE cancellation
    	END AS cancellation
FROM runner_orders;
````

Then, we alter the `pickup_time`, `distance` and `duration` columns to the correct data type.

````sql
ALTER TABLE runner_orders_temp
ALTER COLUMN pickup_time DATETIME,
ALTER COLUMN distance FLOAT,
ALTER COLUMN duration INT;
````

This is what the clean `runner_orders_temp` table looks like, and we will use this table to run all our queries.

![runner_orders_cleaned](https://github.com/PreetKothari/8-Week-SQL-Challenge/assets/87279526/2ae1e36b-3c80-454e-8906-ab2d1510abfd)

***

### 🔨 Table: pizza_recipes

Looking at the `pizza_recipes` table below, we can see that in the `toppings` column, all the topping ids for a pizza recipe are grouped in a string separated with a `,`, instead of reporting them separately. This is going to pose a problem during our analysis.

![pizza_recipes_temp_uncleaned](https://github.com/PreetKothari/8-Week-SQL-Challenge/assets/87279526/17e78658-5022-4596-9380-cecc88414b20)

Our course of action to clean the table:
- Create a temporary table with all the columns, plus a `topping_name` column from the `pizza_toppings` table to make our analysis easier.
- Ungroup the rows with multiple topping values and add separate rows for each value.

````sql
DROP TEMPORARY TABLE IF EXISTS pizza_recipes_temp;
CREATE TEMPORARY TABLE pizza_recipes_temp
WITH RECURSIVE unwound AS (
SELECT 
	*
FROM pizza_runner.pizza_recipes
UNION ALL
SELECT 
	pizza_id, 
	REGEXP_REPLACE(REPLACE(toppings," ",""), '^[^,]*,', '') AS toppings
FROM unwound
WHERE toppings LIKE '%,%')
SELECT 
	u.pizza_id,
    	CAST(REGEXP_REPLACE(u.toppings, ',.*', '') AS UNSIGNED) AS topping_id,
    	t.topping_name
FROM unwound u
JOIN pizza_runner.pizza_toppings t ON t.topping_id = CAST(REGEXP_REPLACE(u.toppings, ',.*', '') AS UNSIGNED)
ORDER BY pizza_id;
````
This is what the clean `pizza_recipes_temp` table looks like:

![pizza_recipes_temp_cleaned](https://github.com/PreetKothari/8-Week-SQL-Challenge/assets/87279526/aaee0a3a-2eb8-49dc-a2ad-d373f2bad146)

***

## Solution

## A. Pizza Metrics

### 1. How many pizzas were ordered?

````sql
SELECT 
	COUNT(order_id) AS pizza_order_count 
FROM pizza_runner.customer_orders_temp;
````

**Answer:**

| pizza_order_count |
| ------------ |
| 14           |

- A total of 14 pizzas were ordered.

### 2. How many unique customer orders were made?

````sql
SELECT 
	COUNT(DISTINCT order_id) AS unique_orders 
FROM pizza_runner.customer_orders_temp;
````

**Answer:**

| unique_orders |
| ------------ |
| 10           |

- There are 10 unique customer orders.

### 3. How many successful orders were delivered by each runner?

````sql
SELECT 
	runner_id, 
    	COUNT(order_id) AS successful_orders
FROM pizza_runner.runner_orders_temp
WHERE distance IS NOT NULL 
GROUP BY runner_id;
````

**Answer:**

| runnrr_id | successful_orders |
| ----------- | ----------- |
| 1           | 4          |
| 2           | 3          |
| 3           | 1          |

- Runner 1 has 4 successfully delivered orders.
- Runner 2 has 3 successfully delivered orders.
- Runner 3 has 1 successfully delivered order.

### 4. How many of each type of pizza was delivered?

````sql
SELECT 
	p.pizza_name, 
    	COUNT(c.pizza_id) AS delivered_pizzas 
FROM pizza_runner.customer_orders_temp c
JOIN pizza_runner.runner_orders_temp r ON c.order_id = r.order_id 
				AND r.pickup_time IS NOT NULL
JOIN pizza_runner.pizza_names p ON c.pizza_id = p.pizza_id
GROUP BY p.pizza_name
ORDER BY c.pizza_id;
````

**Answer:**

| pizza_name | delivered_pizzas |
| ----------- | ----------- |
| Meatlovers  | 9          |
| Vegetarian  | 3          |

- There are 9 delivered Meatlovers pizzas and 3 Vegetarian pizzas.

### 5. How many Vegetarian and Meatlovers were ordered by each customer?**

````sql
SELECT 
	c.customer_id,
	p.pizza_name,
	COUNT(c.pizza_id) AS order_count
FROM pizza_runner.customer_orders_temp c
JOIN pizza_runner.pizza_names p ON c.pizza_id = p.pizza_id
GROUP BY c.customer_id, p.pizza_name
ORDER BY c.customer_id, c.pizza_id;
````

**Answer:**

| customer_id | pizza_name | order_count | 
| ----------- | ---------- | ----------- | 
| 101         | Meatlovers | 2           |
| 101         | Vegetarian | 1           |
| 102         | Meatlovers | 2           |
| 102         | Vegetarian | 1           |
| 103         | Meatlovers | 3           |
| 103         | Vegetarian | 1           |
| 104         | Meatlovers | 3           |
| 105         | Vegetarian | 1           |

- Customer 101 ordered 2 Meatlovers pizzas and 1 Vegetarian pizza.
- Customer 102 ordered 2 Meatlovers pizzas and 1 Vegetarian pizza.
- Customer 103 ordered 3 Meatlovers pizzas and 1 Vegetarian pizza.
- Customer 104 ordered 3 Meatlovers pizzas.
- Customer 105 ordered 1 Vegetarian pizza.

### 6. What was the maximum number of pizzas delivered in a single order?

````sql
SELECT 
	c.order_id,
    	COUNT(c.order_id) AS pizza_per_order 
FROM pizza_runner.customer_orders_temp c
JOIN pizza_runner.runner_orders_temp r ON r.order_id = c.order_id 
				   AND r.distance IS NOT NULL
GROUP BY c.order_id
ORDER BY COUNT(c.order_id) DESC;
````

**Answer:**

| order_id    | pizza_per_order | 
| ----------- | ----------- | 
| 4           | 3           |
| 3           | 2           |
| 10          | 2           |
| 1           | 1           |
| 2           | 1           |
| 5           | 1           |
| 7           | 1           |
| 8           | 1           |

- Maximum number of pizzas delivered in a single order is 3 pizzas.

### 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

````sql
SELECT 
	c.customer_id,
    	SUM(CASE 
		WHEN c.exclusions IS NOT NULL OR c.extras IS NOT NULL THEN 1
            	ELSE 0
	END) AS at_least_1_change,
	SUM(CASE 
		WHEN c.exclusions IS NULL AND c.extras IS NULL THEN 1
            	ELSE 0
	END) AS no_change
FROM pizza_runner.customer_orders_temp c
JOIN pizza_runner.runner_orders_temp r ON r.order_id = c.order_id 
				   AND r.distance IS NOT NULL
GROUP BY c.customer_id
ORDER BY c.customer_id;
````

**Answer:**

| customer_id | at_least_1_change | no_change | 
| ----------- | ---------- | ----------- | 
| 101         | 0          | 2           |
| 102         | 0          | 3           |
| 103         | 3          | 0           |
| 104         | 2          | 1           |
| 105         | 1          | 0           |

- Customers 101 and 102 likes his/her pizzas per the original recipe.
- Customer 103, 104, and 105 have their own preferences for pizza toppings and requested at least 1 change (extra topping or exclusion of topping) on their pizza.

### 8. How many pizzas were delivered that had both exclusions and extras?

````sql
SELECT
    SUM(CASE 
		WHEN c.exclusions IS NOT NULL AND c.extras IS NOT NULL THEN 1
    		ELSE 0
    END) AS pizza_delivered_w_exclusions_extras
FROM pizza_runner.customer_orders_temp c
JOIN pizza_runner.runner_orders_temp r ON r.order_id = c.order_id 
				   AND r.distance IS NOT NULL;
````

**Answer:**

| pizza_delivered_w_exclusions_extras |
| ------------ |
| 1            |

- Only 1 pizza was delivered that had both extra and exclusion toppings. That’s one fussy customer!

### 9. What was the total volume of pizzas ordered for each hour of the day?

````sql
SELECT
	HOUR(order_time) AS hour_of_day,
	COUNT(order_id) AS order_volume
FROM pizza_runner.customer_orders_temp
GROUP BY HOUR(order_time)
ORDER BY HOUR(order_time);
````

**Answer:**

| hour_of_day | order_volume | 
| ----------- | ------------ | 
| 11          | 1            |
| 13          | 3            |
| 18          | 3            |
| 19          | 1            |
| 21          | 3            |
| 23          | 3            |

- Highest volume of pizza ordered is at 13 (1:00 pm), 18 (6:00 pm), 21 (9:00 pm), and 23 (11:00 pm).
- Lowest volume of pizza ordered is at 11 (11:00 am), and 19 (7:00 pm).

### 10. What was the volume of orders for each day of the week?

````sql
SELECT 
	DAYNAME(order_time) AS week_day,
    	COUNT(order_id) AS order_volume
FROM pizza_runner.customer_orders_temp
GROUP BY DAYNAME(order_time);
````

**Answer:**

| week_day    | order_volume | 
| ----------- | ------------ | 
| Friday      | 5            |
| Saturday    | 3            |
| Sunday      | 1            |
| Monday      | 5            |

- There are 5 pizzas ordered on both Friday and Monday.
- There are 3 pizzas ordered on Saturday.
- There is 1 pizza ordered on Sunday.

***

## B. Runner and Customer Experience

### 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

````sql
SELECT 
	WEEK(ADDDATE(registration_date, INTERVAL 2 DAY)) AS registration_week,
	COUNT(runner_id) AS runner_signup
FROM pizza_runner.runners
GROUP BY registration_week;
````

**Answer:**

| registration_week | runner_signup | 
| ----------- | ------------ | 
| 1           | 2            |
| 2           | 1            |
| 3           | 1            |

- On Week 1 of Jan 2021, 2 new runners signed up.
- On Weeks 2 and 3 of Jan 2021, 1 new runner signed up.

### 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pick up the order?

````sql
WITH time_taken AS (
SELECT 
	c.order_id,
    	r.runner_id,
    	c.order_time,
    	r.pickup_time,
    	TIME_TO_SEC(TIMEDIFF(r.pickup_time,c.order_time)) AS pickup_seconds
FROM pizza_runner.customer_orders_temp c
JOIN pizza_runner.runner_orders_temp r ON r.order_id = c.order_id 
				   AND r.distance IS NOT NULL
GROUP BY c.order_id)
SELECT
	runner_id, 
	ROUND((AVG(pickup_seconds)/60), 2) AS avg_pickup_time_minutes
FROM time_taken
GROUP BY runner_id;
````

**Answer:**

| runner_id   | avg_pickup_time_minutes | 
| ----------- | ------------ | 
| 1           | 14.33            |
| 2           | 20.01            |
| 3           | 10.47            |

- The overall average time taken in minutes by runners to arrive at Pizza Runner HQ to pick up the order is 15 minutes. 

### 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

````sql
WITH prep_time_taken AS (
SELECT 
	r.order_id,
    	COUNT(c.order_id) AS no_of_pizza_ordered,
    	c.order_time,
    	r.pickup_time,
    	TIME_TO_SEC(TIMEDIFF(r.pickup_time,c.order_time)) as prep_time_seconds
FROM pizza_runner.customer_orders_temp c
JOIN pizza_runner.runner_orders_temp r ON r.order_id = c.order_id 
				   AND r.distance IS NOT NULL
GROUP BY c.order_id)
SELECT
	no_of_pizza_ordered,
    	ROUND((AVG(prep_time_seconds)/60), 2) AS avg_order_prep_time_minutes,
	ROUND((AVG(prep_time_seconds)/60)/no_of_pizza_ordered, 2) AS avg_time_per_pizza_minutes
FROM prep_time_taken
GROUP BY no_of_pizza_ordered;
````

**Answer:**

| no_of_pizza_ordered | avg_order_prep_time_minutes | avg_time_per_pizza_minutes | 
| ------------------- | --------------------------- | -------------------------- | 
| 1                   | 12.36                       | 12.36                      |
| 2                   | 18.38                       | 9.19                       |
| 3                   | 29.38                       | 9.76                       |

- On average, a single pizza order takes 12 minutes to prepare.
- An order with 3 pizzas takes 30 minutes at an average of 10 minutes per pizza.
- It takes 18 minutes to prepare an order with 2 pizzas which is 9 minutes per pizza — making 2 pizzas in a single order the ultimate efficiency rate.
- Here we can see that as the number of pizzas in an order goes up, so does the total prep time for that order, as you would expect.
- But then we can also notice that the average preparation time per pizza is higher when you order 1 than when you order multiple.

### 4. What was the average distance traveled for each customer?

````sql
WITH distance_travelled AS (
SELECT 
	r.order_id,
    	c.customer_id,
   	r.distance
FROM pizza_runner.runner_orders_temp r
INNER JOIN pizza_runner.customer_orders_temp c ON r.order_id = c.order_id 
					   AND r.distance IS NOT NULL
GROUP BY r.order_id)
SELECT 
	customer_id,
    	ROUND(AVG(distance),2) AS avg_dist_travelled 
FROM  distance_travelled
GROUP BY customer_id;
````

**Answer:**

| customer_id   | avg_distance | 
| ------------- | ------------ | 
| 101           | 20           |
| 102           | 18.4         |
| 103           | 23.4         |
| 104           | 10           |
| 105           | 25           |

_(Assuming that distance is calculated from Pizza Runner HQ to customer’s place)_

- Customer 104 stays the nearest to Pizza Runner HQ at an average distance of 10km, whereas Customer 105 stays the furthest at 25km.

### 5. What was the difference between the longest and shortest delivery times for all orders?

```sql
SELECT 
	(MAX(duration) - MIN(duration)) AS delivery_time_diff
FROM pizza_runner.runner_orders_temp;
```

**Answer:**

| delivery_time_diff | 
| ------------- |
| 30            |

- The difference between longest (40 minutes) and shortest (10 minutes) delivery time for all orders is 30 minutes.

### 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

````sql
SELECT 
	r.runner_id,
    	c.order_id,
    	COUNT(c.order_id) AS pizza_count,
    	r.distance AS distance_km, 
    	ROUND((r.duration/60),2) AS duration_hr,
	ROUND(r.distance/(r.duration/60),2) AS speed_kmph
FROM pizza_runner.runner_orders_temp r
INNER JOIN pizza_runner.customer_orders_temp c ON r.order_id = c.order_id 
					   AND r.distance IS NOT NULL
GROUP BY c.order_id
ORDER BY runner_id;
````

**Answer:**

| runner_id   | order_id   | pizza_count | distance_km | duration_hr | speed_kmph  |  
| ----------- | ---------- | ----------- | ----------- | ----------- | ----------- |
| 1           | 1          | 1           | 20          | 0.53        | 37.5        |
| 1           | 2          | 1           | 20          | 0.45        | 44.44       |
| 1           | 3          | 2           | 13.4        | 0.33        | 40.2        |
| 1           | 10         | 2           | 10          | 0.17        | 60          |
| 2           | 4          | 3           | 23.4        | 0.67        | 35.1        |
| 2           | 7          | 1           | 25          | 0.42        | 60          |
| 2           | 8          | 1           | 23.4        | 0.25        | 93.6        |
| 3           | 5          | 1           | 10          | 0.25        | 40          |

_(Average speed = Distance in km / Duration in hour)_
- Runner 1’s average speed runs from 37.5 km/h to 60 km/h.
- Runner 2’s average speed runs from 35.1 km/h to 93.6 km/h. Danny should investigate Runner 2 as the average speed has a 300% fluctuation rate!
- Runner 3’s average speed is 40km/h

### 7. What is the successful delivery percentage for each runner?

````sql
SELECT 
	runner_id,
    	CONCAT(ROUND(100 * SUM(CASE
				   WHEN distance IS NULL THEN 0
				   ELSE 1
				END)/COUNT(order_id), 0),"%") AS successful_deliveries
FROM pizza_runner.runner_orders_temp
GROUP BY runner_id;
````

**Answer:**

| runner_id   | successful_deliveries | 
| ----------- | ------------ | 
| 1           | 100%           |
| 2           | 75%            |
| 3           | 50%            |

- Runner 1 has 100% successful delivery.
- Runner 2 has 75% successful delivery.
- Runner 3 has 50% successful delivery

_(It’s not right to attribute successful delivery to runners as order cancellations are out of the runner’s control.)_

***

## C. Ingredient Optimisation

### 1. What are the standard ingredients for each pizza?

````sql
SELECT 
	n.pizza_name,
    	GROUP_CONCAT(r.topping_name SEPARATOR ', ') AS standard_toppings
FROM pizza_runner.pizza_names n
JOIN pizza_runner.pizza_recipes_temp r ON r.pizza_id = n.pizza_id
GROUP BY pizza_name
ORDER BY n.pizza_name;
````

**Answer:**

| pizza_name   | standard_toppings | 
| ------------ | ------------ | 
| Meatlovers   | Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| Vegetarian   | Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce            |

### 2. What was the most commonly added extra?

```sql
WITH RECURSIVE numbers AS (
SELECT 
	1 AS n
UNION ALL
SELECT 
	n + 1
FROM numbers
WHERE n <= (SELECT 
		COUNT(order_id) AS pizza_order_count 
	    FROM pizza_runner.customer_orders)),
extra_toppings AS (
SELECT 
    n.n, 
    CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(all_toppings, ',', n), ',', -1) AS UNSIGNED) AS topping_id
FROM (SELECT
	  GROUP_CONCAT(extras SEPARATOR ',') AS all_toppings,
	  LENGTH(GROUP_CONCAT(extras SEPARATOR ',')) - LENGTH(REPLACE(GROUP_CONCAT(extras SEPARATOR ','), ',', '')) + 1 AS topping_count
      FROM pizza_runner.customer_orders_temp) t
JOIN numbers n ON n.n <= t.topping_count)
SELECT 
	e.topping_id,
    	t.topping_name,
    	COUNT(e.topping_id) AS extras_frequency
FROM extra_toppings e
JOIN pizza_runner.pizza_toppings t ON e.topping_id = t.topping_id
GROUP BY e.topping_id
ORDER BY extras_frequency DESC;
```

**Answer:**

| topping_id | topping_name | extras_frequency | 
| ---------- | ------------ | ----------- | 
| 1          | Bacon        | 4           |
| 4          | Cheese       | 1           |
| 5	     | Chicken      | 1           |

- The most commonly added extra was Bacon, customers added bacon 4 times as an extra topping!!

### 3. What was the most common exclusion?

````sql
WITH RECURSIVE numbers AS (
SELECT 
	1 AS n
UNION ALL
SELECT 
	n + 1
FROM numbers
WHERE n <= (SELECT 
		COUNT(order_id) AS pizza_order_count 
	    FROM pizza_runner.customer_orders)),
excluded_toppings AS (
SELECT 
    	n.n, 
    	CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(all_toppings, ',', n), ',', -1) AS UNSIGNED) AS topping_id
FROM (SELECT
	  GROUP_CONCAT(exclusions SEPARATOR ',') AS all_toppings,
	  LENGTH(GROUP_CONCAT(exclusions SEPARATOR ',')) - LENGTH(REPLACE(GROUP_CONCAT(exclusions SEPARATOR ','), ',', '')) + 1 AS topping_count
      FROM pizza_runner.customer_orders_temp) t
JOIN numbers n ON n.n <= t.topping_count)
SELECT 
	e.topping_id,
    	t.topping_name,
    	COUNT(e.topping_id) AS exclusions_frequency
FROM excluded_toppings e
JOIN pizza_runner.pizza_toppings t ON e.topping_id = t.topping_id
GROUP BY e.topping_id
ORDER BY exclusions_frequency DESC;
````

**Answer:**

| topping_id | topping_name | exclusions_frequency | 
| ---------- | ------------ | ----------- | 
| 4          | Cheese       | 4           |
| 2          | BBQ Sauce    | 1           |
| 6	     | Mushrooms    | 1           |

- The most commonly excluded topping was Cheese, customers excluded Cheese 4 times, which shows that our customers might be lactose intolerant!
- Maybe we can profit by adding a special pizza to our menu with some alternatives.

### 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
- Meat Lovers
- Meat Lovers - Exclude Beef
- Meat Lovers - Extra Bacon
- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

````sql
WITH customer_order AS (
SELECT 
	c.order_id, 
    	c.customer_id, 
    	c.pizza_id, 
    	p.pizza_name, 
    	c.exclusions, 
    	c.extras,
    	c.record_id
FROM  pizza_runner.customer_orders_temp c
JOIN  pizza_runner.pizza_names p ON c.pizza_id = p.pizza_id
),
exclusions_and_extras AS (
SELECT 
	ex.order_id, 
    	ex.pizza_id, 
    	e.exclusions_topping_id,
	ex.extras_topping_id, 
    	e.exclusions, 
    	ex.extras, 
    	ex.record_id
FROM (SELECT 
		e.order_id, 
		e.pizza_id, 
		GROUP_CONCAT(e.exclusions_topping_id SEPARATOR ',') AS exclusions_topping_id,
		GROUP_CONCAT(t.topping_name SEPARATOR ', ') AS exclusions, 
		e.record_id
       FROM  pizza_runner.customer_orders_exclusions_temp e
       LEFT JOIN  pizza_runner.pizza_toppings t ON e.exclusions_topping_id = t.topping_id
       GROUP BY e.order_id, e.record_id) e
JOIN (SELECT 
		e.order_id, 
		e.pizza_id, 
		GROUP_CONCAT(e.extras_topping_id SEPARATOR ',') AS extras_topping_id,
		GROUP_CONCAT(t.topping_name SEPARATOR ', ') AS extras, 
		e.record_id
      FROM  pizza_runner.customer_orders_extras_temp e
      LEFT JOIN  pizza_runner.pizza_toppings t ON e.extras_topping_id = t.topping_id
      GROUP BY e.order_id, e.record_id) ex 
ON ex.order_id = e.order_id AND ex.record_id = e.record_id
)
SELECT 
	c.order_id,
    	c.customer_id, 
   	c.pizza_id, 
    	c.exclusions,
    	c.extras,
    	CASE 
		WHEN c.exclusions IS NULL AND c.extras IS NULL THEN c.pizza_name 
        	WHEN c.exclusions IS NOT NULL AND c.extras IS NULL THEN CONCAT(c.pizza_name," - Exclude ",e.exclusions)
        	WHEN c.exclusions IS NULL AND c.extras IS NOT NULL THEN CONCAT(c.pizza_name," - Extra ",e.extras)
        	ELSE CONCAT(c.pizza_name," - Exclude ",e.exclusions," - Extra ",e.extras)
	END AS order_item
FROM customer_order c
JOIN exclusions_and_extras e ON c.order_id = e.order_id AND c.record_id = e.record_id;
````

**Answer:**

| order_id    | customer_id | pizza_id    | exclusions  | extras      | order_item                                                      |  
| ----------- | ----------- | ----------- | ----------- | ----------- | --------------------------------------------------------------- |
| 1           | 101         | 1           | `NULL`      | `NULL`      | Meatlovers                                                      |
| 2           | 101         | 1           | `NULL`      | `NULL`      | Meatlovers                                                      |
| 3           | 102         | 1           | `NULL`      | `NULL`      | Meatlovers                                                      |
| 3           | 102         | 2           | `NULL`      | `NULL`      | Vegetarian                                                      |
| 4           | 103         | 1           | 4           | `NULL`      | Meatlovers - Exclude Cheese                                     |
| 4           | 103         | 1           | 4           | `NULL`      | Meatlovers - Exclude Cheese                                     | 
| 4           | 103         | 2           | 4           | `NULL`      | Vegetarian - Exclude Cheese                                     |
| 5           | 104         | 1           | `NULL`      | 1           | Meatlovers - Extra Bacon                                        |
| 6           | 101         | 2           | `NULL`      | `NULL`      | Vegetarian                                                      |
| 7           | 105         | 2           | `NULL`      | 1           | Vegetarian - Extra Bacon                                        |
| 8           | 102         | 1           | `NULL`      | `NULL`      | Meatlovers                                                      |
| 9           | 103         | 1           | 4           | 1, 5        | Meatlovers - Exclude Cheese - Extra Bacon, Chicken              |
| 10          | 104         | 1           | `NULL`      | `NULL`      | Meatlovers                                                      |
| 10          | 104         | 1           | 2, 6        | 1, 4        | Meatlovers - Exclude BBQ Sauce, Mushrooms - Extra Bacon, Cheese |


### 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
For example: "Meat Lovers: 2xBacon, Beef, ... , Salami

````sql
WITH extras AS (
SELECT 
	record_id,
    	pizza_id,
    	extras_topping_id
FROM pizza_runner.customer_orders_extras_temp 
WHERE extras_topping_id IS NOT NULL),
exclusions AS (
SELECT 
	record_id, 
    	exclusions_topping_id 
FROM pizza_runner.customer_orders_exclusions_temp
WHERE exclusions_topping_id IS NOT NULL),
all_ingredients AS (
SELECT 
	c.record_id,
    	c.pizza_id,
    	r.topping_id,
    	r.topping_name AS topping
FROM pizza_runner.customer_orders_temp c
JOIN pizza_runner.pizza_recipes_temp r ON c.pizza_id = r.pizza_id
WHERE r.topping_id NOT IN (SELECT 
				exclusions_topping_id 
			    FROM exclusions e 
			    WHERE e.record_id = c.record_id)
UNION ALL SELECT 
	e.record_id, 
    	e.pizza_id, 
    	e.extras_topping_id, 
    	NULL AS topping_name
FROM extras e),
ranked_ingredients AS (
SELECT
	i.record_id, 
    	n.pizza_name, 
    	i.topping_id,
    	t.topping_name,
    	RANK() OVER (partition by i.record_id order by t.topping_name) AS ranking
FROM all_ingredients i
JOIN pizza_runner.pizza_names n ON i.pizza_id = n.pizza_id
JOIN pizza_runner.pizza_toppings t ON i.topping_id = t.topping_id
ORDER BY record_id, topping_id)
SELECT 
	r.record_id,
    	CONCAT(r.pizza_name,': ',GROUP_CONCAT(r.ingredient_list SEPARATOR ', ')) AS ingredient_list
FROM (SELECT 
	*,
        IF(COUNT(*)>1, CONCAT("2x ", topping_name), topping_name) AS ingredient_list 
      FROM ranked_ingredients
      GROUP BY record_id, ranking) r
GROUP BY r.record_id, r.pizza_name;
````

**Answer:**

| record_id   | order_item                                                                           |  
| ----------- | ------------------------------------------------------------------------------------ |
| 1           | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami    |
| 2           | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami    |
| 3           | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami    |
| 4           | Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce               |
| 5           | Meatlovers: Bacon, BBQ Sauce, Beef, Chicken, Mushrooms, Pepperoni, Salami            |
| 6           | Meatlovers: Bacon, BBQ Sauce, Beef, Chicken, Mushrooms, Pepperoni, Salami            | 
| 7           | Vegetarian: Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce                       |
| 8           | Meatlovers: 2x Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 9           | Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce               |
| 10          | Vegetarian: Bacon, Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce        |
| 11          | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami    |
| 12          | Meatlovers: 2x Bacon, BBQ Sauce, Beef, 2x Chicken, Mushrooms, Pepperoni, Salami      |
| 13          | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami    |
| 14          | Meatlovers: 2x Bacon, Beef, 2x Cheese, Chicken, Pepperoni, Salami                    |


### 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

````sql
WITH extras AS (
SELECT
	order_id,
	record_id,
    	pizza_id,
    	extras_topping_id
FROM pizza_runner.customer_orders_extras_temp 
WHERE extras_topping_id IS NOT NULL),
exclusions AS (
SELECT 
	record_id, 
    	exclusions_topping_id 
FROM pizza_runner.customer_orders_exclusions_temp
WHERE exclusions_topping_id  IS NOT NULL),
all_ingredients AS (
SELECT 
	c.order_id,
    	c.record_id,
    	c.pizza_id,
    	r.topping_id,
    	r.topping_name AS topping
FROM pizza_runner.customer_orders_temp c
JOIN pizza_runner.pizza_recipes_temp r ON c.pizza_id = r.pizza_id
WHERE r.topping_id NOT IN (SELECT 
				exclusions_topping_id 
			   FROM exclusions e 
			   WHERE e.record_id = c.record_id)
UNION ALL SELECT 
	e.order_id,
    	e.record_id, 
    	e.pizza_id, 
    	e.extras_topping_id, 
    	NULL AS topping_name
FROM extras e
),
ranked_ingredients AS (
SELECT 
	i.order_id,
	i.record_id, 
    	n.pizza_name, 
    	i.topping_id,
    	t.topping_name,
    	RANK() OVER (partition by i.record_id order by t.topping_name) AS ranking
FROM all_ingredients i
JOIN pizza_runner.pizza_names n ON i.pizza_id = n.pizza_id
JOIN pizza_runner.pizza_toppings t ON i.topping_id = t.topping_id
ORDER BY record_id, topping_id)
SELECT 
	ri.topping_name, 
    	COUNT(ri.topping_name) AS quantity
FROM ranked_ingredients ri
JOIN pizza_runner.runner_orders_temp ro ON ri.order_id = ro.order_id 
				AND ro.cancellation IS NULL
GROUP BY ri.topping_name
ORDER BY quantity DESC;
````

**Answer:**

| topping_name  | quantity | 
| ------------- | -------- | 
| Bacon         | 12       |
| Mushrooms     | 11       |
| Cheese        | 10       |
| Beef          | 9        |
| Chicken       | 9        |
| Pepperoni     | 9        |
| Salami        | 9        |
| BBQ Sauce     | 8        |
| Onions        | 3        |
| Peppers       | 3        |
| Tomatoes      | 3        |
| Tomato Sauce  | 3        |

- The most used ingredients are Bacon, Mushrooms, and Cheese whereas Onions, Peppers, Tomatoes, and Tomato Sauce were the least used ingredients in our delivered pizzas.

***

## D. Pricing and Ratings

### 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10, and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

````sql
SELECT
	SUM(CASE
		WHEN c.pizza_id = 1 THEN 12
	        ELSE 10
	     END) AS total_revenue
FROM pizza_runner.customer_orders_temp c
JOIN pizza_runner.runner_orders_temp r ON r.order_id = c.order_id
				AND r.cancellation IS NULL;
````

**Answer:**

| total_revenue |
| ------------- |
| 138           |

- Pizza Runner generated a revenue of $138 for 8 delivered orders, maybe we should charge some money for any extras.

### 2. What if there was an additional $1 charge for any pizza extras?
- Add cheese is $1 extra

````sql
WITH prices AS (
SELECT
    	c.record_id,
	c.order_id,
	c.pizza_id,
	CASE
		WHEN c.pizza_id = 1 THEN 12
		ELSE 10
	END AS pizza_cost,
    	GROUP_CONCAT(e.extras_topping_id SEPARATOR ',') AS extras_topping_id,
    	COUNT(DISTINCT e.extras_topping_id) AS no_of_extras
FROM pizza_runner.customer_orders_temp c
JOIN pizza_runner.runner_orders_temp r ON r.order_id = c.order_id
				AND r.cancellation IS NULL
JOIN pizza_runner.customer_orders_extras_temp e ON e.record_id = c.record_id
GROUP BY c.record_id)
SELECT 
	SUM(pizza_cost + (no_of_extras * 1)) as total_revenue
FROM prices;
````

**Answer:**

| total_revenue |
| ------------- |
| 142           |

- If we charge $1 for each extra, Pizza Runner generated a revenue of $142.

### 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

````sql
DROP TABLE IF EXISTS runner_ratings;
CREATE TABLE runner_ratings (
	order_id INT,
    	customer_id INT,
    	runner_id INT,
    	no_of_pizzas_ordered INT,
    	distance_km FLOAT,
    	time_taken_minutes FLOAT,
    	rating ENUM('1', '2', '3', '4', '5')
);

INSERT INTO pizza_runner.runner_ratings
(order_id ,rating)
VALUES 
(1,3),
(2,4),
(3,5),
(4,2),
(5,1),
(6,NULL),
(7,4),
(8,1),
(9,NULL),
(10,5);

UPDATE pizza_runner.runner_ratings r
JOIN (
SELECT 
	c.order_id, 
	c.customer_id,
    	r.runner_id,
    	COUNT(c.pizza_id) AS no_of_pizzas,
    	r.distance, 
    	r.duration
FROM pizza_runner.customer_orders_temp c 
JOIN pizza_runner.runner_orders_temp r ON r.order_id = c.order_id
GROUP BY c.order_id) c
ON r.order_id = c.order_id
SET r.customer_id = c.customer_id, 
    r.runner_id = c.runner_id,
    r.no_of_pizzas_ordered = c.no_of_pizzas,
    r.distance_km = c.distance,
    r.time_taken_minutes = c.duration;
````

**Answer:**

- This is what a `runner_rating` table would look like:

| order_id    | customer_id | runner_id  | no_of_pizzas_ordered | distance_km | time_taken_minutes | rating  |  
| ----------- | ----------- | ---------- | -------------------- | ----------- | ------------------ | ------- |
| 1           | 101         | 1          | 1                    | 20          | 32                 | 3       |
| 2           | 101         | 1          | 1                    | 20          | 27                 | 4       |
| 3           | 102         | 1          | 2                    | 13.4        | 20                 | 5       |
| 4           | 103         | 2          | 3                    | 23.4        | 40                 | 2       |
| 5           | 104         | 3          | 1                    | 10          | 15                 | 1       |
| 6           | 101         | 3          | 1                    | `NULL`      | `NULL`             | `NULL`  |
| 7           | 105         | 2          | 1                    | 25          | 25                 | 4       |
| 8           | 102         | 2          | 1                    | 23.4        | 15                 | 1       |
| 9           | 103         | 2          | 1                    | `NULL`      | `NULL`             | `NULL`  |
| 10          | 104         | 1          | 2                    | 10          | 10                 | 5       |

- I have included columns like `customer_id`, `runner_id`, `no_of_pizzas_ordered`, `distance_km`, and `time_taken_minutes` so that we can analyze the runner ratings on different parameters. We can understand how fast a delivery was made and for how many pizzas.
- It could also point towards the average rating of a runner or the rating pattern of a particular customer.
- For ex: For order 5, runner 3 delivered a pizza for customer 104 in about 15 mins for a distance of 10 kms and got a rating of 1 out of 5, on the contrary for order 10, runner 1 delivered 2 pizzas for customer 104 in about 10 mins for a distance of 10 kms and got a rating of 5 out of 5. The rating might point towards the dissatisfaction of the customer due to the time taken or maybe even the runner's behaviour, but to be certain we might need to consider more factors.

 
### 4. Using your newly generated table - can you join all of the information together to form a table that has the following information for successful deliveries?
- customer_id
- order_id
- runner_id
- rating
- order_time
- pickup_time
- Time between order and pickup
- Delivery duration
- Average speed
- Total number of pizzas

````sql
SELECT
	c.customer_id,
	c.order_id,
	r.runner_id,
	rr.rating,
	c.order_time,
	r.pickup_time,
	ROUND(TIME_TO_SEC(TIMEDIFF(r.pickup_time,c.order_time))/60, 2) as prep_time_minutes,
	r.duration AS delivery_duration_minutes,
	ROUND(r.distance/(r.duration/60),2) AS average_speed_kmph,
	COUNT(c.pizza_id) AS total_no_of_pizzas
FROM pizza_runner.customer_orders_temp c 
JOIN pizza_runner.runner_orders_temp r ON r.order_id = c.order_id
JOIN pizza_runner.runner_ratings rr ON rr.order_id = r.order_id
GROUP BY c.order_id;
````

**Answer:**

| order_id    | customer_id | runner_id  | rating | order_time          | pickup_time         | prep_time_minutes | delivery_duration_minutes | avg_speed_kmph | total_no_of_pizzas |
| ----------- | ----------- | ---------- | ------ | ------------------- | ------------------- | ----------------- | ------------------------- | -------------- | ------------------ |
| 1           | 101         | 1          | 3      | 2021-01-01 18:05:02 | 2021-01-01 18:15:34 | 10.53             | 32                        | 37.5           | 1                  |
| 2           | 101         | 1          | 4      | 2021-01-01 19:00:52 | 2021-01-01 19:10:54 | 10.03             | 27                        | 44.44          | 1                  |
| 3           | 102         | 1          | 5      | 2021-01-02 23:51:23 | 2021-01-03 00:12:37 | 21.23             | 20                        | 40.2           | 2                  |
| 4           | 103         | 2          | 2      | 2021-01-04 13:23:46 | 2021-01-04 13:53:03 | 29.28             | 40                        | 35.1           | 3                  |
| 5           | 104         | 3          | 1      | 2021-01-08 21:00:29 | 2021-01-08 21:10:57 | 10.47             | 15                        | 40             | 1                  |
| 6           | 101         | 3          | `NULL` | 2021-01-08 21:03:13 | `NULL`              | `NULL`            | `NULL`                    | `NULL`         | 1                  |
| 7           | 105         | 2          | 4      | 2021-01-08 21:20:29 | 2021-01-08 21:30:45 | 10.27             | 25                        | 60             | 1                  |
| 8           | 102         | 2          | 1      | 2021-01-09 23:54:33 | 2021-01-10 00:15:02 | 20.48             | 15                        | 93.6           | 1                  |
| 9           | 103         | 2          | `NULL` | 2021-01-10 11:22:59 | `NULL`              | `NULL`            | `NULL`                    | `NULL`         | 1                  |
| 10          | 104         | 1          | 5      | 2021-01-11 18:34:49 | 2021-01-11 18:50:20 | 15.52             | 10                        | 60             | 2                  |


### 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

````sql
WITH finances AS (
SELECT
	c.order_id,
    	SUM(CASE
		WHEN c.pizza_id = 1 THEN 12
		ELSE 10
	END) AS revenue,
    	r.distance * 0.30 AS runner_payout
FROM pizza_runner.customer_orders_temp c
JOIN pizza_runner.runner_orders_temp r ON r.order_id = c.order_id
				AND r.cancellation IS NULL
GROUP BY c.order_id)
SELECT 
	ROUND(SUM(revenue), 2) AS total_revenue,
    	ROUND(SUM(runner_payout), 2) AS total_runner_payout,
	ROUND(SUM(revenue) - SUM(runner_payout), 2) AS profit 
FROM finances;
````

**Answer:**

| total_revenue | total_runner_payout | profit     | 
| ------------- | ------------------- | ---------- |
| 138           | 43.56               | 94.44      |

- The total revenue generated was $138, and after paying all the runners about $43.56, Pizza Runner made a profit of $94.44.

***

## E. Bonus Questions

### If Danny wants to expand his range of pizzas - how would this impact the existing data  design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza  with all the toppings was added to the Pizza Runner menu.

````sql
INSERT INTO pizza_names
VALUES (3, "Supreme");

SELECT * FROM pizza_names;
````
The updated `pizza_names` table looks like this:

![image](https://github.com/PreetKothari/8-Week-SQL-Challenge/assets/87279526/69926b4b-26da-42eb-b8c9-5f78be536d76)

````sql
INSERT INTO pizza_recipes_temp
WITH RECURSIVE numbers AS (
SELECT
	3 AS pizza_id,
	1 AS n
UNION ALL
SELECT
	3 AS pizza_id,
	n + 1
FROM numbers
WHERE n <= 12)
SELECT n.pizza_id, n.n AS topping_id, t.topping_name FROM numbers n
JOIN pizza_runner.pizza_toppings t ON t.topping_id = n.n;

SELECT * FROM pizza_recipes_temp;
````
The updated `pizza_recipes_temp` table looks like this:

![image](https://github.com/PreetKothari/8-Week-SQL-Challenge/assets/87279526/db4316f5-0e71-44e8-9294-ccac8fb0a6a2)

- Because the pizza recipes table was modified to reflect foreign key designation for each topping linked to the base pizza, the pizza_id will have multiple 3s and align with the standard toppings (individually) within the toppings column.
- In addition, because the data type was cast to an int to take advantage of numerical functions, the insertion of data would not affect the existing data design, unlike the original dangerous approach of comma-separated values in a singular row (list).



