USE pizza_runner;

SELECT * FROM pizza_names;
SELECT * FROM pizza_toppings;
SELECT * FROM runners;

SELECT * FROM pizza_recipes;

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

SELECT * FROM pizza_recipes_temp;

-- SELECT REPLACE(REPLACE(toppings," ","")," ","") FROM pizza_recipes;

/*DROP TEMPORARY TABLE IF EXISTS pizza_recipes_temp;
CREATE TEMPORARY TABLE pizza_recipes_temp(
  pizza_id INTEGER,
  topping_id INTEGER
);
INSERT INTO pizza_recipes_temp
	(pizza_id, topping_id) 
VALUES
	(1,1),
	(1,2),
	(1,3),
	(1,4),
	(1,5),
	(1,6),
	(1,8),
	(1,10),
	(2,4),
	(2,6),
	(2,7),
	(2,9),
	(2,11),
	(2,12);

SELECT * FROM pizza_recipes_temp;*/

SELECT * FROM customer_orders;

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

SELECT * FROM customer_orders_temp;

/*SELECT *,
	ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY pizza_id)
FROM customer_orders_temp;*/

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
/*WITH RECURSIVE unwound_exclusions AS (
SELECT 
	order_id, 
    pizza_id, 
    exclusions,
    ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY pizza_id) AS row_num
FROM pizza_runner.customer_orders_temp
UNION ALL
SELECT
	order_id,
	pizza_id, 
	REGEXP_REPLACE(REPLACE(exclusions," ",""), '^[^,]*,', '') AS exclusions,
    row_num
FROM unwound_exclusions
WHERE exclusions LIKE '%,%')
SELECT 
	order_id,
	pizza_id,
    CAST(REGEXP_REPLACE(exclusions, ',.*', '') AS UNSIGNED) AS exclusions_topping_id,
    row_num
FROM unwound_exclusions
ORDER BY order_id, pizza_id;*/

SELECT * FROM customer_orders_exclusions_temp;

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

/*
WITH RECURSIVE unwound_extras AS (
SELECT 
	order_id, 
    pizza_id, 
    extras,
    ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY pizza_id) AS row_num
FROM pizza_runner.customer_orders_temp
UNION ALL
SELECT
	order_id,
	pizza_id, 
	REGEXP_REPLACE(REPLACE(extras," ",""), '^[^,]*,', '') AS extras,
    row_num
FROM unwound_extras
WHERE extras LIKE '%,%')
SELECT 
	order_id,
	pizza_id,
    CAST(REGEXP_REPLACE(extras, ',.*', '') AS UNSIGNED) AS extras_topping_id,
    row_num
FROM unwound_extras
ORDER BY order_id, pizza_id;*/

SELECT * FROM customer_orders_extras_temp;

SELECT * FROM runner_orders;

/*SELECT POSITION("k" IN "23.4 km  ");
SELECT RTRIM("23.4 km  ");
SELECT LENGTH(RTRIM(SUBSTR("23.4 km  ",1,POSITION("k" IN "23.4 km  ")-1)));*/

/*CASE 
		WHEN pickup_time LIKE '%null%' THEN NULL
        ELSE pickup_time
    END AS pickup_time,
    CASE 
		WHEN distance IS NULL OR distance LIKE '%null%' THEN ''
        WHEN distance LIKE '%km' THEN RTRIM(SUBSTR(distance,1,POSITION("k" IN distance)-1))
        ELSE distance
    END AS distance,
    CASE 
		WHEN duration IS NULL OR duration LIKE '%null%' THEN ''
        WHEN duration LIKE '%mins' OR duration LIKE '%minutes' OR duration LIKE '%minute' 
			THEN RTRIM(SUBSTR(duration,1,POSITION("m" IN duration)-1))
        ELSE duration
    END AS duration,*/

DROP TEMPORARY TABLE IF EXISTS runner_orders_temp;
CREATE TEMPORARY TABLE runner_orders_temp
SELECT order_id, runner_id, 
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

SELECT * FROM runner_orders_temp;

ALTER TABLE runner_orders_temp
CHANGE COLUMN pickup_time pickup_time DATETIME,
CHANGE COLUMN distance distance FLOAT,
CHANGE COLUMN duration duration INT;

