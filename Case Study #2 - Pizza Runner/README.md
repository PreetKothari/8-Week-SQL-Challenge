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

### 4. Is there any relationship between the number of pizzas and how long the order takes to prepare?

````sql
SELECT 
  c.customer_id, 
  AVG(r.distance) AS avg_distance
FROM #customer_orders AS c
JOIN #runner_orders AS r
  ON c.order_id = r.order_id
WHERE r.duration != 0
GROUP BY c.customer_id;
````

**Answer:**

![image](https://user-images.githubusercontent.com/81607668/129739847-5e338f4f-b42c-4531-9685-e2e822063183.png)

_(Assuming that distance is calculated from Pizza Runner HQ to customer’s place)_

- Customer 104 stays the nearest to Pizza Runner HQ at average distance of 10km, whereas Customer 105 stays the furthest at 25km.

### 5. What was the difference between the longest and shortest delivery times for all orders?

_Edit 08/10/21: Thanks to my reader, Ankush Taneja on Medium who caught my mistake. I've amended to the correct solution. Also, I was doing this case study using SQL Server few months ago, but I'm using PostgreSQL on SQLpad now so there could be a slight difference to the syntax._

Firstly, I'm going to filter results with non-null duration first just to have a feel. You can skip this step and go straight to the answer.

````sql
SELECT 
  order_id, duration
FROM #runner_orders
WHERE duration not like ' ';
````

<img width="269" alt="image" src="https://user-images.githubusercontent.com/81607668/136523519-98efb655-d144-496b-a946-42c1c5415403.png">

```sql
SELECT MAX(duration::NUMERIC) - MIN(duration::NUMERIC) AS delivery_time_difference
FROM runner_orders2
where duration not like ' ';
```

**Answer:**

<img width="196" alt="image" src="https://user-images.githubusercontent.com/81607668/136523820-c4504a25-83f8-4236-b08e-37bf542caad0.png">

- The difference between longest (40 minutes) and shortest (10 minutes) delivery time for all orders is 30 minutes.

### 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

````sql
SELECT 
  r.runner_id, 
  c.customer_id, 
  c.order_id, 
  COUNT(c.order_id) AS pizza_count, 
  r.distance, (r.duration / 60) AS duration_hr , 
  ROUND((r.distance/r.duration * 60), 2) AS avg_speed
FROM #runner_orders AS r
JOIN #customer_orders AS c
  ON r.order_id = c.order_id
WHERE distance != 0
GROUP BY r.runner_id, c.customer_id, c.order_id, r.distance, r.duration
ORDER BY c.order_id;
````

**Answer:**

![image](https://user-images.githubusercontent.com/81607668/129739931-54127037-0879-43bf-b53f-e4a1a6ebffeb.png)

_(Average speed = Distance in km / Duration in hour)_
- Runner 1’s average speed runs from 37.5km/h to 60km/h.
- Runner 2’s average speed runs from 35.1km/h to 93.6km/h. Danny should investigate Runner 2 as the average speed has a 300% fluctuation rate!
- Runner 3’s average speed is 40km/h

### 7. What is the successful delivery percentage for each runner?

````sql
SELECT 
  runner_id, 
  ROUND(100 * SUM(
    CASE WHEN distance = 0 THEN 0
    ELSE 1 END) / COUNT(*), 0) AS success_perc
FROM #runner_orders
GROUP BY runner_id;
````

**Answer:**

![image](https://user-images.githubusercontent.com/81607668/129740007-021d78fb-ec32-46c0-98f2-9e8f1891baed.png)

- Runner 1 has 100% successful delivery.
- Runner 2 has 75% successful delivery.
- Runner 3 has 50% successful delivery

_(It’s not right to attribute successful delivery to runners as order cancellations are out of the runner’s control.)_

***

## C. Ingredient Optimisation

### 1. What are the standard ingredients for each pizza?

### 2. What was the most commonly added extra?

```sql
WITH toppings_cte AS (
SELECT
  pizza_id,
  REGEXP_SPLIT_TO_TABLE(toppings, '[,\s]+')::INTEGER AS topping_id
FROM pizza_runner.pizza_recipes)

SELECT 
  t.topping_id, pt.topping_name, 
  COUNT(t.topping_id) AS topping_count
FROM toppings_cte t
INNER JOIN pizza_runner.pizza_toppings pt
  ON t.topping_id = pt.topping_id
GROUP BY t.topping_id, pt.topping_name
ORDER BY topping_count DESC;
```

**Solution**

<img width="582" alt="image" src="https://user-images.githubusercontent.com/81607668/138807557-08909e2e-8201-4e53-87b8-f927928292fb.png">

### 3. What was the most common exclusion?

### 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
- Meat Lovers
- Meat Lovers - Exclude Beef
- Meat Lovers - Extra Bacon
- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

### 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients

### 6. For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

### 7. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

***

## D. Pricing and Ratings

1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
2. What if there was an additional $1 charge for any pizza extras?
- Add cheese is $1 extra
3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
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
5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

***