# A. Pizza Metrics

/*1. How many pizzas were ordered?*/
SELECT 
	COUNT(order_id) AS pizza_order_count 
FROM pizza_runner.customer_orders_temp;

/*2. How many unique customer orders were made?*/
SELECT 
	COUNT(DISTINCT order_id) AS unique_orders 
FROM pizza_runner.customer_orders_temp;

/*3. How many successful orders were delivered by each runner?*/
SELECT 
	runner_id, 
    COUNT(order_id) AS successful_orders
FROM pizza_runner.runner_orders_temp
WHERE distance IS NOT NULL 
GROUP BY runner_id;

/*4. How many of each type of pizza was delivered?*/
SELECT 
	p.pizza_name, 
    COUNT(c.pizza_id) AS delivered_pizzas 
FROM pizza_runner.customer_orders_temp c
JOIN pizza_runner.runner_orders_temp r ON c.order_id = r.order_id 
								   AND r.pickup_time IS NOT NULL
JOIN pizza_runner.pizza_names p ON c.pizza_id = p.pizza_id
GROUP BY p.pizza_name
ORDER BY c.pizza_id;

/*5. How many Vegetarian and Meatlovers were ordered by each customer?*/
SELECT 
	c.customer_id,
    p.pizza_name,
    COUNT(c.pizza_id) AS order_count
FROM pizza_runner.customer_orders_temp c
JOIN pizza_runner.pizza_names p ON c.pizza_id = p.pizza_id
GROUP BY c.customer_id, p.pizza_name
ORDER BY c.customer_id, c.pizza_id;

/*6. What was the maximum number of pizzas delivered in a single order?*/
SELECT 
	c.order_id,
    COUNT(c.order_id) AS pizza_per_order 
FROM pizza_runner.customer_orders_temp c
JOIN pizza_runner.runner_orders_temp r ON r.order_id = c.order_id 
									   AND r.distance IS NOT NULL
GROUP BY c.order_id
ORDER BY COUNT(c.order_id) DESC;

/*7. For each customer, how many delivered pizzas had at least 1 change and how many had 
no changes?*/
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

/*8. How many pizzas were delivered that had both exclusions and extras?*/
SELECT
    SUM(CASE 
			WHEN c.exclusions IS NOT NULL AND c.extras IS NOT NULL THEN 1
            ELSE 0
		END) AS pizza_delivered_w_exclusions_extras
FROM pizza_runner.customer_orders_temp c
JOIN pizza_runner.runner_orders_temp r ON r.order_id = c.order_id 
									   AND r.distance IS NOT NULL;

/*9. What was the total volume of pizzas ordered for each hour of the day?*/
SELECT
	HOUR(order_time) AS hour_of_day,
	COUNT(order_id) AS order_volume
FROM pizza_runner.customer_orders_temp
GROUP BY HOUR(order_time)
ORDER BY HOUR(order_time);

/*10. What was the volume of orders for each day of the week?*/
SELECT 
	DAYNAME(order_time) AS week_day,
    COUNT(order_id) AS order_volume
FROM pizza_runner.customer_orders_temp
GROUP BY DAYNAME(order_time);

# B. Runner and Customer Experience

/*1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)*/
SELECT 
	WEEK(ADDDATE(registration_date, INTERVAL 2 DAY)) AS registration_week,
	COUNT(runner_id) AS runner_signup
FROM pizza_runner.runners
GROUP BY registration_week;


/*SELECT
	CASE
		WHEN registration_date >= "2021-01-01" 
			 AND registration_date < ADDDATE("2021-01-01", INTERVAL 1 WEEK) THEN 1
		WHEN registration_date >= ADDDATE("2021-01-01", INTERVAL 1 WEEK)
					AND registration_date < ADDDATE("2021-01-01", INTERVAL 2 WEEK) THEN 2
		ELSE 3
	END AS registration_week,
	COUNT(runner_id) AS runner_signup
FROM pizza_runner.runners
GROUP BY registration_week;*/

/*2. What was the average time in minutes it took for each runner to arrive at the Pizza 
Runner HQ to pickup the order?*/
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

/*SELECT
	runner_id,
	MINUTE(SEC_TO_TIME(AVG(pickup_seconds))) AS avg_pickup_time_minutes,
    TIME_FORMAT(SEC_TO_TIME(AVG(pickup_seconds)),"%i:%s") 
FROM time_taken
GROUP BY runner_id;*/

/*3. Is there any relationship between the number of pizzas and how long the order takes to 
prepare?*/
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

/*
SELECT
	no_of_pizza_ordered,
	MINUTE(SEC_TO_TIME(AVG(prep_time_seconds))) AS avg_prep_time_minutes
FROM prep_time_taken
GROUP BY no_of_pizza_ordered;*/

/*4. What was the average distance travelled for each customer?*/
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

/*5. What was the difference between the longest and shortest delivery times for all orders?*/
SELECT 
	MAX(duration)-MIN(duration) AS delivery_time_diff
FROM pizza_runner.runner_orders_temp;

/*6. What was the average speed for each runner for each delivery and do you notice any trend 
for these values?*/
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

/*7. What is the successful delivery percentage for each runner?*/
SELECT 
	runner_id,
    CONCAT(ROUND(100 * SUM(
		CASE
			WHEN distance IS NULL THEN 0
            ELSE 1
		END)/COUNT(order_id), 0),"%") AS successful_deliveries
FROM pizza_runner.runner_orders_temp
GROUP BY runner_id;

# C. Ingredient Optimisation

/*1. What are the standard ingredients for each pizza?*/

SELECT 
	n.pizza_name,
    GROUP_CONCAT(r.topping_name SEPARATOR ', ') AS standard_toppings
FROM pizza_runner.pizza_names n
JOIN pizza_runner.pizza_recipes_temp r ON r.pizza_id = n.pizza_id
GROUP BY pizza_name
ORDER BY n.pizza_name;

/*WITH we AS (
SELECT 
	n.pizza_name,
    GROUP_CONCAT(r.topping_name SEPARATOR ', ') AS standard_toppings
FROM pizza_runner.pizza_names n
JOIN pizza_runner.pizza_recipes_temp r ON r.pizza_id = n.pizza_id
GROUP BY pizza_name
ORDER BY n.pizza_name)
SELECT pizza_name, 
	CASE
		WHEN LOCATE("Bacon",standard_toppings) = 0 THEN NULL
        ELSE REPLACE(standard_toppings,"Bacon,","")
	END AS col1,
    standard_toppings
FROM we;*/
    
/*2. What was the most commonly added extra?*/

/*DROP TABLE IF EXISTS numbers;
CREATE TABLE numbers (
	num INT PRIMARY KEY
);
INSERT INTO numbers VALUES
( 1 ), ( 2 ), ( 3 ), ( 4 ), ( 5 ), ( 6 ), ( 7 ), ( 8 ), ( 9 ), ( 10 ),( 11 ), ( 12 ), ( 13 ), ( 14 );
WITH cte AS (SELECT n.num, SUBSTRING_INDEX(SUBSTRING_INDEX(all_tags, ',', num), ',', -1) as one_tag
FROM (
SELECT
GROUP_CONCAT(extras SEPARATOR ',') AS all_tags,
LENGTH(GROUP_CONCAT(extras SEPARATOR ',')) - LENGTH(REPLACE(GROUP_CONCAT(extras SEPARATOR ','), ',', '')) + 1 AS count_tags
FROM customer_orders_temp
) t
JOIN numbers n
ON n.num <= t.count_tags)
select one_tag as Extras,pizza_toppings.topping_name as ExtraTopping, count(one_tag) as Occurrencecount
from cte
inner join pizza_toppings
on pizza_toppings.topping_id = cte.one_tag
where one_tag != 0
group by one_tag;*/

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

/*3. What was the most common exclusion?*/
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


/*4. Generate an order item for each record in the customers_orders table in the format of one 
of the following:
- Meat Lovers
- Meat Lovers - Exclude Beef
- Meat Lovers - Extra Bacon
- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers*/
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

/*5. Generate an alphabetically ordered comma separated ingredient list for each pizza order 
from the customer_orders table and add a 2x in front of any relevant ingredients
For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"*/

/*Works but it is complicated with many CTEs, hopefully can make it better in future.*/
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

/* problem in getting an extra when pizza doesn't have that topping in recipe otherwise is good
WITH extras AS (
SELECT 
	record_id, 
    extras_topping_id
FROM customer_orders_extras_temp 
WHERE extras_topping_id IS NOT NULL),
exclusions AS (
SELECT 
	record_id, 
    exclusions_topping_id 
FROM customer_orders_exclusions_temp
WHERE exclusions_topping_id  IS NOT NULL),
ingredients AS (
SELECT 
	c.record_id,
	n.pizza_name,
    r.topping_id,
    CASE 
		WHEN r.topping_id IN (SELECT
									e.extras_topping_id
							   FROM extras e
							   WHERE c.record_id = e.record_id) THEN CONCAT("2x ", r.topping_name)
		ELSE r.topping_name
	END AS topping
FROM customer_orders_temp c
JOIN pizza_names n ON c.pizza_id = n.pizza_id
JOIN pizza_recipes_temp r ON c.pizza_id = r.pizza_id
WHERE r.topping_id NOT IN (SELECT 
								exclusions_topping_id 
							FROM exclusions e 
							WHERE e.record_id = c.record_id)
ORDER BY c.record_id, r.topping_name)
SELECT 
	i.record_id,
    CONCAT(pizza_name,': ',GROUP_CONCAT(i.topping SEPARATOR ', ')) AS ingredient_list
FROM ingredients i
GROUP BY i.record_id, i.pizza_name;*/

/*6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most 
frequent first?*/

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

# D. Pricing and Ratings

/*1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for 
changes - how much money has Pizza Runner made so far if there are no delivery fees?*/

SELECT
	SUM(CASE
			WHEN c.pizza_id = 1 THEN 12
            ELSE 10
		END) AS total_revenue
FROM pizza_runner.customer_orders_temp c
JOIN pizza_runner.runner_orders_temp r ON r.order_id = c.order_id
									AND r.cancellation IS NULL;

/*
WITH delivered_pizzas AS (
SELECT 
	c.pizza_id,
	COUNT(c.pizza_id) AS no_delivered,
    CASE 
		WHEN c.pizza_id = 1 THEN (COUNT(c.pizza_id) * 12)
        WHEN c.pizza_id = 2 THEN (COUNT(c.pizza_id) * 10)
	END AS revenue
FROM pizza_runner.customer_orders_temp c
JOIN pizza_runner.runner_orders_temp r ON r.order_id = c.order_id 
									AND r.cancellation IS NULL
GROUP BY c.pizza_id
)
SELECT 
	SUM(revenue) AS total_revenue 
FROM delivered_pizzas;*/

/*2. What if there was an additional $1 charge for any pizza extras?
- Add cheese is $1 extra*/

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

/*SELECT 
	SUM(CASE
			WHEN extras_topping_id IS NULL THEN pizza_cost
            ELSE pizza_cost + (no_of_extras * 1) 
		END) as total_revenue
FROM prices;*/
								

/*3. The Pizza Runner team now wants to add an additional ratings system that allows customers 
to rate their runner, how would you design an additional table for this new dataset - generate
 a schema for this new table and insert your own data for ratings for each successful customer 
 order between 1 to 5.*/

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
    
SELECT * FROM pizza_runner.runner_ratings;
							
/*4. Using your newly generated table - can you join all of the information together to form 
a table which has the following information for successful deliveries?
- customer_id
- order_id
- runner_id
- rating
- order_time
- pickup_time
- Time between order and pickup
- Delivery duration
- Average speed
- Total number of pizzas*/

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

/*5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras 
and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have 
left over after these deliveries?*/

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

# E. Bonus Questions

/* If Danny wants to expand his range of pizzas - how would this impact the existing data 
design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza 
with all the toppings was added to the Pizza Runner menu?*/

SELECT * FROM pizza_names;

INSERT INTO pizza_names
VALUES (3, "Supreme");

SELECT * FROM pizza_names;

SELECT * FROM pizza_recipes_temp;

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

/*Because the pizza recipes table was modified to reflect foreign key designation for each topping linked 
to the base pizza, the pizza_id will have multiple 3s and align with the standard toppings (individually) 
within the toppings column.

In addition, because the data type was casted to an int to take advantage of numerical functions, insertion 
of data would not affect the existing data design, unlike the original dangerous approach of comma separated 
values in a singular row (list)*/
